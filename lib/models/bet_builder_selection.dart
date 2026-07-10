// ===========================================
// Zsolt Pro AI
// Version: v0.8.0
// File: lib/models/bet_builder_selection.dart
// ===========================================

class BetBuilderSelection {
  final String market;
  final String selection;
  final double odds;
  final int aiScore;

  const BetBuilderSelection({
    required this.market,
    required this.selection,
    this.odds = 0.0,
    this.aiScore = 0,
  });

  BetBuilderSelection copyWith({
    String? market,
    String? selection,
    double? odds,
    int? aiScore,
  }) {
    return BetBuilderSelection(
      market: market ?? this.market,
      selection: selection ?? this.selection,
      odds: odds ?? this.odds,
      aiScore: aiScore ?? this.aiScore,
    );
  }
}
