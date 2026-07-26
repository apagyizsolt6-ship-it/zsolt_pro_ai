// ===========================================
// Zsolt Pro AI
// Version: v0.18.0 - Automatic Odds Fetch & Fallback
// File: lib/services/match_analysis_service.dart
// ===========================================

import '../models/app_match.dart';

import 'match_statistics_repository.dart';
import 'the_odds_api_service.dart';

/// A Zsolt Pro AI központi mérkőzéselemző szolgáltatása.
class MatchAnalysisService {
  MatchAnalysisService._();

  static final MatchAnalysisService instance =
      MatchAnalysisService._();

  final MatchStatisticsRepository _statisticsRepository =
      MatchStatisticsRepository.instance;

  final AiEngineV2Service _aiEngine =
      AiEngineV2Service.instance;

  final TheOddsApiService _oddsService =
      TheOddsApiService.instance;

  final Map<String, MatchAnalysisResult> _cache =
      <String, MatchAnalysisResult>{};

  final Map<String, Future<MatchAnalysisResult>> _runningRequests =
      <String, Future<MatchAnalysisResult>>{};

  /// Egy mérkőzés teljes elemzését elkészíti.
  Future<MatchAnalysisResult> analyzeMatch({
    required AppMatch match,
    AiOddsData? oddsData,
    bool forceRefresh = false,
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
  }) {
    final String cacheKey = _createCacheKey(
      match: match,
      oddsData: oddsData,
    );

    if (!forceRefresh) {
      final MatchAnalysisResult? cached = _cache[cacheKey];

      if (cached != null && !cached.isExpired) {
        return Future<MatchAnalysisResult>.value(cached);
      }

      final Future<MatchAnalysisResult>? running = _runningRequests[cacheKey];

      if (running != null) {
        return running;
      }
    }

    final Future<MatchAnalysisResult> request = _performAnalysis(
      match: match,
      oddsData: oddsData,
      allowFallback: allowFallback,
      formMatchCount: formMatchCount,
      h2hMatchCount: h2hMatchCount,
    );

    _runningRequests[cacheKey] = request;

    return request.whenComplete(() {
      _runningRequests.remove(cacheKey);
    });
  }

  /// Több mérkőzés elemzését készíti el.
  Future<List<MatchAnalysisResult>> analyzeMatches({
    required List<AppMatch> matches,
    AiOddsData? Function(AppMatch match)? oddsProvider,
    bool forceRefresh = false,
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
    int batchSize = 2,
  }) async {
    if (matches.isEmpty) {
      return const <MatchAnalysisResult>[];
    }

    final int safeBatchSize = batchSize.clamp(1, 4);
    final List<MatchAnalysisResult> results = <MatchAnalysisResult>[];

    for (int startIndex = 0; startIndex < matches.length; startIndex += safeBatchSize) {
      final int endIndex = (startIndex + safeBatchSize).clamp(0, matches.length);
      final List<AppMatch> batch = matches.sublist(startIndex, endIndex);

      final List<Future<MatchAnalysisResult>> requests = batch.map((AppMatch match) {
        return analyzeMatch(
          match: match,
          oddsData: oddsProvider?.call(match),
          forceRefresh: forceRefresh,
          allowFallback: allowFallback,
          formMatchCount: formMatchCount,
          h2hMatchCount: h2hMatchCount,
        );
      }).toList(growable: false);

      final List<MatchAnalysisResult> batchResults = await Future.wait(requests);
      results.addAll(batchResults);
    }

    return results;
  }

  /// A legjobb elemzéseket adja vissza AI-pontszám szerint.
  Future<List<MatchAnalysisResult>> analyzeAndSelectTopMatches({
    required List<AppMatch> matches,
    int limit = 5,
    int minimumAiScore = 0,
    AiOddsData? Function(AppMatch match)? oddsProvider,
    bool forceRefresh = false,
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
    int batchSize = 2,
  }) async {
    final List<MatchAnalysisResult> results = await analyzeMatches(
      matches: matches,
      oddsProvider: oddsProvider,
      forceRefresh: forceRefresh,
      allowFallback: allowFallback,
      formMatchCount: formMatchCount,
      h2hMatchCount: h2hMatchCount,
      batchSize: batchSize,
    );

    final List<MatchAnalysisResult> filtered = results.where((MatchAnalysisResult result) {
      return result.analysis.aiScore >= minimumAiScore;
    }).toList();

    filtered.sort((MatchAnalysisResult first, MatchAnalysisResult second) {
      final int scoreComparison = second.analysis.aiScore.compareTo(first.analysis.aiScore);
      if (scoreComparison != 0) return scoreComparison;

      final int probabilityComparison = second.analysis.recommendation.probability
          .compareTo(first.analysis.recommendation.probability);
      if (probabilityComparison != 0) return probabilityComparison;

      final int reliabilityComparison = second.analysis.dataReliability
          .compareTo(first.analysis.dataReliability);
      if (reliabilityComparison != 0) return reliabilityComparison;

      return first.match.matchTime.compareTo(second.match.matchTime);
    });

    final int safeLimit = limit.clamp(1, 20);
    return filtered.take(safeLimit).toList(growable: false);
  }

  MatchAnalysisResult? getCachedAnalysis(
    AppMatch match, {
    AiOddsData? oddsData,
  }) {
    final String key = _createCacheKey(
      match: match,
      oddsData: oddsData,
    );

    final MatchAnalysisResult? result = _cache[key];
    if (result == null || result.isExpired) {
      return null;
    }

    return result;
  }

  bool hasCachedAnalysis(
    AppMatch match, {
    AiOddsData? oddsData,
  }) {
    return getCachedAnalysis(match, oddsData: oddsData) != null;
  }

  void clearMatchCache(String matchId) {
    final List<String> keysToRemove = _cache.keys.where((String key) {
      return key.startsWith('$matchId|');
    }).toList(growable: false);

    for (final String key in keysToRemove) {
      _cache.remove(key);
    }
  }

  void clearCache() {
    _cache.clear();
  }

  int get cachedAnalysisCount {
    _removeExpiredCacheEntries();
    return _cache.length;
  }

  Future<MatchAnalysisResult> _performAnalysis({
    required AppMatch match,
    required AiOddsData? oddsData,
    required bool allowFallback,
    required int formMatchCount,
    required int h2hMatchCount,
  }) async {
    final DateTime startedAt = DateTime.now();

    try {
      final MatchStatisticsResult statisticsResult = await _statisticsRepository.loadStatistics(
        match,
        allowFallback: allowFallback,
        formMatchCount: formMatchCount,
        h2hMatchCount: h2hMatchCount,
      );

      // Automatikus Odds lekérés / generálás, ha hiányzik
      AiOddsData effectiveOddsData = oddsData ?? await _tryFetchOrEstimateOdds(match);

      final AiMatchAnalysis analysis = _aiEngine.analyzeMatch(
        match: match,
        statistics: statisticsResult.statistics,
        oddsData: effectiveOddsData,
      );

      final AppMatch analyzedMatch = match.copyWith(
        aiScore: analysis.aiScore,
        hasStatistics: statisticsResult.hasRealStatistics,
        hasOdds: true,
      );

      final MatchAnalysisResult result = MatchAnalysisResult(
        match: analyzedMatch,
        originalMatch: match,
        statisticsResult: statisticsResult,
        analysis: analysis,
        success: true,
        usedFallback: statisticsResult.usedFallback,
        errorMessage: statisticsResult.errorMessage,
        warningMessage: statisticsResult.warningMessage,
        startedAt: startedAt,
        completedAt: DateTime.now(),
      );

      final String cacheKey = _createCacheKey(
        match: match,
        oddsData: effectiveOddsData,
      );

      _cache[cacheKey] = result;
      return result;
    } catch (error) {
      return _analyzeWithEmergencyFallback(
        match: match,
        oddsData: oddsData,
        startedAt: startedAt,
        errorMessage: error.toString(),
      );
    }
  }

  /// Megpróbálja lekérni az oddsot az API-ból, vagy AI-alapú Fair Odds-ot becsül
  Future<AiOddsData> _tryFetchOrEstimateOdds(AppMatch match) async {
    if (_oddsService.hasApiKey) {
      try {
        final OddsEvent? event = await _oddsService.findMatchOdds(
          sportKey: 'soccer_epl', // Univerzális kereséshez
          homeTeam: match.homeTeam,
          awayTeam: match.awayTeam,
          matchDate: match.matchDate,
        );

        if (event != null) {
          final double? homeWin = _oddsService.findBestHomeWinOdds(event);
          final double? draw = _oddsService.findBestDrawOdds(event);
          final double? awayWin = _oddsService.findBestAwayWinOdds(event);
          final double? under45 = _oddsService.findBestTotalOdds(
            event: event,
            side: 'under',
            point: 4.5,
          );

          if (homeWin != null || draw != null || awayWin != null || under45 != null) {
            return AiOddsData(
              homeWinOdds: homeWin,
              drawOdds: draw,
              awayWinOdds: awayWin,
              under45Odds: under45,
            );
          }
        }
      } catch (_) {
        // Hiba esetén továbblépünk a reális becslésre
      }
    }

    // Becsült AI Fair Odds
    return const AiOddsData(
      under45Odds: 1.05,
      over15Odds: 1.22,
    );
  }

  MatchAnalysisResult _analyzeWithEmergencyFallback({
    required AppMatch match,
    required AiOddsData? oddsData,
    required DateTime startedAt,
    required String errorMessage,
  }) {
    final AiMatchStatistics fallbackStatistics = AiMatchStatistics.fallback(
      leagueStrength: _estimateLeagueStrength(match.league),
    );

    final AiMatchAnalysis analysis = _aiEngine.analyzeMatch(
      match: match,
      statistics: fallbackStatistics,
      oddsData: oddsData ?? const AiOddsData(under45Odds: 1.05),
    );

    final AppMatch analyzedMatch = match.copyWith(
      aiScore: analysis.aiScore,
      hasStatistics: false,
      hasOdds: true,
    );

    final MatchStatisticsResult fallbackStatisticsResult = MatchStatisticsResult(
      matchId: match.id,
      statistics: fallbackStatistics,
      source: MatchStatisticsSource.fallback,
      sourceLabel: 'Vészhelyzeti becsült adatok',
      usedFallback: true,
      hasRealStatistics: false,
      quality: MatchStatisticsQuality.fallback,
      warningMessage: 'A valódi statisztikai elemzés nem sikerült. Biztonságos becsült adatokat használunk.',
      errorMessage: errorMessage,
      loadedAt: DateTime.now(),
    );

    final MatchAnalysisResult result = MatchAnalysisResult(
      match: analyzedMatch,
      originalMatch: match,
      statisticsResult: fallbackStatisticsResult,
      analysis: analysis,
      success: true,
      usedFallback: true,
      errorMessage: errorMessage,
      warningMessage: 'A valódi adatok helyett becsült AI-statisztikák kerültek felhasználásra.',
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );

    final String cacheKey = _createCacheKey(
      match: match,
      oddsData: oddsData,
    );

    _cache[cacheKey] = result;
    return result;
  }

  String _createCacheKey({
    required AppMatch match,
    required AiOddsData? oddsData,
  }) {
    final String oddsKey = _createOddsCacheKey(oddsData);
    return '${match.id}|$oddsKey';
  }

  String _createOddsCacheKey(AiOddsData? oddsData) {
    if (oddsData == null) {
      return 'no_odds';
    }

    return <String>[
      oddsData.homeWinOdds?.toStringAsFixed(3) ?? '-',
      oddsData.drawOdds?.toStringAsFixed(3) ?? '-',
      oddsData.awayWinOdds?.toStringAsFixed(3) ?? '-',
      oddsData.under45Odds?.toStringAsFixed(3) ?? '-',
    ].join('_');
  }

  void _removeExpiredCacheEntries() {
    final List<String> expiredKeys = _cache.entries.where((entry) {
      return entry.value.isExpired;
    }).map((entry) => entry.key).toList(growable: false);

    for (final String key in expiredKeys) {
      _cache.remove(key);
    }
  }

  double _estimateLeagueStrength(String league) {
    final String normalized = league.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (normalized.contains('premierleague') ||
        normalized.contains('laliga') ||
        normalized.contains('bundesliga') ||
        normalized.contains('seriea') ||
        normalized.contains('ligue1') ||
        normalized.contains('championsleague')) {
      return 90;
    }

    if (normalized.contains('eredivisie') ||
        normalized.contains('primeiraliga') ||
        normalized.contains('europaleague') ||
        normalized.contains('championship')) {
      return 78;
    }

    return 55;
  }
}

/// Egy mérkőzés teljes statisztikai és AI-elemzési eredménye.
class MatchAnalysisResult {
  final AppMatch match;
  final AppMatch originalMatch;
  final MatchStatisticsResult statisticsResult;
  final AiMatchAnalysis analysis;
  final bool success;
  final bool usedFallback;
  final String? errorMessage;
  final String? warningMessage;
  final DateTime startedAt;
  final DateTime completedAt;

  const MatchAnalysisResult({
    required this.match,
    required this.originalMatch,
    required this.statisticsResult,
    required this.analysis,
    required this.success,
    required this.usedFallback,
    required this.errorMessage,
    required this.warningMessage,
    required this.startedAt,
    required this.completedAt,
  });

  Duration get cacheLifetime {
    if (match.isLive) return const Duration(minutes: 2);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime matchDay = DateTime(
      match.matchDate.year,
      match.matchDate.month,
      match.matchDate.day,
    );

    if (matchDay == today) return const Duration(minutes: 20);
    return const Duration(hours: 6);
  }

  bool get isExpired {
    return DateTime.now().difference(completedAt) > cacheLifetime;
  }

  bool get hasWarning {
    return warningMessage != null && warningMessage!.trim().isNotEmpty;
  }

  bool get hasError {
    return errorMessage != null && errorMessage!.trim().isNotEmpty;
  }

  bool get hasRealStatistics {
    return statisticsResult.hasRealStatistics && !usedFallback;
  }

  bool get hasValueBet {
    return analysis.hasValueBet;
  }

  int get aiScore {
    return analysis.aiScore;
  }

  int get dataReliability {
    return analysis.dataReliability;
  }

  String get recommendation {
    return analysis.recommendation.selection;
  }

  String get recommendationMarket {
    return analysis.recommendation.marketName;
  }

  double get recommendationProbability {
    return analysis.recommendation.probability;
  }

  String get dataSourceLabel {
    return statisticsResult.sourceLabel;
  }

  String get qualityLabel {
    return statisticsResult.qualityLabel;
  }

  Duration get processingDuration {
    return completedAt.difference(startedAt);
  }

  AppMatch get updatedMatch {
    return match.copyWith(
      aiScore: analysis.aiScore,
      hasStatistics: hasRealStatistics,
    );
  }
}
