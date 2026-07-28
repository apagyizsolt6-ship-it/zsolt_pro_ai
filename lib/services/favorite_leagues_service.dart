// ===========================================
// Zsolt Pro AI
// Version: v0.1.0 - Persistent Favorite Leagues
// File: lib/services/favorite_leagues_service.dart
// ===========================================

import 'package:shared_preferences/shared_preferences.dart';

class FavoriteLeaguesService {
  FavoriteLeaguesService._();

  static const String _storageKey = 'zsolt_pro_ai_favorite_leagues';
  static final Set<String> _favoriteLeagues = <String>{};
  static bool _isInitialized = false;

  /// Kedvenc ligák inicializálása indításkor
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? storedLeagues = prefs.getStringList(_storageKey);
      if (storedLeagues != null) {
        _favoriteLeagues.clear();
        _favoriteLeagues.addAll(storedLeagues);
      }
      _isInitialized = true;
    } catch (_) {
      // Hiba esetén memóriabeli marad
    }
  }

  static bool isFavorite(String leagueName) {
    return _favoriteLeagues.contains(leagueName);
  }

  static Future<void> toggleFavorite(String leagueName) async {
    if (_favoriteLeagues.contains(leagueName)) {
      _favoriteLeagues.remove(leagueName);
    } else {
      _favoriteLeagues.add(leagueName);
    }
    await _saveToStorage();
  }

  static List<String> get favoriteLeagues {
    return _favoriteLeagues.toList(growable: false);
  }

  static Future<void> clear() async {
    _favoriteLeagues.clear();
    await _saveToStorage();
  }

  static Future<void> _saveToStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favoriteLeagues.toList());
    } catch (_) {
      // Mentési hiba elnyelése
    }
  }
}
