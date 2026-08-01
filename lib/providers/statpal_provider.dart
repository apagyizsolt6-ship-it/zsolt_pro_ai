// ============================================================================
// Zsolt Pro AI - StatPal Provider / Controller (Végleges Tiszta Verzió)
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

  List<Map<String, dynamic>> _rawLiveMatchesGroups = [];
  List<Map<String, dynamic>> get rawLiveMatchesGroups => _rawLiveMatchesGroups;

  List<StatStandingTeam> _standings = [];
  List<StatStandingTeam> get standings => _standings;

  StatPrediction? _currentPrediction;
  StatPrediction? get currentPrediction => _currentPrediction;

  /// Adatok betöltése / frissítése (választható dátum vagy eltolás alapján)
  Future<void> loadInitialData({DateTime? selectedDate, int offset = 0}) async {
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

      // Kiszámítjuk az eltolást (offset), ha dátumot kaptunk
      int calculatedOffset = offset;
      if (selectedDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        calculatedOffset = target.difference(today).inDays;
      }

      // Meccsek lekérése a helyes offset paraméterrel
      final rawLive = await StatPalService.instance.fetchLiveMatches(offset: calculatedOffset);

      _rawLiveMatchesGroups = rawLive;

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
