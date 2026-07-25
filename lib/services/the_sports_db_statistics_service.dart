// ===========================================
// Zsolt Pro AI
// Version: v0.4.3
// File: lib/services/the_sports_db_statistics_service.dart
// ===========================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/app_match.dart';
import 'api_cache_service.dart';
import 'api_rate_limiter.dart';

class TheSportsDbStatisticsException implements Exception {
  final String message;
  const TheSportsDbStatisticsException(this.message);

  @override
  String toString() => 'TheSportsDbStatisticsException: $message';
}

class SportsDbStatisticsResult {
  final double averageGoals;
  final double over15Percentage;
  final double over25Percentage;
  final double over35Percentage;
  final double bttsPercentage;

  final double homeScoredAverage;
  final double homeConcededAverage;
  final double awayScoredAverage;
  final double awayConcededAverage;

  final double homeCleanSheetPercentage;
  final double awayCleanSheetPercentage;
  final double homeFailedToScorePercentage;
  final double awayFailedToScorePercentage;

  final double homeFormPercentage;
  final double awayFormPercentage;
  final List<String> homeFormSequence;
  final List<String> awayFormSequence;

  final List<String> homeVenueFormSequence;
  final List<String> awayVenueFormSequence;

  final int sampleSize;
  final int homeSampleSize;
  final int awaySampleSize;

  final int h2hCount;
  final List<String> h2hResults;

  final double leagueStrength;
  final double dataQualityBonus;

  final double reliability;
  final String dataQualityLabel;
  final String diagnosticMessage;

  const SportsDbStatisticsResult({
    required this.averageGoals,
    required this.over15Percentage,
    required this.over25Percentage,
    required this.over35Percentage,
    required this.bttsPercentage,
    required this.homeScoredAverage,
    required this.homeConcededAverage,
    required this.awayScoredAverage,
    required this.awayConcededAverage,
    required this.homeCleanSheetPercentage,
    required this.awayCleanSheetPercentage,
    required this.homeFailedToScorePercentage,
    required this.awayFailedToScorePercentage,
    required this.homeFormPercentage,
    required this.awayFormPercentage,
    required this.homeFormSequence,
    required this.awayFormSequence,
    required this.homeVenueFormSequence,
    required this.awayVenueFormSequence,
    required this.sampleSize,
    required this.homeSampleSize,
    required this.awaySampleSize,
    required this.h2hCount,
    required this.h2hResults,
    required this.leagueStrength,
    required this.dataQualityBonus,
    required this.reliability,
    required this.dataQualityLabel,
    required this.diagnosticMessage,
  });

  factory SportsDbStatisticsResult.empty({
    String message = 'Nincs elérhető statisztikai adat.',
  }) {
    return SportsDbStatisticsResult(
      averageGoals: 0.0,
      over15Percentage: 0.0,
      over25Percentage: 0.0,
      over35Percentage: 0.0,
      bttsPercentage: 0.0,
      homeScoredAverage: 0.0,
      homeConcededAverage: 0.0,
      awayScoredAverage: 0.0,
      awayConcededAverage: 0.0,
      homeCleanSheetPercentage: 0.0,
      awayCleanSheetPercentage: 0.0,
      homeFailedToScorePercentage: 0.0,
      awayFailedToScorePercentage: 0.0,
      homeFormPercentage: 0.0,
      awayFormPercentage: 0.0,
      homeFormSequence: const <String>[],
      awayFormSequence: const <String>[],
      homeVenueFormSequence: const <String>[],
      awayVenueFormSequence: const <String>[],
      sampleSize: 0,
      homeSampleSize: 0,
      awaySampleSize: 0,
      h2hCount: 0,
      h2hResults: const <String>[],
      leagueStrength: 50.0,
      dataQualityBonus: 0.0,
      reliability: 0.0,
      dataQualityLabel: 'Nincs adat',
      diagnosticMessage: message,
    );
  }

  bool get hasEnoughData => sampleSize >= 4;
}

class TheSportsDbStatisticsService {
  TheSportsDbStatisticsService._internal();

  static final TheSportsDbStatisticsService instance =
      TheSportsDbStatisticsService._internal();

  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json';
  static const String _freeApiKey = '123';

  final ApiCacheService _cacheService = ApiCacheService.instance;
  final ApiRateLimiter _rateLimiter = ApiRateLimiter.instance;

  String get apiKey {
    const String envKey = String.fromEnvironment('THESPORTSDB_API_KEY');
    if (envKey.trim().isNotEmpty) {
      return envKey.trim();
    }
    return _freeApiKey;
  }

  bool get usesFreeApiKey => apiKey == _freeApiKey;

  Future<SportsDbStatisticsResult> loadMatchStatistics({
    required AppMatch match,
    int formMatchCount = 5,
    int h2hMatchCount = 5,
  }) async {
    final int safeLastMatchesCount = formMatchCount.clamp(3, 10);
    final int safeH2hCount = h2hMatchCount.clamp(2, 10);

    final DateTime matchDate = match.matchDate;

    try {
      final _SportsDbTeamLookup homeTeam = await _findTeam(
        teamName: match.homeTeam,
        leagueName: match.league,
      );

      final _SportsDbTeamLookup awayTeam = await _findTeam(
        teamName: match.awayTeam,
        leagueName: match.league,
      );

      if (!homeTeam.hasId && !awayTeam.hasId) {
        return SportsDbStatisticsResult.empty(
          message: 'Egyik csapat sem azonosítható a TheSportsDB adatbázisában.',
        );
      }

      final String? homeTeamId = homeTeam.id;
      final String? awayTeamId = awayTeam.id;

      final List<_SportsDbStatisticsEvent> rawHomeEvents = homeTeamId != null
          ? await _fetchLastEventsForTeam(
              teamId: homeTeamId,
              matchDate: matchDate,
              limit: safeLastMatchesCount * 3,
            )
          : <_SportsDbStatisticsEvent>[];

      final List<_SportsDbStatisticsEvent> rawAwayEvents = awayTeamId != null
          ? await _fetchLastEventsForTeam(
              teamId: awayTeamId,
              matchDate: matchDate,
              limit: safeLastMatchesCount * 3,
            )
          : <_SportsDbStatisticsEvent>[];

      final List<_SportsDbStatisticsEvent> homeLastEvents = rawHomeEvents
          .take(safeLastMatchesCount)
          .toList(growable: false);

      final List<_SportsDbStatisticsEvent> awayLastEvents = rawAwayEvents
          .take(safeLastMatchesCount)
          .toList(growable: false);

      // DEDIKÁLT H2H KÉRÉS
      List<_SportsDbStatisticsEvent> h2hEvents =
          await _fetchDirectHeadToHeadEvents(
        homeTeamName: match.homeTeam,
        awayTeamName: match.awayTeam,
        matchDate: matchDate,
        limit: safeH2hCount,
      );

      // FALLBACK H2H
      if (h2hEvents.isEmpty) {
        h2hEvents = _findHeadToHeadEvents(
          homeEvents: rawHomeEvents,
          awayEvents: rawAwayEvents,
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          matchDate: matchDate,
          limit: safeH2hCount,
        );
      }

      final int homeSampleSize = homeLastEvents.length;
      final int awaySampleSize = awayLastEvents.length;
      final int sampleSize = homeSampleSize + awaySampleSize;

      if (sampleSize == 0) {
        return SportsDbStatisticsResult.empty(
          message: 'A csapatokhoz nem találhatók befejezett korábbi mérkőzések.',
        );
      }

      final _TeamStats homeStats = _calculateTeamStats(
        events: homeLastEvents,
        targetTeamId: homeTeamId,
        targetTeamName: match.homeTeam,
      );

      final _TeamStats awayStats = _calculateTeamStats(
        events: awayLastEvents,
        targetTeamId: awayTeamId,
        targetTeamName: match.awayTeam,
      );

      final List<_SportsDbStatisticsEvent> homeVenueEvents = rawHomeEvents
          .where((event) => _isTeamHome(
                event: event,
                targetTeamId: homeTeamId,
                targetTeamName: match.homeTeam,
              ))
          .take(safeLastMatchesCount)
          .toList(growable: false);

      final List<_SportsDbStatisticsEvent> awayVenueEvents = rawAwayEvents
          .where((event) => _isTeamAway(
                event: event,
                targetTeamId: awayTeamId,
                targetTeamName: match.awayTeam,
              ))
          .take(safeLastMatchesCount)
          .toList(growable: false);

      final List<String> homeVenueFormSequence = _extractFormSequence(
        events: homeVenueEvents,
        targetTeamId: homeTeamId,
        targetTeamName: match.homeTeam,
      );

      final List<String> awayVenueFormSequence = _extractFormSequence(
        events: awayVenueEvents,
        targetTeamId: awayTeamId,
        targetTeamName: match.awayTeam,
      );

      final int totalGoalsScored = homeStats.scored + awayStats.scored;
      final int totalGoalsConceded = homeStats.conceded + awayStats.conceded;
      final double averageGoals = sampleSize > 0
          ? (totalGoalsScored + totalGoalsConceded) / (sampleSize * 2)
          : 0.0;

      final int combinedOver15 = homeStats.over15Count + awayStats.over15Count;
      final int combinedOver25 = homeStats.over25Count + awayStats.over25Count;
      final int combinedOver35 = homeStats.over35Count + awayStats.over35Count;
      final int combinedBtts = homeStats.bttsCount + awayStats.bttsCount;

      final double over15Percentage =
          sampleSize > 0 ? (combinedOver15 / sampleSize) * 100.0 : 0.0;
      final double over25Percentage =
          sampleSize > 0 ? (combinedOver25 / sampleSize) * 100.0 : 0.0;
      final double over35Percentage =
          sampleSize > 0 ? (combinedOver35 / sampleSize) * 100.0 : 0.0;
      final double bttsPercentage =
          sampleSize > 0 ? (combinedBtts / sampleSize) * 100.0 : 0.0;

      final double homeScoredAverage =
          homeSampleSize > 0 ? homeStats.scored / homeSampleSize : 0.0;
      final double homeConcededAverage =
          homeSampleSize > 0 ? homeStats.conceded / homeSampleSize : 0.0;
      final double awayScoredAverage =
          awaySampleSize > 0 ? awayStats.scored / awaySampleSize : 0.0;
      final double awayConcededAverage =
          awaySampleSize > 0 ? awayStats.conceded / awaySampleSize : 0.0;

      final double homeCleanSheetPercentage = homeSampleSize > 0
          ? (homeStats.cleanSheetCount / homeSampleSize) * 100.0
          : 0.0;
      final double awayCleanSheetPercentage = awaySampleSize > 0
          ? (awayStats.cleanSheetCount / awaySampleSize) * 100.0
          : 0.0;

      final double homeFailedToScorePercentage = homeSampleSize > 0
          ? (homeStats.failedToScoreCount / homeSampleSize) * 100.0
          : 0.0;
      final double awayFailedToScorePercentage = awaySampleSize > 0
          ? (awayStats.failedToScoreCount / awaySampleSize) * 100.0
          : 0.0;

      final List<String> h2hResults = h2hEvents.map((event) {
        final String home = event.homeTeam;
        final String away = event.awayTeam;
        final int? homeScore = event.homeScore;
        final int? awayScore = event.awayScore;
        return '$home $homeScore - $awayScore $away';
      }).toList(growable: false);

      final double leagueStrength = _calculateLeagueStrength(match.league);

      final double dataQualityBonus = _calculateDataQualityBonus(
        homeFound: homeTeam.hasId,
        awayFound: awayTeam.hasId,
        sampleSize: sampleSize,
        h2hCount: h2hEvents.length,
      );

      final double reliability = _calculateReliability(
        homeFound: homeTeam.hasId,
        awayFound: awayTeam.hasId,
        sampleSize: sampleSize,
        h2hCount: h2hEvents.length,
      );

      final String dataQualityLabel = _buildDataQualityLabel(
        reliability: reliability,
        sampleSize: sampleSize,
      );

      final String diagnosticMessage = _buildDiagnosticMessage(
        homeFound: homeTeam.hasId,
        awayFound: awayTeam.hasId,
        sampleSize: sampleSize,
        h2hCount: h2hEvents.length,
      );

      return SportsDbStatisticsResult(
        averageGoals: double.parse(averageGoals.toStringAsFixed(2)),
        over15Percentage: double.parse(over15Percentage.toStringAsFixed(1)),
        over25Percentage: double.parse(over25Percentage.toStringAsFixed(1)),
        over35Percentage: double.parse(over35Percentage.toStringAsFixed(1)),
        bttsPercentage: double.parse(bttsPercentage.toStringAsFixed(1)),
        homeScoredAverage: double.parse(homeScoredAverage.toStringAsFixed(2)),
        homeConcededAverage:
            double.parse(homeConcededAverage.toStringAsFixed(2)),
        awayScoredAverage: double.parse(awayScoredAverage.toStringAsFixed(2)),
        awayConcededAverage:
            double.parse(awayConcededAverage.toStringAsFixed(2)),
        homeCleanSheetPercentage:
            double.parse(homeCleanSheetPercentage.toStringAsFixed(1)),
        awayCleanSheetPercentage:
            double.parse(awayCleanSheetPercentage.toStringAsFixed(1)),
        homeFailedToScorePercentage:
            double.parse(homeFailedToScorePercentage.toStringAsFixed(1)),
        awayFailedToScorePercentage:
            double.parse(awayFailedToScorePercentage.toStringAsFixed(1)),
        homeFormPercentage:
            double.parse(homeStats.formPercentage.toStringAsFixed(1)),
        awayFormPercentage:
            double.parse(awayStats.formPercentage.toStringAsFixed(1)),
        homeFormSequence: homeStats.formSequence,
        awayFormSequence: awayStats.formSequence,
        homeVenueFormSequence: homeVenueFormSequence,
        awayVenueFormSequence: awayVenueFormSequence,
        sampleSize: sampleSize,
        homeSampleSize: homeSampleSize,
        awaySampleSize: awaySampleSize,
        h2hCount: h2hEvents.length,
        h2hResults: h2hResults,
        leagueStrength: double.parse(leagueStrength.toStringAsFixed(1)),
        dataQualityBonus: double.parse(dataQualityBonus.toStringAsFixed(2)),
        reliability: double.parse(reliability.toStringAsFixed(1)),
        dataQualityLabel: dataQualityLabel,
        diagnosticMessage: diagnosticMessage,
      );
    } catch (error) {
      throw TheSportsDbStatisticsException(
        'Hiba történt a statisztikák feldolgozása közben: $error',
      );
    }
  }

  Future<List<_SportsDbStatisticsEvent>> _fetchDirectHeadToHeadEvents({
    required String homeTeamName,
    required String awayTeamName,
    required DateTime matchDate,
    required int limit,
  }) async {
    final String cleanHome = homeTeamName.trim();
    final String cleanAway = awayTeamName.trim();

    if (cleanHome.isEmpty || cleanAway.isEmpty) {
      return const <_SportsDbStatisticsEvent>[];
    }

    final Uri uri =
        Uri.parse('$_baseUrl/$apiKey/searcheventsvsevents.php').replace(
      queryParameters: <String, String>{
        'q': '$cleanHome vs $cleanAway',
      },
    );

    try {
      final dynamic decoded = await _getJsonWithCacheAndRateLimit(uri);

      if (decoded is! Map<String, dynamic>) {
        return const <_SportsDbStatisticsEvent>[];
      }

      final dynamic rawEvents = decoded['event'] ?? decoded['events'];
      if (rawEvents is! List<dynamic>) {
        return const <_SportsDbStatisticsEvent>[];
      }

      final List<_SportsDbStatisticsEvent> events = rawEvents
          .whereType<Map<String, dynamic>>()
          .map(_SportsDbStatisticsEvent.fromJson)
          .where((event) =>
              event.isSoccer &&
              event.hasValidScore &&
              event.isFinished &&
              event.startDateTime.isBefore(matchDate))
          .toList();

      events.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
      return events.take(limit).toList(growable: false);
    } catch (_) {
      return const <_SportsDbStatisticsEvent>[];
    }
  }

  Future<_SportsDbTeamLookup> _findTeam({
    required String teamName,
    required String leagueName,
  }) async {
    final String cleanTeam = teamName.trim();
    if (cleanTeam.isEmpty) {
      return _SportsDbTeamLookup.empty();
    }

    final Uri uri = Uri.parse('$_baseUrl/$apiKey/searchteams.php').replace(
      queryParameters: <String, String>{'t': cleanTeam},
    );

    try {
      final dynamic decoded = await _getJsonWithCacheAndRateLimit(uri);

      if (decoded is! Map<String, dynamic>) {
        return _SportsDbTeamLookup.empty();
      }

      final dynamic rawTeams = decoded['teams'];
      if (rawTeams is! List<dynamic> || rawTeams.isEmpty) {
        return _SportsDbTeamLookup.empty();
      }

      final List<Map<String, dynamic>> teams =
          rawTeams.whereType<Map<String, dynamic>>().toList();

      for (final Map<String, dynamic> team in teams) {
        final String? id = team['idTeam']?.toString();
        final String? name = team['strTeam']?.toString();
        final String? league = team['strLeague']?.toString();

        if (id != null &&
            name != null &&
            _isSameTeamName(name, cleanTeam) &&
            _isSameLeagueName(league, leagueName)) {
          return _SportsDbTeamLookup(id: id, name: name);
        }
      }

      for (final Map<String, dynamic> team in teams) {
        final String? id = team['idTeam']?.toString();
        final String? name = team['strTeam']?.toString();

        if (id != null && name != null && _isSameTeamName(name, cleanTeam)) {
          return _SportsDbTeamLookup(id: id, name: name);
        }
      }

      final Map<String, dynamic> first = teams.first;
      return _SportsDbTeamLookup(
        id: first['idTeam']?.toString(),
        name: first['strTeam']?.toString() ?? cleanTeam,
      );
    } catch (_) {
      return _SportsDbTeamLookup.empty();
    }
  }

  Future<List<_SportsDbStatisticsEvent>> _fetchLastEventsForTeam({
    required String teamId,
    required DateTime matchDate,
    required int limit,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/$apiKey/eventslast.php').replace(
      queryParameters: <String, String>{'id': teamId},
    );

    try {
      final dynamic decoded = await _getJsonWithCacheAndRateLimit(uri);

      if (decoded is! Map<String, dynamic>) {
        return const <_SportsDbStatisticsEvent>[];
      }

      final dynamic rawEvents = decoded['results'];
      if (rawEvents is! List<dynamic>) {
        return const <_SportsDbStatisticsEvent>[];
      }

      final List<_SportsDbStatisticsEvent> events = rawEvents
          .whereType<Map<String, dynamic>>()
          .map(_SportsDbStatisticsEvent.fromJson)
          .where((event) =>
              event.isSoccer &&
              event.hasValidScore &&
              event.isFinished &&
              event.startDateTime.isBefore(matchDate))
          .toList();

      events.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
      return events.take(limit).toList(growable: false);
    } catch (_) {
      return const <_SportsDbStatisticsEvent>[];
    }
  }

  List<_SportsDbStatisticsEvent> _findHeadToHeadEvents({
    required List<_SportsDbStatisticsEvent> homeEvents,
    required List<_SportsDbStatisticsEvent> awayEvents,
    required String? homeTeamId,
    required String? awayTeamId,
    required DateTime matchDate,
    required int limit,
  }) {
    final Map<String, _SportsDbStatisticsEvent> uniqueH2h =
        <String, _SportsDbStatisticsEvent>{};

    for (final _SportsDbStatisticsEvent event in <_SportsDbStatisticsEvent>[
      ...homeEvents,
      ...awayEvents,
    ]) {
      final bool isHomeMatch = _isTeamInEvent(
        event: event,
        teamId: homeTeamId,
      );
      final bool isAwayMatch = _isTeamInEvent(
        event: event,
        teamId: awayTeamId,
      );

      if (isHomeMatch &&
          isAwayMatch &&
          event.startDateTime.isBefore(matchDate)) {
        uniqueH2h[event.id] = event;
      }
    }

    final List<_SportsDbStatisticsEvent> sorted = uniqueH2h.values.toList()
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

    return sorted.take(limit).toList(growable: false);
  }

  _TeamStats _calculateTeamStats({
    required List<_SportsDbStatisticsEvent> events,
    required String? targetTeamId,
    required String targetTeamName,
  }) {
    int scored = 0;
    int conceded = 0;
    int over15Count = 0;
    int over25Count = 0;
    int over35Count = 0;
    int bttsCount = 0;
    int cleanSheetCount = 0;
    int failedToScoreCount = 0;

    double points = 0.0;
    final List<String> formSequence = <String>[];

    for (final _SportsDbStatisticsEvent event in events) {
      final bool isHome = _isTeamHome(
        event: event,
        targetTeamId: targetTeamId,
        targetTeamName: targetTeamName,
      );

      final int teamScore = isHome ? event.homeScore! : event.awayScore!;
      final int opponentScore = isHome ? event.awayScore! : event.homeScore!;
      final int totalGoals = teamScore + opponentScore;

      scored += teamScore;
      conceded += opponentScore;

      if (totalGoals > 1) over15Count++;
      if (totalGoals > 2) over25Count++;
      if (totalGoals > 3) over35Count++;

      if (teamScore > 0 && opponentScore > 0) bttsCount++;
      if (opponentScore == 0) cleanSheetCount++;
      if (teamScore == 0) failedToScoreCount++;

      if (teamScore > opponentScore) {
        points += 3.0;
        formSequence.add('G');
      } else if (teamScore == opponentScore) {
        points += 1.0;
        formSequence.add('D');
      } else {
        formSequence.add('V');
      }
    }

    final int maxPoints = events.length * 3;
    final double formPercentage =
        maxPoints > 0 ? (points / maxPoints) * 100.0 : 0.0;

    return _TeamStats(
      scored: scored,
      conceded: conceded,
      over15Count: over15Count,
      over25Count: over25Count,
      over35Count: over35Count,
      bttsCount: bttsCount,
      cleanSheetCount: cleanSheetCount,
      failedToScoreCount: failedToScoreCount,
      formPercentage: formPercentage,
      formSequence: formSequence,
    );
  }

  List<String> _extractFormSequence({
    required List<_SportsDbStatisticsEvent> events,
    required String? targetTeamId,
    required String targetTeamName,
  }) {
    final List<String> form = <String>[];

    for (final _SportsDbStatisticsEvent event in events) {
      final bool isHome = _isTeamHome(
        event: event,
        targetTeamId: targetTeamId,
        targetTeamName: targetTeamName,
      );

      final int teamScore = isHome ? event.homeScore! : event.awayScore!;
      final int opponentScore = isHome ? event.awayScore! : event.homeScore!;

      if (teamScore > opponentScore) {
        form.add('G');
      } else if (teamScore == opponentScore) {
        form.add('D');
      } else {
        form.add('V');
      }
    }

    return form;
  }

  bool _isTeamInEvent({
    required _SportsDbStatisticsEvent event,
    required String? teamId,
  }) {
    if (teamId != null && teamId.isNotEmpty) {
      return event.homeTeamId == teamId || event.awayTeamId == teamId;
    }
    return false;
  }

  bool _isTeamHome({
    required _SportsDbStatisticsEvent event,
    required String? targetTeamId,
    required String targetTeamName,
  }) {
    if (targetTeamId != null && targetTeamId.isNotEmpty) {
      return event.homeTeamId == targetTeamId;
    }
    return _isSameTeamName(event.homeTeam, targetTeamName);
  }

  bool _isTeamAway({
    required _SportsDbStatisticsEvent event,
    required String? targetTeamId,
    required String targetTeamName,
  }) {
    if (targetTeamId != null && targetTeamId.isNotEmpty) {
      return event.awayTeamId == targetTeamId;
    }
    return _isSameTeamName(event.awayTeam, targetTeamName);
  }

  bool _isSameTeamName(String first, String second) {
    final String cleanFirst = _normalizeString(first);
    final String cleanSecond = _normalizeString(second);
    return cleanFirst.contains(cleanSecond) || cleanSecond.contains(cleanFirst);
  }

  bool _isSameLeagueName(String? first, String second) {
    if (first == null || first.trim().isEmpty) return false;
    final String cleanFirst = _normalizeString(first);
    final String cleanSecond = _normalizeString(second);
    return cleanFirst.contains(cleanSecond) || cleanSecond.contains(cleanFirst);
  }

  String _normalizeString(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  double _calculateLeagueStrength(String leagueName) {
    final String normalized = leagueName.toLowerCase();

    if (normalized.contains('champions league') ||
        normalized.contains('premier league') ||
        normalized.contains('la liga') ||
        normalized.contains('serie a') ||
        normalized.contains('bundesliga')) {
      return 95.0;
    }

    if (normalized.contains('europa league') ||
        normalized.contains('ligue 1') ||
        normalized.contains('eredivisie') ||
        normalized.contains('primeira liga')) {
      return 88.0;
    }

    if (normalized.contains('hungarian nb i') ||
        normalized.contains('nb i') ||
        normalized.contains('otp bank liga')) {
      return 78.0;
    }

    return 70.0;
  }

  double _calculateDataQualityBonus({
    required bool homeFound,
    required bool awayFound,
    required int sampleSize,
    required int h2hCount,
  }) {
    double bonus = 0.0;
    if (homeFound && awayFound) bonus += 8.0;
    if (sampleSize >= 10) bonus += 5.0;
    if (h2hCount >= 3) bonus += 3.0;
    return bonus;
  }

  double _calculateReliability({
    required bool homeFound,
    required bool awayFound,
    required int sampleSize,
    required int h2hCount,
  }) {
    double score = 40.0;
    if (homeFound) score += 15.0;
    if (awayFound) score += 15.0;
    score += (sampleSize * 2.0).clamp(0.0, 20.0);
    score += (h2hCount * 2.0).clamp(0.0, 10.0);
    return score.clamp(0.0, 100.0);
  }

  String _buildDataQualityLabel({
    required double reliability,
    required int sampleSize,
  }) {
    if (reliability >= 80.0 && sampleSize >= 8) {
      return 'Kiváló adatminőség';
    }
    if (reliability >= 60.0 && sampleSize >= 5) {
      return 'Jó adatminőség';
    }
    if (reliability >= 40.0) {
      return 'Közepes adatminőség';
    }
    return 'Korlátozott adatminőség';
  }

  String _buildDiagnosticMessage({
    required bool homeFound,
    required bool awayFound,
    required int sampleSize,
    required int h2hCount,
  }) {
    if (homeFound && awayFound && h2hCount > 0) {
      return 'Teljes statisztikai minta és H2H adatok állnak rendelkezésre.';
    }
    if (homeFound && awayFound) {
      return 'TheSportsDB: megfelelő csapatforma áll rendelkezésre, de kevés a H2H-adat.';
    }
    return 'Hiányos csapatprofilok miatt a statisztikai minta korlátozott.';
  }

  Future<dynamic> _getJsonWithCacheAndRateLimit(Uri uri) async {
    final String urlString = uri.toString();

    final dynamic cachedData = await _cacheService.get<dynamic>(urlString);
    if (cachedData != null) {
      return cachedData;
    }

    return await _rateLimiter.schedule(() async {
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP hiba: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      await _cacheService.set(
        urlString,
        decoded,
        ttl: const Duration(hours: 12),
      );

      return decoded;
    });
  }
}

class _SportsDbTeamLookup {
  final String? id;
  final String name;

  const _SportsDbTeamLookup({
    required this.id,
    required this.name,
  });

  factory _SportsDbTeamLookup.empty() {
    return const _SportsDbTeamLookup(
      id: null,
      name: '',
    );
  }

  bool get hasId => id != null && id!.isNotEmpty;
}

class _SportsDbStatisticsEvent {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamId;
  final String? awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final DateTime startDateTime;
  final String? strSport;
  final String? strStatus;

  const _SportsDbStatisticsEvent({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.startDateTime,
    required this.strSport,
    required this.strStatus,
  });

  factory _SportsDbStatisticsEvent.fromJson(Map<String, dynamic> json) {
    final String id = json['idEvent']?.toString() ?? '';
    final String homeTeam = json['strHomeTeam']?.toString() ?? '';
    final String awayTeam = json['strAwayTeam']?.toString() ?? '';
    final String? homeTeamId = json['idHomeTeam']?.toString();
    final String? awayTeamId = json['idAwayTeam']?.toString();

    final int? homeScore = int.tryParse(json['intHomeScore']?.toString() ?? '');
    final int? awayScore = int.tryParse(json['intAwayScore']?.toString() ?? '');

    final String dateStr = json['strTimestamp']?.toString() ??
        json['dateEvent']?.toString() ??
        '';

    DateTime parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    if (dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr) ?? parsedDate;
    }

    return _SportsDbStatisticsEvent(
      id: id,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      startDateTime: parsedDate,
      strSport: json['strSport']?.toString(),
      strStatus: json['strStatus']?.toString(),
    );
  }

  bool get isSoccer {
    if (strSport == null) return true;
    return strSport!.toLowerCase() == 'soccer';
  }

  bool get hasValidScore => homeScore != null && awayScore != null;

  bool get isFinished {
    if (strStatus == null) return true;
    final String status = strStatus!.toLowerCase();
    return status.contains('match finished') ||
        status.contains('ft') ||
        status == 'finished';
  }
}

class _TeamStats {
  final int scored;
  final int conceded;
  final int over15Count;
  final int over25Count;
  final int over35Count;
  final int bttsCount;
  final int cleanSheetCount;
  final int failedToScoreCount;
  final double formPercentage;
  final List<String> formSequence;

  const _TeamStats({
    required this.scored,
    required this.conceded,
    required this.over15Count,
    required this.over25Count,
    required this.over35Count,
    required this.bttsCount,
    required this.cleanSheetCount,
    required this.failedToScoreCount,
    required this.formPercentage,
    required this.formSequence,
  });
}
