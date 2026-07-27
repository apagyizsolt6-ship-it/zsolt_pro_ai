// ============================================================================
// Zsolt Pro AI - Central Match Analysis Service - PART 1
// Version: v0.18.2 - Production Ready Full Synchronized Architecture
// File: lib/services/match_analysis_service.dart
// ============================================================================

import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';
import 'match_statistics_repository.dart';
import 'the_odds_api_service.dart';

/// A Zsolt Pro AI központi mérkőzéselemző szolgáltatása.
class MatchAnalysisService {
  MatchAnalysisService._();

  static final MatchAnalysisService instance = MatchAnalysisService._();

  final MatchStatisticsRepository _statisticsRepository = MatchStatisticsRepository.instance;
  final AiEngineV2Service _aiEngine = AiEngineV2Service.instance;
  final TheOddsApiService _oddsService = TheOddsApiService.instance;

  final Map<String, MatchAnalysisResult> _cache = <String, MatchAnalysisResult>{};
  final Map<String, Future<MatchAnalysisResult>> _runningRequests = <String, Future<MatchAnalysisResult>>{};

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

  /// Több mérkőzés elemzését készíti el batchesítve.
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

  /// A legjobb elemzéseket adja vissza AI-pontszám szerint rendezve.
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

  MatchAnalysisResult? getCachedAnalysis(AppMatch match, {AiOddsData? oddsData}) {
    final String key = _createCacheKey(match: match, oddsData: oddsData);
    final MatchAnalysisResult? result = _cache[key];
    if (result == null || result.isExpired) {
      return null;
    }
    return result;
  }

  bool hasCachedAnalysis(AppMatch match, {AiOddsData? oddsData}) {
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
}
// ============================================================================
// Zsolt Pro AI - Central Match Analysis Service - PART 2
// ============================================================================

extension MatchAnalysisServiceInternal on MatchAnalysisService {
  Future<MatchAnalysisResult> _performAnalysis({
    required AppMatch match,
    required AiOddsData? oddsData,
    required bool allowFallback,
    required int formMatchCount,
    required int h2hMatchCount,
  }) async {
    final DateTime startedAt = DateTime.now();

    try {
      final statisticsResult = await _statisticsRepository.loadStatistics(
        match,
        allowFallback: allowFallback,
        formMatchCount: formMatchCount,
        h2hMatchCount: h2hMatchCount,
      );

      final AiOddsData effectiveOddsData = oddsData ?? await _tryFetchOrEstimateOdds(match);

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

      final String cacheKey = _createCacheKey(match: match, oddsData: effectiveOddsData);
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

  Future<AiOddsData> _tryFetchOrEstimateOdds(AppMatch match) async {
    if (_oddsService.hasApiKey) {
      try {
        final event = await _oddsService.findMatchOdds(match);
        if (event != null) {
          return AiOddsData(
            homeWinOdds: event.homeOdds,
            drawOdds: event.drawOdds,
            awayWinOdds: event.awayOdds,
            over15Odds: event.over15Odds,
            over25Odds: event.over25Odds,
            under25Odds: event.under25Odds,
            bttsYesOdds: event.bttsOdds,
          );
        }
      } catch (_) {}
    }
    return const AiOddsData();
  }

  String _createCacheKey({required AppMatch match, AiOddsData? oddsData}) {
    return '${match.id}|${oddsData?.hashCode ?? "no_odds"}';
  }

  void _removeExpiredCacheEntries() {
    _cache.removeWhere((_, result) => result.isExpired);
  }

  MatchAnalysisResult _analyzeWithEmergencyFallback({
    required AppMatch match,
    AiOddsData? oddsData,
    required DateTime startedAt,
    required String errorMessage,
  }) {
    final fallbackAnalysis = _aiEngine.analyzeWithFallbackData(
      match: match,
      oddsData: oddsData,
    );
    return MatchAnalysisResult(
      match: match,
      originalMatch: match,
      statisticsResult: MatchStatisticsResult.empty(errorMessage: errorMessage),
      analysis: fallbackAnalysis,
      success: false,
      usedFallback: true,
      errorMessage: errorMessage,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
  }
}

/// Az elemzés eredményét és metaadatait csomagoló osztály.
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
    this.usedFallback = false,
    this.errorMessage,
    this.warningMessage,
    required this.startedAt,
    required this.completedAt,
  });

  Duration get cacheLifetime {
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

  bool get isExpired => DateTime.now().difference(completedAt) > cacheLifetime;
  bool get hasWarning => warningMessage != null && warningMessage!.trim().isNotEmpty;
  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
  bool get hasRealStatistics => statisticsResult.hasRealStatistics && !usedFallback;
  bool get hasValueBet => analysis.hasValueBet;
  int get aiScore => analysis.aiScore;
  int get dataReliability => analysis.dataReliability;
  String get recommendation => analysis.recommendation.selection;
  String get recommendationMarket => analysis.recommendation.marketName;
  double get recommendationProbability => analysis.recommendation.probability;
  
  double get fairOdds => analysis.recommendation.fairOdds;
  double get marketOdds => analysis.recommendation.marketOdds;
  double get valueEdgePercentage => analysis.recommendation.edgePercentage;

  String get dataSourceLabel => statisticsResult.sourceLabel;
  String get qualityLabel => statisticsResult.qualityLabel;
  Duration get processingDuration => completedAt.difference(startedAt);

  AppMatch get updatedMatch {
    return match.copyWith(
      aiScore: analysis.aiScore,
      hasStatistics: hasRealStatistics,
    );
  }
}
