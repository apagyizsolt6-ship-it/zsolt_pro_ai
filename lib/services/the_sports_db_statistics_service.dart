// ===========================================
// Zsolt Pro AI
// Version: v0.16.1
// File: lib/services/the_sports_db_statistics_service.dart
// ===========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';

/// TheSportsDB-alapú mérkőzés-statisztikai szolgáltatás.
///
/// Feladatai:
/// - hazai és vendégcsapat korábbi meccseinek lekérése;
/// - forma kiszámítása;
/// - hazai és idegenbeli forma kiszámítása;
/// - rúgott és kapott gólátlag;
/// - clean sheet arány;
/// - gól nélküli mérkőzések aránya;
/// - Over 1,5 / 2,5 / 3,5;
/// - BTTS;
/// - H2H-becslés, amikor rendelkezésre áll megfelelő adat.
///
/// Az ingyenes TheSportsDB-kulcs kevesebb múltbeli eseményt
/// adhat vissza. Emiatt a szolgáltatás automatikusan alacsonyabb
/// adatminőségi értéket ad, ha kevés mérkőzésből kell számolnia.
class TheSportsDbStatisticsService {
  TheSportsDbStatisticsService._();

  static final TheSportsDbStatisticsService instance =
      TheSportsDbStatisticsService._();

  static const String _baseUrl =
      'https://www.thesportsdb.com/api/v1/json';

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

  bool get hasApiKey {
    return apiKey.trim().isNotEmpty;
  }

  bool get usesFreeApiKey {
    return apiKey == _freeApiKey;
  }

  String get planLabel {
    return usesFreeApiKey
        ? 'Ingyenes TheSportsDB-kulcs'
        : 'Saját TheSportsDB-kulcs';
  }

  /// Teljes AI-statisztikai csomag lekérése egy
  /// TheSportsDB-meccshez.
  Future<AiMatchStatistics> loadMatchStatistics(
    AppMatch match, {
    int formMatchCount = 5,
    int h2hMatchCount = 8,
  }) async {
    _ensureApiKey();

    if (!match.isTheSportsDbMatch) {
      throw const TheSportsDbStatisticsException(
        'Ehhez a mérkőzéshez nincs TheSportsDB '
        'statisztikai adatforrás.',
      );
    }

    if (!match.hasTeamIds) {
      throw const TheSportsDbStatisticsException(
        'A TheSportsDB csapatazonosítók hiányoznak.',
      );
    }

    final String homeTeamId =
        match.homeTeamId.trim();

    final String awayTeamId =
        match.awayTeamId.trim();

    if (homeTeamId.isEmpty ||
        awayTeamId.isEmpty) {
      throw const TheSportsDbStatisticsException(
        'A TheSportsDB csapatazonosítók érvénytelenek.',
      );
    }

    final int safeFormCount =
        formMatchCount.clamp(
      1,
      10,
    );

    final int safeH2hCount =
        h2hMatchCount.clamp(
      1,
      20,
    );

    final List<dynamic> responses =
        await Future.wait<dynamic>(
      <Future<dynamic>>[
        _fetchLastTeamEvents(
          teamId: homeTeamId,
        ),
        _fetchLastTeamEvents(
          teamId: awayTeamId,
        ),
      ],
    );

    final List<_SportsDbStatisticsEvent>
        rawHomeEvents =
        responses[0]
            as List<_SportsDbStatisticsEvent>;

    final List<_SportsDbStatisticsEvent>
        rawAwayEvents =
        responses[1]
            as List<_SportsDbStatisticsEvent>;

    final DateTime matchDate =
        DateTime(
      match.matchDate.year,
      match.matchDate.month,
      match.matchDate.day,
    );

    final List<_SportsDbStatisticsEvent>
        homeEvents =
        _finishedEventsBeforeDate(
      events: rawHomeEvents,
      date: matchDate,
    )
            .take(
              safeFormCount,
            )
            .toList(
              growable: false,
            );

    final List<_SportsDbStatisticsEvent>
        awayEvents =
        _finishedEventsBeforeDate(
      events: rawAwayEvents,
      date: matchDate,
    )
            .take(
              safeFormCount,
            )
            .toList(
              growable: false,
            );

    final List<_SportsDbStatisticsEvent>
        homeVenueEvents =
        homeEvents.where(
      (
        _SportsDbStatisticsEvent event,
      ) {
        return event.homeTeamId ==
            homeTeamId;
      },
    ).toList(
      growable: false,
    );

    final List<_SportsDbStatisticsEvent>
        awayVenueEvents =
        awayEvents.where(
      (
        _SportsDbStatisticsEvent event,
      ) {
        return event.awayTeamId ==
            awayTeamId;
      },
    ).toList(
      growable: false,
    );

    final List<_SportsDbStatisticsEvent>
        h2hEvents =
        _findHeadToHeadEvents(
      homeEvents: rawHomeEvents,
      awayEvents: rawAwayEvents,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      matchDate: matchDate,
      limit: safeH2hCount,
    );

    final _TeamStatisticsSummary
        homeSummary =
        _buildTeamSummary(
      events: homeEvents,
      teamId: homeTeamId,
    );

    final _TeamStatisticsSummary
        awaySummary =
        _buildTeamSummary(
      events: awayEvents,
      teamId: awayTeamId,
    );

    final _GoalStatisticsSummary
        goalSummary =
        _buildGoalSummary(
      <_SportsDbStatisticsEvent>[
        ...homeEvents,
        ...awayEvents,
      ],
    );

    final _HeadToHeadSummary h2hSummary =
        _buildHeadToHeadSummary(
      events: h2hEvents,
      selectedHomeTeamId:
          homeTeamId,
      selectedAwayTeamId:
          awayTeamId,
    );

    final double dataQualityBonus =
        _calculateDataQualityBonus(
      homeEventCount:
          homeEvents.length,
      awayEventCount:
          awayEvents.length,
      h2hEventCount:
          h2hEvents.length,
    );

    return AiMatchStatistics(
      homeForm:
          _buildForm(
        events: homeEvents,
        teamId: homeTeamId,
      ),
      awayForm:
          _buildForm(
        events: awayEvents,
        teamId: awayTeamId,
      ),
      homeVenueForm:
          _buildForm(
        events: homeVenueEvents,
        teamId: homeTeamId,
      ),
      awayVenueForm:
          _buildForm(
        events: awayVenueEvents,
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
          homeEvents.length,
      awaySampleSize:
          awayEvents.length,
      dataQualityBonus:
          dataQualityBonus,
    );
  }

  /// Kapcsolat és adatlekérés tesztelése.
  Future<TheSportsDbStatisticsConnectionResult>
      testConnection({
    String? teamId,
  }) async {
    try {
      _ensureApiKey();

      final String cleanTeamId =
          teamId?.trim() ?? '';

      if (cleanTeamId.isEmpty) {
        return TheSportsDbStatisticsConnectionResult(
          success: true,
          message:
              'A TheSportsDB statisztikai szolgáltatás '
              'használatra kész. Csomag: $planLabel.',
          eventCount: 0,
          usesFreeApiKey: usesFreeApiKey,
        );
      }

      final List<_SportsDbStatisticsEvent> events =
          await _fetchLastTeamEvents(
        teamId: cleanTeamId,
      );

      return TheSportsDbStatisticsConnectionResult(
        success: true,
        message:
            'A TheSportsDB statisztikai kapcsolat működik. '
            '${events.length} korábbi esemény érkezett.',
        eventCount: events.length,
        usesFreeApiKey: usesFreeApiKey,
      );
    } on TheSportsDbStatisticsException catch (
      error,
    ) {
      return TheSportsDbStatisticsConnectionResult(
        success: false,
        message: error.message,
        statusCode: error.statusCode,
        eventCount: 0,
        usesFreeApiKey: usesFreeApiKey,
      );
    } catch (error) {
      return TheSportsDbStatisticsConnectionResult(
        success: false,
        message:
            'Ismeretlen TheSportsDB statisztikai hiba: '
            '$error',
        eventCount: 0,
        usesFreeApiKey: usesFreeApiKey,
      );
    }
  }

  Future<List<_SportsDbStatisticsEvent>>
      _fetchLastTeamEvents({
    required String teamId,
  }) async {
    final String cleanTeamId =
        teamId.trim();

    if (cleanTeamId.isEmpty) {
      return const
          <_SportsDbStatisticsEvent>[];
    }

    final Uri uri = Uri.parse(
      '$_baseUrl/$apiKey/eventslast.php',
    ).replace(
      queryParameters: <String, String>{
        'id': cleanTeamId,
      },
    );

    final dynamic decoded =
        await _getJson(
      uri,
    );

    if (decoded is! Map<String, dynamic>) {
      throw const TheSportsDbStatisticsException(
        'A TheSportsDB korábbi eseményválasza '
        'hibás formátumú.',
      );
    }

    final dynamic rawResults =
        decoded['results'];

    if (rawResults == null) {
      return const
          <_SportsDbStatisticsEvent>[];
    }

    if (rawResults is! List<dynamic>) {
      throw const TheSportsDbStatisticsException(
        'A TheSportsDB korábbi eseménylistája '
        'hibás formátumú.',
      );
    }

    final List<_SportsDbStatisticsEvent> events =
        rawResults
            .whereType<
                Map<String, dynamic>>()
            .map(
              _SportsDbStatisticsEvent
                  .fromJson,
            )
            .where(
              (
                _SportsDbStatisticsEvent event,
              ) {
                return event.isSoccer &&
                    event.hasTeamIds &&
                    event.hasValidScore;
              },
            )
            .toList(
              growable: false,
            );

    final List<_SportsDbStatisticsEvent>
        sorted =
        List<_SportsDbStatisticsEvent>.from(
      events,
    );

    sorted.sort(
      (
        _SportsDbStatisticsEvent first,
        _SportsDbStatisticsEvent second,
      ) {
        return second.startDateTime.compareTo(
          first.startDateTime,
        );
      },
    );

    return _removeDuplicateEvents(
      sorted,
    );
  }

  List<_SportsDbStatisticsEvent>
      _finishedEventsBeforeDate({
    required List<_SportsDbStatisticsEvent>
        events,
    required DateTime date,
  }) {
    return events.where(
      (
        _SportsDbStatisticsEvent event,
      ) {
        return event.isFinished &&
            event.hasValidScore &&
            event.startDateTime.isBefore(
              date,
            );
      },
    ).toList(
      growable: false,
    );
  }

  List<_SportsDbStatisticsEvent>
      _findHeadToHeadEvents({
    required List<_SportsDbStatisticsEvent>
        homeEvents,
    required List<_SportsDbStatisticsEvent>
        awayEvents,
    required String homeTeamId,
    required String awayTeamId,
    required DateTime matchDate,
    required int limit,
  }) {
    final Map<String, _SportsDbStatisticsEvent>
        combined =
        <String, _SportsDbStatisticsEvent>{};

    for (final _SportsDbStatisticsEvent event
        in <_SportsDbStatisticsEvent>[
      ...homeEvents,
      ...awayEvents,
    ]) {
      if (!event.startDateTime.isBefore(
        matchDate,
      )) {
        continue;
      }

      if (!event.hasValidScore ||
          !event.isFinished) {
        continue;
      }

      final bool correctTeams =
          (event.homeTeamId == homeTeamId &&
                  event.awayTeamId ==
                      awayTeamId) ||
              (event.homeTeamId ==
                      awayTeamId &&
                  event.awayTeamId ==
                      homeTeamId);

      if (!correctTeams) {
        continue;
      }

      combined[event.uniqueKey] =
          event;
    }

    final List<_SportsDbStatisticsEvent>
        result =
        combined.values.toList();

    result.sort(
      (
        _SportsDbStatisticsEvent first,
        _SportsDbStatisticsEvent second,
      ) {
        return second.startDateTime.compareTo(
          first.startDateTime,
        );
      },
    );

    return result
        .take(
          limit,
        )
        .toList(
          growable: false,
        );
  }

  List<AiMatchResult> _buildForm({
    required List<_SportsDbStatisticsEvent>
        events,
    required String teamId,
  }) {
    return events.map(
      (
        _SportsDbStatisticsEvent event,
      ) {
        final int goalsFor =
            event.goalsForTeam(
          teamId,
        );

        final int goalsAgainst =
            event.goalsAgainstTeam(
          teamId,
        );

        if (goalsFor > goalsAgainst) {
          return AiMatchResult.win;
        }

        if (goalsFor == goalsAgainst) {
          return AiMatchResult.draw;
        }

        return AiMatchResult.loss;
      },
    ).toList(
      growable: false,
    );
  }

  _TeamStatisticsSummary _buildTeamSummary({
    required List<_SportsDbStatisticsEvent>
        events,
    required String teamId,
  }) {
    if (events.isEmpty) {
      return const
          _TeamStatisticsSummary.empty();
    }

    int goalsScored = 0;
    int goalsConceded = 0;
    int cleanSheets = 0;
    int failedToScore = 0;
    int validEvents = 0;

    for (final _SportsDbStatisticsEvent event
        in events) {
      if (!event.containsTeam(
        teamId,
      )) {
        continue;
      }

      final int scored =
          event.goalsForTeam(
        teamId,
      );

      final int conceded =
          event.goalsAgainstTeam(
        teamId,
      );

      goalsScored += scored;
      goalsConceded += conceded;
      validEvents += 1;

      if (conceded == 0) {
        cleanSheets += 1;
      }

      if (scored == 0) {
        failedToScore += 1;
      }
    }

    if (validEvents == 0) {
      return const
          _TeamStatisticsSummary.empty();
    }

    return _TeamStatisticsSummary(
      goalsScoredAverage:
          _roundToTwoDecimals(
        goalsScored / validEvents,
      ),
      goalsConcededAverage:
          _roundToTwoDecimals(
        goalsConceded / validEvents,
      ),
      cleanSheetPercent:
          _roundToTwoDecimals(
        cleanSheets /
            validEvents *
            100,
      ),
      failedToScorePercent:
          _roundToTwoDecimals(
        failedToScore /
            validEvents *
            100,
      ),
    );
  }

  _GoalStatisticsSummary _buildGoalSummary(
    List<_SportsDbStatisticsEvent> events,
  ) {
    final List<_SportsDbStatisticsEvent>
        uniqueEvents =
        _removeDuplicateEvents(
      events.where(
        (
          _SportsDbStatisticsEvent event,
        ) {
          return event.hasValidScore &&
              event.isFinished;
        },
      ).toList(),
    );

    if (uniqueEvents.isEmpty) {
      return const
          _GoalStatisticsSummary.empty();
    }

    int totalGoals = 0;
    int over15 = 0;
    int over25 = 0;
    int over35 = 0;
    int btts = 0;

    for (final _SportsDbStatisticsEvent event
        in uniqueEvents) {
      final int matchGoals =
          event.homeGoals +
              event.awayGoals;

      totalGoals += matchGoals;

      if (matchGoals >= 2) {
        over15 += 1;
      }

      if (matchGoals >= 3) {
        over25 += 1;
      }

      if (matchGoals >= 4) {
        over35 += 1;
      }

      if (event.homeGoals > 0 &&
          event.awayGoals > 0) {
        btts += 1;
      }
    }

    final int count =
        uniqueEvents.length;

    return _GoalStatisticsSummary(
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

  _HeadToHeadSummary
      _buildHeadToHeadSummary({
    required List<_SportsDbStatisticsEvent>
        events,
    required String selectedHomeTeamId,
    required String selectedAwayTeamId,
  }) {
    if (events.isEmpty) {
      return const
          _HeadToHeadSummary.empty();
    }

    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;
    int totalGoals = 0;
    int btts = 0;
    int over25 = 0;
    int validEvents = 0;

    for (final _SportsDbStatisticsEvent event
        in events) {
      if (!event.containsTeam(
            selectedHomeTeamId,
          ) ||
          !event.containsTeam(
            selectedAwayTeamId,
          )) {
        continue;
      }

      final int selectedHomeGoals =
          event.goalsForTeam(
        selectedHomeTeamId,
      );

      final int selectedAwayGoals =
          event.goalsForTeam(
        selectedAwayTeamId,
      );

      final int matchGoals =
          event.homeGoals +
              event.awayGoals;

      validEvents += 1;
      totalGoals += matchGoals;

      if (selectedHomeGoals >
          selectedAwayGoals) {
        homeWins += 1;
      } else if (selectedHomeGoals <
          selectedAwayGoals) {
        awayWins += 1;
      } else {
        draws += 1;
      }

      if (event.homeGoals > 0 &&
          event.awayGoals > 0) {
        btts += 1;
      }

      if (matchGoals >= 3) {
        over25 += 1;
      }
    }

    if (validEvents == 0) {
      return const
          _HeadToHeadSummary.empty();
    }

    return _HeadToHeadSummary(
      homeWins: homeWins,
      draws: draws,
      awayWins: awayWins,
      averageGoals:
          _roundToTwoDecimals(
        totalGoals / validEvents,
      ),
      bttsPercent:
          _roundToTwoDecimals(
        btts / validEvents * 100,
      ),
      over25Percent:
          _roundToTwoDecimals(
        over25 / validEvents * 100,
      ),
    );
  }

  List<_SportsDbStatisticsEvent>
      _removeDuplicateEvents(
    List<_SportsDbStatisticsEvent> events,
  ) {
    final Map<String, _SportsDbStatisticsEvent>
        unique =
        <String, _SportsDbStatisticsEvent>{};

    for (final _SportsDbStatisticsEvent event
        in events) {
      unique[event.uniqueKey] =
          event;
    }

    final List<_SportsDbStatisticsEvent>
        result =
        unique.values.toList();

    result.sort(
      (
        _SportsDbStatisticsEvent first,
        _SportsDbStatisticsEvent second,
      ) {
        return second.startDateTime.compareTo(
          first.startDateTime,
        );
      },
    );

    return result;
  }

  double _calculateDataQualityBonus({
    required int homeEventCount,
    required int awayEventCount,
    required int h2hEventCount,
  }) {
    double bonus = 0;

    bonus +=
        homeEventCount.clamp(
              0,
              5,
            ) *
            1.6;

    bonus +=
        awayEventCount.clamp(
              0,
              5,
            ) *
            1.6;

    bonus +=
        h2hEventCount.clamp(
              0,
              5,
            ) *
            1.2;

    if (usesFreeApiKey) {
      bonus *= 0.65;
    }

    return _roundToTwoDecimals(
      bonus.clamp(
        0,
        24,
      ),
    );
  }

  double _estimateLeagueStrength(
    String league,
  ) {
    final String normalized =
        league
            .toLowerCase()
            .replaceAll(
              RegExp(
                r'[^a-z0-9]',
              ),
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

  Future<dynamic> _getJson(
    Uri uri,
  ) async {
    final HttpClient client =
        HttpClient();

    client.connectionTimeout =
        _connectionTimeout;

    try {
      final HttpClientRequest request =
          await client
              .getUrl(
                uri,
              )
              .timeout(
                _connectionTimeout,
              );

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Zsolt-Pro-AI/0.16.1',
      );

      final HttpClientResponse response =
          await request
              .close()
              .timeout(
                _responseTimeout,
              );

      final String body =
          await response
              .transform(
                utf8.decoder,
              )
              .join()
              .timeout(
                _responseTimeout,
              );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw TheSportsDbStatisticsException(
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
        return jsonDecode(
          body,
        );
      } on FormatException catch (
        error,
      ) {
        throw TheSportsDbStatisticsException(
          'A TheSportsDB statisztikai válasza '
          'nem érvényes JSON. '
          'Részlet: ${error.message}',
        );
      }
    } on TimeoutException catch (error) {
      throw TheSportsDbStatisticsException(
        'A TheSportsDB statisztikai API '
        'nem válaszolt időben. '
        'Részlet: '
        '${error.message ?? 'időtúllépés'}',
      );
    } on HandshakeException catch (error) {
      throw TheSportsDbStatisticsException(
        'TLS-kapcsolati hiba történt a '
        'TheSportsDB elérésekor. '
        'Részlet: ${error.message}',
      );
    } on SocketException catch (error) {
      throw TheSportsDbStatisticsException(
        _buildSocketErrorMessage(
          error,
        ),
      );
    } on HttpException catch (error) {
      throw TheSportsDbStatisticsException(
        'TheSportsDB HTTP-hiba: '
        '${error.message}.',
      );
    } on TheSportsDbStatisticsException {
      rethrow;
    } catch (error) {
      throw TheSportsDbStatisticsException(
        'Váratlan TheSportsDB statisztikai hiba: '
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
      return 'TheSportsDB statisztikai API-hiba '
          '(HTTP $statusCode): $apiMessage';
    }

    switch (statusCode) {
      case 400:
        return 'TheSportsDB statisztikai API-hiba '
            '(HTTP 400): hibás kérési paraméter.';
      case 401:
        return 'TheSportsDB statisztikai API-hiba '
            '(HTTP 401): hibás API-kulcs.';
      case 403:
        return 'TheSportsDB statisztikai API-hiba '
            '(HTTP 403): a jelenlegi csomag nem '
            'engedélyezi ezt az adatot.';
      case 404:
        return 'TheSportsDB statisztikai API-hiba '
            '(HTTP 404): a kért adat nem található.';
      case 429:
        return 'TheSportsDB statisztikai API-hiba '
            '(HTTP 429): túl sok kérés történt.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'TheSportsDB szerverhiba '
            '(HTTP $statusCode). '
            'Próbáld újra később.';
      default:
        return 'TheSportsDB statisztikai API-hiba: '
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
        combined.contains(
          'dns',
        )) {
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
          'Ellenőrizd a mobilinternetet vagy '
          'a Wi-Fi-kapcsolatot.';
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
      return 'A TheSportsDB statisztikai API '
          'nem válaszolt időben.';
    }

    return 'TheSportsDB hálózati hiba: '
        '${error.message}.';
  }

  void _ensureApiKey() {
    if (!hasApiKey) {
      throw const TheSportsDbStatisticsException(
        'A TheSportsDB API-kulcs nincs '
        'beállítva.',
      );
    }
  }

  double _roundToTwoDecimals(
    double value,
  ) {
    return (value * 100).round() /
        100;
  }
}

class TheSportsDbStatisticsConnectionResult {
  final bool success;
  final String message;
  final int eventCount;
  final bool usesFreeApiKey;
  final int? statusCode;

  const TheSportsDbStatisticsConnectionResult({
    required this.success,
    required this.message,
    required this.eventCount,
    required this.usesFreeApiKey,
    this.statusCode,
  });
}

class TheSportsDbStatisticsException
    implements Exception {
  final String message;
  final int? statusCode;

  const TheSportsDbStatisticsException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}

class _SportsDbStatisticsEvent {
  final String id;

  final String sport;

  final String homeTeamId;
  final String awayTeamId;

  final String homeTeam;
  final String awayTeam;

  final DateTime startDateTime;

  final int homeGoals;
  final int awayGoals;

  final String status;

  const _SportsDbStatisticsEvent({
    required this.id,
    required this.sport,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeam,
    required this.awayTeam,
    required this.startDateTime,
    required this.homeGoals,
    required this.awayGoals,
    required this.status,
  });

  factory _SportsDbStatisticsEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    final String timestamp =
        _readString(
      json,
      <String>[
        'strTimestamp',
      ],
    );

    final String date =
        _readString(
      json,
      <String>[
        'dateEvent',
        'dateEventLocal',
      ],
    );

    final String time =
        _readString(
      json,
      <String>[
        'strTime',
        'strTimeLocal',
      ],
    );

    return _SportsDbStatisticsEvent(
      id: _readString(
        json,
        <String>[
          'idEvent',
        ],
      ),
      sport: _readString(
        json,
        <String>[
          'strSport',
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
      homeTeam: _readString(
        json,
        <String>[
          'strHomeTeam',
        ],
      ),
      awayTeam: _readString(
        json,
        <String>[
          'strAwayTeam',
        ],
      ),
      startDateTime:
          _parseDateTime(
        timestamp: timestamp,
        date: date,
        time: time,
      ),
      homeGoals:
          _readScore(
        json,
        'intHomeScore',
      ),
      awayGoals:
          _readScore(
        json,
        'intAwayScore',
      ),
      status: _readString(
        json,
        <String>[
          'strStatus',
          'strProgress',
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

  bool get hasTeamIds {
    return homeTeamId.trim().isNotEmpty &&
        awayTeamId.trim().isNotEmpty;
  }

  bool get hasValidScore {
    return homeGoals >= 0 &&
        awayGoals >= 0;
  }

  bool get isFinished {
    final String normalizedStatus =
        status.trim().toLowerCase();

    if (normalizedStatus.isEmpty) {
      return hasValidScore;
    }

    return normalizedStatus == 'ft' ||
        normalizedStatus == 'aet' ||
        normalizedStatus ==
            'after penalties' ||
        normalizedStatus.contains(
          'finished',
        ) ||
        normalizedStatus.contains(
          'match finished',
        );
  }

  String get uniqueKey {
    if (id.trim().isNotEmpty) {
      return id.trim();
    }

    return '${homeTeamId.trim()}|'
        '${awayTeamId.trim()}|'
        '${startDateTime.toIso8601String()}';
  }

  bool containsTeam(
    String teamId,
  ) {
    final String cleanId =
        teamId.trim();

    return homeTeamId == cleanId ||
        awayTeamId == cleanId;
  }

  int goalsForTeam(
    String teamId,
  ) {
    final String cleanId =
        teamId.trim();

    if (homeTeamId == cleanId) {
      return homeGoals;
    }

    if (awayTeamId == cleanId) {
      return awayGoals;
    }

    return 0;
  }

  int goalsAgainstTeam(
    String teamId,
  ) {
    final String cleanId =
        teamId.trim();

    if (homeTeamId == cleanId) {
      return awayGoals;
    }

    if (awayTeamId == cleanId) {
      return homeGoals;
    }

    return 0;
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

  static int _readScore(
    Map<String, dynamic> json,
    String key,
  ) {
    final dynamic value =
        json[key];

    if (value == null) {
      return -1;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().trim(),
        ) ??
        -1;
  }

  static DateTime _parseDateTime({
    required String timestamp,
    required String date,
    required String time,
  }) {
    final DateTime? parsedTimestamp =
        DateTime.tryParse(
      timestamp,
    );

    if (parsedTimestamp != null) {
      return parsedTimestamp.toLocal();
    }

    String cleanTime =
        time.trim();

    if (cleanTime.endsWith(
      'Z',
    )) {
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
      '${date.trim()}T$cleanTime',
    );

    if (combined != null) {
      return combined.toLocal();
    }

    return DateTime.tryParse(
          date.trim(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(
          0,
        );
  }
}

class _TeamStatisticsSummary {
  final double goalsScoredAverage;
  final double goalsConcededAverage;
  final double cleanSheetPercent;
  final double failedToScorePercent;

  const _TeamStatisticsSummary({
    required this.goalsScoredAverage,
    required this.goalsConcededAverage,
    required this.cleanSheetPercent,
    required this.failedToScorePercent,
  });

  const _TeamStatisticsSummary.empty()
      : goalsScoredAverage = 0,
        goalsConcededAverage = 0,
        cleanSheetPercent = 0,
        failedToScorePercent = 0;
}

class _GoalStatisticsSummary {
  final double averageGoals;
  final double over15Percent;
  final double over25Percent;
  final double over35Percent;
  final double bttsPercent;

  const _GoalStatisticsSummary({
    required this.averageGoals,
    required this.over15Percent,
    required this.over25Percent,
    required this.over35Percent,
    required this.bttsPercent,
  });

  const _GoalStatisticsSummary.empty()
      : averageGoals = 0,
        over15Percent = 0,
        over25Percent = 0,
        over35Percent = 0,
        bttsPercent = 0;
}

class _HeadToHeadSummary {
  final int homeWins;
  final int draws;
  final int awayWins;

  final double averageGoals;
  final double bttsPercent;
  final double over25Percent;

  const _HeadToHeadSummary({
    required this.homeWins,
    required this.draws,
    required this.awayWins,
    required this.averageGoals,
    required this.bttsPercent,
    required this.over25Percent,
  });

  const _HeadToHeadSummary.empty()
      : homeWins = 0,
        draws = 0,
        awayWins = 0,
        averageGoals = 0,
        bttsPercent = 0,
        over25Percent = 0;
}
