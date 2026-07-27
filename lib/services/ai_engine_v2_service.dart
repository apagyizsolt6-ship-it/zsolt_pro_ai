// ============================================================================
// Zsolt Pro AI Engine v2.0 - Professional Quant Edition - PART 1
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
    required this.homeSampleSize,
    required this.awaySampleSize,
    required this.leagueStrength,
    required this.dataQualityBonus,
    this.homeAdvantage = 1.12,
  });

  int get totalSampleSize => homeSampleSize + awaySampleSize;
  int get h2hTotalMatches => h2hHomeWins + h2hDraws + h2hAwayWins;

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
  final double? under45Odds;
  final double? bttsYesOdds;
  final double? homeOrDrawOdds;
  final double? awayOrDrawOdds;

  const AiOddsData({
    this.homeWinOdds,
    this.drawOdds,
    this.awayWinOdds,
    this.over15Odds,
    this.over25Odds,
    this.over35Odds,
    this.under45Odds,
    this.bttsYesOdds,
    this.homeOrDrawOdds,
    this.awayOrDrawOdds,
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

class AiMatchAnalysis {
  final int aiScore;
  final int dataReliability;
  final AiRecommendation recommendation;
  final double homeXG;
  final double awayXG;
  final bool hasValueBet;

  const AiMatchAnalysis({
    required this.aiScore,
    required this.dataReliability,
    required this.recommendation,
    required this.homeXG,
    required this.awayXG,
    required this.hasValueBet,
  });
}
// ============================================================================
// Zsolt Pro AI Engine v2.0 - Professional Quant Edition - PART 2 (Engine)
// ============================================================================

class AiEngineV2Service {
  AiEngineV2Service._();
  static final AiEngineV2Service instance = AiEngineV2Service._();

  AiMatchAnalysis analyzeMatch({
    required AppMatch match,
    required AiMatchStatistics statistics,
    AiOddsData? oddsData,
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

    final Map<String, double> probabilities = _calculatePoissonProbabilities(homeXG, awayXG);

    final double pHomePct = probabilities['homeWin']! * 100.0;
    final double pAwayPct = probabilities['awayWin']! * 100.0;
    

    final double pOver15 = probabilities['over15']! * 100.0;
    final double pOver25 = probabilities['over25']! * 100.0;
    
    final double pBtts = probabilities['btts']! * 100.0;

    final double p1X = (probabilities['homeWin']! + probabilities['draw']!).clamp(0.0, 1.0) * 100.0;
    final double pX2 = (probabilities['awayWin']! + probabilities['draw']!).clamp(0.0, 1.0) * 100.0;

    final List<AiRecommendation> candidates = [
      AiRecommendation(marketName: '1X2', selection: 'Hazai (1)', probability: pHomePct, fairOdds: 100.0 / (pHomePct > 0 ? pHomePct : 1)),
      AiRecommendation(marketName: '1X2', selection: 'Vendég (2)', probability: pAwayPct, fairOdds: 100.0 / (pAwayPct > 0 ? pAwayPct : 1)),
      AiRecommendation(marketName: 'Gólok', selection: '1.5 gól felett', probability: pOver15, fairOdds: 100.0 / (pOver15 > 0 ? pOver15 : 1)),
      AiRecommendation(marketName: 'Gólok', selection: '2.5 gól felett', probability: pOver25, fairOdds: 100.0 / (pOver25 > 0 ? pOver25 : 1)),
      AiRecommendation(marketName: 'Mindkét csapat szerez gólt', selection: 'Igen (BTTS)', probability: pBtts, fairOdds: 100.0 / (pBtts > 0 ? pBtts : 1)),
      AiRecommendation(marketName: 'Dupla esély', selection: 'Hazai vagy Döntetlen (1X)', probability: p1X, fairOdds: 100.0 / (p1X > 0 ? p1X : 1)),
      AiRecommendation(marketName: 'Dupla esély', selection: 'Vendég vagy Döntetlen (X2)', probability: pX2, fairOdds: 100.0 / (pX2 > 0 ? pX2 : 1)),
    ];

    final List<AiRecommendation> validCandidates = candidates.where((c) => c.probability >= 58.0 && c.fairOdds <= 3.20).toList();
    validCandidates.sort((a, b) => b.probability.compareTo(a.probability));

    final AiRecommendation bestRecommendation = validCandidates.isNotEmpty ? validCandidates.first : candidates.first;

    final double confidenceBonus = (statistics.homeSampleSize + statistics.awaySampleSize) * 0.4;
    final double leagueBonus = statistics.leagueStrength * 0.1;
    final int finalAiScore = (bestRecommendation.probability * 0.75 + confidenceBonus + leagueBonus).round().clamp(72, 97);

    final int reliability = ((statistics.homeSampleSize + statistics.awaySampleSize) * 4.0 + statistics.leagueStrength * 0.25).round().clamp(65, 96);

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
    );
  }

  AiMatchAnalysis analyzeWithFallbackData({
    required AppMatch match,
    AiOddsData? oddsData,
  }) {
    return analyzeMatch(
      match: match,
      statistics: AiMatchStatistics.fallback(),
      oddsData: oddsData,
    );
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
    double under35 = 0.0;
    double btts = 0.0;

    for (int h = 0; h <= 6; h++) {
      for (int a = 0; a <= 6; a++) {
        final double pHomeG = _poisson(h, homeXG);
        final double pAwayG = _poisson(a, awayXG);
        final double cellProb = pHomeG * pAwayG;

        if (h > a) homeWin += cellProb;
        if (h == a) draw += cellProb;
        if (h < a) awayWin += cellProb;

        final int totalG = h + a;
        if (totalG > 1) over15 += cellProb;
        if (totalG > 2) over25 += cellProb;
        if (totalG < 4) under35 += cellProb;
        if (h > 0 && a > 0) btts += cellProb;
      }
    }

    return {
      'homeWin': homeWin,
      'draw': draw,
      'awayWin': awayWin,
      'over15': over15,
      'over25': over25,
      'under35': under35,
      'btts': btts,
    };
  }

  double _poisson(int k, double lambda) {
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
    if (rec.selection.contains('Hazai (1)')) marketOdds = odds.homeWinOdds;
    if (rec.selection.contains('Vendég (2)')) marketOdds = odds.awayWinOdds;
    if (rec.selection.contains('2.5 gól felett')) marketOdds = odds.over25Odds;
    if (rec.selection.contains('1.5 gól felett')) marketOdds = odds.over15Odds;
    if (rec.selection.contains('Igen (BTTS)')) marketOdds = odds.bttsYesOdds;
    if (rec.selection.contains('1X')) marketOdds = odds.homeOrDrawOdds;
    if (rec.selection.contains('X2')) marketOdds = odds.awayOrDrawOdds;

    if (marketOdds == null || marketOdds == 0) return false;
    return marketOdds > rec.fairOdds;
  }
}
