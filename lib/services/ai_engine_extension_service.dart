// ===========================================
// Zsolt Pro AI
// Version: v0.21.5
// File: lib/services/ai_engine_extension_service.dart
// ===========================================

import 'dart:async';
import '../models/recognized_betslip.dart';
import 'sportsdb_search_service.dart';

/// Kiegészítő AI szolgáltatás a Zsolt Pro AI rendszeréhez.
/// Összeköti a felismert szelvényeket a TheSportsDB élő adataival,
/// elkerülve a meglévő nagyméretű motor módosítását.
class AiEngineExtensionService {
  AiEngineExtensionService._privateConstructor();
  static final AiEngineExtensionService instance = AiEngineExtensionService._privateConstructor();

  final SportsDbSearchService _searchService = SportsDbSearchService.instance;

  /// Feldolgozza a felismert szelvényt, párosítja a csapatokat a TheSportsDB-vel,
  /// és előkészíti a matematikai előrejelzéseket.
  Future<Map<String, dynamic>> analyzeBetslipWithSportsDb(RecognizedBetslip betslip) async {
    final List<Map<String, dynamic>> analyzedMatches = [];
    int successfulMatchesCount = 0;

    for (final match in betslip.matches) {
      // 1. Megkeressük a hazai csapat azonosítóját a TheSportsDB rendszerében
      final String? homeId = await _searchService.findTeamId(match.homeTeam);
      
      // 2. Megkeressük a vendég csapat azonosítóját
      final String? awayId = await _searchService.findTeamId(match.awayTeam);

      if (homeId != null && awayId != null) {
        successfulMatchesCount++;
        
        analyzedMatches.add({
          'originalMatch': match,
          'homeTeamId': homeId,
          'awayTeamId': awayId,
          'status': 'Párosítva',
        });
      } else {
        analyzedMatches.add({
          'originalMatch': match,
          'homeTeamId': null,
          'awayTeamId': null,
          'status': 'Azonosítatlan csapat',
        });
      }
    }

    return {
      'totalMatches': betslip.matches.length,
      'successfullyAnalyzedCount': successfulMatchesCount,
      'matches': analyzedMatches,
      'aiEngineVersion': 'v0.21.5',
    };
  }
}
