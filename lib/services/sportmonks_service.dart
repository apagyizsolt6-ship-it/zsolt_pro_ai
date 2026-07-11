// ===========================================
// Zsolt Pro AI
// Version: v0.13.0
// File: lib/services/sportmonks_service.dart
// ===========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SportMonksService {
  SportMonksService._();

  static final SportMonksService instance =
      SportMonksService._();

  static const String _baseUrl =
      'https://api.sportmonks.com/v3/football';

  static const String _apiToken =
      String.fromEnvironment(
    'SPORTMONKS_API_TOKEN',
  );

  static const Duration _connectionTimeout =
      Duration(seconds: 20);

  static const Duration _responseTimeout =
      Duration(seconds: 30);

  bool get hasApiToken {
    return _apiToken.trim().isNotEmpty;
  }

  Future<SportMonksConnectionResult>
      testConnection() async {
    if (!hasApiToken) {
      return const SportMonksConnectionResult(
        success: false,
        message:
            'A SPORTMONKS_API_TOKEN nincs beállítva az APK-ban.',
      );
    }

    try {
      final DateTime now = DateTime.now();

      final List<SportMonksFixture> fixtures =
          await fetchFixturesByDate(now);

      return SportMonksConnectionResult(
        success: true,
        message:
            'A SportMonks kapcsolat működik. '
            '${fixtures.length} mérkőzés érhető el a mai napra.',
        fixtureCount: fixtures.length,
      );
    } on SportMonksException catch (error) {
      return SportMonksConnectionResult(
        success: false,
        message: error.message,
        statusCode: error.statusCode,
      );
    } catch (error) {
      return SportMonksConnectionResult(
        success: false,
        message:
            'Ismeretlen SportMonks hiba: $error',
      );
    }
  }

  Future<List<SportMonksFixture>>
      fetchTodayFixtures() {
    return fetchFixturesByDate(
      DateTime.now(),
    );
  }

  Future<List<SportMonksFixture>>
      fetchTomorrowFixtures() {
    return fetchFixturesByDate(
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }

  Future<List<SportMonksFixture>>
      fetchFixturesByDate(
    DateTime date, {
    int perPage = 50,
  }) async {
    _ensureApiToken();

    final String formattedDate =
        _formatDate(date);

    final List<SportMonksFixture> fixtures =
        <SportMonksFixture>[];

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Uri uri = Uri.parse(
        '$_baseUrl/fixtures/date/'
        '$formattedDate',
      ).replace(
        queryParameters: <String, String>{
          'api_token': _apiToken,
          'include':
              'participants;league;state',
          'per_page':
              perPage.clamp(1, 50).toString(),
          'page': page.toString(),
        },
      );

      final _SportMonksApiResponse response =
          await _get(uri);

      fixtures.addAll(
        _parseFixtures(response.data),
      );

      hasMore = response.hasMore;
      page += 1;

      if (page > 20) {
        break;
      }
    }

    fixtures.sort(
      (
        SportMonksFixture first,
        SportMonksFixture second,
      ) {
        return first.startingAt.compareTo(
          second.startingAt,
        );
      },
    );

    return fixtures;
  }

  Future<List<SportMonksFixture>>
      fetchFixturesBetween({
    required DateTime startDate,
    required DateTime endDate,
    int perPage = 50,
  }) async {
    _ensureApiToken();

    if (endDate.isBefore(startDate)) {
      throw const SportMonksException(
        'A záró dátum nem lehet korábbi '
        'a kezdő dátumnál.',
      );
    }

    final List<SportMonksFixture> fixtures =
        <SportMonksFixture>[];

    DateTime currentDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final DateTime finalDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    while (!currentDate.isAfter(finalDate)) {
      fixtures.addAll(
        await fetchFixturesByDate(
          currentDate,
          perPage: perPage,
        ),
      );

      currentDate = currentDate.add(
        const Duration(days: 1),
      );
    }

    fixtures.sort(
      (
        SportMonksFixture first,
        SportMonksFixture second,
      ) {
        return first.startingAt.compareTo(
          second.startingAt,
        );
      },
    );

    return fixtures;
  }

  Future<SportMonksFixture?>
      fetchFixtureById(
    int fixtureId,
  ) async {
    _ensureApiToken();

    if (fixtureId <= 0) {
      throw const SportMonksException(
        'A mérkőzés azonosítója érvénytelen.',
      );
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/fixtures/$fixtureId',
    ).replace(
      queryParameters: <String, String>{
        'api_token': _apiToken,
        'include':
            'participants;league;state;scores',
      },
    );

    final _SportMonksApiResponse response =
        await _get(uri);

    final dynamic data = response.data;

    if (data is! Map<String, dynamic>) {
      return null;
    }

    return SportMonksFixture.fromJson(
      data,
    );
  }

  Future<List<SportMonksFixture>>
      fetchLiveFixtures() async {
    _ensureApiToken();

    final Uri uri = Uri.parse(
      '$_baseUrl/livescores/inplay',
    ).replace(
      queryParameters: <String, String>{
        'api_token': _apiToken,
        'include':
            'participants;league;state;scores',
      },
    );

    final _SportMonksApiResponse response =
        await _get(uri);

    final List<SportMonksFixture> fixtures =
        _parseFixtures(response.data);

    fixtures.sort(
      (
        SportMonksFixture first,
        SportMonksFixture second,
      ) {
        return first.startingAt.compareTo(
          second.startingAt,
        );
      },
    );

    return fixtures;
  }

  List<SportMonksFixture> _parseFixtures(
    dynamic data,
  ) {
    if (data is! List<dynamic>) {
      return const <SportMonksFixture>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          SportMonksFixture.fromJson,
        )
        .where(
          (SportMonksFixture fixture) {
            return fixture.homeTeam.isNotEmpty &&
                fixture.awayTeam.isNotEmpty;
          },
        )
        .toList(growable: false);
  }

  Future<_SportMonksApiResponse> _get(
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
        'Zsolt-Pro-AI/0.13.0',
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
        throw SportMonksException(
          _buildErrorMessage(
            statusCode:
                response.statusCode,
            body: body,
          ),
          statusCode:
              response.statusCode,
        );
      }

      final dynamic decoded =
          _decodeJson(body);

      if (decoded
          is! Map<String, dynamic>) {
        throw const SportMonksException(
          'A SportMonks válasza hibás formátumú.',
        );
      }

      final dynamic data = decoded['data'];

      final dynamic pagination =
          decoded['pagination'];

      bool hasMore = false;

      if (pagination
          is Map<String, dynamic>) {
        hasMore =
            pagination['has_more'] == true;
      }

      return _SportMonksApiResponse(
        data: data,
        hasMore: hasMore,
      );
    } on TimeoutException catch (error) {
      throw SportMonksException(
        'A SportMonks API nem válaszolt időben. '
        'Részlet: '
        '${error.message ?? 'időtúllépés'}',
      );
    } on HandshakeException catch (error) {
      throw SportMonksException(
        'TLS-kapcsolati hiba történt a '
        'SportMonks API elérésekor. '
        'Részlet: ${error.message}',
      );
    } on SocketException catch (error) {
      throw SportMonksException(
        _buildSocketErrorMessage(error),
      );
    } on HttpException catch (error) {
      throw SportMonksException(
        'HTTP hálózati hiba történt. '
        'Részlet: ${error.message}',
      );
    } on SportMonksException {
      rethrow;
    } catch (error) {
      throw SportMonksException(
        'Váratlan SportMonks hiba történt. '
        'Típus: ${error.runtimeType}. '
        'Részlet: $error',
      );
    } finally {
      client.close(
        force: true,
      );
    }
  }

  dynamic _decodeJson(
    String body,
  ) {
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw SportMonksException(
        'A SportMonks válasza nem érvényes JSON. '
        'Részlet: ${error.message}',
      );
    }
  }

  String _buildErrorMessage({
    required int statusCode,
    required String body,
  }) {
    String? message;

    try {
      final dynamic decoded =
          jsonDecode(body);

      if (decoded
          is Map<String, dynamic>) {
        final dynamic rawMessage =
            decoded['message'];

        if (rawMessage != null) {
          message =
              rawMessage.toString().trim();
        }

        final dynamic error =
            decoded['error'];

        if ((message == null ||
                message.isEmpty) &&
            error != null) {
          message =
              error.toString().trim();
        }
      }
    } catch (_) {
      // Az alapértelmezett HTTP-hibaüzenet marad.
    }

    if (message != null &&
        message.isNotEmpty) {
      return 'SportMonks API hiba '
          '(HTTP $statusCode): $message';
    }

    switch (statusCode) {
      case 400:
        return 'SportMonks API hiba '
            '(HTTP 400): hibás kérési paraméter.';
      case 401:
        return 'SportMonks API hiba '
            '(HTTP 401): hibás vagy hiányzó API-token.';
      case 403:
        return 'SportMonks API hiba '
            '(HTTP 403): ehhez az adathoz '
            'nincs hozzáférés az előfizetésben.';
      case 404:
        return 'SportMonks API hiba '
            '(HTTP 404): a kért végpont vagy '
            'mérkőzés nem található.';
      case 429:
        return 'SportMonks API hiba '
            '(HTTP 429): túl sok API-kérés történt.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'SportMonks szerverhiba '
            '(HTTP $statusCode). '
            'Próbáld újra később.';
      default:
        return 'SportMonks API hiba: '
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
          'elérni az api.sportmonks.com címet.';
    }

    if (combined.contains(
          'network is unreachable',
        ) ||
        combined.contains(
          'no route to host',
        )) {
      return 'A hálózat nem érhető el. '
          'Ellenőrizd a mobilinternetet vagy '
          'a Wi-Fi-kapcsolatot.';
    }

    if (combined.contains(
          'connection refused',
        )) {
      return 'A SportMonks szervere '
          'elutasította a kapcsolatot.';
    }

    if (combined.contains(
          'timed out',
        )) {
      return 'A SportMonks API nem válaszolt időben.';
    }

    return 'SportMonks hálózati hiba: '
        '${error.message}.';
  }

  void _ensureApiToken() {
    if (!hasApiToken) {
      throw const SportMonksException(
        'A SPORTMONKS_API_TOKEN nincs '
        'beállítva az alkalmazás buildjében.',
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

class SportMonksConnectionResult {
  final bool success;
  final String message;
  final int? statusCode;
  final int? fixtureCount;

  const SportMonksConnectionResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.fixtureCount,
  });
}

class SportMonksFixture {
  final int id;
  final int leagueId;
  final int seasonId;
  final int stateId;
  final String name;
  final DateTime startingAt;
  final int startingAtTimestamp;
  final String resultInfo;
  final bool placeholder;
  final bool hasOdds;
  final String leagueName;
  final String leagueImagePath;
  final String stateName;
  final String stateShortName;
  final SportMonksParticipant? homeParticipant;
  final SportMonksParticipant? awayParticipant;
  final List<SportMonksParticipant> participants;

  const SportMonksFixture({
    required this.id,
    required this.leagueId,
    required this.seasonId,
    required this.stateId,
    required this.name,
    required this.startingAt,
    required this.startingAtTimestamp,
    required this.resultInfo,
    required this.placeholder,
    required this.hasOdds,
    required this.leagueName,
    required this.leagueImagePath,
    required this.stateName,
    required this.stateShortName,
    required this.homeParticipant,
    required this.awayParticipant,
    required this.participants,
  });

  String get homeTeam {
    return homeParticipant?.name ??
        _teamNameFromFixtureName(
          position: 0,
        );
  }

  String get awayTeam {
    return awayParticipant?.name ??
        _teamNameFromFixtureName(
          position: 1,
        );
  }

  int get homeTeamId {
    return homeParticipant?.id ?? 0;
  }

  int get awayTeamId {
    return awayParticipant?.id ?? 0;
  }

  String get homeTeamImagePath {
    return homeParticipant?.imagePath ?? '';
  }

  String get awayTeamImagePath {
    return awayParticipant?.imagePath ?? '';
  }

  bool get isLive {
    final String state =
        stateShortName.toLowerCase();

    return state == 'live' ||
        state == '1st' ||
        state == '2nd' ||
        state == 'ht' ||
        state == 'et' ||
        state == 'pen_live' ||
        stateName.toLowerCase().contains(
          'inplay',
        ) ||
        stateName.toLowerCase().contains(
          'live',
        );
  }

  bool get isFinished {
    final String state =
        stateShortName.toLowerCase();

    return state == 'ft' ||
        state == 'aet' ||
        state == 'pen' ||
        stateName.toLowerCase().contains(
          'finished',
        );
  }

  String get matchTime {
    final DateTime local =
        startingAt.toLocal();

    final String hour =
        local.hour.toString().padLeft(
              2,
              '0',
            );

    final String minute =
        local.minute.toString().padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  factory SportMonksFixture.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<SportMonksParticipant>
        participants =
        _parseParticipants(
      json['participants'],
    );

    SportMonksParticipant?
        homeParticipant;

    SportMonksParticipant?
        awayParticipant;

    for (final SportMonksParticipant
        participant in participants) {
      final String location =
          participant.location.toLowerCase();

      if (location == 'home') {
        homeParticipant = participant;
      }

      if (location == 'away') {
        awayParticipant = participant;
      }
    }

    if (homeParticipant == null &&
        participants.isNotEmpty) {
      homeParticipant = participants.first;
    }

    if (awayParticipant == null &&
        participants.length > 1) {
      awayParticipant = participants[1];
    }

    final Map<String, dynamic>? league =
        _asMap(json['league']);

    final Map<String, dynamic>? state =
        _asMap(json['state']);

    final String rawStartingAt =
        json['starting_at']?.toString() ?? '';

    final int timestamp =
        _toInt(
      json['starting_at_timestamp'],
    );

    DateTime? parsedStartingAt =
        DateTime.tryParse(rawStartingAt);

    if (parsedStartingAt == null &&
        timestamp > 0) {
      parsedStartingAt =
          DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000,
        isUtc: true,
      );
    }

    return SportMonksFixture(
      id: _toInt(json['id']),
      leagueId:
          _toInt(json['league_id']),
      seasonId:
          _toInt(json['season_id']),
      stateId:
          _toInt(json['state_id']),
      name: json['name']?.toString() ??
          '',
      startingAt: parsedStartingAt ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
            isUtc: true,
          ),
      startingAtTimestamp: timestamp,
      resultInfo:
          json['result_info']?.toString() ??
              '',
      placeholder:
          json['placeholder'] == true,
      hasOdds: json['has_odds'] == true ||
          json['has_premium_odds'] == true,
      leagueName:
          league?['name']?.toString() ??
              'Ismeretlen bajnokság',
      leagueImagePath:
          league?['image_path']
                  ?.toString() ??
              '',
      stateName:
          state?['name']?.toString() ??
              '',
      stateShortName:
          state?['short_name']
                  ?.toString() ??
              state?['code']?.toString() ??
              '',
      homeParticipant:
          homeParticipant,
      awayParticipant:
          awayParticipant,
      participants: participants,
    );
  }

  String _teamNameFromFixtureName({
    required int position,
  }) {
    if (name.trim().isEmpty) {
      return position == 0
          ? 'Hazai csapat'
          : 'Vendég csapat';
    }

    final List<String> separators =
        <String>[
      ' vs ',
      ' - ',
      ' v ',
      '–',
    ];

    for (final String separator
        in separators) {
      final List<String> parts =
          name.split(separator);

      if (parts.length >= 2) {
        return parts[position].trim();
      }
    }

    return position == 0
        ? name.trim()
        : 'Vendég csapat';
  }

  static List<SportMonksParticipant>
      _parseParticipants(
    dynamic rawParticipants,
  ) {
    if (rawParticipants
        is! List<dynamic>) {
      return const
          <SportMonksParticipant>[];
    }

    return rawParticipants
        .whereType<Map<String, dynamic>>()
        .map(
          SportMonksParticipant.fromJson,
        )
        .toList(growable: false);
  }

  static Map<String, dynamic>? _asMap(
    dynamic value,
  ) {
    if (value
        is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class SportMonksParticipant {
  final int id;
  final String name;
  final String shortCode;
  final String imagePath;
  final String location;
  final int position;

  const SportMonksParticipant({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.imagePath,
    required this.location,
    required this.position,
  });

  factory SportMonksParticipant.fromJson(
    Map<String, dynamic> json,
  ) {
    final Map<String, dynamic>? meta =
        json['meta']
                is Map<String, dynamic>
            ? json['meta']
                as Map<String, dynamic>
            : null;

    return SportMonksParticipant(
      id: _toInt(json['id']),
      name: json['name']?.toString() ??
          '',
      shortCode:
          json['short_code']?.toString() ??
              '',
      imagePath:
          json['image_path']?.toString() ??
              '',
      location:
          meta?['location']?.toString() ??
              '',
      position:
          _toInt(meta?['position']),
    );
  }

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class SportMonksException implements Exception {
  final String message;
  final int? statusCode;

  const SportMonksException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}

class _SportMonksApiResponse {
  final dynamic data;
  final bool hasMore;

  const _SportMonksApiResponse({
    required this.data,
    required this.hasMore,
  });
}
