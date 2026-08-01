// ============================================================================
// Zsolt Pro AI - StatPal Provider / Controller (Dátumszűréssel Ellátott Verzió)
// File: lib/providers/statpal_provider.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import '../services/statpal_service.dart';
import '../models/statpal_models.dart';

class StatPalProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<StatLeague> _leagues = [];
  List<StatLeague> get leagues => _leagues;

  List<StatMatch> _liveMatches = [];
  List<StatMatch> get liveMatches => _liveMatches;

  // Tároló a ligák szerinti csoportosításhoz
  List<Map<String, dynamic>> _rawLiveMatchesGroups = [];
  List<Map<String, dynamic>> get rawLiveMatchesGroups => _rawLiveMatchesGroups;

  List<StatStandingTeam> _standings = [];
  List<StatStandingTeam> get standings => _standings;

  StatPrediction? _currentPrediction;
  StatPrediction? get currentPrediction => _currentPrediction;

  /// Adatok betöltése / frissítése (választható dátum alapján)
  Future<void> loadInitialData({DateTime? selectedDate}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await StatPalService.instance.initialize();

      if (!StatPalService.instance.hasApiKey) {
        _errorMessage = 'Nincs beállítva StatPal API kulcs!';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Ligák lekérése
      final rawLeagues = await StatPalService.instance.fetchLeagues();
      _leagues = rawLeagues.map((json) => StatLeague.fromJson(json)).toList();

      // Meccsek és ligacsoportok lekérése a kiválasztott dátum alapján
      List<Map<String, dynamic>> rawLive = [];
      
      if (selectedDate != null) {
        final String formattedDate = 
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        
        // Dátum szerinti lekérdezés a service-en keresztül
        try {
          rawLive = await StatPalService.instance.fetchLiveMatches(date: formattedDate);
        } catch (_) {
          rawLive = await StatPalService.instance.fetchLiveMatches();
        }
      } else {
        rawLive = await StatPalService.instance.fetchLiveMatches();
      }

      _rawLiveMatchesGroups = rawLive; // Mentjük a nyers csoportokat a nézethez

      _liveMatches = [];
      for (var leagueGroup in rawLive) {
        if (leagueGroup['match'] is List) {
          for (var matchJson in leagueGroup['match']) {
            _liveMatches.add(StatMatch.fromJson(matchJson));
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Hiba történt az adatok betöltése közben: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tabella betöltése adott ligához
  Future<void> loadStandings(String leagueId, {String? season}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await StatPalService.instance.fetchStandings(leagueId: leagueId, season: season);
      if (data != null && data['table'] is List) {
        _standings = (data['table'] as List)
            .map((item) => StatStandingTeam.fromJson(item))
            .toList();
      } else {
        _standings = [];
      }
    } catch (e) {
      _errorMessage = 'Hiba a tabella lekérésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Meccs előrejelzés lekérése
  Future<void> loadPrediction(String matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await StatPalService.instance.fetchMatchPrediction(matchId: matchId);
      if (data != null) {
        _currentPrediction = StatPrediction.fromJson(data);
      } else {
        _currentPrediction = null;
      }
    } catch (e) {
      _errorMessage = 'Hiba az előrejelzés lekérésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
