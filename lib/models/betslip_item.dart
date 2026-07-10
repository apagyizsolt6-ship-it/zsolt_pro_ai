// ===========================================
// Zsolt Pro AI
// Version: v0.8.1
// File: lib/models/betslip_item.dart
// ===========================================

import 'app_match.dart';
import 'bet_builder_selection.dart';

class BetslipItem {
  final AppMatch match;

  // Egyetlen hagyományos tipphez
  final String market;
  final String selection;

  // Fogadáskészítőhöz: több tipp ugyanazon a meccsen
  final List<BetBuilderSelection> builderSelections;

  final double odds;

  const BetslipItem({
    required this.match,
    required this.market,
    required this.selection,
    this.builderSelections = const <BetBuilderSelection>[],
    this.odds = 0.0,
  });

  String get id => match.id;

  bool get isBetBuilder => builderSelections.isNotEmpty;

  int get selectionCount {
    if (isBetBuilder) {
      return builderSelections.length;
    }

    return selection.trim().isEmpty ? 0 : 1;
  }

  String get displayMarket {
    if (isBetBuilder) {
      return 'Fogadáskészítő';
    }

    return market;
  }

  String get displaySelection {
    if (isBetBuilder) {
      return '${builderSelections.length} kiválasztott tipp';
    }

    return selection;
  }

  int get builderAiScore {
    if (builderSelections.isEmpty) {
      return match.aiScore;
    }

    final int total = builderSelections.fold<int>(
      0,
      (sum, item) => sum + item.aiScore,
    );

    return (total / builderSelections.length).round();
  }

  double get builderOdds {
    if (builderSelections.isEmpty) {
      return odds;
    }

    final List<double> validOdds = builderSelections
        .map(
          (item) => item.odds,
        )
        .where(
          (value) => value > 0,
        )
        .toList();

    if (validOdds.isEmpty) {
      return 0.0;
    }

    return validOdds.fold<double>(
      1.0,
      (total, value) => total * value,
    );
  }

  BetslipItem copyWith({
    AppMatch? match,
    String? market,
    String? selection,
    List<BetBuilderSelection>? builderSelections,
    double? odds,
  }) {
    return BetslipItem(
      match: match ?? this.match,
      market: market ?? this.market,
      selection: selection ?? this.selection,
      builderSelections:
          builderSelections ?? this.builderSelections,
      odds: odds ?? this.odds,
    );
  }
}
