// ===========================================
// Zsolt Pro AI
// Version: v0.14.2
// File: lib/services/the_sports_db_service.dart
// ===========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TheSportsDbService {
  TheSportsDbService._();

  static final TheSportsDbService instance =
      TheSportsDbService._();

  static const String _baseUrl =
      'https://www.thesportsdb.com/api/v1/json';

  /// Ingyenes fejlesztői kulcs: 123
  ///
  /// Később prémium kulcs használható GitHub Secretből:
  ///
  /// --dart-define=THE_SPORTS_DB_API_KEY=SAJAT_KULCS
  static const String _environmentApiKey =
      String.fromEnvironment(
    'THE_SPORTS_DB_API_KEY',
  );

  static const String _freeApiKey = '123';

  static const Duration _connectionTimeout =
      Duration(seconds: 20);

  static const Duration _responseTimeout =
      Duration(seconds: 30);

  String get apiKey {
    final String configuredKey =
        _environmentApiKey.trim();

    if (configuredKey.isNotEmpty) {
      return configuredKey;
    }

    return _freeApiKey;
  }

  bool get usesFreeApiKey {
    return apiKey == _freeApiKey;
  }

  bool get hasApiKey {
    return apiKey.trim().isNotEmpty;
  }

  String get planLabel {
    return usesFreeApiKey
        ? 'Ingyenes tesztkulcs'
        : 'Saját API-kulcs';
  }

  Future<TheSportsDbConnectionResult>
      testConnection() async {
    try {
      final DateTime today = DateTime.now();

      final List<TheSportsDbEvent> events =
          await fetchEventsByDate(
        today,
      );

      return TheSportsDbConnectionResult(
        success: true,
        message:
            'A TheSportsDB kapcsolat működik. '
            '${events.length} focimeccs érkezett '
            'a mai napra.',
        eventCount: events.length,
        usesFreeApiKey: usesFreeApiKey,
      );
    } on TheSportsDbException catch (error) {
      return TheSportsDbConnectionResult(
        success: false,
        message: error.message,
        statusCode: error.statusCode,
        usesFreeApiKey: usesFreeApiKey,
      );
    } catch (error) {
      return TheSportsDbConnectionResult(
        success: false,
        message:
            'Ismeretlen TheSportsDB hiba: $error',
        usesFreeApiKey: usesFreeApiKey,
      );
    }
  }

  Future<List<TheSportsDbEvent>>
      fetchTodayEvents() {
    return fetchEventsByDate(
      DateTime.now(),
    );
  }

  Future<List<TheSportsDbEvent>>
      fetchTomorrowEvents() {
    return fetchEventsByDate(
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }

  Future<List<TheSportsDbEvent>>
      fetchEventsByDate(
    DateTime date, {
    String sport = 'Soccer',
    String? leagueId,
  }) async {
    _ensureApiKey();

    final Map<String, String> parameters =
        <String, String>{
      'd': _formatDate(date),
      's': sport,
    };

    final String cleanLeagueId =
        leagueId?.trim() ?? '';

    if (cleanLeagueId.isNotEmpty) {
      parameters['l'] = cleanLeagueId;
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/$apiKey/eventsday.php',
    ).replace(
      queryParameters: parameters,
    );

    final dynamic decoded =
        await _getJson(uri);

    if (decoded is! Map<String, dynamic>) {
      throw const TheSportsDbException(
        'A TheSportsDB napi eseményválasza '
        'hibás formátumú.',
      );
    }

    final dynamic rawEvents =
        decoded['events'];

    if (rawEvents == null) {
      return const <TheSportsDbEvent>[];
    }

    if (rawEvents is! List<dynamic>) {
      throw const TheSportsDbException(
        'A TheSportsDB eseménylista '
        'hibás formátumú.',
      );
    }

    final List<TheSportsDbEvent> events =
        rawEvents
            .whereType<Map<String, dynamic>>()
            .map(
              TheSportsDbEvent.fromJson,
            )
            .where(
              (
                TheSportsDbEvent event,
              ) {
                return event.isSoccer &&
                    event.homeTeam.isNotEmpty &&
                    event.awayTeam.isNotEmpty;
              },
            )
            .toList(growable: false);

    events.sort(
      (
        TheSportsDbEvent first,
        TheSportsDbEvent second,
      ) {
        return first.startDateTime.compareTo(
          second.startDateTime,
        );
      },
    );

    return events;
  }

  Future<TheSportsDbAvailabilityResult>
      findNextAvailableEvents({
    required DateTime startDate,
    int daysToCheck = 30,
  }) async {
    if (daysToCheck <= 0) {
      throw const TheSportsDbException(
        'Az ellenőrzendő napok száma '
        'legalább 1 legyen.',
      );
    }

    final int safeDays =
        daysToCheck.clamp(1, 60);

    final DateTime normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    for (int offset = 0;
        offset < safeDays;
        offset++) {
      final DateTime checkedDate =
          normalizedStart.add(
        Duration(days: offset),
      );

      final List<TheSportsDbEvent> events =
          await fetchEventsByDate(
        checkedDate,
      );

      if (events.isNotEmpty) {
        return TheSportsDbAvailabilityResult(
          date: checkedDate,
          events: events,
          checkedDays: offset + 1,
        );
      }
    }

    return TheSportsDbAvailabilityResult(
      date: null,
      events: const <TheSportsDbEvent>[],
      checkedDays: safeDays,
    );
  }

  Future<List<TheSportsDbEvent>>
      fetchEventsBetween({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final DateTime normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    if (normalizedEnd.isBefore(
      normalizedStart,
    )) {
      throw const TheSportsDbException(
        'A záró dátum nem lehet korábbi '
        'a kezdő dátumnál.',
      );
    }

    final List<TheSportsDbEvent> events =
        <TheSportsDbEvent>[];

    DateTime currentDate = normalizedStart;

    while (!currentDate.isAfter(
      normalizedEnd,
    )) {
      events.addAll(
        await fetchEventsByDate(
          currentDate,
        ),
      );

      currentDate = currentDate.add(
        const Duration(days: 1),
      );
    }

    events.sort(
      (
        TheSportsDbEvent first,
        TheSportsDbEvent second,
      ) {
        return first.startDateTime.compareTo(
          second.startDateTime,
        );
      },
    );

    return _removeDuplicateEvents(
      events,
    );
  }

  Future<TheSportsDbEvent?>
      fetchEventById(
    String eventId,
  ) async {
    _ensureApiKey();

    final String cleanId =
        eventId.trim();

    if (cleanId.isEmpty) {
      throw const TheSportsDbException(
        'Az eseményazonosító nem lehet üres.',
      );
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/$apiKey/lookupevent.php',
    ).replace(
      queryParameters: <String, String>{
        'id': cleanId,
      },
    );

    final dynamic decoded =
        await _getJson(uri);

    if (decoded is! Map<String, dynamic>) {
      throw const TheSportsDbException(
        'A TheSportsDB eseményválasza '
        'hibás formátumú.',
      );
    }

    final dynamic rawEvents =
        decoded['events'];

    if (rawEvents is! List<dynamic> ||
        rawEvents.isEmpty) {
      return null;
    }

    for (final dynamic rawEvent in rawEvents) {
      if (rawEvent is Map<String, dynamic>) {
        return TheSportsDbEvent.fromJson(
          rawEvent,
        );
      }
    }

    return null;
  }

  Future<TheSportsDbTeam?>
      fetchTeamById(
    String teamId,
  ) async {
    _ensureApiKey();

    final String cleanId =
        teamId.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/$apiKey/lookupteam.php',
    ).replace(
      queryParameters: <String, String>{
        'id': cleanId,
      },
    );

    final dynamic decoded =
        await _getJson(uri);

    if (decoded is! Map<String, dynamic>) {
      throw const TheSportsDbException(
        'A TheSportsDB csapatválasza '
        'hibás formátumú.',
      );
    }

    final dynamic rawTeams =
        decoded['teams'];

    if (rawTeams is! List<dynamic> ||
        rawTeams.isEmpty) {
      return null;
    }

    for (final dynamic rawTeam in rawTeams) {
      if (rawTeam is Map<String, dynamic>) {
        return TheSportsDbTeam.fromJson(
          rawTeam,
        );
      }
    }

    return null;
  }

  Future<TheSportsDbTeam?>
      searchTeam(
    String teamName,
  ) async {
    _ensureApiKey();

    final String cleanName =
        teamName.trim();

    if (cleanName.isEmpty) {
      return null;
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/$apiKey/searchteams.php',
    ).replace(
      queryParameters: <String, String>{
        't': cleanName,
      },
    );

    final dynamic decoded =
        await _getJson(uri);

    if (decoded is! Map<String, dynamic>) {
      throw const TheSportsDbException(
        'A TheSportsDB csapatkeresési válasza '
        'hibás formátumú.',
      );
    }

    final dynamic rawTeams =
        decoded['teams'];

    if (rawTeams is! List<dynamic> ||
        rawTeams.isEmpty) {
      return null;
    }

    for (final dynamic rawTeam in rawTeams) {
      if (rawTeam is Map<String, dynamic>) {
        return TheSportsDbTeam.fromJson(
          rawTeam,
        );
      }
    }

    return null;
  }

  Future<List<TheSportsDbLeague>>
      fetchSoccerLeagues() async {
    _ensureApiKey();

    final Uri uri = Uri.parse(
      '$_baseUrl/$apiKey/all_leagues.php',
    );

    final dynamic decoded =
        await _getJson(uri);

    if (decoded is! Map<String, dynamic>) {
      throw const TheSportsDbException(
        'A TheSportsDB ligaválasza '
        'hibás formátumú.',
      );
    }

    final dynamic rawLeagues =
        decoded['leagues'];

    if (rawLeagues is! List<dynamic>) {
      return const <TheSportsDbLeague>[];
    }

    final List<TheSportsDbLeague> leagues =
        rawLeagues
            .whereType<Map<String, dynamic>>()
            .map(
              TheSportsDbLeague.fromJson,
            )
            .where(
              (
                TheSportsDbLeague league,
              ) {
                return league.sport
                        .toLowerCase() ==
                    'soccer';
              },
            )
            .toList(growable: false);

    leagues.sort(
      (
        TheSportsDbLeague first,
        TheSportsDbLeague second,
      ) {
        return first.name
            .toLowerCase()
            .compareTo(
              second.name.toLowerCase(),
            );
      },
    );

    return leagues;
  }

  Future<dynamic> _getJson(
    Uri uri,
  ) async {
    final HttpClient client = HttpClient();

    client.connectionTimeout =
        _connectionTimeout;

    try {
      final HttpClientRequest request =
          await client
              .getUrl(uri)
              .timeout(
                _connectionTimeout,
              );

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Zsolt-Pro-AI/0.14.2',
      );

      final HttpClientResponse response =
          await request
              .close()
              .timeout(
                _responseTimeout,
              );

      final String body = await response
          .transform(
            utf8.decoder,
          )
          .join()
          .timeout(
            _responseTimeout,
          );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw TheSportsDbException(
          _buildHttpErrorMessage(
            statusCode:
                response.statusCode,
            body: body,
          ),
          statusCode:
              response.statusCode,
        );
      }

      try {
        return jsonDecode(body);
      } on FormatException catch (error) {
        throw TheSportsDbException(
          'A TheSportsDB nem érvényes JSON '
          'választ küldött. '
          'Részlet: ${error.message}',
        );
      }
    } on TimeoutException catch (error) {
      throw TheSportsDbException(
        'A TheSportsDB API nem válaszolt '
        'időben. Részlet: '
        '${error.message ?? 'időtúllépés'}',
      );
    } on HandshakeException catch (error) {
      throw TheSportsDbException(
        'Biztonságos kapcsolati hiba történt '
        'a TheSportsDB elérésekor. '
        'Részlet: ${error.message}',
      );
    } on SocketException catch (error) {
      throw TheSportsDbException(
        _buildSocketErrorMessage(
          error,
        ),
      );
    } on HttpException catch (error) {
      throw TheSportsDbException(
        'HTTP hálózati hiba történt. '
        'Részlet: ${error.message}',
      );
    } on TheSportsDbException {
      rethrow;
    } catch (error) {
      throw TheSportsDbException(
        'Váratlan TheSportsDB hiba történt. '
        'Típus: ${error.runtimeType}. '
        'Részlet: $error',
      );
    } finally {
      client.close(
        force: true,
      );
    }
  }

  List<TheSportsDbEvent>
      _removeDuplicateEvents(
    List<TheSportsDbEvent> events,
  ) {
    final Map<String, TheSportsDbEvent>
        uniqueEvents =
        <String, TheSportsDbEvent>{};

    for (final TheSportsDbEvent event
        in events) {
      final String key =
          event.id.isNotEmpty
              ? event.id
              : event.uniqueKey;

      uniqueEvents[key] = event;
    }

    final List<TheSportsDbEvent> result =
        uniqueEvents.values.toList()
          ..sort(
            (
              TheSportsDbEvent first,
              TheSportsDbEvent second,
            ) {
              return first.startDateTime
                  .compareTo(
                second.startDateTime,
              );
            },
          );

    return result;
  }

  String _buildHttpErrorMessage({
    required int statusCode,
    required String body,
  }) {
    String? apiMessage;

    try {
      final dynamic decoded =
          jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final dynamic rawMessage =
            decoded['message'] ??
                decoded['error'];

        if (rawMessage != null) {
          apiMessage =
              rawMessage.toString().trim();
        }
      }
    } catch (_) {
      // Az alapértelmezett hibaüzenet marad.
    }

    if (apiMessage != null &&
        apiMessage.isNotEmpty) {
      return 'TheSportsDB API hiba '
          '(HTTP $statusCode): $apiMessage';
    }

    switch (statusCode) {
      case 400:
        return 'TheSportsDB API hiba '
            '(HTTP 400): hibás kérési paraméter.';
      case 401:
        return 'TheSportsDB API hiba '
            '(HTTP 401): hibás API-kulcs.';
      case 403:
        return 'TheSportsDB API hiba '
            '(HTTP 403): nincs hozzáférés '
            'ehhez az adathoz.';
      case 404:
        return 'TheSportsDB API hiba '
            '(HTTP 404): a kért végpont '
            'nem található.';
      case 429:
        return 'TheSportsDB API hiba '
            '(HTTP 429): elérted a percenkénti '
            'lekérési korlátot. '
            'Várj egy percet, majd próbáld újra.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'TheSportsDB szerverhiba '
            '(HTTP $statusCode). '
            'Próbáld újra később.';
      default:
        return 'TheSportsDB API hiba: '
            'HTTP $statusCode.';
    }
  }

  String _buildSocketErrorMessage(
    SocketException error,
  ) {
    final String message =
        error.message.trim();

    final String osMessage =
        error.osError?.message.trim() ?? '';

    final String combined =
        '$message $osMessage'.toLowerCase();

    if (combined.contains(
          'failed host lookup',
        ) ||
        combined.contains(
          'name or service not known',
        ) ||
        combined.contains('dns')) {
      return 'DNS-hiba: a telefon nem tudta '
          'elérni a www.thesportsdb.com címet.';
    }

    if (combined.contains(
          'network is unreachable',
        ) ||
        combined.contains(
          'no route to host',
        )) {
      return 'A hálózat nem érhető el. '
          'Ellenőrizd a mobilinternetet '
          'vagy a Wi-Fi-kapcsolatot.';
    }

    if (combined.contains(
      'connection refused',
    )) {
      return 'A TheSportsDB szervere '
          'elutasította a kapcsolatot.';
    }

    if (combined.contains(
      'timed out',
    )) {
      return 'A TheSportsDB API nem '
          'válaszolt időben.';
    }

    return 'TheSportsDB hálózati hiba: '
        '${error.message}.';
  }

  void _ensureApiKey() {
    if (!hasApiKey) {
      throw const TheSportsDbException(
        'A TheSportsDB API-kulcs nincs '
        'beállítva.',
      );
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    final String year =
        date.year.toString().padLeft(
              4,
              '0',
            );

    final String month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final String day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }
}

class TheSportsDbConnectionResult {
  final bool success;
  final String message;
  final int? statusCode;
  final int eventCount;
  final bool usesFreeApiKey;

  const TheSportsDbConnectionResult({
    required this.success,
    required this.message,
    required this.usesFreeApiKey,
    this.statusCode,
    this.eventCount = 0,
  });
}

class TheSportsDbAvailabilityResult {
  final DateTime? date;
  final List<TheSportsDbEvent> events;
  final int checkedDays;

  const TheSportsDbAvailabilityResult({
    required this.date,
    required this.events,
    required this.checkedDays,
  });

  bool get hasEvents {
    return date != null &&
        events.isNotEmpty;
  }
}

class TheSportsDbEvent {
  final String id;
  final String eventName;
  final String sport;
  final String leagueId;
  final String leagueName;
  final String season;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeam;
  final String awayTeam;
  final String date;
  final String time;
  final String timestamp;
  final String status;
  final String venue;
  final String country;
  final String homeScore;
  final String awayScore;
  final String homeTeamBadgeUrl;
  final String awayTeamBadgeUrl;
  final String leagueBadgeUrl;
  final String eventThumbUrl;
  final String eventPosterUrl;

  const TheSportsDbEvent({
    required this.id,
    required this.eventName,
    required this.sport,
    required this.leagueId,
    required this.leagueName,
    required this.season,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.time,
    required this.timestamp,
    required this.status,
    required this.venue,
    required this.country,
    required this.homeScore,
    required this.awayScore,
    required this.homeTeamBadgeUrl,
    required this.awayTeamBadgeUrl,
    required this.leagueBadgeUrl,
    required this.eventThumbUrl,
    required this.eventPosterUrl,
  });

  factory TheSportsDbEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    final String eventName =
        _readString(
      json,
      <String>[
        'strEvent',
        'strEventAlternate',
      ],
    );

    String homeTeam =
        _readString(
      json,
      <String>[
        'strHomeTeam',
      ],
    );

    String awayTeam =
        _readString(
      json,
      <String>[
        'strAwayTeam',
      ],
    );

    if ((homeTeam.isEmpty ||
            awayTeam.isEmpty) &&
        eventName.isNotEmpty) {
      final List<String> teams =
          _splitEventName(
        eventName,
      );

      if (homeTeam.isEmpty &&
          teams.isNotEmpty) {
        homeTeam = teams.first;
      }

      if (awayTeam.isEmpty &&
          teams.length > 1) {
        awayTeam = teams[1];
      }
    }

    return TheSportsDbEvent(
      id: _readString(
        json,
        <String>[
          'idEvent',
        ],
      ),
      eventName: eventName,
      sport: _readString(
        json,
        <String>[
          'strSport',
        ],
      ),
      leagueId: _readString(
        json,
        <String>[
          'idLeague',
        ],
      ),
      leagueName: _readString(
        json,
        <String>[
          'strLeague',
          'strLeagueAlternate',
        ],
      ),
      season: _readString(
        json,
        <String>[
          'strSeason',
        ],
      ),
      homeTeamId: _readString(
        json,
        <String>[
          'idHomeTeam',
        ],
      ),
      awayTeamId: _readString(
        json,
        <String>[
          'idAwayTeam',
        ],
      ),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      date: _readString(
        json,
        <String>[
          'dateEvent',
          'dateEventLocal',
        ],
      ),
      time: _readString(
        json,
        <String>[
          'strTime',
          'strTimeLocal',
        ],
      ),
      timestamp: _readString(
        json,
        <String>[
          'strTimestamp',
        ],
      ),
      status: _readString(
        json,
        <String>[
          'strStatus',
          'strProgress',
        ],
      ),
      venue: _readString(
        json,
        <String>[
          'strVenue',
        ],
      ),
      country: _readString(
        json,
        <String>[
          'strCountry',
        ],
      ),
      homeScore: _readString(
        json,
        <String>[
          'intHomeScore',
        ],
      ),
      awayScore: _readString(
        json,
        <String>[
          'intAwayScore',
        ],
      ),
      homeTeamBadgeUrl: _readString(
        json,
        <String>[
          'strHomeTeamBadge',
        ],
      ),
      awayTeamBadgeUrl: _readString(
        json,
        <String>[
          'strAwayTeamBadge',
        ],
      ),
      leagueBadgeUrl: _readString(
        json,
        <String>[
          'strLeagueBadge',
        ],
      ),
      eventThumbUrl: _readString(
        json,
        <String>[
          'strThumb',
        ],
      ),
      eventPosterUrl: _readString(
        json,
        <String>[
          'strPoster',
        ],
      ),
    );
  }

  bool get isSoccer {
    final String normalized =
        sport.trim().toLowerCase();

    return normalized == 'soccer' ||
        normalized == 'football';
  }

  bool get hasScore {
    return homeScore.isNotEmpty &&
        awayScore.isNotEmpty;
  }

  String get scoreText {
    if (!hasScore) {
      return '';
    }

    return '$homeScore–$awayScore';
  }

  bool get isLive {
    final String normalized =
        status.toLowerCase();

    return normalized.contains('live') ||
        normalized.contains('in play') ||
        normalized.contains('inplay') ||
        normalized == '1h' ||
        normalized == '2h' ||
        normalized == 'ht' ||
        normalized == 'et' ||
        normalized == 'pen';
  }

  bool get isFinished {
    final String normalized =
        status.toLowerCase();

    return normalized == 'ft' ||
        normalized.contains('finished') ||
        normalized == 'aet' ||
        normalized == 'after penalties';
  }

  DateTime get startDateTime {
    final DateTime? timestampDate =
        DateTime.tryParse(
      timestamp,
    );

    if (timestampDate != null) {
      return timestampDate.toLocal();
    }

    final String cleanDate =
        date.trim();

    String cleanTime =
        time.trim();

    if (cleanTime.endsWith('Z')) {
      cleanTime = cleanTime.substring(
        0,
        cleanTime.length - 1,
      );
    }

    if (cleanTime.isEmpty) {
      cleanTime = '12:00:00';
    }

    final DateTime? combined =
        DateTime.tryParse(
      '${cleanDate}T$cleanTime',
    );

    if (combined != null) {
      return combined.toLocal();
    }

    final DateTime? parsedDate =
        DateTime.tryParse(
      cleanDate,
    );

    return parsedDate ??
        DateTime.fromMillisecondsSinceEpoch(
          0,
        );
  }

  DateTime get matchDate {
    final DateTime start =
        startDateTime;

    return DateTime(
      start.year,
      start.month,
      start.day,
    );
  }

  String get matchTime {
    final DateTime start =
        startDateTime;

    final String hour =
        start.hour.toString().padLeft(
              2,
              '0',
            );

    final String minute =
        start.minute.toString().padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  String get uniqueKey {
    final String normalizedHome =
        _normalizeText(homeTeam);

    final String normalizedAway =
        _normalizeText(awayTeam);

    return '$normalizedHome|'
        '$normalizedAway|'
        '${matchDate.toIso8601String()}';
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value =
          json[key];

      if (value == null) {
        continue;
      }

      final String result =
          value.toString().trim();

      if (result.isNotEmpty &&
          result.toLowerCase() != 'null') {
        return result;
      }
    }

    return '';
  }

  static List<String> _splitEventName(
    String eventName,
  ) {
    final List<String> separators =
        <String>[
      ' vs ',
      ' VS ',
      ' v ',
      ' - ',
      ' – ',
    ];

    for (final String separator
        in separators) {
      final List<String> parts =
          eventName.split(
        separator,
      );

      if (parts.length >= 2) {
        return <String>[
          parts.first.trim(),
          parts.sublist(1).join(
                separator,
              ).trim(),
        ];
      }
    }

    return <String>[
      eventName.trim(),
    ];
  }

  static String _normalizeText(
    String value,
  ) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ő', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ű', 'u')
        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
  }
}

class TheSportsDbTeam {
  final String id;
  final String name;
  final String shortName;
  final String alternateName;
  final String sport;
  final String leagueId;
  final String leagueName;
  final String country;
  final String stadium;
  final String badgeUrl;
  final String logoUrl;
  final String jerseyUrl;
  final String fanartUrl;

  const TheSportsDbTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.alternateName,
    required this.sport,
    required this.leagueId,
    required this.leagueName,
    required this.country,
    required this.stadium,
    required this.badgeUrl,
    required this.logoUrl,
    required this.jerseyUrl,
    required this.fanartUrl,
  });

  factory TheSportsDbTeam.fromJson(
    Map<String, dynamic> json,
  ) {
    return TheSportsDbTeam(
      id: _readString(
        json,
        'idTeam',
      ),
      name: _readString(
        json,
        'strTeam',
      ),
      shortName: _readString(
        json,
        'strTeamShort',
      ),
      alternateName: _readString(
        json,
        'strAlternate',
      ),
      sport: _readString(
        json,
        'strSport',
      ),
      leagueId: _readString(
        json,
        'idLeague',
      ),
      leagueName: _readString(
        json,
        'strLeague',
      ),
      country: _readString(
        json,
        'strCountry',
      ),
      stadium: _readString(
        json,
        'strStadium',
      ),
      badgeUrl: _readString(
        json,
        'strBadge',
      ),
      logoUrl: _readString(
        json,
        'strLogo',
      ),
      jerseyUrl: _readString(
        json,
        'strEquipment',
      ),
      fanartUrl: _readString(
        json,
        'strTeamFanart1',
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key,
  ) {
    final dynamic value =
        json[key];

    if (value == null) {
      return '';
    }

    final String result =
        value.toString().trim();

    if (result.toLowerCase() == 'null') {
      return '';
    }

    return result;
  }
}

class TheSportsDbLeague {
  final String id;
  final String name;
  final String alternateName;
  final String sport;

  const TheSportsDbLeague({
    required this.id,
    required this.name,
    required this.alternateName,
    required this.sport,
  });

  factory TheSportsDbLeague.fromJson(
    Map<String, dynamic> json,
  ) {
    return TheSportsDbLeague(
      id: json['idLeague']
              ?.toString()
              .trim() ??
          '',
      name: json['strLeague']
              ?.toString()
              .trim() ??
          '',
      alternateName:
          json['strLeagueAlternate']
                  ?.toString()
                  .trim() ??
              '',
      sport: json['strSport']
              ?.toString()
              .trim() ??
          '',
    );
  }
}

class TheSportsDbException implements Exception {
  final String message;
  final int? statusCode;

  const TheSportsDbException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}
