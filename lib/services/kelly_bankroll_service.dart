// ============================================================================
// Zsolt Pro AI - Smart Bankroll & Kelly Engine
// File: lib/services/kelly_bankroll_service.dart
// ============================================================================

class KellyBankrollResult {
  final double recommendedStakePercent;
  final double recommendedStakeAmount;
  final String riskLevel;
  final bool isValueBet;

  const KellyBankrollResult({
    required this.recommendedStakePercent,
    required this.recommendedStakeAmount,
    required this.riskLevel,
    required this.isValueBet,
  });
}

class KellyBankrollService {
  KellyBankrollService._();
  static final KellyBankrollService instance = KellyBankrollService._();

  /// Kiszámolja az optimális tétet a Kelly-kritérium alapján.
  /// [bankroll]: A felhasználó teljes tőkéje (pl. 100 000 Ft)
  /// [probability]: Az AI által számolt valószínűség (0.0 és 1.0 között, pl. 0.55)
  /// [odds]: A fogadóiroda szorzója (pl. 2.10)
  /// [fraction]: Kelly frakció a kockázatkezeléshez (pl. 0.25 a biztonságos negyed-Kelly-hez)
  KellyBankrollResult calculateOptimalStake({
    required double bankroll,
    required double probability,
    required double odds,
    double fraction = 0.25, 
  }) {
    if (probability <= 0 || odds <= 1.0 || bankroll <= 0) {
      return const KellyBankrollResult(
        recommendedStakePercent: 0.0,
        recommendedStakeAmount: 0.0,
        riskLevel: 'Nincs tét',
        isValueBet: false,
      );
    }

    // Kelly-képlet: f* = (bp - q) / b
    // ahol b = odds - 1, p = esély, q = 1 - p
    final double b = odds - 1.0;
    final double q = 1.0 - probability;
    final double kellyFraction = ((b * probability) - q) / b;

    if (kellyFraction <= 0) {
      return const KellyBankrollResult(
        recommendedStakePercent: 0.0,
        recommendedStakeAmount: 0.0,
        riskLevel: 'Nem Value Bet',
        isValueBet: false,
      );
    }

    // Biztonságos frakció alkalmazása (pl. negyed-Kelly a túlzott kockázat elkerülésére)
    final double safeKelly = kellyFraction * fraction;
    final double maxCap = 0.05; // Soha ne ajánljon 5%-nál többet egyetlen tettre sem
    final double finalPercent = safeKelly > maxCap ? maxCap : safeKelly;

    final double stakeAmount = bankroll * finalPercent;

    String risk = 'Konzervatív';
    if (finalPercent > 0.03) {
      risk = 'Agresszív';
    } else if (finalPercent > 0.015) {
      risk = 'Moderált';
    }

    return KellyBankrollResult(
      recommendedStakePercent: double.parse((finalPercent * 100.0).toStringAsFixed(2)),
      recommendedStakeAmount: double.parse(stakeAmount.toStringAsFixed(1)),
      riskLevel: risk,
      isValueBet: true,
    );
  }
}
