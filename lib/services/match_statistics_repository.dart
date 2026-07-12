// ===========================================
// Zsolt Pro AI
// Version: v0.16.3
// File: lib/services/match_statistics_repository.dart
// ===========================================

import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';
import 'sportmonks_statistics_service.dart';
import 'the_sports_db_statistics_service.dart';

/// A Zsolt Pro AI központi statisztikai adatkezelője.
///
/// Feladatai:
/// - felismeri a mérkőzés adatforrását;
/// - SportMonks-meccsnél SportMonks-statisztikát kér le;
/// - TheSportsDB-meccsnél TheSportsDB-statisztikát kér le;
/// - hiba vagy hiányos adat esetén fallback adatokra vált;
/// - egységes eredményt ad vissza az AI Engine számára;
/// - eltárolja az adatforrást, a figyelmeztetést és az
///   adatmegbízhatóság állapotát.
///
/// A képernyőknek és az AI Engine-nek nem kell tudnia,
/// melyik API szolgáltatta a statisztikát.
class MatchStatisticsRepository {
  MatchStatisticsRepository._();

  static final MatchStatisticsRepository instance =
      MatchStatisticsRepository._();

  final SportMonksStatisticsService
      _sportMonksStatisticsService =
      SportMonksStatisticsService.instance;

  final TheSportsDbStatisticsService
      _theSportsDbStatisticsService =
      TheSportsDbStatisticsService.instance;

  /// Egy mérkőzés részletes statisztikai csomagját tölti be.
  ///
  /// A szolgáltatás mindig eredménnyel tér vissza.
  /// Ha a valódi statisztikai API hibázik vagy nem ad elég adatot,
  /// biztonságos fallback statisztikát használ.
  Future<MatchStatisticsResult> loadStatistics(
    AppMatch match, {
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
  }) async {
    final int safeFormMatchCount =
        formMatchCount.clamp(
      1,
      10,
    );

    final int safeH2hMatchCount =
        h2hMatchCount.clamp(
      1,
      20,
    );

    if (match.isSportMonksMatch) {
      return _loadSportMonksStatistics(
        match: match,
        allowFallback: allowFallback,
        formMatchCount:
            safeFormMatchCount,
        h2hMatchCount:
            safeH2hMatchCount,
      );
    }

    if (match.isTheSportsDbMatch) {
      return _loadTheSportsDbStatistics(
        match: match,
        allowFallback: allowFallback,
        formMatchCount:
            safeFormMatchCount,
        h2hMatchCount:
            safeH2hMatchCount,
      );
    }

    if (!allowFallback) {
      throw MatchStatisticsRepositoryException(
        'A mérkőzés adatforrása nem támogatott: '
        '${match.dataSourceLabel}.',
      );
    }

    return _createFallbackResult(
      match: match,
      warningMessage:
          'A mérkőzés adatforrása nem támogat részletes '
          'statisztikai lekérést. Becsült adatokat használunk.',
      originalError: null,
    );
  }

  /// Több mérkőzés statisztikáját tölti be egymás után.
  ///
  /// Telefonon és ingyenes API-csomagoknál szándékosan nem
  /// indít egyszerre túl sok hálózati kérést.
  Future<List<MatchStatisticsResult>>
      loadStatisticsForMatches(
    List<AppMatch> matches, {
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
  }) async {
    final List<MatchStatisticsResult> results =
        <MatchStatisticsResult>[];

    for (final AppMatch match in matches) {
      final MatchStatisticsResult result =
          await loadStatistics(
        match,
        allowFallback: allowFallback,
        formMatchCount:
            formMatchCount,
        h2hMatchCount:
            h2hMatchCount,
      );

      results.add(
        result,
      );
    }

    return results;
  }

  /// Statisztika betöltése és teljes AI-elemzés készítése.
  Future<MatchStatisticsAnalysisResult>
      loadStatisticsAndAnalyze({
    required AppMatch match,
    required AiEngineV2Service aiEngine,
    AiOddsData? oddsData,
    bool allowFallback = true,
    int formMatchCount = 5,
    int h2hMatchCount = 8,
  }) async {
    final MatchStatisticsResult statisticsResult =
        await loadStatistics(
      match,
      allowFallback: allowFallback,
      formMatchCount:
          formMatchCount,
      h2hMatchCount:
          h2hMatchCount,
    );

    final AiMatchAnalysis analysis =
        aiEngine.analyzeMatch(
      match: match,
      statistics:
          statisticsResult.statistics,
      oddsData: oddsData,
    );

    return MatchStatisticsAnalysisResult(
      match: match,
      statisticsResult:
          statisticsResult,
      analysis: analysis,
    );
  }

  Future<MatchStatisticsResult>
      _loadSportMonksStatistics({
    required AppMatch match,
    required bool allowFallback,
    required int formMatchCount,
    required int h2hMatchCount,
  }) async {
    if (!match.hasTeamIds) {
      if (!allowFallback) {
        throw const MatchStatisticsRepositoryException(
          'A SportMonks csapatazonosítók hiányoznak.',
        );
      }

      return _createFallbackResult(
        match: match,
        warningMessage:
            'A SportMonks csapatazonosítók hiányoznak, '
            'ezért becsült statisztikát használunk.',
        originalError:
            'Hiányzó SportMonks csapatazonosítók.',
      );
    }

    try {
      final AiMatchStatistics statistics =
          await _sportMonksStatisticsService
              .loadMatchStatistics(
        match,
        formMatchCount:
            formMatchCount,
        h2hMatchCount:
            h2hMatchCount,
      );

      final MatchStatisticsQuality quality =
          _evaluateStatisticsQuality(
        statistics,
      );

      if (!_hasUsableStatistics(
        statistics,
      )) {
        if (!allowFallback) {
          throw const MatchStatisticsRepositoryException(
            'A SportMonks nem adott elegendő '
            'statisztikai adatot.',
          );
        }

        return _createFallbackResult(
          match: match,
          warningMessage:
              'A SportMonks kapcsolat működik, de nem érkezett '
              'elegendő korábbi mérkőzésadat. '
              'Becsült statisztikát használunk.',
          originalError:
              'Nincs elegendő SportMonks statisztikai adat.',
        );
      }

      return MatchStatisticsResult(
        matchId: match.id,
        statistics: statistics,
        source:
            MatchStatisticsSource.sportMonks,
        sourceLabel:
            'SportMonks',
        usedFallback: false,
        hasRealStatistics: true,
        quality: quality,
        warningMessage:
            _buildQualityWarning(
          quality: quality,
          sourceLabel:
              'SportMonks',
          statistics: statistics,
        ),
        errorMessage: null,
        loadedAt: DateTime.now(),
      );
    } on SportMonksStatisticsException catch (error) {
      if (!allowFallback) {
        throw MatchStatisticsRepositoryException(
          error.message,
        );
      }

      return _createFallbackResult(
        match: match,
        warningMessage:
            'A SportMonks statisztikák betöltése nem sikerült. '
            'Becsült adatokat használunk.',
        originalError:
            error.message,
      );
    } catch (error) {
      if (!allowFallback) {
        throw MatchStatisticsRepositoryException(
          'Váratlan SportMonks statisztikai hiba: $error',
        );
      }

      return _createFallbackResult(
        match: match,
        warningMessage:
            'Váratlan SportMonks statisztikai hiba történt. '
            'Becsült adatokat használunk.',
        originalError:
            error.toString(),
      );
    }
  }

  Future<MatchStatisticsResult>
      _loadTheSportsDbStatistics({
    required AppMatch match,
    required bool allowFallback,
    required int formMatchCount,
    required int h2hMatchCount,
  }) async {
    if (!match.hasTeamIds) {
      if (!allowFallback) {
        throw const MatchStatisticsRepositoryException(
          'A TheSportsDB csapatazonosítók hiányoznak.',
        );
      }

      return _createFallbackResult(
        match: match,
        warningMessage:
            'A TheSportsDB csapatazonosítók hiányoznak, '
            'ezért becsült statisztikát használunk.',
        originalError:
            'Hiányzó TheSportsDB csapatazonosítók.',
      );
    }

    try {
      final AiMatchStatistics statistics =
          await _theSportsDbStatisticsService
              .loadMatchStatistics(
        match,
        formMatchCount:
            formMatchCount,
        h2hMatchCount:
            h2hMatchCount,
      );

      final MatchStatisticsQuality quality =
          _evaluateStatisticsQuality(
        statistics,
      );

      if (!_hasUsableStatistics(
        statistics,
      )) {
        if (!allowFallback) {
          throw const MatchStatisticsRepositoryException(
            'A TheSportsDB nem adott elegendő '
            'statisztikai adatot.',
          );
        }

        return _createFallbackResult(
          match: match,
          warningMessage:
              'A TheSportsDB kapcsolat működik, de az ingyenes '
              'csomag nem adott elegendő korábbi mérkőzést. '
              'Becsült statisztikát használunk.',
          originalError:
              'Nincs elegendő TheSportsDB statisztikai adat.',
        );
      }

      String? warningMessage =
          _buildQualityWarning(
        quality: quality,
        sourceLabel:
            'TheSportsDB',
        statistics: statistics,
      );

      if (_theSportsDbStatisticsService
              .usesFreeApiKey &&
          warningMessage == null) {
        warningMessage =
            'Az ingyenes TheSportsDB-kulcs korlátozott számú '
            'korábbi mérkőzést adhat vissza.';
      } else if (_theSportsDbStatisticsService
              .usesFreeApiKey &&
          warningMessage != null) {
        warningMessage =
            '$warningMessage '
            'Az ingyenes TheSportsDB-kulcs korlátozott.';
      }

      return MatchStatisticsResult(
        matchId: match.id,
        statistics: statistics,
        source:
            MatchStatisticsSource.theSportsDb,
        sourceLabel:
            'TheSportsDB',
        usedFallback: false,
        hasRealStatistics: true,
        quality: quality,
        warningMessage:
            warningMessage,
        errorMessage: null,
        loadedAt: DateTime.now(),
      );
    } on TheSportsDbStatisticsException catch (error) {
      if (!allowFallback) {
        throw MatchStatisticsRepositoryException(
          error.message,
        );
      }

      return _createFallbackResult(
        match: match,
        warningMessage:
            'A TheSportsDB statisztikák betöltése nem '
            'sikerült. Becsült adatokat használunk.',
        originalError:
            error.message,
      );
    } catch (error) {
      if (!allowFallback) {
        throw MatchStatisticsRepositoryException(
          'Váratlan TheSportsDB statisztikai hiba: $error',
        );
      }

      return _createFallbackResult(
        match: match,
        warningMessage:
            'Váratlan TheSportsDB statisztikai hiba történt. '
            'Becsült adatokat használunk.',
        originalError:
            error.toString(),
      );
    }
  }

  MatchStatisticsResult _createFallbackResult({
    required AppMatch match,
    required String warningMessage,
    required String? originalError,
  }) {
    final AiMatchStatistics fallbackStatistics =
        AiMatchStatistics.fallback(
      leagueStrength:
          _estimateLeagueStrength(
        match.league,
      ),
    );

    return MatchStatisticsResult(
      matchId: match.id,
      statistics:
          fallbackStatistics,
      source:
          MatchStatisticsSource.fallback,
      sourceLabel:
          'Becsült AI-adatok',
      usedFallback: true,
      hasRealStatistics: false,
      quality:
          MatchStatisticsQuality.fallback,
      warningMessage:
          warningMessage,
      errorMessage:
          originalError,
      loadedAt: DateTime.now(),
    );
  }

  bool _hasUsableStatistics(
    AiMatchStatistics statistics,
  ) {
    final bool hasForm =
        statistics.homeForm.isNotEmpty ||
            statistics.awayForm.isNotEmpty;

    final bool hasSample =
        statistics.totalSampleSize > 0;

    final bool hasGoals =
        statistics.homeGoalsScoredAverage > 0 ||
            statistics.awayGoalsScoredAverage > 0 ||
            statistics.leagueAverageGoals > 0;

    final bool hasMarkets =
        statistics.over15Percent > 0 ||
            statistics.over25Percent > 0 ||
            statistics.bttsPercent > 0;

    return hasForm ||
        hasSample ||
        hasGoals ||
        hasMarkets;
  }

  MatchStatisticsQuality _evaluateStatisticsQuality(
    AiMatchStatistics statistics,
  ) {
    final int homeSample =
        statistics.homeSampleSize;

    final int awaySample =
        statistics.awaySampleSize;

    final int h2hSample =
        statistics.h2hTotalMatches;

    final int totalSample =
        statistics.totalSampleSize;

    if (homeSample >= 5 &&
        awaySample >= 5 &&
        h2hSample >= 3 &&
        totalSample >= 10) {
      return MatchStatisticsQuality.excellent;
    }

    if (homeSample >= 4 &&
        awaySample >= 4 &&
        totalSample >= 8) {
      return MatchStatisticsQuality.good;
    }

    if (homeSample >= 2 &&
        awaySample >= 2 &&
        totalSample >= 4) {
      return MatchStatisticsQuality.limited;
    }

    if (totalSample > 0 ||
        statistics.homeForm.isNotEmpty ||
        statistics.awayForm.isNotEmpty) {
      return MatchStatisticsQuality.weak;
    }

    return MatchStatisticsQuality.fallback;
  }

  String? _buildQualityWarning({
    required MatchStatisticsQuality quality,
    required String sourceLabel,
    required AiMatchStatistics statistics,
  }) {
    switch (quality) {
      case MatchStatisticsQuality.excellent:
        return null;

      case MatchStatisticsQuality.good:
        if (statistics.h2hTotalMatches < 3) {
          return '$sourceLabel: megfelelő csapatforma áll '
              'rendelkezésre, de kevés a H2H-adat.';
        }

        return null;

      case MatchStatisticsQuality.limited:
        return '$sourceLabel: korlátozott számú korábbi '
            'mérkőzésből készült az elemzés.';

      case MatchStatisticsQuality.weak:
        return '$sourceLabel: nagyon kevés statisztikai adat '
            'áll rendelkezésre, ezért az AI-értékelés '
            'bizonytalanabb.';

      case MatchStatisticsQuality.fallback:
        return '$sourceLabel: nem érkezett használható '
            'statisztikai adat.';
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

/// Egy mérkőzés statisztikai lekérésének egységes eredménye.
class MatchStatisticsResult {
  final String matchId;

  final AiMatchStatistics statistics;

  final MatchStatisticsSource source;
  final String sourceLabel;

  final bool usedFallback;
  final bool hasRealStatistics;

  final MatchStatisticsQuality quality;

  final String? warningMessage;
  final String? errorMessage;

  final DateTime loadedAt;

  const MatchStatisticsResult({
    required this.matchId,
    required this.statistics,
    required this.source,
    required this.sourceLabel,
    required this.usedFallback,
    required this.hasRealStatistics,
    required this.quality,
    required this.warningMessage,
    required this.errorMessage,
    required this.loadedAt,
  });

  bool get hasWarning {
    return warningMessage != null &&
        warningMessage!.trim().isNotEmpty;
  }

  bool get hasError {
    return errorMessage != null &&
        errorMessage!.trim().isNotEmpty;
  }

  bool get isHighQuality {
    return quality ==
            MatchStatisticsQuality.excellent ||
        quality ==
            MatchStatisticsQuality.good;
  }

  bool get isLimited {
    return quality ==
            MatchStatisticsQuality.limited ||
        quality ==
            MatchStatisticsQuality.weak;
  }

  int get sampleSize {
    return statistics.totalSampleSize;
  }

  String get qualityLabel {
    return switch (quality) {
      MatchStatisticsQuality.excellent =>
        'Kiváló adatminőség',
      MatchStatisticsQuality.good =>
        'Jó adatminőség',
      MatchStatisticsQuality.limited =>
        'Korlátozott adatminőség',
      MatchStatisticsQuality.weak =>
        'Gyenge adatminőség',
      MatchStatisticsQuality.fallback =>
        'Becsült adatok',
    };
  }

  String get shortSourceLabel {
    return switch (source) {
      MatchStatisticsSource.sportMonks =>
        'SportMonks',
      MatchStatisticsSource.theSportsDb =>
        'TheSportsDB',
      MatchStatisticsSource.fallback =>
        'Fallback',
      MatchStatisticsSource.unknown =>
        'Ismeretlen',
    };
  }
}

/// Egy statisztikai lekérés és AI-elemzés közös eredménye.
class MatchStatisticsAnalysisResult {
  final AppMatch match;

  final MatchStatisticsResult
      statisticsResult;

  final AiMatchAnalysis analysis;

  const MatchStatisticsAnalysisResult({
    required this.match,
    required this.statisticsResult,
    required this.analysis,
  });

  bool get usedRealStatistics {
    return statisticsResult.hasRealStatistics &&
        !statisticsResult.usedFallback;
  }

  bool get usedFallback {
    return statisticsResult.usedFallback;
  }
}

enum MatchStatisticsSource {
  sportMonks,
  theSportsDb,
  fallback,
  unknown,
}

enum MatchStatisticsQuality {
  excellent,
  good,
  limited,
  weak,
  fallback,
}

class MatchStatisticsRepositoryException
    implements Exception {
  final String message;

  const MatchStatisticsRepositoryException(
    this.message,
  );

  @override
  String toString() {
    return message;
  }
}
