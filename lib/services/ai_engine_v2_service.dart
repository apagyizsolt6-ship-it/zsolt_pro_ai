// ===========================================
// Zsolt Pro AI
// Version: v0.15.0
// File: lib/services/ai_engine_v2_service.dart
// ===========================================

import 'dart:math' as math;

import '../models/app_match.dart';

/// A Zsolt Pro AI adatvezérelt elemzőmotorja.
///
/// Ez a szolgáltatás önmagában nem végez API-lekérést.
/// A SportMonksból, TheSportsDB-ből és később más
/// szolgáltatásokból érkező statisztikákat egységes
/// [AiMatchStatistics] objektumként kapja meg.
///
/// A számítás figyelembe veszi:
/// - hazai és vendég csapatformát;
/// - hazai és idegenbeli teljesítményt;
/// - rúgott és kapott gólokat;
/// - Over 1,5 / Over 2,5 / Over 3,5 arányokat;
/// - BTTS arányt;
/// - egymás elleni mérleget;
/// - hazai pálya előnyét;
/// - bajnokság erősségét;
/// - adatok megbízhatóságát;
/// - később a valódi oddsokat és Value Bet értéket.
///
/// A szolgáltatás nem használ véletlenszerű számokat.
/// Ugyanazokból az adatokból mindig ugyanazt az
/// eredményt állítja elő.
class AiEngineV2Service {
  AiEngineV2Service._();

  static final AiEngineV2Service instance =
      AiEngineV2Service._();

  static const int _minimumAiScore = 35;
  static const int _maximumAiScore = 95;

  /// Teljes mérkőzéselemzés készítése.
  AiMatchAnalysis analyzeMatch({
    required AppMatch match,
    required AiMatchStatistics statistics,
    AiOddsData? oddsData,
  }) {
    final AiTeamMetrics homeMetrics =
        _calculateTeamMetrics(
      form: statistics.homeForm,
      locationForm: statistics.homeVenueForm,
      goalsScoredAverage:
          statistics.homeGoalsScoredAverage,
      goalsConcededAverage:
          statistics.homeGoalsConcededAverage,
      cleanSheetPercent:
          statistics.homeCleanSheetPercent,
      failedToScorePercent:
          statistics.homeFailedToScorePercent,
      isHomeTeam: true,
    );

    final AiTeamMetrics awayMetrics =
        _calculateTeamMetrics(
      form: statistics.awayForm,
      locationForm: statistics.awayVenueForm,
      goalsScoredAverage:
          statistics.awayGoalsScoredAverage,
      goalsConcededAverage:
          statistics.awayGoalsConcededAverage,
      cleanSheetPercent:
          statistics.awayCleanSheetPercent,
      failedToScorePercent:
          statistics.awayFailedToScorePercent,
      isHomeTeam: false,
    );

    final double expectedHomeGoals =
        _calculateExpectedHomeGoals(
      statistics: statistics,
      homeMetrics: homeMetrics,
      awayMetrics: awayMetrics,
    );

    final double expectedAwayGoals =
        _calculateExpectedAwayGoals(
      statistics: statistics,
      homeMetrics: homeMetrics,
      awayMetrics: awayMetrics,
    );

    final double expectedTotalGoals =
        expectedHomeGoals +
            expectedAwayGoals;

    final AiMarketProbabilities probabilities =
        _calculateMarketProbabilities(
      statistics: statistics,
      homeMetrics: homeMetrics,
      awayMetrics: awayMetrics,
      expectedHomeGoals: expectedHomeGoals,
      expectedAwayGoals: expectedAwayGoals,
    );

    final AiRecommendation recommendation =
        _selectBestRecommendation(
      probabilities: probabilities,
      statistics: statistics,
      oddsData: oddsData,
    );

    final int dataReliability =
        _calculateDataReliability(
      statistics,
    );

    final int aiScore =
        _calculateOverallAiScore(
      recommendationProbability:
          recommendation.probability,
      dataReliability: dataReliability,
      leagueStrength:
          statistics.leagueStrength,
      sampleSize:
          statistics.totalSampleSize,
      oddsData: oddsData,
      recommendation:
          recommendation,
    );

    final AiRiskLevel riskLevel =
        _calculateRiskLevel(
      aiScore: aiScore,
      dataReliability:
          dataReliability,
      probability:
          recommendation.probability,
    );

    final List<String> strengths =
        _buildStrengths(
      statistics: statistics,
      probabilities: probabilities,
      homeMetrics: homeMetrics,
      awayMetrics: awayMetrics,
      recommendation:
          recommendation,
    );

    final List<String> warnings =
        _buildWarnings(
      statistics: statistics,
      dataReliability:
          dataReliability,
      recommendation:
          recommendation,
      oddsData: oddsData,
    );

    final List<String> explanation =
        _buildExplanation(
      match: match,
      statistics: statistics,
      homeMetrics: homeMetrics,
      awayMetrics: awayMetrics,
      probabilities: probabilities,
      expectedHomeGoals:
          expectedHomeGoals,
      expectedAwayGoals:
          expectedAwayGoals,
      dataReliability:
          dataReliability,
    );

    final AiValueBetResult? valueBet =
        oddsData == null
            ? null
            : calculateValueBet(
                probability:
                    recommendation.probability,
                realOdds:
                    oddsData.oddsForMarket(
                  recommendation.marketKey,
                ),
              );

    return AiMatchAnalysis(
      matchId: match.id,
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      league: match.league,
      aiScore: aiScore,
      dataReliability:
          dataReliability,
      riskLevel: riskLevel,
      recommendation:
          recommendation,
      probabilities:
          probabilities,
      expectedHomeGoals:
          _roundToTwoDecimals(
        expectedHomeGoals,
      ),
      expectedAwayGoals:
          _roundToTwoDecimals(
        expectedAwayGoals,
      ),
      expectedTotalGoals:
          _roundToTwoDecimals(
        expectedTotalGoals,
      ),
      homeMetrics: homeMetrics,
      awayMetrics: awayMetrics,
      strengths: strengths,
      warnings: warnings,
      explanation: explanation,
      valueBet: valueBet,
      generatedAt: DateTime.now(),
    );
  }

  /// Elemzés készítése akkor is, ha még nem állnak
  /// rendelkezésre részletes API-statisztikák.
  ///
  /// Ez nem véletlenszerű pontszámot készít, hanem
  /// semleges alapértékeket használ, ezért az eredmény
  /// óvatosabb és alacsonyabb megbízhatóságú lesz.
  AiMatchAnalysis analyzeWithFallbackData({
    required AppMatch match,
    AiOddsData? oddsData,
  }) {
    final AiMatchStatistics fallbackStatistics =
        AiMatchStatistics.fallback(
      leagueStrength:
          _estimateLeagueStrength(
        match.league,
      ),
    );

    return analyzeMatch(
      match: match,
      statistics:
          fallbackStatistics,
      oddsData: oddsData,
    );
  }

  /// Több mérkőzés elemzése és AI-pontszám szerinti
  /// rendezése.
  List<AiMatchAnalysis> analyzeMatches({
    required List<AiMatchInput> inputs,
  }) {
    final List<AiMatchAnalysis> analyses =
        inputs.map(
      (AiMatchInput input) {
        return analyzeMatch(
          match: input.match,
          statistics:
              input.statistics,
          oddsData: input.oddsData,
        );
      },
    ).toList(growable: false);

    final List<AiMatchAnalysis> sorted =
        List<AiMatchAnalysis>.from(
      analyses,
    );

    sorted.sort(
      (
        AiMatchAnalysis first,
        AiMatchAnalysis second,
      ) {
        final int scoreComparison =
            second.aiScore.compareTo(
          first.aiScore,
        );

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        final int probabilityComparison =
            second.recommendation.probability
                .compareTo(
          first.recommendation.probability,
        );

        if (probabilityComparison != 0) {
          return probabilityComparison;
        }

        return second.dataReliability.compareTo(
          first.dataReliability,
        );
      },
    );

    return sorted;
  }

  /// Legjobb elemzések kiválasztása.
  List<AiMatchAnalysis> selectTopMatches({
    required List<AiMatchAnalysis> analyses,
    int limit = 5,
    int minimumAiScore = 60,
  }) {
    final int safeLimit =
        limit.clamp(1, 20);

    final List<AiMatchAnalysis> filtered =
        analyses.where(
      (AiMatchAnalysis analysis) {
        return analysis.aiScore >=
            minimumAiScore;
      },
    ).toList();

    filtered.sort(
      (
        AiMatchAnalysis first,
        AiMatchAnalysis second,
      ) {
        return second.aiScore.compareTo(
          first.aiScore,
        );
      },
    );

    return filtered
        .take(safeLimit)
        .toList(growable: false);
  }

  /// Fair odds és Value Bet számítása.
  AiValueBetResult? calculateValueBet({
    required double probability,
    required double? realOdds,
  }) {
    if (probability <= 0 ||
        probability >= 100 ||
        realOdds == null ||
        realOdds <= 1) {
      return null;
    }

    final double normalizedProbability =
        probability / 100;

    final double fairOdds =
        1 / normalizedProbability;

    final double expectedValue =
        normalizedProbability *
                realOdds -
            1;

    final double valuePercent =
        expectedValue * 100;

    final double edgePercent =
        ((realOdds / fairOdds) - 1) *
            100;

    final bool isValueBet =
        valuePercent >= 3;

    final AiValueLevel level;

    if (valuePercent >= 15) {
      level = AiValueLevel.strong;
    } else if (valuePercent >= 8) {
      level = AiValueLevel.good;
    } else if (valuePercent >= 3) {
      level = AiValueLevel.small;
    } else if (valuePercent >= 0) {
      level = AiValueLevel.neutral;
    } else {
      level = AiValueLevel.negative;
    }

    return AiValueBetResult(
      probability:
          _roundToTwoDecimals(
        probability,
      ),
      realOdds:
          _roundToTwoDecimals(
        realOdds,
      ),
      fairOdds:
          _roundToTwoDecimals(
        fairOdds,
      ),
      expectedValuePercent:
          _roundToTwoDecimals(
        valuePercent,
      ),
      edgePercent:
          _roundToTwoDecimals(
        edgePercent,
      ),
      isValueBet: isValueBet,
      level: level,
    );
  }

  AiTeamMetrics _calculateTeamMetrics({
    required List<AiMatchResult> form,
    required List<AiMatchResult>
        locationForm,
    required double goalsScoredAverage,
    required double goalsConcededAverage,
    required double cleanSheetPercent,
    required double failedToScorePercent,
    required bool isHomeTeam,
  }) {
    final List<AiMatchResult> effectiveForm =
        form.isEmpty
            ? const <AiMatchResult>[]
            : form;

    final List<AiMatchResult>
        effectiveLocationForm =
        locationForm.isEmpty
            ? effectiveForm
            : locationForm;

    final double overallFormScore =
        _calculateWeightedFormScore(
      effectiveForm,
    );

    final double venueFormScore =
        _calculateWeightedFormScore(
      effectiveLocationForm,
    );

    final double attackingScore =
        _calculateAttackingScore(
      goalsScoredAverage:
          goalsScoredAverage,
      failedToScorePercent:
          failedToScorePercent,
    );

    final double defensiveScore =
        _calculateDefensiveScore(
      goalsConcededAverage:
          goalsConcededAverage,
      cleanSheetPercent:
          cleanSheetPercent,
    );

    final double homeBonus =
        isHomeTeam ? 4 : 0;

    final double totalScore =
        overallFormScore * 0.34 +
            venueFormScore * 0.28 +
            attackingScore * 0.23 +
            defensiveScore * 0.15 +
            homeBonus;

    return AiTeamMetrics(
      overallFormScore:
          _roundToTwoDecimals(
        overallFormScore,
      ),
      venueFormScore:
          _roundToTwoDecimals(
        venueFormScore,
      ),
      attackingScore:
          _roundToTwoDecimals(
        attackingScore,
      ),
      defensiveScore:
          _roundToTwoDecimals(
        defensiveScore,
      ),
      totalStrength:
          _roundToTwoDecimals(
        totalScore.clamp(
          0,
          100,
        ),
      ),
      goalsScoredAverage:
          _roundToTwoDecimals(
        goalsScoredAverage,
      ),
      goalsConcededAverage:
          _roundToTwoDecimals(
        goalsConcededAverage,
      ),
    );
  }

  double _calculateWeightedFormScore(
    List<AiMatchResult> results,
  ) {
    if (results.isEmpty) {
      return 50;
    }

    const List<double> weights =
        <double>[
      1.00,
      0.88,
      0.76,
      0.66,
      0.58,
      0.50,
      0.44,
      0.38,
      0.33,
      0.28,
    ];

    double weightedPoints = 0;
    double maximumPoints = 0;

    final int count = math.min(
      results.length,
      weights.length,
    );

    for (int index = 0;
        index < count;
        index++) {
      final double weight =
          weights[index];

      final double points =
          switch (results[index]) {
        AiMatchResult.win => 3,
        AiMatchResult.draw => 1,
        AiMatchResult.loss => 0,
      };

      weightedPoints +=
          points * weight;

      maximumPoints +=
          3 * weight;
    }

    if (maximumPoints <= 0) {
      return 50;
    }

    return (weightedPoints /
            maximumPoints) *
        100;
  }

  double _calculateAttackingScore({
    required double goalsScoredAverage,
    required double failedToScorePercent,
  }) {
    final double goalScore =
        (goalsScoredAverage / 2.5) *
            100;

    final double scoringReliability =
        100 -
            failedToScorePercent.clamp(
              0,
              100,
            );

    return (goalScore.clamp(
                  0,
                  100,
                ) *
                0.68 +
            scoringReliability * 0.32)
        .clamp(
          0,
          100,
        );
  }

  double _calculateDefensiveScore({
    required double goalsConcededAverage,
    required double cleanSheetPercent,
  }) {
    final double concededScore =
        100 -
            (goalsConcededAverage /
                    2.5) *
                100;

    return (concededScore.clamp(
                  0,
                  100,
                ) *
                0.68 +
            cleanSheetPercent.clamp(
                  0,
                  100,
                ) *
                0.32)
        .clamp(
          0,
          100,
        );
  }

  double _calculateExpectedHomeGoals({
    required AiMatchStatistics
        statistics,
    required AiTeamMetrics homeMetrics,
    required AiTeamMetrics awayMetrics,
  }) {
    final double attackingBase =
        statistics.homeGoalsScoredAverage >
                0
            ? statistics
                .homeGoalsScoredAverage
            : 1.35;

    final double opponentDefence =
        statistics.awayGoalsConcededAverage >
                0
            ? statistics
                .awayGoalsConcededAverage
            : 1.25;

    final double formAdjustment =
        (homeMetrics.totalStrength -
                awayMetrics.defensiveScore) /
            200;

    final double homeAdvantage =
        statistics.homeAdvantage /
            100;

    final double leagueAdjustment =
        statistics.leagueAverageGoals >
                0
            ? statistics.leagueAverageGoals /
                2.7
            : 1;

    final double result =
        ((attackingBase +
                    opponentDefence) /
                2) *
            (1 +
                formAdjustment +
                homeAdvantage * 0.18) *
            leagueAdjustment;

    return result.clamp(
      0.25,
      3.80,
    );
  }

  double _calculateExpectedAwayGoals({
    required AiMatchStatistics
        statistics,
    required AiTeamMetrics homeMetrics,
    required AiTeamMetrics awayMetrics,
  }) {
    final double attackingBase =
        statistics.awayGoalsScoredAverage >
                0
            ? statistics
                .awayGoalsScoredAverage
            : 1.15;

    final double opponentDefence =
        statistics.homeGoalsConcededAverage >
                0
            ? statistics
                .homeGoalsConcededAverage
            : 1.15;

    final double formAdjustment =
        (awayMetrics.totalStrength -
                homeMetrics.defensiveScore) /
            210;

    final double homeAdvantagePenalty =
        statistics.homeAdvantage /
            100;

    final double leagueAdjustment =
        statistics.leagueAverageGoals >
                0
            ? statistics.leagueAverageGoals /
                2.7
            : 1;

    final double result =
        ((attackingBase +
                    opponentDefence) /
                2) *
            (1 +
                formAdjustment -
                homeAdvantagePenalty * 0.12) *
            leagueAdjustment;

    return result.clamp(
      0.20,
      3.50,
    );
  }

  AiMarketProbabilities
      _calculateMarketProbabilities({
    required AiMatchStatistics
        statistics,
    required AiTeamMetrics homeMetrics,
    required AiTeamMetrics awayMetrics,
    required double expectedHomeGoals,
    required double expectedAwayGoals,
  }) {
    final double totalExpectedGoals =
        expectedHomeGoals +
            expectedAwayGoals;

    final double poissonHomeWin =
        _poissonHomeWinProbability(
      expectedHomeGoals,
      expectedAwayGoals,
    );

    final double poissonDraw =
        _poissonDrawProbability(
      expectedHomeGoals,
      expectedAwayGoals,
    );

    final double poissonAwayWin =
        (100 -
                poissonHomeWin -
                poissonDraw)
            .clamp(
              0,
              100,
            );

    final double formDifference =
        homeMetrics.totalStrength -
            awayMetrics.totalStrength;

    final double adjustedHomeWin =
        (poissonHomeWin +
                formDifference * 0.12 +
                statistics.homeAdvantage *
                    0.10)
            .clamp(
              5,
              90,
            );

    final double adjustedAwayWin =
        (poissonAwayWin -
                formDifference * 0.10 -
                statistics.homeAdvantage *
                    0.06)
            .clamp(
              5,
              90,
            );

    final double adjustedDraw =
        (100 -
                adjustedHomeWin -
                adjustedAwayWin)
            .clamp(
              5,
              50,
            );

    final double over15ByGoals =
        _poissonOverProbability(
      totalExpectedGoals,
      1.5,
    );

    final double over25ByGoals =
        _poissonOverProbability(
      totalExpectedGoals,
      2.5,
    );

    final double over35ByGoals =
        _poissonOverProbability(
      totalExpectedGoals,
      3.5,
    );

    final double over15 =
        _weightedAverage(
      <double>[
        over15ByGoals,
        statistics.over15Percent,
      ],
      <double>[
        0.58,
        0.42,
      ],
      fallback: over15ByGoals,
    ).clamp(
      5,
      97,
    );

    final double over25 =
        _weightedAverage(
      <double>[
        over25ByGoals,
        statistics.over25Percent,
      ],
      <double>[
        0.62,
        0.38,
      ],
      fallback: over25ByGoals,
    ).clamp(
      3,
      94,
    );

    final double over35 =
        _weightedAverage(
      <double>[
        over35ByGoals,
        statistics.over35Percent,
      ],
      <double>[
        0.66,
        0.34,
      ],
      fallback: over35ByGoals,
    ).clamp(
      2,
      88,
    );

    final double bttsPoisson =
        _calculateBttsProbability(
      expectedHomeGoals:
          expectedHomeGoals,
      expectedAwayGoals:
          expectedAwayGoals,
    );

    final double btts =
        _weightedAverage(
      <double>[
        bttsPoisson,
        statistics.bttsPercent,
      ],
      <double>[
        0.58,
        0.42,
      ],
      fallback: bttsPoisson,
    ).clamp(
      5,
      94,
    );

    final double under45 =
        (100 -
                _poissonOverProbability(
                  totalExpectedGoals,
                  4.5,
                ))
            .clamp(
              5,
              98,
            );

    final double homeOrDraw =
        (adjustedHomeWin +
                adjustedDraw)
            .clamp(
              10,
              98,
            );

    final double awayOrDraw =
        (adjustedAwayWin +
                adjustedDraw)
            .clamp(
              10,
              98,
            );

    final double noDraw =
        (adjustedHomeWin +
                adjustedAwayWin)
            .clamp(
              10,
              98,
            );

    final double homeOrDrawOver15 =
        _combinedProbability(
      homeOrDraw,
      over15,
      dependencyFactor: 0.95,
    );

    final double awayOrDrawOver15 =
        _combinedProbability(
      awayOrDraw,
      over15,
      dependencyFactor: 0.95,
    );

    return AiMarketProbabilities(
      homeWin:
          _roundToTwoDecimals(
        adjustedHomeWin,
      ),
      draw:
          _roundToTwoDecimals(
        adjustedDraw,
      ),
      awayWin:
          _roundToTwoDecimals(
        adjustedAwayWin,
      ),
      homeOrDraw:
          _roundToTwoDecimals(
        homeOrDraw,
      ),
      awayOrDraw:
          _roundToTwoDecimals(
        awayOrDraw,
      ),
      noDraw:
          _roundToTwoDecimals(
        noDraw,
      ),
      over15:
          _roundToTwoDecimals(
        over15,
      ),
      over25:
          _roundToTwoDecimals(
        over25,
      ),
      over35:
          _roundToTwoDecimals(
        over35,
      ),
      under45:
          _roundToTwoDecimals(
        under45,
      ),
      btts:
          _roundToTwoDecimals(
        btts,
      ),
      homeOrDrawOver15:
          _roundToTwoDecimals(
        homeOrDrawOver15,
      ),
      awayOrDrawOver15:
          _roundToTwoDecimals(
        awayOrDrawOver15,
      ),
    );
  }

  AiRecommendation _selectBestRecommendation({
    required AiMarketProbabilities
        probabilities,
    required AiMatchStatistics statistics,
    required AiOddsData? oddsData,
  }) {
    final List<AiRecommendation>
        candidates =
        <AiRecommendation>[
      AiRecommendation(
        marketKey:
            AiMarketKey.homeOrDrawOver15,
        marketName:
            'Dupla esély + összes gól',
        selection:
            '1X és több mint 1,5 gól',
        probability:
            probabilities.homeOrDrawOver15,
        reason:
            'A hazai csapat várhatóan nem kap ki, '
            'és legalább két gól valószínű.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.awayOrDrawOver15,
        marketName:
            'Dupla esély + összes gól',
        selection:
            'X2 és több mint 1,5 gól',
        probability:
            probabilities.awayOrDrawOver15,
        reason:
            'A vendég csapat várhatóan nem kap ki, '
            'és legalább két gól valószínű.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.over15,
        marketName:
            'Összes gól',
        selection:
            'Több mint 1,5 gól',
        probability:
            probabilities.over15,
        reason:
            'A gólátlagok és a támadómutatók '
            'legalább két gólt jeleznek.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.under45,
        marketName:
            'Összes gól',
        selection:
            'Kevesebb mint 4,5 gól',
        probability:
            probabilities.under45,
        reason:
            'Öt vagy több gól valószínűsége '
            'alacsony.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.homeOrDraw,
        marketName:
            'Dupla esély',
        selection:
            '1X – Hazai vagy döntetlen',
        probability:
            probabilities.homeOrDraw,
        reason:
            'A hazai forma és a pályaelőny '
            'a hazai csapat felé billenti a mérleget.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.awayOrDraw,
        marketName:
            'Dupla esély',
        selection:
            'X2 – Vendég vagy döntetlen',
        probability:
            probabilities.awayOrDraw,
        reason:
            'A vendégcsapat teljesítménye alapján '
            'kicsi a vereség kockázata.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.over25,
        marketName:
            'Összes gól',
        selection:
            'Több mint 2,5 gól',
        probability:
            probabilities.over25,
        reason:
            'A várható gólszám és az Over-statisztika '
            'gólgazdag mérkőzést jelez.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.btts,
        marketName:
            'Mindkét csapat szerez gólt',
        selection:
            'Igen',
        probability:
            probabilities.btts,
        reason:
            'Mindkét csapat támadó- és védelmi '
            'mutatói támogatják a BTTS-piacot.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.homeWin,
        marketName:
            'Mérkőzés győztese',
        selection:
            'Hazai győzelem',
        probability:
            probabilities.homeWin,
        reason:
            'A hazai csapat formája és erőssége '
            'kedvezőbb.',
      ),
      AiRecommendation(
        marketKey:
            AiMarketKey.awayWin,
        marketName:
            'Mérkőzés győztese',
        selection:
            'Vendég győzelem',
        probability:
            probabilities.awayWin,
        reason:
            'A vendégcsapat mutatói jelentős '
            'előnyt jeleznek.',
      ),
    ];

    AiRecommendation best =
        candidates.first;

    double bestRankingScore =
        _recommendationRankingScore(
      recommendation: best,
      oddsData: oddsData,
      statistics: statistics,
    );

    for (final AiRecommendation candidate
        in candidates.skip(1)) {
      final double rankingScore =
          _recommendationRankingScore(
        recommendation:
            candidate,
        oddsData: oddsData,
        statistics: statistics,
      );

      if (rankingScore >
          bestRankingScore) {
        best = candidate;
        bestRankingScore =
            rankingScore;
      }
    }

    return best;
  }

  double _recommendationRankingScore({
    required AiRecommendation
        recommendation,
    required AiOddsData? oddsData,
    required AiMatchStatistics statistics,
  }) {
    double score =
        recommendation.probability;

    switch (recommendation.marketKey) {
      case AiMarketKey.homeOrDrawOver15:
      case AiMarketKey.awayOrDrawOver15:
        score += 2.5;
      case AiMarketKey.over15:
      case AiMarketKey.under45:
        score += 2;
      case AiMarketKey.homeOrDraw:
      case AiMarketKey.awayOrDraw:
        score += 1.5;
      case AiMarketKey.over25:
      case AiMarketKey.btts:
        score += 0.5;
      case AiMarketKey.homeWin:
      case AiMarketKey.awayWin:
      case AiMarketKey.draw:
      case AiMarketKey.noDraw:
      case AiMarketKey.over35:
        break;
    }

    final double? realOdds =
        oddsData?.oddsForMarket(
      recommendation.marketKey,
    );

    if (realOdds != null &&
        realOdds > 1) {
      final AiValueBetResult? valueResult =
          calculateValueBet(
        probability:
            recommendation.probability,
        realOdds: realOdds,
      );

      if (valueResult != null) {
        score +=
            valueResult.expectedValuePercent *
                0.12;
      }
    }

    score +=
        statistics.dataQualityBonus *
            0.08;

    return score;
  }

  int _calculateDataReliability(
    AiMatchStatistics statistics,
  ) {
    double score = 20;

    if (statistics.homeForm.length >= 5) {
      score += 12;
    } else {
      score +=
          statistics.homeForm.length *
              2.2;
    }

    if (statistics.awayForm.length >= 5) {
      score += 12;
    } else {
      score +=
          statistics.awayForm.length *
              2.2;
    }

    if (statistics.homeVenueForm.length >=
        3) {
      score += 8;
    }

    if (statistics.awayVenueForm.length >=
        3) {
      score += 8;
    }

    if (statistics.h2hTotalMatches >= 3) {
      score += 8;
    }

    if (statistics.homeGoalsScoredAverage >
            0 &&
        statistics
                .awayGoalsScoredAverage >
            0) {
      score += 8;
    }

    if (statistics.over25Percent > 0) {
      score += 6;
    }

    if (statistics.bttsPercent > 0) {
      score += 6;
    }

    if (statistics.leagueAverageGoals >
        0) {
      score += 5;
    }

    if (statistics.totalSampleSize >= 10) {
      score += 7;
    }

    return score.round().clamp(
          20,
          100,
        );
  }

  int _calculateOverallAiScore({
    required double
        recommendationProbability,
    required int dataReliability,
    required double leagueStrength,
    required int sampleSize,
    required AiOddsData? oddsData,
    required AiRecommendation
        recommendation,
  }) {
    final double reliabilityFactor =
        dataReliability / 100;

    final double leagueFactor =
        leagueStrength.clamp(
              20,
              100,
            ) /
            100;

    final double sampleFactor =
        (sampleSize / 20).clamp(
      0,
      1,
    );

    double score =
        recommendationProbability *
                0.62 +
            dataReliability * 0.25 +
            leagueFactor * 100 * 0.08 +
            sampleFactor * 100 * 0.05;

    if (reliabilityFactor < 0.50) {
      score -= 8;
    }

    if (sampleSize < 5) {
      score -= 6;
    }

    final double? realOdds =
        oddsData?.oddsForMarket(
      recommendation.marketKey,
    );

    if (realOdds != null) {
      final AiValueBetResult? valueBet =
          calculateValueBet(
        probability:
            recommendationProbability,
        realOdds: realOdds,
      );

      if (valueBet != null &&
          valueBet.isValueBet) {
        score += math.min(
          4,
          valueBet.expectedValuePercent /
              5,
        );
      }
    }

    return score.round().clamp(
          _minimumAiScore,
          _maximumAiScore,
        );
  }

  AiRiskLevel _calculateRiskLevel({
    required int aiScore,
    required int dataReliability,
    required double probability,
  }) {
    if (aiScore >= 85 &&
        dataReliability >= 75 &&
        probability >= 78) {
      return AiRiskLevel.low;
    }

    if (aiScore >= 70 &&
        dataReliability >= 55 &&
        probability >= 65) {
      return AiRiskLevel.medium;
    }

    return AiRiskLevel.high;
  }

  List<String> _buildStrengths({
    required AiMatchStatistics
        statistics,
    required AiMarketProbabilities
        probabilities,
    required AiTeamMetrics homeMetrics,
    required AiTeamMetrics awayMetrics,
    required AiRecommendation
        recommendation,
  }) {
    final List<String> strengths =
        <String>[];

    if (recommendation.probability >= 80) {
      strengths.add(
        'A kiválasztott piac számított '
        'valószínűsége magas.',
      );
    }

    if (probabilities.over15 >= 80) {
      strengths.add(
        'A mérkőzés legalább két gólos '
        'valószínűsége erős.',
      );
    }

    if (probabilities.btts >= 65) {
      strengths.add(
        'Mindkét csapat gólszerzési mutatói '
        'kedvezőek.',
      );
    }

    if (homeMetrics.totalStrength -
            awayMetrics.totalStrength >=
        12) {
      strengths.add(
        'A hazai csapat forma- és '
        'erősségmutatója jobb.',
      );
    }

    if (awayMetrics.totalStrength -
            homeMetrics.totalStrength >=
        12) {
      strengths.add(
        'A vendégcsapat forma- és '
        'erősségmutatója jobb.',
      );
    }

    if (statistics.h2hTotalMatches >=
        5) {
      strengths.add(
        'Megfelelő számú egymás elleni '
        'eredmény áll rendelkezésre.',
      );
    }

    if (statistics.totalSampleSize >= 10) {
      strengths.add(
        'A számítás megfelelő méretű '
        'statisztikai mintán alapul.',
      );
    }

    if (strengths.isEmpty) {
      strengths.add(
        'A rendelkezésre álló mutatók '
        'kiegyensúlyozott mérkőzést jeleznek.',
      );
    }

    return strengths;
  }

  List<String> _buildWarnings({
    required AiMatchStatistics
        statistics,
    required int dataReliability,
    required AiRecommendation
        recommendation,
    required AiOddsData? oddsData,
  }) {
    final List<String> warnings =
        <String>[];

    if (dataReliability < 55) {
      warnings.add(
        'Kevés vagy hiányos statisztikai adat '
        'áll rendelkezésre.',
      );
    }

    if (statistics.homeForm.length < 5 ||
        statistics.awayForm.length < 5) {
      warnings.add(
        'Az egyik csapat utolsó öt '
        'mérkőzésének adatai hiányosak.',
      );
    }

    if (statistics.h2hTotalMatches < 3) {
      warnings.add(
        'Kevés egymás elleni mérkőzés '
        'szerepel a számításban.',
      );
    }

    if (recommendation.probability < 65) {
      warnings.add(
        'A kiválasztott tipp valószínűsége '
        'nem éri el a 65%-ot.',
      );
    }

    if (oddsData == null) {
      warnings.add(
        'Valódi odds nélkül Value Bet '
        'nem számítható.',
      );
    }

    return warnings;
  }

  List<String> _buildExplanation({
    required AppMatch match,
    required AiMatchStatistics
        statistics,
    required AiTeamMetrics homeMetrics,
    required AiTeamMetrics awayMetrics,
    required AiMarketProbabilities
        probabilities,
    required double expectedHomeGoals,
    required double expectedAwayGoals,
    required int dataReliability,
  }) {
    return <String>[
      '${match.homeTeam} formaértéke: '
          '${homeMetrics.overallFormScore.toStringAsFixed(0)}%.',
      '${match.awayTeam} formaértéke: '
          '${awayMetrics.overallFormScore.toStringAsFixed(0)}%.',
      'Várható gólok: '
          '${match.homeTeam} '
          '${expectedHomeGoals.toStringAsFixed(2)}, '
          '${match.awayTeam} '
          '${expectedAwayGoals.toStringAsFixed(2)}.',
      'Over 1,5 valószínűség: '
          '${probabilities.over15.toStringAsFixed(0)}%.',
      'Over 2,5 valószínűség: '
          '${probabilities.over25.toStringAsFixed(0)}%.',
      'BTTS valószínűség: '
          '${probabilities.btts.toStringAsFixed(0)}%.',
      'Adatmegbízhatóság: $dataReliability%.',
      'Ligaerősségi érték: '
          '${statistics.leagueStrength.toStringAsFixed(0)}%.',
    ];
  }

  double _poissonHomeWinProbability(
    double homeExpectedGoals,
    double awayExpectedGoals,
  ) {
    double probability = 0;

    for (int homeGoals = 0;
        homeGoals <= 8;
        homeGoals++) {
      for (int awayGoals = 0;
          awayGoals <= 8;
          awayGoals++) {
        if (homeGoals > awayGoals) {
          probability +=
              _poissonProbability(
                    homeExpectedGoals,
                    homeGoals,
                  ) *
                  _poissonProbability(
                    awayExpectedGoals,
                    awayGoals,
                  );
        }
      }
    }

    return probability * 100;
  }

  double _poissonDrawProbability(
    double homeExpectedGoals,
    double awayExpectedGoals,
  ) {
    double probability = 0;

    for (int goals = 0;
        goals <= 8;
        goals++) {
      probability +=
          _poissonProbability(
                homeExpectedGoals,
                goals,
              ) *
              _poissonProbability(
                awayExpectedGoals,
                goals,
              );
    }

    return probability * 100;
  }

  double _poissonOverProbability(
    double expectedGoals,
    double line,
  ) {
    final int maximumUnderGoals =
        line.floor();

    double underProbability = 0;

    for (int goals = 0;
        goals <= maximumUnderGoals;
        goals++) {
      underProbability +=
          _poissonProbability(
        expectedGoals,
        goals,
      );
    }

    return ((1 - underProbability) * 100)
        .clamp(
          0,
          100,
        );
  }

  double _calculateBttsProbability({
    required double expectedHomeGoals,
    required double expectedAwayGoals,
  }) {
    final double homeNoGoal =
        _poissonProbability(
      expectedHomeGoals,
      0,
    );

    final double awayNoGoal =
        _poissonProbability(
      expectedAwayGoals,
      0,
    );

    final double bothNoGoal =
        homeNoGoal * awayNoGoal;

    final double probability =
        1 -
            homeNoGoal -
            awayNoGoal +
            bothNoGoal;

    return (probability * 100).clamp(
      0,
      100,
    );
  }

  double _poissonProbability(
    double lambda,
    int goals,
  ) {
    if (lambda <= 0) {
      return goals == 0 ? 1 : 0;
    }

    return math.exp(-lambda) *
        math.pow(
          lambda,
          goals,
        ) /
        _factorial(goals);
  }

  int _factorial(int value) {
    if (value <= 1) {
      return 1;
    }

    int result = 1;

    for (int index = 2;
        index <= value;
        index++) {
      result *= index;
    }

    return result;
  }

  double _combinedProbability(
    double first,
    double second, {
    double dependencyFactor = 1,
  }) {
    return ((first / 100) *
                (second / 100) *
                dependencyFactor *
                100)
            .clamp(
          0,
          98,
        );
  }

  double _weightedAverage(
    List<double> values,
    List<double> weights, {
    required double fallback,
  }) {
    if (values.isEmpty ||
        values.length != weights.length) {
      return fallback;
    }

    double weightedTotal = 0;
    double totalWeight = 0;

    for (int index = 0;
        index < values.length;
        index++) {
      final double value =
          values[index];

      if (value <= 0) {
        continue;
      }

      weightedTotal +=
          value * weights[index];

      totalWeight +=
          weights[index];
    }

    if (totalWeight <= 0) {
      return fallback;
    }

    return weightedTotal /
        totalWeight;
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

  double _roundToTwoDecimals(
    double value,
  ) {
    return (value * 100).round() /
        100;
  }
}

class AiMatchInput {
  final AppMatch match;
  final AiMatchStatistics statistics;
  final AiOddsData? oddsData;

  const AiMatchInput({
    required this.match,
    required this.statistics,
    this.oddsData,
  });
}

class AiMatchStatistics {
  final List<AiMatchResult> homeForm;
  final List<AiMatchResult> awayForm;

  final List<AiMatchResult>
      homeVenueForm;
  final List<AiMatchResult>
      awayVenueForm;

  final double homeGoalsScoredAverage;
  final double homeGoalsConcededAverage;
  final double awayGoalsScoredAverage;
  final double awayGoalsConcededAverage;

  final double homeCleanSheetPercent;
  final double awayCleanSheetPercent;

  final double homeFailedToScorePercent;
  final double awayFailedToScorePercent;

  final double over15Percent;
  final double over25Percent;
  final double over35Percent;
  final double bttsPercent;

  final int h2hHomeWins;
  final int h2hDraws;
  final int h2hAwayWins;

  final double h2hAverageGoals;
  final double h2hBttsPercent;
  final double h2hOver25Percent;

  final double leagueAverageGoals;
  final double leagueStrength;
  final double homeAdvantage;

  final int homeSampleSize;
  final int awaySampleSize;

  final double dataQualityBonus;

  const AiMatchStatistics({
    this.homeForm =
        const <AiMatchResult>[],
    this.awayForm =
        const <AiMatchResult>[],
    this.homeVenueForm =
        const <AiMatchResult>[],
    this.awayVenueForm =
        const <AiMatchResult>[],
    this.homeGoalsScoredAverage = 0,
    this.homeGoalsConcededAverage = 0,
    this.awayGoalsScoredAverage = 0,
    this.awayGoalsConcededAverage = 0,
    this.homeCleanSheetPercent = 0,
    this.awayCleanSheetPercent = 0,
    this.homeFailedToScorePercent = 0,
    this.awayFailedToScorePercent = 0,
    this.over15Percent = 0,
    this.over25Percent = 0,
    this.over35Percent = 0,
    this.bttsPercent = 0,
    this.h2hHomeWins = 0,
    this.h2hDraws = 0,
    this.h2hAwayWins = 0,
    this.h2hAverageGoals = 0,
    this.h2hBttsPercent = 0,
    this.h2hOver25Percent = 0,
    this.leagueAverageGoals = 0,
    this.leagueStrength = 55,
    this.homeAdvantage = 8,
    this.homeSampleSize = 0,
    this.awaySampleSize = 0,
    this.dataQualityBonus = 0,
  });

  factory AiMatchStatistics.fallback({
    double leagueStrength = 55,
  }) {
    return AiMatchStatistics(
      homeGoalsScoredAverage: 1.35,
      homeGoalsConcededAverage: 1.20,
      awayGoalsScoredAverage: 1.15,
      awayGoalsConcededAverage: 1.35,
      homeCleanSheetPercent: 25,
      awayCleanSheetPercent: 20,
      homeFailedToScorePercent: 22,
      awayFailedToScorePercent: 28,
      over15Percent: 68,
      over25Percent: 48,
      over35Percent: 27,
      bttsPercent: 52,
      leagueAverageGoals: 2.60,
      leagueStrength: leagueStrength,
      homeAdvantage: 8,
      homeSampleSize: 0,
      awaySampleSize: 0,
    );
  }

  int get h2hTotalMatches {
    return h2hHomeWins +
        h2hDraws +
        h2hAwayWins;
  }

  int get totalSampleSize {
    return homeSampleSize +
        awaySampleSize;
  }

  AiMatchStatistics copyWith({
    List<AiMatchResult>? homeForm,
    List<AiMatchResult>? awayForm,
    List<AiMatchResult>?
        homeVenueForm,
    List<AiMatchResult>?
        awayVenueForm,
    double? homeGoalsScoredAverage,
    double? homeGoalsConcededAverage,
    double? awayGoalsScoredAverage,
    double? awayGoalsConcededAverage,
    double? homeCleanSheetPercent,
    double? awayCleanSheetPercent,
    double? homeFailedToScorePercent,
    double? awayFailedToScorePercent,
    double? over15Percent,
    double? over25Percent,
    double? over35Percent,
    double? bttsPercent,
    int? h2hHomeWins,
    int? h2hDraws,
    int? h2hAwayWins,
    double? h2hAverageGoals,
    double? h2hBttsPercent,
    double? h2hOver25Percent,
    double? leagueAverageGoals,
    double? leagueStrength,
    double? homeAdvantage,
    int? homeSampleSize,
    int? awaySampleSize,
    double? dataQualityBonus,
  }) {
    return AiMatchStatistics(
      homeForm:
          homeForm ?? this.homeForm,
      awayForm:
          awayForm ?? this.awayForm,
      homeVenueForm:
          homeVenueForm ??
              this.homeVenueForm,
      awayVenueForm:
          awayVenueForm ??
              this.awayVenueForm,
      homeGoalsScoredAverage:
          homeGoalsScoredAverage ??
              this.homeGoalsScoredAverage,
      homeGoalsConcededAverage:
          homeGoalsConcededAverage ??
              this.homeGoalsConcededAverage,
      awayGoalsScoredAverage:
          awayGoalsScoredAverage ??
              this.awayGoalsScoredAverage,
      awayGoalsConcededAverage:
          awayGoalsConcededAverage ??
              this.awayGoalsConcededAverage,
      homeCleanSheetPercent:
          homeCleanSheetPercent ??
              this.homeCleanSheetPercent,
      awayCleanSheetPercent:
          awayCleanSheetPercent ??
              this.awayCleanSheetPercent,
      homeFailedToScorePercent:
          homeFailedToScorePercent ??
              this.homeFailedToScorePercent,
      awayFailedToScorePercent:
          awayFailedToScorePercent ??
              this.awayFailedToScorePercent,
      over15Percent:
          over15Percent ??
              this.over15Percent,
      over25Percent:
          over25Percent ??
              this.over25Percent,
      over35Percent:
          over35Percent ??
              this.over35Percent,
      bttsPercent:
          bttsPercent ??
              this.bttsPercent,
      h2hHomeWins:
          h2hHomeWins ??
              this.h2hHomeWins,
      h2hDraws:
          h2hDraws ??
              this.h2hDraws,
      h2hAwayWins:
          h2hAwayWins ??
              this.h2hAwayWins,
      h2hAverageGoals:
          h2hAverageGoals ??
              this.h2hAverageGoals,
      h2hBttsPercent:
          h2hBttsPercent ??
              this.h2hBttsPercent,
      h2hOver25Percent:
          h2hOver25Percent ??
              this.h2hOver25Percent,
      leagueAverageGoals:
          leagueAverageGoals ??
              this.leagueAverageGoals,
      leagueStrength:
          leagueStrength ??
              this.leagueStrength,
      homeAdvantage:
          homeAdvantage ??
              this.homeAdvantage,
      homeSampleSize:
          homeSampleSize ??
              this.homeSampleSize,
      awaySampleSize:
          awaySampleSize ??
              this.awaySampleSize,
      dataQualityBonus:
          dataQualityBonus ??
              this.dataQualityBonus,
    );
  }
}

class AiOddsData {
  final double? homeWinOdds;
  final double? drawOdds;
  final double? awayWinOdds;

  final double? homeOrDrawOdds;
  final double? awayOrDrawOdds;
  final double? noDrawOdds;

  final double? over15Odds;
  final double? over25Odds;
  final double? over35Odds;
  final double? under45Odds;

  final double? bttsYesOdds;

  final double? homeOrDrawOver15Odds;
  final double? awayOrDrawOver15Odds;

  const AiOddsData({
    this.homeWinOdds,
    this.drawOdds,
    this.awayWinOdds,
    this.homeOrDrawOdds,
    this.awayOrDrawOdds,
    this.noDrawOdds,
    this.over15Odds,
    this.over25Odds,
    this.over35Odds,
    this.under45Odds,
    this.bttsYesOdds,
    this.homeOrDrawOver15Odds,
    this.awayOrDrawOver15Odds,
  });

  double? oddsForMarket(
    AiMarketKey marketKey,
  ) {
    return switch (marketKey) {
      AiMarketKey.homeWin =>
        homeWinOdds,
      AiMarketKey.draw =>
        drawOdds,
      AiMarketKey.awayWin =>
        awayWinOdds,
      AiMarketKey.homeOrDraw =>
        homeOrDrawOdds,
      AiMarketKey.awayOrDraw =>
        awayOrDrawOdds,
      AiMarketKey.noDraw =>
        noDrawOdds,
      AiMarketKey.over15 =>
        over15Odds,
      AiMarketKey.over25 =>
        over25Odds,
      AiMarketKey.over35 =>
        over35Odds,
      AiMarketKey.under45 =>
        under45Odds,
      AiMarketKey.btts =>
        bttsYesOdds,
      AiMarketKey.homeOrDrawOver15 =>
        homeOrDrawOver15Odds,
      AiMarketKey.awayOrDrawOver15 =>
        awayOrDrawOver15Odds,
    };
  }
}

class AiMatchAnalysis {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String league;

  final int aiScore;
  final int dataReliability;

  final AiRiskLevel riskLevel;

  final AiRecommendation recommendation;

  final AiMarketProbabilities probabilities;

  final double expectedHomeGoals;
  final double expectedAwayGoals;
  final double expectedTotalGoals;

  final AiTeamMetrics homeMetrics;
  final AiTeamMetrics awayMetrics;

  final List<String> strengths;
  final List<String> warnings;
  final List<String> explanation;

  final AiValueBetResult? valueBet;

  final DateTime generatedAt;

  const AiMatchAnalysis({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.aiScore,
    required this.dataReliability,
    required this.riskLevel,
    required this.recommendation,
    required this.probabilities,
    required this.expectedHomeGoals,
    required this.expectedAwayGoals,
    required this.expectedTotalGoals,
    required this.homeMetrics,
    required this.awayMetrics,
    required this.strengths,
    required this.warnings,
    required this.explanation,
    required this.valueBet,
    required this.generatedAt,
  });

  String get confidenceLabel {
    if (aiScore >= 88) {
      return 'Kiemelt AI tipp';
    }

    if (aiScore >= 82) {
      return 'Nagyon erős tipp';
    }

    if (aiScore >= 75) {
      return 'Erős tipp';
    }

    if (aiScore >= 67) {
      return 'Jó tipp';
    }

    if (aiScore >= 58) {
      return 'Közepes tipp';
    }

    return 'Óvatos tipp';
  }

  String get riskLabel {
    return switch (riskLevel) {
      AiRiskLevel.low =>
        'Alacsonyabb kockázat',
      AiRiskLevel.medium =>
        'Közepes kockázat',
      AiRiskLevel.high =>
        'Magasabb kockázat',
    };
  }

  bool get hasValueBet {
    return valueBet?.isValueBet == true;
  }
}

class AiRecommendation {
  final AiMarketKey marketKey;
  final String marketName;
  final String selection;
  final double probability;
  final String reason;

  const AiRecommendation({
    required this.marketKey,
    required this.marketName,
    required this.selection,
    required this.probability,
    required this.reason,
  });
}

class AiMarketProbabilities {
  final double homeWin;
  final double draw;
  final double awayWin;

  final double homeOrDraw;
  final double awayOrDraw;
  final double noDraw;

  final double over15;
  final double over25;
  final double over35;
  final double under45;

  final double btts;

  final double homeOrDrawOver15;
  final double awayOrDrawOver15;

  const AiMarketProbabilities({
    required this.homeWin,
    required this.draw,
    required this.awayWin,
    required this.homeOrDraw,
    required this.awayOrDraw,
    required this.noDraw,
    required this.over15,
    required this.over25,
    required this.over35,
    required this.under45,
    required this.btts,
    required this.homeOrDrawOver15,
    required this.awayOrDrawOver15,
  });

  double probabilityForMarket(
    AiMarketKey key,
  ) {
    return switch (key) {
      AiMarketKey.homeWin =>
        homeWin,
      AiMarketKey.draw =>
        draw,
      AiMarketKey.awayWin =>
        awayWin,
      AiMarketKey.homeOrDraw =>
        homeOrDraw,
      AiMarketKey.awayOrDraw =>
        awayOrDraw,
      AiMarketKey.noDraw =>
        noDraw,
      AiMarketKey.over15 =>
        over15,
      AiMarketKey.over25 =>
        over25,
      AiMarketKey.over35 =>
        over35,
      AiMarketKey.under45 =>
        under45,
      AiMarketKey.btts =>
        btts,
      AiMarketKey.homeOrDrawOver15 =>
        homeOrDrawOver15,
      AiMarketKey.awayOrDrawOver15 =>
        awayOrDrawOver15,
    };
  }
}

class AiTeamMetrics {
  final double overallFormScore;
  final double venueFormScore;
  final double attackingScore;
  final double defensiveScore;
  final double totalStrength;

  final double goalsScoredAverage;
  final double goalsConcededAverage;

  const AiTeamMetrics({
    required this.overallFormScore,
    required this.venueFormScore,
    required this.attackingScore,
    required this.defensiveScore,
    required this.totalStrength,
    required this.goalsScoredAverage,
    required this.goalsConcededAverage,
  });
}

class AiValueBetResult {
  final double probability;
  final double realOdds;
  final double fairOdds;

  final double expectedValuePercent;
  final double edgePercent;

  final bool isValueBet;
  final AiValueLevel level;

  const AiValueBetResult({
    required this.probability,
    required this.realOdds,
    required this.fairOdds,
    required this.expectedValuePercent,
    required this.edgePercent,
    required this.isValueBet,
    required this.level,
  });

  String get label {
    return switch (level) {
      AiValueLevel.strong =>
        'Erős Value Bet',
      AiValueLevel.good =>
        'Jó Value Bet',
      AiValueLevel.small =>
        'Kisebb Value Bet',
      AiValueLevel.neutral =>
        'Semleges érték',
      AiValueLevel.negative =>
        'Nem Value Bet',
    };
  }
}

enum AiMatchResult {
  win,
  draw,
  loss,
}

enum AiRiskLevel {
  low,
  medium,
  high,
}

enum AiValueLevel {
  strong,
  good,
  small,
  neutral,
  negative,
}

enum AiMarketKey {
  homeWin,
  draw,
  awayWin,

  homeOrDraw,
  awayOrDraw,
  noDraw,

  over15,
  over25,
  over35,
  under45,

  btts,

  homeOrDrawOver15,
  awayOrDrawOver15,
}
