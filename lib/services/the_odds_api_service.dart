// ===========================================
// Zsolt Pro AI
// Version: v0.11.0
// File: lib/services/the_odds_api_service.dart
// ===========================================

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

  bool get hasApiKey {
    return _apiKey.trim().isNotEmpty;
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
        jsonDecode(response.body);

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

    if (sportKey.trim().isEmpty) {
      throw const OddsApiException(
        'A sport azonosítója nem lehet üres.',
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
          commenceTimeFrom
              .toUtc()
              .toIso8601String();
    }

    if (commenceTimeTo != null) {
      parameters['commenceTimeTo'] =
          commenceTimeTo
              .toUtc()
              .toIso8601String();
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/sports/'
      '${Uri.encodeComponent(sportKey)}/odds',
    ).replace(
      queryParameters: parameters,
    );

    final _ApiResponse response =
        await _get(uri);

    final dynamic decoded =
        jsonDecode(response.body);

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
        score += 4;
      } else if (_namesSimilar(
        eventHome,
        normalizedHome,
      )) {
        score += 2;
      }

      if (eventAway == normalizedAway) {
        score += 4;
      } else if (_namesSimilar(
        eventAway,
        normalizedAway,
      )) {
        score += 2;
      }

      final Duration difference =
          event.commenceTime.difference(
        matchDate.toUtc(),
      );

      if (difference.inHours.abs() <= 3) {
        score += 2;
      } else if (difference.inHours.abs() <= 12) {
        score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = event;
      }
    }

    if (bestScore < 4) {
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
            outcome.name.trim().toLowerCase() ==
                normalizedSide;

        final bool samePoint =
            outcome.point != null &&
                (outcome.point! - point).abs() <
                    0.001;

        if (!sameSide || !samePoint) {
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
          bookmaker.marketByKey(marketKey);

      if (market == null) {
        continue;
      }

      for (final OddsOutcome outcome
          in market.outcomes) {
        final String normalizedName =
            _normalizeTeamName(outcome.name);

        if (normalizedName != normalizedOutcome) {
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

    try {
      final HttpClientRequest request =
          await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final HttpClientResponse response =
          await request.close();

      final String body =
          await response.transform(
        utf8.decoder,
      ).join();

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw OddsApiException(
          _buildErrorMessage(
            statusCode: response.statusCode,
            body: body,
          ),
          statusCode: response.statusCode,
        );
      }

      return _ApiResponse(
        body: body,
        requestsRemaining:
            _readIntHeader(
          response,
          'x-requests-remaining',
        ),
        requestsUsed:
            _readIntHeader(
          response,
          'x-requests-used',
        ),
        requestsLast:
            _readIntHeader(
          response,
          'x-requests-last',
        ),
      );
    } on SocketException {
      throw const OddsApiException(
        'Nincs internetkapcsolat, vagy az odds '
        'szolgáltatás nem érhető el.',
      );
    } on HttpException {
      throw const OddsApiException(
        'Hálózati hiba történt az oddsok lekérésekor.',
      );
    } on FormatException {
      throw const OddsApiException(
        'Az odds szolgáltatás hibás adatot küldött.',
      );
    } finally {
      client.close(
        force: true,
      );
    }
  }

  void _ensureApiKey() {
    if (!hasApiKey) {
      throw const OddsApiException(
        'A THE_ODDS_API_KEY nincs beállítva.',
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

    return int.tryParse(value);
  }

  String _buildErrorMessage({
    required int statusCode,
    required String body,
  }) {
    try {
      final dynamic decoded =
          jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final dynamic message =
            decoded['message'];

        final dynamic errorCode =
            decoded['error_code'];

        if (message is String &&
            message.trim().isNotEmpty) {
          if (errorCode is String &&
              errorCode.trim().isNotEmpty) {
            return '$message ($errorCode)';
          }

          return message;
        }
      }
    } catch (_) {
      // A nyers választ használjuk.
    }

    return 'The Odds API hiba: HTTP $statusCode.';
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

    return first.contains(second) ||
        second.contains(first);
  }
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
      group: json['group']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
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
      json['commence_time']?.toString() ?? '',
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
          json['sport_key']?.toString() ?? '',
      sportTitle:
          json['sport_title']?.toString() ?? '',
      commenceTime:
          parsedDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      homeTeam:
          json['home_team']?.toString() ?? '',
      awayTeam:
          json['away_team']?.toString() ?? '',
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
      title: json['title']?.toString() ?? '',
      lastUpdate: DateTime.tryParse(
        json['last_update']?.toString() ?? '',
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
        json['last_update']?.toString() ?? '',
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
    final dynamic rawPrice = json['price'];
    final dynamic rawPoint = json['point'];

    return OddsOutcome(
      name: json['name']?.toString() ?? '',
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
