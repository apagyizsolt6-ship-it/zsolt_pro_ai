/*
===========================================
MeccsIQ Pro
AI Engine V3
Build: #016.1
File: ai_analysis.dart
===========================================
*/

import 'ai_probability.dart';
import 'ai_recommendation.dart';
import 'ai_score.dart';
import 'ai_value_bet.dart';

class AiAnalysis {
  final AiScore score;

  final List<AiRecommendation> recommendations;

  final List<AiProbability> probabilities;

  final List<AiValueBet> valueBets;

  final double expectedHomeGoals;
  final double expectedAwayGoals;

  final DateTime createdAt;

  const AiAnalysis({
    required this.score,
    required this.recommendations,
    required this.probabilities,
    required this.valueBets,
    required this.expectedHomeGoals,
    required this.expectedAwayGoals,
    required this.createdAt,
  });

  bool get hasValueBet => valueBets.isNotEmpty;

  bool get hasRecommendation => recommendations.isNotEmpty;

  double get totalExpectedGoals =>
      expectedHomeGoals + expectedAwayGoals;
}
