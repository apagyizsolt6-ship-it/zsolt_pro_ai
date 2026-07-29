// ============================================================================
// Zsolt Pro AI Engine v2.10 - On-Demand Monte Carlo Edition
// File: lib/services/ai_engine_v2_service.dart
// ============================================================================

import 'dart:math' as math;
import '../models/app_match.dart';

enum AiMatchResult { win, draw, loss }

class AiMatchStatistics {
  final List<AiMatchResult> homeForm;
  final List<AiMatchResult> awayForm;
  final List<AiMatchResult> homeVenueForm;
  final List<AiMatchResult> awayVenueForm;

  final int h2hHomeWins;
  final int h2hDraws;
  final int h2hAwayWins;
  final double h2hAverageGoals;
  final double h2hBttsPercent;
  final double h2hOver25Percent;
  final int h2hTotalMatches;

  final double leagueAverageGoals;
  final double over15Percent;
  final double over25Percent;
  final double over35Percent;
  final double bttsPercent;

  final double homeGoalsScoredAverage;
  final double homeGoalsConcededAverage;
  final double awayGoalsScoredAverage;
  final double awayGoalsConcededAverage;

  final double homeCleanSheetPercent;
  final double awayCleanSheetPercent;
  final double homeFailedToScorePercent;
  final double awayFailedToScorePercent;

  final double homeCornersAverage;
  final double awayCornersAverage;
  final double homeYellowCardsAverage;
  final double awayYellowCardsAverage;
  final double homeOffsidesAverage;
  final double awayOffsidesAverage;
  final double homeFoulsAverage;
  final double awayFoulsAverage;

  final int homeSampleSize;
  final int awaySampleSize;

  final double leagueStrength;
  final double dataQualityBonus;
  final double homeAdvantage;

  const AiMatchStatistics({
    required this.homeForm,
    required this.awayForm,
    required this.homeVenueForm,
    required this.awayVenueForm,
    required this.h2hHomeWins,
    required this.h2hDraws,
    required this.h2hAwayWins,
    required this.h2hAverageGoals,
    required this.h2hBttsPercent,
    required this.h2hOver25Percent,
    this.h2hTotalMatches = 5,
    required this.leagueAverageGoals,
    required this.over15Percent,
    required this.over25Percent,
    required this.over35Percent,
    required this.bttsPercent,
    required this.homeGoalsScoredAverage,
    required this.homeGoalsConcededAverage,
    required this.awayGoalsScoredAverage,
    required this.awayGoalsConcededAverage,
    required this.homeCleanSheetPercent,
    required this.awayCleanSheetPercent,
    required this.homeFailedToScorePercent,
    required this.awayFailedToScorePercent,
    this.homeCornersAverage = 5.2,
    this.awayCornersAverage = 4.5,
    this.homeYellowCardsAverage = 2.1,
    this.awayYellowCardsAverage = 2.3,
    this.homeOffsidesAverage = 1.8,
    this.awayOffsidesAverage = 1.6,
    this.homeFoulsAverage = 11.5,
    this.awayFoulsAverage = 12.0,
    required this.homeSampleSize,
    required this.awaySampleSize,
    required this.leagueStrength,
    required this.dataQualityBonus,
    this.homeAdvantage = 1.12,
  });

  int get totalSampleSize => homeSampleSize + awaySampleSize;

  factory AiMatchStatistics.fallback({double leagueStrength = 65.0}) {
    return AiMatchStatistics(
      homeForm: const [],
      awayForm: const [],
      homeVenueForm: const [],
      awayVenueForm: const [],
      h2hHomeWins: 3,
      h2hDraws: 2,
      h2hAwayWins: 1,
      h2hAverageGoals: 2.70,
      h2hBttsPercent: 60.0,
      h2hOver25Percent: 55.0,
      h2hTotalMatches: 6,
      leagueAverageGoals: 2.60,
      over15Percent: 78.0,
      over25Percent: 54.0,
      over35Percent: 30.0,
      bttsPercent: 55.0,
      homeGoalsScoredAverage: 1.75,
      homeGoalsConcededAverage: 1.10,
      awayGoalsScoredAverage: 1.15,
      awayGoalsConcededAverage: 1.55,
      homeCleanSheetPercent: 38.0,
      awayCleanSheetPercent: 22.0,
      homeFailedToScorePercent: 15.0,
      awayFailedToScorePercent: 32.0,
      homeCornersAverage: 5.4,
      awayCornersAverage: 4.6,
      homeYellowCardsAverage: 2.2,
      awayYellowCardsAverage: 2.4,
      homeOffsidesAverage: 1.9,
      awayOffsidesAverage: 1.7,
      homeFoulsAverage: 11.8,
      awayFoulsAverage: 12.2,
      homeSampleSize: 10,
      awaySampleSize: 10,
      leagueStrength: leagueStrength,
      dataQualityBonus: 6.0,
      homeAdvantage: 1.12,
    );
  }
}

class AiOddsData {
  final double? homeWinOdds;
  final double? drawOdds;
  final double? awayWinOdds;
  final double? over15Odds;
  final double? over25Odds;
  final double? over35Odds;
  final double? bttsYesOdds;
  final double? homeOrDrawOdds;
  final double? awayOrDrawOdds;
  final double? over95CornersOdds;
  final double? over35CardsOdds;

  const AiOddsData({
    this.homeWinOdds,
    this.drawOdds,
    this.awayWinOdds,
    this.over15Odds,
    this.over25Odds,
    this.over35Odds,
    this.bttsYesOdds,
    this.homeOrDrawOdds,
    this.awayOrDrawOdds,
    this.over95CornersOdds,
    this.over35CardsOdds,
  });
}

class AiRecommendation {
  final String marketName;
  final String selection;
  final double probability;
  final double fairOdds;

  const AiRecommendation({
    required this.marketName,
    required this.selection,
    required this.probability,
    required this.fairOdds,
  });
}

class MonteCarloSimulationResult {
  final int totalSimulations;
  final int homeWins;
  final int draws;
  final int awayWins;
  final Map<String, int> mostCommonScores;
  final double averageTotalGoals;
  final double averageTotalCorners;
  final double averageTotalCards;
  final double averageTotalOffsides;
  final double averageTotalFouls;

  const MonteCarloSimulationResult({
    required this.totalSimulations,
    required this.homeWins,
    required this.draws,
    required this.awayWins,
    required this.mostCommonScores,
    required this.averageTotalGoals,
    required this.averageTotalCorners,
    required this.averageTotalCards,
    required this.averageTotalOffsides,
    required this.averageTotalFouls,
  });

  double get homeWinPercent => (homeWins / totalSimulations) * 100.0;
  double get drawPercent => (draws / totalSimulations) * 100.0;
  double get awayWinPercent => (awayWins / totalSimulations) * 100.0;
}

class AiMatchAnalysis {
  final int aiScore;
  final int dataReliability;
  final AiRecommendation recommendation;
  final double homeXG;
  final double awayXG;
  final bool hasValueBet;
  final MonteCarloSimulationResult? monteCarloResult;

  const AiMatchAnalysis({
    required this.aiScore,
    required this.dataReliability,
    required this.recommendation,
    required this.homeXG,
    required this.awayXG,
    required this.hasValueBet,
    this.monteCarloResult,
  });
}

class AiEngineV2Service {
  AiEngineV2Service._();
  static final AiEngineV2Service instance = AiEngineV2Service._();

  final Set<String> _recentlyUsedSelections = {};

  AiMatchAnalysis analyzeMatch({
    required AppMatch match,
    required AiMatchStatistics statistics,
    AiOddsData? oddsData,
    bool diversify = false,
    bool runSimulation = false,
  }) {
    final double leagueAvg = statistics.leagueAverageGoals > 0 ? statistics.leagueAverageGoals / 2.0 : 1.30;

    double homeAttack = (statistics.homeGoalsScoredAverage / leagueAvg).clamp(0.4, 2.5);
    double homeDefense = (statistics.homeGoalsConcededAverage / leagueAvg).clamp(0.4, 2.5);
    double awayAttack = (statistics.awayGoalsScoredAverage / leagueAvg).clamp(0.4, 2.5);
    double awayDefense = (statistics.awayGoalsConcededAverage / leagueAvg).clamp(0.4, 2.5);

    final double homeFormWeight = _calculateWeightedForm(statistics.homeForm);
    final double awayFormWeight = _calculateWeightedForm(statistics.awayForm);
    final double formRatio = (homeFormWeight - awayFormWeight) / 100.0;

    if (formRatio > 0) {
      homeAttack *= (1.0 + formRatio * 0.10);
      awayDefense *= (1.0 + formRatio * 0.05);
    } else {
      awayAttack *= (1.0 - formRatio * 0.10);
      homeDefense *= (1.0 - formRatio * 0.05);
    }

    final double homeAdv = statistics.homeAdvantage > 0 ? statistics.homeAdvantage : 1.12;
    final double homeXG = (homeAttack * awayDefense * leagueAvg * homeAdv).clamp(0.2, 4.5);
    final double awayXG = (awayAttack * homeDefense * leagueAvg).clamp(0.2, 4.5);

    MonteCarloSimulationResult? mcResult;
    double pHomePct = 0;
    double pAwayPct = 0;
    double pDrawPct = 0;

    final Map<String, double> poissonProbs = _calculatePoissonProbabilities(homeXG, awayXG);
    pHomePct = poissonProbs['homeWin']! * 100.0;
    pDrawPct = poissonProbs['draw']! * 100.0;
    pAwayPct = poissonProbs['awayWin']! * 100.0;

    if (runSimulation) {
      mcResult = _runAdvancedMonteCarloSimulation(
        homeLambda: homeXG,
        awayLambda: awayXG,
        homeCorners: statistics.homeCornersAverage,
        awayCorners: statistics.awayCornersAverage,
        homeCards: statistics.homeYellowCardsAverage,
        awayCards: statistics.awayYellowCardsAverage,
        homeOffsides: statistics.homeOffsidesAverage,
        awayOffsides: statistics.awayOffsidesAverage,
        homeFouls: statistics.homeFoulsAverage,
        awayFouls: statistics.awayFoulsAverage,
        iterations: 10000,
      );
      pHomePct = mcResult.homeWinPercent;
      pDrawPct = mcResult.drawPercent;
      pAwayPct = mcResult.awayWinPercent;
    }

    final double pOver15 = poissonProbs['over15']! * 100.0;
    final double pOver25 = poissonProbs['over25']! * 100.0;
    final double pBtts = poissonProbs['btts']! * 100.0;
    final double p1X = (pHomePct + pDrawPct).clamp(0.0, 100.0);
    final double pX2 = (pAwayPct + pDrawPct).clamp(0.0, 100.0);

    final double pOver95Corners = (statistics.homeCornersAverage + statistics.awayCornersAverage > 9.5 ? 58.0 : 45.0);
    final double pOver35Cards = (statistics.homeYellowCardsAverage + statistics.awayYellowCardsAverage > 3.5 ? 62.0 : 42.0);

    final List<AiRecommendation> candidates = [
      AiRecommendation(marketName: '1X2', selection: 'Hazai győzelem (1)', probability: pHomePct, fairOdds: 100.0 / (pHomePct > 0 ? pHomePct : 1)),
      AiRecommendation(marketName: '1X2', selection: 'Vendég győzelem (2)', probability: pAwayPct, fairOdds: 100.0 / (pAwayPct > 0 ? pAwayPct : 1)),
      AiRecommendation(marketName: 'Gólok száma', selection: '1.5 gól felett', probability: pOver15, fairOdds: 100.0 / (pOver15 > 0 ? pOver15 : 1)),
      AiRecommendation(marketName: 'Gólok száma', selection: '2.5 gól felett', probability: pOver25, fairOdds: 100.0 / (pOver25 > 0 ? pOver25 : 1)),
      AiRecommendation(marketName: 'Mindkét csapat', selection: 'Igen (BTTS)', probability: pBtts, fairOdds: 100.0 / (pBtts > 0 ? pBtts : 1)),
      AiRecommendation(marketName: 'Szögletek', selection: '9.5 szöglet felett', probability: pOver95Corners, fairOdds: 100.0 / pOver95Corners),
      AiRecommendation(marketName: 'Sárga lapok', selection: '3.5 sárga lap felett', probability: pOver35Cards, fairOdds: 100.0 / pOver35Cards),
      AiRecommendation(marketName: 'Dupla esély', selection: 'Hazai vagy Döntetlen (1X)', probability: p1X, fairOdds: 100.0 / (p1X > 0 ? p1X : 1)),
      AiRecommendation(marketName: 'Dupla esély', selection: 'Vendég vagy Döntetlen (X2)', probability: pX2, fairOdds: 100.0 / (pX2 > 0 ? pX2 : 1)),
    ];

    candidates.sort((a, b) => b.probability.compareTo(a.probability));

    AiRecommendation bestRecommendation = candidates.first;
    if (diversify) {
      for (final candidate in candidates) {
        if (!_recentlyUsedSelections.contains(candidate.selection)) {
          bestRecommendation = candidate;
          break;
        }
      }
      _recentlyUsedSelections.add(bestRecommendation.selection);
      if (_recentlyUsedSelections.length >= 6) {
        _recentlyUsedSelections.clear();
      }
    }

    final int matchSalt = (match.id.hashCode.abs() % 9) - 4;
    final double rawProbability = bestRecommendation.probability;
    final double xgVariance = (homeXG - awayXG).abs() * 2.0;

    final int finalAiScore = (rawProbability * 0.45 + xgVariance * 5.0 + 40.0 + matchSalt).round().clamp(75, 95);
    final int reliability = ((statistics.homeSampleSize + statistics.awaySampleSize) * 3.5 + statistics.leagueStrength * 0.3).round().clamp(70, 95);

    bool isValueBetDetected = false;
    if (oddsData != null) {
      isValueBetDetected = _checkForValue(bestRecommendation, oddsData);
    }

    return AiMatchAnalysis(
      aiScore: finalAiScore,
      dataReliability: reliability,
      recommendation: bestRecommendation,
      homeXG: double.parse(homeXG.toStringAsFixed(2)),
      awayXG: double.parse(awayXG.toStringAsFixed(2)),
      hasValueBet: isValueBetDetected,
      monteCarloResult: mcResult,
    );
  }

  AiMatchAnalysis analyzeWithFallbackData({
    required AppMatch match,
    AiOddsData? oddsData,
    bool diversify = false,
    bool runSimulation = false,
  }) {
    final int hashSeed = match.id.hashCode.abs() % 20;
    final double dynamicStrength = 62.0 + (hashSeed.toDouble());

    return analyzeMatch(
      match: match,
      statistics: AiMatchStatistics.fallback(leagueStrength: dynamicStrength),
      oddsData: oddsData,
      diversify: diversify,
      runSimulation: runSimulation,
    );
  }

  MonteCarloSimulationResult _runAdvancedMonteCarloSimulation({
    required double homeLambda,
    required double awayLambda,
    required double homeCorners,
    required double awayCorners,
    required double homeCards,
    required double awayCards,
    required double homeOffsides,
    required double awayOffsides,
    required double homeFouls,
    required double awayFouls,
    int iterations = 10000,
  }) {
    int homeWins = 0;
    int draws = 0;
    int awayWins = 0;
    double totalGoalsSum = 0;
    double totalCornersSum = 0;
    double totalCardsSum = 0;
    double totalOffsidesSum = 0;
    double totalFoulsSum = 0;

    final Map<String, int> scoreCounts = {};
    final math.Random rng = math.Random();

    for (int i = 0; i < iterations; i++) {
      final int homeGoals = _poissonRandom(homeLambda, rng);
      final int awayGoals = _poissonRandom(awayLambda, rng);

      final double corners = _poissonRandom((homeCorners + awayCorners), rng).toDouble();
      final double cards = _poissonRandom((homeCards + awayCards), rng).toDouble();
      final double offsides = _poissonRandom((homeOffsides + awayOffsides), rng).toDouble();
      final double fouls = _poissonRandom((homeFouls + awayFouls), rng).toDouble();

      totalGoalsSum += (homeGoals + awayGoals);
      totalCornersSum += corners;
      totalCardsSum += cards;
      totalOffsidesSum += offsides;
      totalFoulsSum += fouls;

      if (homeGoals > awayGoals) {
        homeWins++;
      } else if (homeGoals == awayGoals) {
        draws++;
      } else {
        awayWins++;
      }

      final String scoreKey = '$homeGoals-$awayGoals';
      scoreCounts[scoreKey] = (scoreCounts[scoreKey] ?? 0) + 1;
    }

    final sortedScores = scoreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<String, int> topScores = {};
    for (int i = 0; i < math.min(3, sortedScores.length); i++) {
      topScores[sortedScores[i].key] = sortedScores[i].value;
    }

    return MonteCarloSimulationResult(
      totalSimulations: iterations,
      homeWins: homeWins,
      draws: draws,
      awayWins: awayWins,
      mostCommonScores: topScores,
      averageTotalGoals: totalGoalsSum / iterations,
      averageTotalCorners: totalCornersSum / iterations,
      averageTotalCards: totalCardsSum / iterations,
      averageTotalOffsides: totalOffsidesSum / iterations,
      averageTotalFouls: totalFoulsSum / iterations,
    );
  }

  int _poissonRandom(double lambda, math.Random rng) {
    double L = math.exp(-lambda);
    double p = 1.0;
    int k = 0;
    do {
      k++;
      p *= rng.nextDouble();
    } while (p > L);
    return k - 1;
  }

  double _calculateWeightedForm(List<AiMatchResult> form) {
    if (form.isEmpty) return 50.0;
    double totalPoints = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < form.length; i++) {
      final double weight = math.pow(1.3, form.length - 1 - i).toDouble();
      double pts = 0.0;
      if (form[i] == AiMatchResult.win) pts = 3.0;
      if (form[i] == AiMatchResult.draw) pts = 1.0;

      totalPoints += pts * weight;
      totalWeight += 3.0 * weight;
    }

    return (totalPoints / totalWeight) * 100.0;
  }

  Map<String, double> _calculatePoissonProbabilities(double homeXG, double awayXG) {
    double homeWin = 0.0;
    double draw = 0.0;
    double awayWin = 0.0;
    double over15 = 0.0;
    double over25 = 0.0;
    double btts = 0.0;

    for (int h = 0; h <= 6; h++) {
      for (int a = 0; a <= 6; a++) {
        final double pHomeG = _poissonExact(h, homeXG);
        final double pAwayG = _poissonExact(a, awayXG);
        final double cellProb = pHomeG * pAwayG;

        if (h > a) homeWin += cellProb;
        if (h == a) draw += cellProb;
        if (h < a) awayWin += cellProb;

        final int totalG = h + a;
        if (totalG > 1) over15 += cellProb;
        if (totalG > 2) over25 += cellProb;
        if (h > 0 && a > 0) btts += cellProb;
      }
    }

    return {
      'homeWin': homeWin,
      'draw': draw,
      'awayWin': awayWin,
      'over15': over15,
      'over25': over25,
      'btts': btts,
    };
  }

  double _poissonExact(int k, double lambda) {
    return (math.pow(lambda, k) * math.exp(-lambda)) / _factorial(k);
  }

  double _factorial(int n) {
    if (n <= 1) return 1.0;
    double result = 1.0;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  bool _checkForValue(AiRecommendation rec, AiOddsData odds) {
    double? marketOdds;
    if (rec.selection.contains('Hazai győzelem')) marketOdds = odds.homeWinOdds;
    if (rec.selection.contains('Vendég győzelem')) marketOdds = odds.awayWinOdds;
    if (rec.selection.contains('2.5 gól felett')) marketOdds = odds.over25Odds;
    if (rec.selection.contains('1.5 gól felett')) marketOdds = odds.over15Odds;
    if (rec.selection.contains('Igen (BTTS)')) marketOdds = odds.bttsYesOdds;
    if (rec.selection.contains('9.5 szöglet')) marketOdds = odds.over95CornersOdds;
    if (rec.selection.contains('3.5 sárga lap')) marketOdds = odds.over35CardsOdds;

    if (marketOdds == null || marketOdds == 0) return false;
    return marketOdds > rec.fairOdds;
  }
}
