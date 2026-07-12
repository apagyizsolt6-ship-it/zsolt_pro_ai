// ===========================================
// Zsolt Pro AI
// Version: v0.17.0
// File: lib/services/match_analysis_service.dart
// ===========================================

import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';
import 'match_statistics_repository.dart';

/// A Zsolt Pro AI központi mérkőzéselemző szolgáltatása.
///
/// Ez a réteg kapcsolja össze:
/// - a mérkőzést;
/// - a SportMonks vagy TheSportsDB statisztikákat;
/// - az AI Engine 2.0 számítását;
/// - a fallback működést;
/// - az esetleges oddsadatokat.
///
/// A képernyőknek ettől kezdve nem kell külön kezelniük:
/// - az API adatforrását;
/// - a statisztikai szolgáltatást;
/// - a fallback adatokat;
/// - az AI Engine meghívását.
class MatchAnalysisService {
  MatchAnalysisService._();

  static final MatchAnalysisService instance =
      MatchAnalysisService._();

  final MatchStatisticsRepository
      _statisticsRepository =
      MatchStatisticsRepository.instance;

  final AiEngineV2Service _aiEngine =
      AiEngineV2Service.instance;

  final Map<String, MatchAnalysisResult> _cache =
      <String, MatchAnalysisResult>{};

  final Map<String, Future<MatchAnalysisResult>>
      _runningRequests =
      <String, Future<MatchAnalysisResult>>{};

  /// Egy mérkőzés teljes elemzését elkészíti.
  ///
  /// Alapesetben:
  /// - először megvizsgálja a gyorsítótárat;
  /// - lekéri a valódi statisztikákat;
  /// - hiba esetén fallback adatokat használ;
  /// - elkészíti az AI-elemzést;
  /// - eltárolja az eredményt a gyorsítótárban.
  Future<MatchAnalysisResult> analyzeMatch({
    required AppMatch match,
    AiOddsData? oddsData,
    bool forceRefresh = false,
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
  }) {
    final String cacheKey =
        _createCacheKey(
      match: match,
      oddsData: oddsData,
    );

    if (!forceRefresh) {
      final MatchAnalysisResult? cached =
          _cache[cacheKey];

      if (cached != null &&
          !cached.isExpired) {
        return Future<MatchAnalysisResult>.value(
          cached,
        );
      }

      final Future<MatchAnalysisResult>? running =
          _runningRequests[cacheKey];

      if (running != null) {
        return running;
      }
    }

    final Future<MatchAnalysisResult> request =
        _performAnalysis(
      match: match,
      oddsData: oddsData,
      allowFallback: allowFallback,
      formMatchCount: formMatchCount,
      h2hMatchCount: h2hMatchCount,
    );

    _runningRequests[cacheKey] =
        request;

    return request.whenComplete(
      () {
        _runningRequests.remove(
          cacheKey,
        );
      },
    );
  }

  /// Több mérkőzés elemzését készíti el.
  ///
  /// A kérések kisebb csoportokban futnak, hogy:
  /// - ne terheljük túl az ingyenes API-kat;
  /// - ne induljon egyszerre túl sok hálózati kérés;
  /// - telefonon is stabil maradjon az alkalmazás.
  Future<List<MatchAnalysisResult>>
      analyzeMatches({
    required List<AppMatch> matches,
    AiOddsData? Function(AppMatch match)?
        oddsProvider,
    bool forceRefresh = false,
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
    int batchSize = 2,
  }) async {
    if (matches.isEmpty) {
      return const <MatchAnalysisResult>[];
    }

    final int safeBatchSize =
        batchSize.clamp(
      1,
      4,
    );

    final List<MatchAnalysisResult> results =
        <MatchAnalysisResult>[];

    for (
      int startIndex = 0;
      startIndex < matches.length;
      startIndex += safeBatchSize
    ) {
      final int endIndex =
          (startIndex + safeBatchSize)
              .clamp(
        0,
        matches.length,
      );

      final List<AppMatch> batch =
          matches.sublist(
        startIndex,
        endIndex,
      );

      final List<Future<MatchAnalysisResult>>
          requests =
          batch.map(
        (AppMatch match) {
          return analyzeMatch(
            match: match,
            oddsData:
                oddsProvider?.call(
              match,
            ),
            forceRefresh:
                forceRefresh,
            allowFallback:
                allowFallback,
            formMatchCount:
                formMatchCount,
            h2hMatchCount:
                h2hMatchCount,
          );
        },
      ).toList(
        growable: false,
      );

      final List<MatchAnalysisResult>
          batchResults =
          await Future.wait(
        requests,
      );

      results.addAll(
        batchResults,
      );
    }

    return results;
  }

  /// A legjobb elemzéseket adja vissza AI-pontszám szerint.
  ///
  /// Ez lesz később az AI Top 5 központi adatforrása.
  Future<List<MatchAnalysisResult>>
      analyzeAndSelectTopMatches({
    required List<AppMatch> matches,
    int limit = 5,
    int minimumAiScore = 0,
    AiOddsData? Function(AppMatch match)?
        oddsProvider,
    bool forceRefresh = false,
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
    int batchSize = 2,
  }) async {
    final List<MatchAnalysisResult> results =
        await analyzeMatches(
      matches: matches,
      oddsProvider:
          oddsProvider,
      forceRefresh:
          forceRefresh,
      allowFallback:
          allowFallback,
      formMatchCount:
          formMatchCount,
      h2hMatchCount:
          h2hMatchCount,
      batchSize:
          batchSize,
    );

    final List<MatchAnalysisResult> filtered =
        results.where(
      (MatchAnalysisResult result) {
        return result.analysis.aiScore >=
            minimumAiScore;
      },
    ).toList();

    filtered.sort(
      (
        MatchAnalysisResult first,
        MatchAnalysisResult second,
      ) {
        final int scoreComparison =
            second.analysis.aiScore.compareTo(
          first.analysis.aiScore,
        );

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        final int probabilityComparison =
            second
                .analysis
                .recommendation
                .probability
                .compareTo(
                  first
                      .analysis
                      .recommendation
                      .probability,
                );

        if (probabilityComparison != 0) {
          return probabilityComparison;
        }

        final int reliabilityComparison =
            second
                .analysis
                .dataReliability
                .compareTo(
                  first
                      .analysis
                      .dataReliability,
                );

        if (reliabilityComparison != 0) {
          return reliabilityComparison;
        }

        return first.match.matchTime.compareTo(
          second.match.matchTime,
        );
      },
    );

    final int safeLimit =
        limit.clamp(
      1,
      20,
    );

    return filtered
        .take(
          safeLimit,
        )
        .toList(
          growable: false,
        );
  }

  /// Egy mérkőzés gyorsítótárazott elemzését adja vissza.
  ///
  /// Nem indít hálózati lekérést.
  MatchAnalysisResult? getCachedAnalysis(
    AppMatch match, {
    AiOddsData? oddsData,
  }) {
    final String key =
        _createCacheKey(
      match: match,
      oddsData: oddsData,
    );

    final MatchAnalysisResult? result =
        _cache[key];

    if (result == null ||
        result.isExpired) {
      return null;
    }

    return result;
  }

  /// Megadja, hogy van-e érvényes gyorsítótárazott elemzés.
  bool hasCachedAnalysis(
    AppMatch match, {
    AiOddsData? oddsData,
  }) {
    return getCachedAnalysis(
          match,
          oddsData: oddsData,
        ) !=
        null;
  }

  /// Egyetlen mérkőzés gyorsítótárát törli.
  void clearMatchCache(
    String matchId,
  ) {
    final List<String> keysToRemove =
        _cache.keys.where(
      (String key) {
        return key.startsWith(
          '$matchId|',
        );
      },
    ).toList(
      growable: false,
    );

    for (final String key
        in keysToRemove) {
      _cache.remove(
        key,
      );
    }
  }

  /// A teljes elemzési gyorsítótárat törli.
  void clearCache() {
    _cache.clear();
  }

  /// A gyorsítótárban lévő elemek száma.
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
    final DateTime startedAt =
        DateTime.now();

    try {
      final MatchStatisticsResult
          statisticsResult =
          await _statisticsRepository
              .loadStatistics(
        match,
        allowFallback:
            allowFallback,
        formMatchCount:
            formMatchCount,
        h2hMatchCount:
            h2hMatchCount,
      );

      final AiMatchAnalysis analysis =
          _aiEngine.analyzeMatch(
        match: match,
        statistics:
            statisticsResult.statistics,
        oddsData:
            oddsData,
      );

      final AppMatch analyzedMatch =
          match.copyWith(
        aiScore:
            analysis.aiScore,
        hasStatistics:
            statisticsResult
                .hasRealStatistics,
        hasOdds:
            oddsData != null ||
                match.hasOdds,
      );

      final MatchAnalysisResult result =
          MatchAnalysisResult(
        match:
            analyzedMatch,
        originalMatch:
            match,
        statisticsResult:
            statisticsResult,
        analysis:
            analysis,
        success:
            true,
        usedFallback:
            statisticsResult.usedFallback,
        errorMessage:
            statisticsResult.errorMessage,
        warningMessage:
            statisticsResult.warningMessage,
        startedAt:
            startedAt,
        completedAt:
            DateTime.now(),
      );

      final String cacheKey =
          _createCacheKey(
        match: match,
        oddsData: oddsData,
      );

      _cache[cacheKey] =
          result;

      return result;
    } on MatchStatisticsRepositoryException catch (
      error,
    ) {
      if (!allowFallback) {
        return _createFailureResult(
          match: match,
          startedAt: startedAt,
          message: error.message,
        );
      }

      return _analyzeWithEmergencyFallback(
        match: match,
        oddsData: oddsData,
        startedAt: startedAt,
        errorMessage:
            error.message,
      );
    } catch (error) {
      if (!allowFallback) {
        return _createFailureResult(
          match: match,
          startedAt: startedAt,
          message:
              'Váratlan mérkőzéselemzési hiba: $error',
        );
      }

      return _analyzeWithEmergencyFallback(
        match: match,
        oddsData: oddsData,
        startedAt: startedAt,
        errorMessage:
            error.toString(),
      );
    }
  }

  MatchAnalysisResult
      _analyzeWithEmergencyFallback({
    required AppMatch match,
    required AiOddsData? oddsData,
    required DateTime startedAt,
    required String errorMessage,
  }) {
    final AiMatchStatistics fallbackStatistics =
        AiMatchStatistics.fallback(
      leagueStrength:
          _estimateLeagueStrength(
        match.league,
      ),
    );

    final AiMatchAnalysis analysis =
        _aiEngine.analyzeMatch(
      match: match,
      statistics:
          fallbackStatistics,
      oddsData:
          oddsData,
    );

    final AppMatch analyzedMatch =
        match.copyWith(
      aiScore:
          analysis.aiScore,
      hasStatistics:
          false,
      hasOdds:
          oddsData != null ||
              match.hasOdds,
    );

    final MatchStatisticsResult
        fallbackStatisticsResult =
        MatchStatisticsResult(
      matchId:
          match.id,
      statistics:
          fallbackStatistics,
      source:
          MatchStatisticsSource.fallback,
      sourceLabel:
          'Vészhelyzeti becsült adatok',
      usedFallback:
          true,
      hasRealStatistics:
          false,
      quality:
          MatchStatisticsQuality.fallback,
      warningMessage:
          'A valódi statisztikai elemzés nem sikerült. '
          'Biztonságos becsült adatokat használunk.',
      errorMessage:
          errorMessage,
      loadedAt:
          DateTime.now(),
    );

    final MatchAnalysisResult result =
        MatchAnalysisResult(
      match:
          analyzedMatch,
      originalMatch:
          match,
      statisticsResult:
          fallbackStatisticsResult,
      analysis:
          analysis,
      success:
          true,
      usedFallback:
          true,
      errorMessage:
          errorMessage,
      warningMessage:
          'A valódi adatok helyett becsült '
          'AI-statisztikák kerültek felhasználásra.',
      startedAt:
          startedAt,
      completedAt:
          DateTime.now(),
    );

    final String cacheKey =
        _createCacheKey(
      match: match,
      oddsData: oddsData,
    );

    _cache[cacheKey] =
        result;

    return result;
  }

  MatchAnalysisResult _createFailureResult({
    required AppMatch match,
    required DateTime startedAt,
    required String message,
  }) {
    final AiMatchStatistics fallbackStatistics =
        AiMatchStatistics.fallback(
      leagueStrength:
          _estimateLeagueStrength(
        match.league,
      ),
    );

    final AiMatchAnalysis analysis =
        _aiEngine.analyzeMatch(
      match: match,
      statistics:
          fallbackStatistics,
    );

    final MatchStatisticsResult
        statisticsResult =
        MatchStatisticsResult(
      matchId:
          match.id,
      statistics:
          fallbackStatistics,
      source:
          MatchStatisticsSource.unknown,
      sourceLabel:
          'Nincs statisztikai adat',
      usedFallback:
          true,
      hasRealStatistics:
          false,
      quality:
          MatchStatisticsQuality.fallback,
      warningMessage:
          null,
      errorMessage:
          message,
      loadedAt:
          DateTime.now(),
    );

    return MatchAnalysisResult(
      match:
          match,
      originalMatch:
          match,
      statisticsResult:
          statisticsResult,
      analysis:
          analysis,
      success:
          false,
      usedFallback:
          true,
      errorMessage:
          message,
      warningMessage:
          null,
      startedAt:
          startedAt,
      completedAt:
          DateTime.now(),
    );
  }

  String _createCacheKey({
    required AppMatch match,
    required AiOddsData? oddsData,
  }) {
    final String oddsKey =
        _createOddsCacheKey(
      oddsData,
    );

    return '${match.id}|$oddsKey';
  }

  String _createOddsCacheKey(
    AiOddsData? oddsData,
  ) {
    if (oddsData == null) {
      return 'no_odds';
    }

    return <String>[
      oddsData.homeWinOdds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.drawOdds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.awayWinOdds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.over15Odds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.over25Odds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.over35Odds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.under45Odds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.bttsYesOdds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.homeOrDrawOdds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.awayOrDrawOdds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.homeOrDrawOver15Odds
              ?.toStringAsFixed(3) ??
          '-',
      oddsData.awayOrDrawOver15Odds
              ?.toStringAsFixed(3) ??
          '-',
    ].join(
      '_',
    );
  }

  void _removeExpiredCacheEntries() {
    final List<String> expiredKeys =
        _cache.entries.where(
      (
        MapEntry<String, MatchAnalysisResult>
            entry,
      ) {
        return entry.value.isExpired;
      },
    ).map(
      (
        MapEntry<String, MatchAnalysisResult>
            entry,
      ) {
        return entry.key;
      },
    ).toList(
      growable: false,
    );

    for (final String key
        in expiredKeys) {
      _cache.remove(
        key,
      );
    }
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
}

/// Egy mérkőzés teljes statisztikai és AI-elemzési eredménye.
class MatchAnalysisResult {
  final AppMatch match;

  /// Az elemzés előtti eredeti mérkőzésobjektum.
  final AppMatch originalMatch;

  final MatchStatisticsResult
      statisticsResult;

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

  /// A gyorsítótár érvényességi ideje.
  ///
  /// A múltbeli statisztikák ritkán változnak, de az
  /// élő vagy aznapi meccseknél gyakrabban frissítünk.
  Duration get cacheLifetime {
    if (match.isLive) {
      return const Duration(
        minutes: 2,
      );
    }

    final DateTime now =
        DateTime.now();

    final DateTime today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime matchDay =
        DateTime(
      match.matchDate.year,
      match.matchDate.month,
      match.matchDate.day,
    );

    if (matchDay == today) {
      return const Duration(
        minutes: 20,
      );
    }

    return const Duration(
      hours: 6,
    );
  }

  bool get isExpired {
    return DateTime.now().difference(
          completedAt,
        ) >
        cacheLifetime;
  }

  bool get hasWarning {
    return warningMessage != null &&
        warningMessage!.trim().isNotEmpty;
  }

  bool get hasError {
    return errorMessage != null &&
        errorMessage!.trim().isNotEmpty;
  }

  bool get hasRealStatistics {
    return statisticsResult
            .hasRealStatistics &&
        !usedFallback;
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
    return analysis
        .recommendation
        .selection;
  }

  String get recommendationMarket {
    return analysis
        .recommendation
        .marketName;
  }

  double get recommendationProbability {
    return analysis
        .recommendation
        .probability;
  }

  String get dataSourceLabel {
    return statisticsResult.sourceLabel;
  }

  String get qualityLabel {
    return statisticsResult.qualityLabel;
  }

  Duration get processingDuration {
    return completedAt.difference(
      startedAt,
    );
  }

  AppMatch get updatedMatch {
    return match.copyWith(
      aiScore:
          analysis.aiScore,
      hasStatistics:
          hasRealStatistics,
    );
  }
}
