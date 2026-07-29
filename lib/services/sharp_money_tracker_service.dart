// ============================================================================
// Zsolt Pro AI - Sharp Money Tracker & Arbitrage Engine
// File: lib/services/sharp_money_tracker_service.dart
// ============================================================================

class SharpMoneySignal {
  final bool hasSharpMovement;
  final String description;
  final double oddsDropPercent;
  final bool isArbitrageOpportunity;
  final double arbitrageProfitPercent;

  const SharpMoneySignal({
    required this.hasSharpMovement,
    required this.description,
    required this.oddsDropPercent,
    required this.isArbitrageOpportunity,
    required this.arbitrageProfitPercent,
  });
}

class SharpMoneyTrackerService {
  SharpMoneyTrackerService._();
  static final SharpMoneyTrackerService instance = SharpMoneyTrackerService._();

  /// Elemzi a piaci oddsokat és a bookmaker mozgásokat Sharp Money / Arbitrázs szempontból.
  SharpMoneySignal analyzeMarketFlow({
    required double openingOdds,
    required double currentOdds,
    required double bestBookmakerOdds,
    required double aiFairOdds,
  }) {
    // 1. Odds esés számítása (Sharp Money jelzés, ha a pro játékosok megütötték a piacot)
    double oddsDrop = 0.0;
    if (openingOdds > currentOdds) {
      oddsDrop = ((openingOdds - currentOdds) / openingOdds) * 100.0;
    }

    bool sharpMovement = oddsDrop >= 5.0; // Ha 5%-nál többet esett az odds hirtelen
    String desc = 'Stabil piaci mozgás';

    if (sharpMovement) {
      desc = 'Sharp Money észlelem! A piac hirtelen lefele nyomta az oddsot (${oddsDrop.toStringAsFixed(1)}%).';
    } else if (currentOdds < aiFairOdds * 0.95) {
      desc = 'A piac alulárazza a kimenetelt az AI becsléséhez képest.';
    }

    // 2. Arbitrázs számítás (Biztos profit szűrő, ha a különböző irodák szorzóinak reciproka < 1.0)
    // Feltételezve, hogy a bestBookmakerOdds a hazai, nézzük meg az ellenoldali arbitrázst is
    bool arbFound = false;
    double arbProfit = 0.0;

    if (bestBookmakerOdds > 1.0 && aiFairOdds > 1.0) {
      // Egyszerűsített arbitrázs check: ha a bookie odds nagyobb, mint az AI fair odds / piaci átlag extra marzsa
      double impliedProbability = 1.0 / bestBookmakerOdds;
      double fairProbability = 1.0 / aiFairOdds;

      if (impliedProbability < fairProbability * 0.92) {
         arbFound = true;
         arbProfit = ((fairProbability - impliedProbability) / impliedProbability) * 100.0;
      }
    }

    return SharpMoneySignal(
      hasSharpMovement: sharpMovement,
      description: desc,
      oddsDropPercent: double.parse(oddsDrop.toStringAsFixed(1)),
      isArbitrageOpportunity: arbFound,
      arbitrageProfitPercent: arbFound ? double.parse(arbProfit.toStringAsFixed(1)) : 0.0,
    );
  }
}
