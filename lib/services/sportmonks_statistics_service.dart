// ===========================================
// Zsolt Pro AI
// Version: v0.16.0
// File: lib/services/sportmonks_statistics_service.dart
// ===========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';

class SportMonksStatisticsService {
  SportMonksStatisticsService._();

  static final SportMonksStatisticsService instance =
      SportMonksStatisticsService._();

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

  Future<AiMatchStatistics>
      loadMatchStatistics(
    AppMatch match, {
    int lookbackDays = 180,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
  }) async {
    _ensureApiToken();

    if (!match.isSportMonksMatch) {
      throw const SportMonksStatisticsException(
        'Ehhez a mérkőzéshez nincs SportMonks '
        'statisztikai adatforrás.',
      );
    }

    if (!match.hasTeamIds) {
      throw const SportMonksStatisticsException(
        'A SportMonks csapatazonosítók hiányoznak.',
      );
    }

    final int homeTeamId =
        int.tryParse(
          match.homeTeamId,
        ) ??
        0;

    final int awayTeamId =
        int.tryParse(
          match.awayTeamId,
        ) ??
        0;

    if (homeTeamId <= 0 ||
        awayTeamId <= 0) {
      throw const SportMonksStatisticsException(
        'A SportMonks csapatazonosítók érvénytelenek.',
      );
    }

    final DateTime matchDate =
        DateTime(
      match.matchDate.year,
      match.matchDate.month,
      match.matchDate.day,
    );

    final DateTime endDate =
        matchDate.subtract(
      const Duration(days: 1),
    );

    final DateTime startDate =
        endDate.subtract(
      Duration(
        days: lookbackDays.clamp(
          30,
          730,
        ),
      ),
    );

    final List<dynamic> responses =
        await Future.wait<dynamic>(
      <Future<dynamic>>[
        _fetchTeamFixtures(
          teamId: homeTeamId,
          startDate: startDate,
          endDate: endDate,
        ),
        _fetchTeamFixtures(
          teamId: awayTeamId,
          startDate: startDate,
          endDate: endDate,
        ),
        _fetchHeadToHeadFixtures(
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
        ),
      ],
    );

    final List<_StatisticsFixture> homeFixtures =
        responses[0]
            as List<_StatisticsFixture>;

    final List<_StatisticsFixture> awayFixtures =
        responses[1]
            as List<_StatisticsFixture>;

    final List<_StatisticsFixture> h2hFixtures =
        responses[2]
            as List<_StatisticsFixture>;

    final List<_StatisticsFixture>
        finishedHomeFixtures =
        _finishedFixturesBeforeDate(
      fixtures: homeFixtures,
      date: matchDate,
    );

    final List<_StatisticsFixture>
        finishedAwayFixtures =
        _finishedFixturesBeforeDate(
      fixtures: awayFixtures,
      date: matchDate,
    );

    final List<_StatisticsFixture>
        finishedH2hFixtures =
        _finishedFixturesBeforeDate(
      fixtures: h2hFixtures,
      date: matchDate,
    );

    final List<_StatisticsFixture>
        recentHomeFixtures =
        finishedHomeFixtures
            .take(
              formMatchCount.clamp(
                1,
                10,
              ),
            )
            .toList(
              growable: false,
            );

    final List<_StatisticsFixture>
        recentAwayFixtures =
        finishedAwayFixtures
            .take(
              formMatchCount.clamp(
                1,
                10,
              ),
            )
            .toList(
              growable: false,
            );

    final List<_StatisticsFixture>
        recentHomeVenueFixtures =
        finishedHomeFixtures
            .where(
              (_StatisticsFixture fixture) {
                return fixture.homeTeamId ==
                    homeTeamId;
              },
            )
            .take(
              formMatchCount.clamp(
                1,
                10,
              ),
            )
            .toList(
              growable: false,
            );

    final List<_StatisticsFixture>
        recentAwayVenueFixtures =
        finishedAwayFixtures
            .where(
              (_StatisticsFixture fixture) {
                return fixture.awayTeamId ==
                    awayTeamId;
              },
            )
            .take(
              formMatchCount.clamp(
                1,
                10,
              ),
            )
            .toList(
              growable: false,
            );

    final List<_StatisticsFixture>
        recentH2hFixtures =
        finishedH2hFixtures
            .take(
              h2hMatchCount.clamp(
                1,
                20,
              ),
            )
            .toList(
              growable: false,
            );

    final _TeamSummary homeSummary =
        _buildTeamSummary(
      fixtures: recentHomeFixtures,
      teamId: homeTeamId,
    );

    final _TeamSummary awaySummary =
        _buildTeamSummary(
      fixtures: recentAwayFixtures,
      teamId: awayTeamId,
    );

    final _GoalMarketSummary goalSummary =
        _buildGoalMarketSummary(
      <_StatisticsFixture>[
        ...recentHomeFixtures,
        ...recentAwayFixtures,
      ],
    );

    final _H2hSummary h2hSummary =
        _buildH2hSummary(
      fixtures: recentH2hFixtures,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
    );

    return AiMatchStatistics(
      homeForm:
          _buildForm(
        fixtures: recentHomeFixtures,
        teamId: homeTeamId,
      ),
      awayForm:
          _buildForm(
        fixtures: recentAwayFixtures,
        teamId: awayTeamId,
      ),
      homeVenueForm:
          _buildForm(
        fixtures:
            recentHomeVenueFixtures,
        teamId: homeTeamId,
      ),
      awayVenueForm:
          _buildForm(
        fixtures:
            recentAwayVenueFixtures,
        teamId: awayTeamId,
      ),
      homeGoalsScoredAverage:
          homeSummary.goalsScoredAverage,
      homeGoalsConcededAverage:
          homeSummary.goalsConcededAverage,
      awayGoalsScoredAverage:
          awaySummary.goalsScoredAverage,
      awayGoalsConcededAverage:
          awaySummary.goalsConcededAverage,
      homeCleanSheetPercent:
          homeSummary.cleanSheetPercent,
      awayCleanSheetPercent:
          awaySummary.cleanSheetPercent,
      homeFailedToScorePercent:
          homeSummary.failedToScorePercent,
      awayFailedToScorePercent:
          awaySummary.failedToScorePercent,
      over15Percent:
          goalSummary.over15Percent,
      over25Percent:
          goalSummary.over25Percent,
      over35Percent:
          goalSummary.over35Percent,
      bttsPercent:
          goalSummary.bttsPercent,
      h2hHomeWins:
          h2hSummary.homeWins,
      h2hDraws:
          h2hSummary.draws,
      h2hAwayWins:
          h2hSummary.awayWins,
      h2hAverageGoals:
          h2hSummary.averageGoals,
      h2hBttsPercent:
          h2hSummary.bttsPercent,
      h2hOver25Percent:
          h2hSummary.over25Percent,
      leagueAverageGoals:
          goalSummary.averageGoals,
      leagueStrength:
          _estimateLeagueStrength(
        match.league,
      ),
      homeAdvantage: 8,
      homeSampleSize:
          recentHomeFixtures.length,
      awaySampleSize:
          recentAwayFixtures.length,
      dataQualityBonus:
          _calculateDataQualityBonus(
        homeFixtureCount:
            recentHomeFixtures.length,
        awayFixtureCount:
            recentAwayFixtures.length,
        h2hFixtureCount:
            recentH2hFixtures.length,
      ),
    );
  }

  Future<List<_StatisticsFixture>>
      _fetchTeamFixtures({
    required int teamId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/fixtures/between/'
      '${_formatDate(startDate)}/'
      '${_formatDate(endDate)}/'
      '$teamId',
    ).replace(
      queryParameters: <String, String>{
        'api_token': _apiToken,
        'include':
            'participants;state;scores',
        'per_page': '50',
      },
    );

    return _fetchFixturesWithPagination(
      uri,
    );
  }

  Future<List<_StatisticsFixture>>
      _fetchHeadToHeadFixtures({
    required int homeTeamId,
    required int awayTeamId,
  }) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/fixtures/head-to-head/'
      '$homeTeamId/$awayTeamId',
    ).replace(
      queryParameters: <String, String>{
        'api_token': _apiToken,
        'include':
            'participants;state;scores',
        'per_page': '50',
      },
    );

    return _fetchFixturesWithPagination(
      uri,
    );
  }

  Future<List<_StatisticsFixture>>
      _fetchFixturesWithPagination(
    Uri initialUri,
  ) async {
    final List<_StatisticsFixture> fixtures =
        <_StatisticsFixture>[];

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Uri uri =
          initialUri.replace(
        queryParameters: <String, String>{
          ...initialUri.queryParameters,
          'page': page.toString(),
        },
      );

      final _ApiResponse response =
          await _get(uri);

      if (response.data
          is List<dynamic>) {
        fixtures.addAll(
          response.data
              .whereType<
                  Map<String, dynamic>>()
              .map(
                _StatisticsFixture.fromJson,
              ),
        );
      }

      hasMore = response.hasMore;
      page += 1;

      if (page > 10) {
        break;
      }
    }

    fixtures.sort(
      (
        _StatisticsFixture first,
        _StatisticsFixture second,
      ) {
        return second.startingAt.compareTo(
          first.startingAt,
        );
      },
    );

    return fixtures;
  }

  List<_StatisticsFixture>
      _finishedFixturesBeforeDate({
    required List<_StatisticsFixture> fixtures,
    required DateTime date,
  }) {
    return fixtures.where(
      (_StatisticsFixture fixture) {
        return fixture.isFinished &&
            fixture.hasValidScore &&
            fixture.startingAt.isBefore(
              date,
            );
      },
    ).toList(
      growable: false,
    );
  }

  List<AiMatchResult> _buildForm({
    required List<_StatisticsFixture> fixtures,
    required int teamId,
  }) {
    return fixtures.map(
      (_StatisticsFixture fixture) {
        final int teamGoals =
            fixture.goalsForTeam(
          teamId,
        );

        final int opponentGoals =
            fixture.goalsAgainstTeam(
          teamId,
        );

        if (teamGoals > opponentGoals) {
          return AiMatchResult.win;
        }

        if (teamGoals == opponentGoals) {
          return AiMatchResult.draw;
        }

        return AiMatchResult.loss;
      },
    ).toList(
      growable: false,
    );
  }

  _TeamSummary _buildTeamSummary({
    required List<_StatisticsFixture> fixtures,
    required int teamId,
  }) {
    if (fixtures.isEmpty) {
      return const _TeamSummary.empty();
    }

    int goalsScored = 0;
    int goalsConceded = 0;
    int cleanSheets = 0;
    int failedToScore = 0;

    for (final _StatisticsFixture fixture
        in fixtures) {
      final int scored =
          fixture.goalsForTeam(
        teamId,
      );

      final int conceded =
          fixture.goalsAgainstTeam(
        teamId,
      );

      goalsScored += scored;
      goalsConceded += conceded;

      if (conceded == 0) {
        cleanSheets += 1;
      }

      if (scored == 0) {
        failedToScore += 1;
      }
    }

    final int count =
        fixtures.length;

    return _TeamSummary(
      goalsScoredAverage:
          _roundToTwoDecimals(
        goalsScored / count,
      ),
      goalsConcededAverage:
          _roundToTwoDecimals(
        goalsConceded / count,
      ),
      cleanSheetPercent:
          _roundToTwoDecimals(
        cleanSheets / count * 100,
      ),
      failedToScorePercent:
          _roundToTwoDecimals(
        failedToScore / count * 100,
      ),
    );
  }

  _GoalMarketSummary
      _buildGoalMarketSummary(
    List<_StatisticsFixture> fixtures,
  ) {
    final Map<int, _StatisticsFixture> unique =
        <int, _StatisticsFixture>{
      for (final _StatisticsFixture fixture
          in fixtures)
        fixture.id: fixture,
    };

    final List<_StatisticsFixture> values =
        unique.values.toList();

    if (values.isEmpty) {
      return const _GoalMarketSummary.empty();
    }

    int totalGoals = 0;
    int over15 = 0;
    int over25 = 0;
    int over35 = 0;
    int btts = 0;

    for (final _StatisticsFixture fixture
        in values) {
      final int goals =
          fixture.homeGoals +
              fixture.awayGoals;

      totalGoals += goals;

      if (goals >= 2) {
        over15 += 1;
      }

      if (goals >= 3) {
        over25 += 1;
      }

      if (goals >= 4) {
        over35 += 1;
      }

      if (fixture.homeGoals > 0 &&
          fixture.awayGoals > 0) {
        btts += 1;
      }
    }

    final int count =
        values.length;

    return _GoalMarketSummary(
      averageGoals:
          _roundToTwoDecimals(
        totalGoals / count,
      ),
      over15Percent:
          _roundToTwoDecimals(
        over15 / count * 100,
      ),
      over25Percent:
          _roundToTwoDecimals(
        over25 / count * 100,
      ),
      over35Percent:
          _roundToTwoDecimals(
        over35 / count * 100,
      ),
      bttsPercent:
          _roundToTwoDecimals(
        btts / count * 100,
      ),
    );
  }

  _H2hSummary _buildH2hSummary({
    required List<_StatisticsFixture> fixtures,
    required int homeTeamId,
    required int awayTeamId,
  }) {
    if (fixtures.isEmpty) {
      return const _H2hSummary.empty();
    }

    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;
    int totalGoals = 0;
    int btts = 0;
    int over25 = 0;

    for (final _StatisticsFixture fixture
        in fixtures) {
      final int homeTeamGoals =
          fixture.goalsForTeam(
        homeTeamId,
      );

      final int awayTeamGoals =
          fixture.goalsForTeam(
        awayTeamId,
      );

      final int goals =
          fixture.homeGoals +
              fixture.awayGoals;

      totalGoals += goals;

      if (homeTeamGoals >
          awayTeamGoals) {
        homeWins += 1;
      } else if (homeTeamGoals <
          awayTeamGoals) {
        awayWins += 1;
      } else {
        draws += 1;
      }

      if (fixture.homeGoals > 0 &&
          fixture.awayGoals > 0) {
        btts += 1;
      }

      if (goals >= 3) {
        over25 += 1;
      }
    }

    final int count =
        fixtures.length;

    return _H2hSummary(
      homeWins: homeWins,
      draws: draws,
      awayWins: awayWins,
      averageGoals:
          _roundToTwoDecimals(
        totalGoals / count,
      ),
      bttsPercent:
          _roundToTwoDecimals(
        btts / count * 100,
      ),
      over25Percent:
          _roundToTwoDecimals(
        over25 / count * 100,
      ),
    );
  }

  double _calculateDataQualityBonus({
    required int homeFixtureCount,
    required int awayFixtureCount,
    required int h2hFixtureCount,
  }) {
    double score = 0;

    score +=
        homeFixtureCount.clamp(
              0,
              5,
            ) *
            2;

    score +=
        awayFixtureCount.clamp(
              0,
              5,
            ) *
            2;

    score +=
        h2hFixtureCount.clamp(
              0,
              5,
            ) *
            1.5;

    return score.clamp(
      0,
      30,
    );
  }

  double _estimateLeagueStrength(
    String league,
  ) {
    final String normalized =
        league
            .toLowerCase()
            .replaceAll(
              RegExp(r'[^a-z0-9]'),
              '',
            );

    if (normalized.contains(
          'premierleague',
        ) ||
        normalized.contains(
          'laliga',
        ) ||
        normalized.contains(
          'bundesliga',
        ) ||
        normalized.contains(
          'seriea',
        ) ||
        normalized.contains(
          'ligue1',
        ) ||
        normalized.contains(
          'championsleague',
        )) {
      return 90;
    }

    if (normalized.contains(
          'eredivisie',
        ) ||
        normalized.contains(
          'primeiraliga',
        ) ||
        normalized.contains(
          'europaleague',
        ) ||
        normalized.contains(
          'championship',
        )) {
      return 78;
    }

    if (normalized.contains(
          'allsvenskan',
        ) ||
        normalized.contains(
          'superliga',
        ) ||
        normalized.contains(
          'eliteserien',
        ) ||
        normalized.contains(
          'mls',
        )) {
      return 68;
    }

    return 55;
  }

  Future<_ApiResponse> _get(
    Uri uri,
  ) async {
    final HttpClient client =
        HttpClient();

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
        'Zsolt-Pro-AI/0.16.0',
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
        throw SportMonksStatisticsException(
          _buildHttpErrorMessage(
            statusCode:
                response.statusCode,
            body: body,
          ),
          statusCode:
              response.statusCode,
        );
      }

      final dynamic decoded;

      try {
        decoded = jsonDecode(
          body,
        );
      } on FormatException catch (error) {
        throw SportMonksStatisticsException(
          'A SportMonks statisztikai válasza '
          'nem érvényes JSON. '
          'Részlet: ${error.message}',
        );
      }

      if (decoded
          is! Map<String, dynamic>) {
        throw const SportMonksStatisticsException(
          'A SportMonks statisztikai válasza '
          'hibás formátumú.',
        );
      }

      bool hasMore = false;

      final dynamic pagination =
          decoded['pagination'];

      if (pagination
          is Map<String, dynamic>) {
        hasMore =
            pagination['has_more'] == true;
      }

      return _ApiResponse(
        data: decoded['data'],
        hasMore: hasMore,
      );
    } on TimeoutException catch (error) {
      throw SportMonksStatisticsException(
        'A SportMonks statisztikai API '
        'nem válaszolt időben. '
        'Részlet: '
        '${error.message ?? 'időtúllépés'}',
      );
    } on HandshakeException catch (error) {
      throw SportMonksStatisticsException(
        'TLS-kapcsolati hiba történt. '
        'Részlet: ${error.message}',
      );
    } on SocketException catch (error) {
      throw SportMonksStatisticsException(
        'SportMonks hálózati hiba: '
        '${error.message}.',
      );
    } on HttpException catch (error) {
      throw SportMonksStatisticsException(
        'SportMonks HTTP-hiba: '
        '${error.message}.',
      );
    } on SportMonksStatisticsException {
      rethrow;
    } catch (error) {
      throw SportMonksStatisticsException(
        'Váratlan SportMonks statisztikai hiba: '
        '$error',
      );
    } finally {
      client.close(
        force: true,
      );
    }
  }

  String _buildHttpErrorMessage({
    required int statusCode,
    required String body,
  }) {
    String? apiMessage;

    try {
      final dynamic decoded =
          jsonDecode(
        body,
      );

      if (decoded
          is Map<String, dynamic>) {
        final dynamic message =
            decoded['message'] ??
                decoded['error'];

        if (message != null) {
          apiMessage =
              message.toString().trim();
        }
      }
    } catch (_) {
      // Az alapértelmezett hibaüzenet marad.
    }

    if (apiMessage != null &&
        apiMessage.isNotEmpty) {
      return 'SportMonks statisztikai API-hiba '
          '(HTTP $statusCode): $apiMessage';
    }

    switch (statusCode) {
      case 401:
        return 'SportMonks statisztikai API-hiba '
            '(HTTP 401): hibás vagy hiányzó token.';
      case 403:
        return 'SportMonks statisztikai API-hiba '
            '(HTTP 403): a jelenlegi csomag nem '
            'engedélyezi ezt az adatot.';
      case 404:
        return 'SportMonks statisztikai API-hiba '
            '(HTTP 404): a kért adat nem található.';
      case 429:
        return 'SportMonks statisztikai API-hiba '
            '(HTTP 429): túl sok kérés történt.';
      default:
        return 'SportMonks statisztikai API-hiba: '
            'HTTP $statusCode.';
    }
  }

  void _ensureApiToken() {
    if (!hasApiToken) {
      throw const SportMonksStatisticsException(
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

  double _roundToTwoDecimals(
    double value,
  ) {
    return (value * 100).round() /
        100;
  }
}

class SportMonksStatisticsException
    implements Exception {
  final String message;
  final int? statusCode;

  const SportMonksStatisticsException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}

class _ApiResponse {
  final dynamic data;
  final bool hasMore;

  const _ApiResponse({
    required this.data,
    required this.hasMore,
  });
}

class _StatisticsFixture {
  final int id;
  final DateTime startingAt;
  final int homeTeamId;
  final int awayTeamId;
  final int homeGoals;
  final int awayGoals;
  final String stateShortName;
  final String stateName;

  const _StatisticsFixture({
    required this.id,
    required this.startingAt,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeGoals,
    required this.awayGoals,
    required this.stateShortName,
    required this.stateName,
  });

  bool get hasValidScore {
    return homeGoals >= 0 &&
        awayGoals >= 0;
  }

  bool get isFinished {
    final String shortState =
        stateShortName.toLowerCase();

    final String fullState =
        stateName.toLowerCase();

    return shortState == 'ft' ||
        shortState == 'aet' ||
        shortState == 'pen' ||
        fullState.contains(
          'finished',
        );
  }

  int goalsForTeam(
    int teamId,
  ) {
    if (teamId == homeTeamId) {
      return homeGoals;
    }

    if (teamId == awayTeamId) {
      return awayGoals;
    }

    return 0;
  }

  int goalsAgainstTeam(
    int teamId,
  ) {
    if (teamId == homeTeamId) {
      return awayGoals;
    }

    if (teamId == awayTeamId) {
      return homeGoals;
    }

    return 0;
  }

  factory _StatisticsFixture.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<dynamic> participants =
        json['participants']
                is List<dynamic>
            ? json['participants']
                as List<dynamic>
            : const <dynamic>[];

    int homeTeamId = 0;
    int awayTeamId = 0;

    for (final dynamic participant
        in participants) {
      if (participant
          is! Map<String, dynamic>) {
        continue;
      }

      final dynamic meta =
          participant['meta'];

      final String location =
          meta is Map<String, dynamic>
              ? meta['location']
                      ?.toString()
                      .toLowerCase() ??
                  ''
              : '';

      final int participantId =
          _toInt(
        participant['id'],
      );

      if (location == 'home') {
        homeTeamId =
            participantId;
      }

      if (location == 'away') {
        awayTeamId =
            participantId;
      }
    }

    final List<dynamic> scores =
        json['scores']
                is List<dynamic>
            ? json['scores']
                as List<dynamic>
            : const <dynamic>[];

    int homeGoals = -1;
    int awayGoals = -1;

    for (final dynamic score
        in scores) {
      if (score
          is! Map<String, dynamic>) {
        continue;
      }

      final String description =
          score['description']
                  ?.toString()
                  .toUpperCase() ??
              '';

      if (description != 'CURRENT') {
        continue;
      }

      final int participantId =
          _toInt(
        score['participant_id'],
      );

      final Map<String, dynamic>? scoreData =
          score['score']
                  is Map<String, dynamic>
              ? score['score']
                  as Map<String, dynamic>
              : null;

      final int goals =
          _toInt(
        scoreData?['goals'],
      );

      if (participantId ==
          homeTeamId) {
        homeGoals = goals;
      }

      if (participantId ==
          awayTeamId) {
        awayGoals = goals;
      }
    }

    final Map<String, dynamic>? state =
        json['state']
                is Map<String, dynamic>
            ? json['state']
                as Map<String, dynamic>
            : null;

    final String rawStartingAt =
        json['starting_at']
                ?.toString() ??
            '';

    return _StatisticsFixture(
      id: _toInt(
        json['id'],
      ),
      startingAt:
          DateTime.tryParse(
            rawStartingAt,
          ) ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
          ),
      homeTeamId:
          homeTeamId,
      awayTeamId:
          awayTeamId,
      homeGoals:
          homeGoals,
      awayGoals:
          awayGoals,
      stateShortName:
          state?['short_name']
                  ?.toString() ??
              state?['code']
                  ?.toString() ??
              '',
      stateName:
          state?['name']
                  ?.toString() ??
              '',
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

class _TeamSummary {
  final double goalsScoredAverage;
  final double goalsConcededAverage;
  final double cleanSheetPercent;
  final double failedToScorePercent;

  const _TeamSummary({
    required this.goalsScoredAverage,
    required this.goalsConcededAverage,
    required this.cleanSheetPercent,
    required this.failedToScorePercent,
  });

  const _TeamSummary.empty()
      : goalsScoredAverage = 0,
        goalsConcededAverage = 0,
        cleanSheetPercent = 0,
        failedToScorePercent = 0;
}

class _GoalMarketSummary {
  final double averageGoals;
  final double over15Percent;
  final double over25Percent;
  final double over35Percent;
  final double bttsPercent;

  const _GoalMarketSummary({
    required this.averageGoals,
    required this.over15Percent,
    required this.over25Percent,
    required this.over35Percent,
    required this.bttsPercent,
  });

  const _GoalMarketSummary.empty()
      : averageGoals = 0,
        over15Percent = 0,
        over25Percent = 0,
        over35Percent = 0,
        bttsPercent = 0;
}

class _H2hSummary {
  final int homeWins;
  final int draws;
  final int awayWins;
  final double averageGoals;
  final double bttsPercent;
  final double over25Percent;

  const _H2hSummary({
    required this.homeWins,
    required this.draws,
    required this.awayWins,
    required this.averageGoals,
    required this.bttsPercent,
    required this.over25Percent,
  });

  const _H2hSummary.empty()
      : homeWins = 0,
        draws = 0,
        awayWins = 0,
        averageGoals = 0,
        bttsPercent = 0,
        over25Percent = 0;
}
