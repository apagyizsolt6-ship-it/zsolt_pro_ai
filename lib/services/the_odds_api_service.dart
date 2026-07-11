// ===========================================
// Zsolt Pro AI
// Version: v0.11.2
// File: lib/services/the_odds_api_service.dart
// ===========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TheOddsApiService {
  TheOddsApiService._();

  static final TheOddsApiService instance =
      TheOddsApiService._();

  static const String _baseUrl =
      'https://api.the-odds-api.com/v4';

  static const String _apiKey =
      String.fromEnvironment(
    'THE_ODDS_API_KEY',
  );

  static const Duration _connectionTimeout =
      Duration(seconds: 20);

  static const Duration _responseTimeout =
      Duration(seconds: 30);

  int? _requestsRemaining;
  int? _requestsUsed;
  int? _requestsLast;

  bool get hasApiKey {
    return _apiKey.trim().isNotEmpty;
  }

  int? get requestsRemaining {
    return _requestsRemaining;
  }

  int? get requestsUsed {
    return _requestsUsed;
  }

  int? get requestsLast {
    return _requestsLast;
  }

  Future<OddsApiConnectionResult>
      testConnection() async {
    if (!hasApiKey) {
      return const OddsApiConnectionResult(
        success: false,
        message:
            'A THE_ODDS_API_KEY nincs beállítva az APK-ban.',
      );
    }

    try {
      final List<OddsSport> sports =
          await fetchSports();

      final int activeSportCount = sports
          .where(
            (OddsSport sport) => sport.active,
          )
          .length;

      return OddsApiConnectionResult(
        success: true,
        message:
            'A The Odds API kapcsolat működik. '
            '$activeSportCount aktív sport érhető el.',
        requestsRemaining: _requestsRemaining,
        requestsUsed: _requestsUsed,
      );
    } on OddsApiException catch (error) {
      return OddsApiConnectionResult(
        success: false,
        message: error.message,
        statusCode: error.statusCode,
        requestsRemaining: _requestsRemaining,
        requestsUsed: _requestsUsed,
      );
    } catch (error) {
      return OddsApiConnectionResult(
        success: false,
        message:
            'Ismeretlen kapcsolati hiba: $error',
        requestsRemaining: _requestsRemaining,
        requestsUsed: _requestsUsed,
      );
    }
  }

  Future<List<OddsSport>> fetchSports() async {
    _ensureApiKey();

    final Uri uri = Uri.parse(
      '$_baseUrl/sports',
    ).replace(
      queryParameters: <String, String>{
        'apiKey': _apiKey,
      },
    );

    final _ApiResponse response =
        await _get(uri);

    final dynamic decoded =
        _decodeJson(response.body);

    if (decoded is! List<dynamic>) {
      throw const OddsApiException(
        'A sportlista válasza hibás formátumú.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(OddsSport.fromJson)
        .toList(growable: false);
  }

  Future<List<OddsEvent>> fetchOdds({
    required String sportKey,
    String regions = 'eu',
    List<String> markets = const <String>[
      'h2h',
      'totals',
    ],
    String oddsFormat = 'decimal',
    DateTime? commenceTimeFrom,
    DateTime? commenceTimeTo,
  }) async {
    _ensureApiKey();

    final String cleanSportKey =
        sportKey.trim();

    if (cleanSportKey.isEmpty) {
      throw const OddsApiException(
        'A sport azonosítója nem lehet üres.',
      );
    }

    if (markets.isEmpty) {
      throw const OddsApiException(
        'Legalább egy odds piacot meg kell adni.',
      );
    }

    final Map<String, String> parameters =
        <String, String>{
      'apiKey': _apiKey,
      'regions': regions,
      'markets': markets.join(','),
      'oddsFormat': oddsFormat,
      'dateFormat': 'iso',
    };

    if (commenceTimeFrom != null) {
      parameters['commenceTimeFrom'] =
          _formatApiDate(
        commenceTimeFrom,
      );
    }

    if (commenceTimeTo != null) {
      parameters['commenceTimeTo'] =
          _formatApiDate(
        commenceTimeTo,
      );
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/sports/'
      '${Uri.encodeComponent(cleanSportKey)}/odds',
    ).replace(
      queryParameters: parameters,
    );

    final _ApiResponse response =
        await _get(uri);

    final dynamic decoded =
        _decodeJson(response.body);

    if (decoded is! List<dynamic>) {
      throw const OddsApiException(
        'Az odds válasza hibás formátumú.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(OddsEvent.fromJson)
        .toList(growable: false);
  }

  Future<OddsEvent?> findMatchOdds({
    required String sportKey,
    required String homeTeam,
    required String awayTeam,
    required DateTime matchDate,
    String regions = 'eu',
    List<String> markets = const <String>[
      'h2h',
      'totals',
    ],
  }) async {
    final DateTime from = matchDate
        .subtract(
          const Duration(hours: 18),
        )
        .toUtc();

    final DateTime to = matchDate
        .add(
          const Duration(hours: 30),
        )
        .toUtc();

    final List<OddsEvent> events =
        await fetchOdds(
      sportKey: sportKey,
      regions: regions,
      markets: markets,
      commenceTimeFrom: from,
      commenceTimeTo: to,
    );

    final String normalizedHome =
        _normalizeTeamName(homeTeam);

    final String normalizedAway =
        _normalizeTeamName(awayTeam);

    OddsEvent? bestMatch;
    int bestScore = 0;

    for (final OddsEvent event in events) {
      final String eventHome =
          _normalizeTeamName(event.homeTeam);

      final String eventAway =
          _normalizeTeamName(event.awayTeam);

      int score = 0;

      if (eventHome == normalizedHome) {
        score += 5;
      } else if (_namesSimilar(
        eventHome,
        normalizedHome,
      )) {
        score += 3;
      }

      if (eventAway == normalizedAway) {
        score += 5;
      } else if (_namesSimilar(
        eventAway,
        normalizedAway,
      )) {
        score += 3;
      }

      final Duration difference =
          event.commenceTime.difference(
        matchDate.toUtc(),
      );

      final int hourDifference =
          difference.inHours.abs();

      if (hourDifference <= 3) {
        score += 3;
      } else if (hourDifference <= 12) {
        score += 2;
      } else if (hourDifference <= 24) {
        score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = event;
      }
    }

    if (bestScore < 6) {
      return null;
    }

    return bestMatch;
  }

  double? findBestHomeWinOdds(
    OddsEvent event,
  ) {
    return _findBestOutcomePrice(
      event: event,
      marketKey: 'h2h',
      outcomeName: event.homeTeam,
    );
  }

  double? findBestDrawOdds(
    OddsEvent event,
  ) {
    return _findBestOutcomePrice(
      event: event,
      marketKey: 'h2h',
      outcomeName: 'Draw',
    );
  }

  double? findBestAwayWinOdds(
    OddsEvent event,
  ) {
    return _findBestOutcomePrice(
      event: event,
      marketKey: 'h2h',
      outcomeName: event.awayTeam,
    );
  }

  double? findBestTotalOdds({
    required OddsEvent event,
    required String side,
    required double point,
  }) {
    final String normalizedSide =
        side.trim().toLowerCase();

    double? bestPrice;

    for (final OddsBookmaker bookmaker
        in event.bookmakers) {
      final OddsMarket? market =
          bookmaker.marketByKey('totals');

      if (market == null) {
        continue;
      }

      for (final OddsOutcome outcome
          in market.outcomes) {
        final bool sameSide =
            outcome.name
                    .trim()
                    .toLowerCase() ==
                normalizedSide;

        final bool samePoint =
            outcome.point != null &&
                (outcome.point! - point).abs() <
                    0.001;

        if (!sameSide ||
            !samePoint ||
            outcome.price <= 0) {
          continue;
        }

        if (bestPrice == null ||
            outcome.price > bestPrice) {
          bestPrice = outcome.price;
        }
      }
    }

    return bestPrice;
  }

  double? _findBestOutcomePrice({
    required OddsEvent event,
    required String marketKey,
    required String outcomeName,
  }) {
    final String normalizedOutcome =
        _normalizeTeamName(outcomeName);

    double? bestPrice;

    for (final OddsBookmaker bookmaker
        in event.bookmakers) {
      final OddsMarket? market =
          bookmaker.marketByKey(
        marketKey,
      );

      if (market == null) {
        continue;
      }

      for (final OddsOutcome outcome
          in market.outcomes) {
        final String normalizedName =
            _normalizeTeamName(outcome.name);

        if (normalizedName !=
                normalizedOutcome ||
            outcome.price <= 0) {
          continue;
        }

        if (bestPrice == null ||
            outcome.price > bestPrice) {
          bestPrice = outcome.price;
        }
      }
    }

    return bestPrice;
  }

  Future<_ApiResponse> _get(
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
        'Zsolt-Pro-AI/0.11.2',
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

      _updateQuotaData(response);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw OddsApiException(
          _buildErrorMessage(
            statusCode:
                response.statusCode,
            body: body,
          ),
          statusCode:
              response.statusCode,
        );
      }

      return _ApiResponse(
        body: body,
        requestsRemaining:
            _requestsRemaining,
        requestsUsed: _requestsUsed,
        requestsLast: _requestsLast,
      );
    } on TimeoutException catch (error) {
      throw OddsApiException(
        'Időtúllépés történt a The Odds API '
        'kapcsolódásakor. Részlet: '
        '${error.message ?? 'nincs válasz'}',
      );
    } on HandshakeException catch (error) {
      throw OddsApiException(
        'Biztonságos TLS-kapcsolati hiba történt. '
        'Részlet: ${error.message}',
      );
    } on SocketException catch (error) {
      throw OddsApiException(
        _buildSocketErrorMessage(error),
      );
    } on HttpException catch (error) {
      throw OddsApiException(
        'HTTP hálózati hiba történt. '
        'Részlet: ${error.message}',
      );
    } on FormatException catch (error) {
      throw OddsApiException(
        'Az odds szolgáltatás hibás szöveges '
        'adatot küldött. Részlet: '
        '${error.message}',
      );
    } on OddsApiException {
      rethrow;
    } catch (error) {
      throw OddsApiException(
        'Váratlan hálózati hiba történt. '
        'Típus: ${error.runtimeType}. '
        'Részlet: $error',
      );
    } finally {
      client.close(
        force: true,
      );
    }
  }

  String _formatApiDate(
    DateTime date,
  ) {
    final DateTime utcDate =
        date.toUtc();

    final String year =
        utcDate.year
            .toString()
            .padLeft(4, '0');

    final String month =
        utcDate.month
            .toString()
            .padLeft(2, '0');

    final String day =
        utcDate.day
            .toString()
            .padLeft(2, '0');

    final String hour =
        utcDate.hour
            .toString()
            .padLeft(2, '0');

    final String minute =
        utcDate.minute
            .toString()
            .padLeft(2, '0');

    final String second =
        utcDate.second
            .toString()
            .padLeft(2, '0');

    return '$year-$month-${day}T'
        '$hour:$minute:${second}Z';
  }

  void _updateQuotaData(
    HttpClientResponse response,
  ) {
    _requestsRemaining = _readIntHeader(
      response,
      'x-requests-remaining',
    );

    _requestsUsed = _readIntHeader(
      response,
      'x-requests-used',
    );

    _requestsLast = _readIntHeader(
      response,
      'x-requests-last',
    );
  }

  String _buildSocketErrorMessage(
    SocketException error,
  ) {
    final String socketMessage =
        error.message.trim();

    final String osMessage =
        error.osError?.message.trim() ?? '';

    final int? errorCode =
        error.osError?.errorCode;

    final String combined =
        '$socketMessage $osMessage'
            .toLowerCase();

    if (combined.contains(
          'failed host lookup',
        ) ||
        combined.contains(
          'name or service not known',
        ) ||
        combined.contains(
          'nodename nor servname',
        ) ||
        combined.contains('dns')) {
      return 'DNS-hiba: a telefon nem tudta '
          'feloldani az api.the-odds-api.com '
          'címet. Ellenőrizd az internetet, '
          'a privát DNS-t, a VPN-t vagy a '
          'reklámblokkolót. Technikai részlet: '
          '${_socketDetails(error, errorCode)}';
    }

    if (combined.contains(
          'network is unreachable',
        ) ||
        combined.contains(
          'no route to host',
        )) {
      return 'A hálózat nem érhető el. '
          'Ellenőrizd a mobilinternetet vagy '
          'a Wi-Fi-kapcsolatot. Technikai részlet: '
          '${_socketDetails(error, errorCode)}';
    }

    if (combined.contains(
          'connection refused',
        )) {
      return 'A The Odds API szervere '
          'elutasította a kapcsolatot. '
          'Technikai részlet: '
          '${_socketDetails(error, errorCode)}';
    }

    if (combined.contains(
          'connection reset',
        ) ||
        combined.contains(
          'broken pipe',
        )) {
      return 'A hálózati kapcsolat megszakadt '
          'az adatátvitel közben. '
          'Technikai részlet: '
          '${_socketDetails(error, errorCode)}';
    }

    if (combined.contains(
          'timed out',
        )) {
      return 'A The Odds API nem válaszolt '
          'időben. Technikai részlet: '
          '${_socketDetails(error, errorCode)}';
    }

    return 'Socket hálózati hiba történt. '
        'Technikai részlet: '
        '${_socketDetails(error, errorCode)}';
  }

  String _socketDetails(
    SocketException error,
    int? errorCode,
  ) {
    final List<String> details =
        <String>[];

    if (error.message.trim().isNotEmpty) {
      details.add(error.message.trim());
    }

    final String? osMessage =
        error.osError?.message.trim();

    if (osMessage != null &&
        osMessage.isNotEmpty &&
        osMessage != error.message.trim()) {
      details.add(osMessage);
    }

    if (errorCode != null) {
      details.add('hibakód: $errorCode');
    }

    if (error.address != null) {
      details.add(
        'cím: ${error.address!.address}',
      );
    }

    if (error.port != null) {
      details.add(
        'port: ${error.port}',
      );
    }

    if (details.isEmpty) {
      return 'ismeretlen SocketException';
    }

    return details.join(', ');
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw OddsApiException(
        'Az API válasza nem érvényes JSON. '
        'Részlet: ${error.message}',
      );
    }
  }

  void _ensureApiKey() {
    if (!hasApiKey) {
      throw const OddsApiException(
        'A THE_ODDS_API_KEY nincs beállítva '
        'az alkalmazás buildjében.',
      );
    }
  }

  int? _readIntHeader(
    HttpClientResponse response,
    String name,
  ) {
    final String? value =
        response.headers.value(name);

    if (value == null) {
      return null;
    }

    return int.tryParse(
      value.trim(),
    );
  }

  String _buildErrorMessage({
    required int statusCode,
    required String body,
  }) {
    String? apiMessage;
    String? apiErrorCode;

    try {
      final dynamic decoded =
          jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final dynamic message =
            decoded['message'];

        final dynamic errorCode =
            decoded['error_code'];

        if (message != null) {
          apiMessage =
              message.toString().trim();
        }

        if (errorCode != null) {
          apiErrorCode =
              errorCode.toString().trim();
        }
      }
    } catch (_) {
      // Ha nem JSON, az alap HTTP-hibaüzenet marad.
    }

    final String suffix =
        apiErrorCode != null &&
                apiErrorCode.isNotEmpty
            ? ' ($apiErrorCode)'
            : '';

    if (apiMessage != null &&
        apiMessage.isNotEmpty) {
      return 'The Odds API hiba '
          '(HTTP $statusCode): '
          '$apiMessage$suffix';
    }

    switch (statusCode) {
      case 400:
        return 'The Odds API hiba (HTTP 400): '
            'hibás kérési paraméter.';
      case 401:
        return 'The Odds API hiba (HTTP 401): '
            'érvénytelen vagy hiányzó API-kulcs.';
      case 404:
        return 'The Odds API hiba (HTTP 404): '
            'a sportkulcs vagy a végpont nem található.';
      case 422:
        return 'The Odds API hiba (HTTP 422): '
            'nem támogatott piac vagy paraméter.';
      case 429:
        return 'The Odds API hiba (HTTP 429): '
            'elfogyott vagy túllépésre került '
            'az API-kvóta.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'The Odds API szerverhiba '
            '(HTTP $statusCode). Próbáld újra később.';
      default:
        return 'The Odds API hiba: '
            'HTTP $statusCode.';
    }
  }

  String _normalizeTeamName(
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

  bool _namesSimilar(
    String first,
    String second,
  ) {
    if (first.isEmpty || second.isEmpty) {
      return false;
    }

    if (first == second) {
      return true;
    }

    if (first.contains(second) ||
        second.contains(first)) {
      return true;
    }

    final int shortestLength =
        first.length < second.length
            ? first.length
            : second.length;

    if (shortestLength < 5) {
      return false;
    }

    final String firstPrefix =
        first.substring(
      0,
      shortestLength >= 7 ? 7 : 5,
    );

    final String secondPrefix =
        second.substring(
      0,
      shortestLength >= 7 ? 7 : 5,
    );

    return firstPrefix == secondPrefix;
  }
}

class OddsApiConnectionResult {
  final bool success;
  final String message;
  final int? statusCode;
  final int? requestsRemaining;
  final int? requestsUsed;

  const OddsApiConnectionResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.requestsRemaining,
    this.requestsUsed,
  });
}

class OddsSport {
  final String key;
  final String group;
  final String title;
  final String description;
  final bool active;
  final bool hasOutrights;

  const OddsSport({
    required this.key,
    required this.group,
    required this.title,
    required this.description,
    required this.active,
    required this.hasOutrights,
  });

  factory OddsSport.fromJson(
    Map<String, dynamic> json,
  ) {
    return OddsSport(
      key: json['key']?.toString() ?? '',
      group:
          json['group']?.toString() ?? '',
      title:
          json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ??
              '',
      active: json['active'] == true,
      hasOutrights:
          json['has_outrights'] == true,
    );
  }
}

class OddsEvent {
  final String id;
  final String sportKey;
  final String sportTitle;
  final DateTime commenceTime;
  final String homeTeam;
  final String awayTeam;
  final List<OddsBookmaker> bookmakers;

  const OddsEvent({
    required this.id,
    required this.sportKey,
    required this.sportTitle,
    required this.commenceTime,
    required this.homeTeam,
    required this.awayTeam,
    required this.bookmakers,
  });

  factory OddsEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    final DateTime? parsedDate =
        DateTime.tryParse(
      json['commence_time']?.toString() ??
          '',
    );

    final dynamic bookmakerData =
        json['bookmakers'];

    final List<OddsBookmaker> bookmakers =
        bookmakerData is List<dynamic>
            ? bookmakerData
                .whereType<
                    Map<String, dynamic>>()
                .map(
                  OddsBookmaker.fromJson,
                )
                .toList(growable: false)
            : const <OddsBookmaker>[];

    return OddsEvent(
      id: json['id']?.toString() ?? '',
      sportKey:
          json['sport_key']?.toString() ??
              '',
      sportTitle:
          json['sport_title']?.toString() ??
              '',
      commenceTime: parsedDate ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
            isUtc: true,
          ),
      homeTeam:
          json['home_team']?.toString() ??
              '',
      awayTeam:
          json['away_team']?.toString() ??
              '',
      bookmakers: bookmakers,
    );
  }
}

class OddsBookmaker {
  final String key;
  final String title;
  final DateTime? lastUpdate;
  final List<OddsMarket> markets;

  const OddsBookmaker({
    required this.key,
    required this.title,
    required this.lastUpdate,
    required this.markets,
  });

  factory OddsBookmaker.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic marketData =
        json['markets'];

    final List<OddsMarket> markets =
        marketData is List<dynamic>
            ? marketData
                .whereType<
                    Map<String, dynamic>>()
                .map(
                  OddsMarket.fromJson,
                )
                .toList(growable: false)
            : const <OddsMarket>[];

    return OddsBookmaker(
      key: json['key']?.toString() ?? '',
      title:
          json['title']?.toString() ?? '',
      lastUpdate: DateTime.tryParse(
        json['last_update']?.toString() ??
            '',
      ),
      markets: markets,
    );
  }

  OddsMarket? marketByKey(
    String marketKey,
  ) {
    for (final OddsMarket market
        in markets) {
      if (market.key == marketKey) {
        return market;
      }
    }

    return null;
  }
}

class OddsMarket {
  final String key;
  final DateTime? lastUpdate;
  final List<OddsOutcome> outcomes;

  const OddsMarket({
    required this.key,
    required this.lastUpdate,
    required this.outcomes,
  });

  factory OddsMarket.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic outcomeData =
        json['outcomes'];

    final List<OddsOutcome> outcomes =
        outcomeData is List<dynamic>
            ? outcomeData
                .whereType<
                    Map<String, dynamic>>()
                .map(
                  OddsOutcome.fromJson,
                )
                .toList(growable: false)
            : const <OddsOutcome>[];

    return OddsMarket(
      key: json['key']?.toString() ?? '',
      lastUpdate: DateTime.tryParse(
        json['last_update']?.toString() ??
            '',
      ),
      outcomes: outcomes,
    );
  }
}

class OddsOutcome {
  final String name;
  final double price;
  final double? point;
  final String? description;

  const OddsOutcome({
    required this.name,
    required this.price,
    required this.point,
    required this.description,
  });

  factory OddsOutcome.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawPrice =
        json['price'];

    final dynamic rawPoint =
        json['point'];

    return OddsOutcome(
      name:
          json['name']?.toString() ?? '',
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(
                rawPrice?.toString() ?? '',
              ) ??
              0.0,
      point: rawPoint is num
          ? rawPoint.toDouble()
          : double.tryParse(
              rawPoint?.toString() ?? '',
            ),
      description:
          json['description']?.toString(),
    );
  }
}

class OddsApiException implements Exception {
  final String message;
  final int? statusCode;

  const OddsApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}

class _ApiResponse {
  final String body;
  final int? requestsRemaining;
  final int? requestsUsed;
  final int? requestsLast;

  const _ApiResponse({
    required this.body,
    required this.requestsRemaining,
    required this.requestsUsed,
    required this.requestsLast,
  });
}
