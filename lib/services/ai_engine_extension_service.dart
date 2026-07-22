// ===========================================
// Zsolt Pro AI
// Version: v0.22.1
// File: lib/services/ai_engine_extension_service.dart
// ===========================================

import 'dart:async';
import 'package:zsolt_pro_ai/models/recognized_betslip.dart';
import 'sportsdb_search_service.dart';

/// Kiegészítő AI szolgáltatás a Zsolt Pro AI rendszeréhez.
/// Kiszámolja a valós esélyeket és azonosítja a Tippmix Value Bet-eket.
class AiEngineExtensionService {
  AiEngineExtensionService._privateConstructor();
  static final AiEngineExtensionService instance = AiEngineExtensionService._privateConstructor();

  final SportsDbSearchService _searchService = SportsDbSearchService.instance;

  /// Feldolgozza a szelvényt, és minden meccshez kiszámolja a matematikai értéket.
  Future<Map<String, dynamic>> analyzeBetslipWithValueBet(RecognizedBetslip betslip) async {
    final List<Map<String, dynamic>> analyzedMatches = [];
    int valueBetsCount = 0;

    for (final match in betslip.matches) {
      final String? homeId = await _searchService.findTeamId(match.homeTeam);
      
      // Alapértelmezett értékek, ha az API nem ad vissza részletes formát
      double realProbability = 0.45; 
      bool isValueBet = false;

      if (homeId != null) {
        // Lekérjük az aktuális bajnokság adatait (pl. 4328 - Premier League)
        final List<dynamic> table = await _searchService.getLeagueTable('4328', '2025-2026');
        
        // Megkeressük a csapatunkat a tabellán, hogy leolvassuk a formáját
        String teamForm = '';
        for (final team in table) {
          if (team['idTeam']?.toString() == homeId) {
            teamForm = team['strForm'] ?? '';
            break;
          }
        }

        // Elvégezzük a matematikai számításokat
        realProbability = _calculateRealProbability(teamForm);
        
        double currentOdds = 1.85; 
        isValueBet = _checkIsValueBet(currentOdds, realProbability);
        
        if (isValueBet) valueBetsCount++;
      }

      // Kijavított szoftveres string összefűzés (Dart interpolation szabvány)
      final String percentageString = '${(realProbability * 100).toStringAsFixed(0)}%';

      analyzedMatches.add({
        'match': match,
        'probability': percentageString,
        'isValueBet': isValueBet,
        'recommendation': isValueBet ? 'ÉRTÉKES FOGADÁS (Value)' : 'Normál kockázat',
      });
    }

    return {
      'totalMatches': betslip.matches.length,
      'valueBetsFound': valueBetsCount,
      'analyzedMatches': analyzedMatches,
    };
  }

  /// Kiszámolja egy kimenetel valós statisztikai valószínűségét (0.0 - 1.0 között)
  double _calculateRealProbability(String formString) {
    if (formString.isEmpty) return 0.33;
    
    final List<String> matches = formString.split('-');
    int wins = 0;
    int draws = 0;

    for (final res in matches) {
      if (res.toUpperCase() == 'W') wins++;
      if (res.toUpperCase() == 'D') draws++;
    }

    final double score = (wins * 1.0 + draws * 0.5) / matches.length;
    return score.clamp(0.15, 0.85);
  }

  /// Megvizsgálja, hogy a Tippmix szorzó (odds) értékes-e a valós esélyekhez képest.
  bool _checkIsValueBet(double tippmixOdds, double realProbability) {
    if (tippmixOdds <= 0) return false;
    return (tippmixOdds * realProbability) > 1.05;
  }
}
