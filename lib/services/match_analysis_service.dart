// ============================================================================
// Zsolt Pro AI - Central Match Analysis Service - PART 1
// Version: v0.18.6 - Compiler Safe Architecture & Production Ready
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
    final String cacheKey = '${match.id}|${oddsData?.hashCode ?? "no_odds"}';

    if (!forceRefresh) {
      final MatchAnalysisResult? cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        return Future<MatchAnalysisResult>.value(cached);
      }

      final Future<MatchAnalysisResult>? running = _runningRequests[cacheKey];
      if (running != null) return running;
    }

    final Future<MatchAnalysisResult> request = _performAnalysis(
      match: match,
      oddsData: oddsData,
      allowFallback: allowFallback,
      formMatchCount: formMatchCount,
      h2hMatchCount: h2hMatchCount,
    );

    _runningRequests[cacheKey] = request;
    return request.whenComplete(() => _runningRequests.remove(cacheKey));
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
    if (matches.isEmpty) return const <MatchAnalysisResult>[];
    final int safeBatchSize = batchSize.clamp(1, 4);
    final List<MatchAnalysisResult> results = <MatchAnalysisResult>[];

    for (int i = 0; i < matches.length; i += safeBatchSize) {
      final int end = (i + safeBatchSize).clamp(0, matches.length);
      final List<AppMatch> batch = matches.sublist(i, end);

      final List<Future<MatchAnalysisResult>> requests = batch.map((m) {
        return analyzeMatch(
          match: m,
          oddsData: oddsProvider?.call(m),
          forceRefresh: forceRefresh,
          allowFallback: allowFallback,
          formMatchCount: formMatchCount,
          h2hMatchCount: h2hMatchCount,
        );
      }).toList(growable: false);

      results.addAll(await Future.wait(requests));
    }
    return results;
  }
// ============================================================================
// Zsolt Pro AI - Central Match Analysis Service - PART 2
// ============================================================================

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

    final List<MatchAnalysisResult> filtered = results.where((r) => r.analysis.aiScore >= minimumAiScore).toList();
    filtered.sort((a, b) => b.analysis.aiScore.compareTo(a.analysis.aiScore));
    return filtered.take(limit.clamp(1, 20)).toList(growable: false);
  }

  MatchAnalysisResult? getCachedAnalysis(AppMatch match, {AiOddsData? oddsData}) {
    final String key = '${match.id}|${oddsData?.hashCode ?? "no_odds"}';
    final MatchAnalysisResult? result = _cache[key];
    return (result == null || result.isExpired) ? null : result;
  }

  bool hasCachedAnalysis(AppMatch match, {AiOddsData? oddsData}) => getCachedAnalysis(match, oddsData: oddsData) != null;
  void clearMatchCache(String id) => _cache.removeWhere((k, _) => k.startsWith('$id|'));
  void clearCache() => _cache.clear();
  int get cachedAnalysisCount { _cache.removeWhere((_, r) => r.isExpired); return _cache.length; }

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

      final MatchAnalysisResult result = MatchAnalysisResult(
        match: match.copyWith(aiScore: analysis.aiScore, hasStatistics: statisticsResult.hasRealStatistics, hasOdds: true),
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

      _cache['${match.id}|${effectiveOddsData.hashCode}'] = result;
      return result;
    } catch (error) {
      final fallbackAnalysis = _aiEngine.analyzeWithFallbackData(match: match, oddsData: oddsData);
      
      return MatchAnalysisResult(
        match: match,
        originalMatch: match,
        statisticsResult: MatchStatisticsResult(
          matchId: match.id,
          statistics: AiMatchStatistics.fallback(),
          source: MatchStatisticsSource.fallback,
          sourceLabel: 'Becsült AI-adatok',
          usedFallback: true,
          hasRealStatistics: false,
          quality: MatchStatisticsQuality.fallback,
          warningMessage: 'Hiba történt a statisztikák letöltésekor.',
          errorMessage: error.toString(),
          loadedAt: DateTime.now(),
        ),
        analysis: fallbackAnalysis,
        success: false,
        usedFallback: true,
        errorMessage: error.toString(),
        startedAt: startedAt,
        completedAt: DateTime.now(),
      );
    }
  }

  Future<AiOddsData> _tryFetchOrEstimateOdds(AppMatch match) async {
    if (_oddsService.hasApiKey) {
      try {
        final event = await _oddsService.findMatchOdds(
          homeTeam: match.homeTeam,
          awayTeam: match.awayTeam,
          matchDate: match.date,
          sportKey: match.sportKey,
        );
        if (event != null) {
          return AiOddsData(
            homeWinOdds: event.homeWinOdds,
            drawOdds: event.drawOdds,
            awayWinOdds: event.awayWinOdds,
            over15Odds: event.over15Odds,
            over25Odds: event.over25Odds,
            under25Odds: event.under25Odds,
            bttsYesOdds: event.bttsYesOdds,
          );
        }
      } catch (_) {}
    }
    return const AiOddsData();
  }
}

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

  bool get isExpired => DateTime.now().difference(completedAt) > const Duration(minutes: 20);
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

  AppMatch get updatedMatch => match.copyWith(aiScore: analysis.aiScore, hasStatistics: hasRealStatistics);
}
