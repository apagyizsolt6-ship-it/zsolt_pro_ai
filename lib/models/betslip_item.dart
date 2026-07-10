// ===========================================
// Zsolt Pro AI
// Version: v0.6.0
// File: lib/models/betslip_item.dart
// ===========================================

import 'app_match.dart';

class BetslipItem {
  final AppMatch match;
  final String market;
  final String selection;
  final double odds;

  const BetslipItem({
    required this.match,
    required this.market,
    required this.selection,
    this.odds = 0.0,
  });

  String get id => match.id;

  BetslipItem copyWith({
    AppMatch? match,
    String? market,
    String? selection,
    double? odds,
  }) {
    return BetslipItem(
      match: match ?? this.match,
      market: market ?? this.market,
      selection: selection ?? this.selection,
      odds: odds ?? this.odds,
    );
  }
}
