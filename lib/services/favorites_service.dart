// ===========================================
// Zsolt Pro AI
// Version: v0.18.0 - Persistent Favorites
// File: lib/services/favorites_service.dart
// ===========================================

import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  FavoritesService._();

  static const String _storageKey = 'zsolt_pro_ai_favorites';
  static final Set<String> _favorites = <String>{};
  static bool _isInitialized = false;

  /// Kedvencek inicializálása (induláskor érdemes meghívni)
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? storedFavorites = prefs.getStringList(_storageKey);
      if (storedFavorites != null) {
        _favorites.clear();
        _favorites.addAll(storedFavorites);
      }
      _isInitialized = true;
    } catch (_) {
      // Hiba esetén memóriabeli marad
    }
  }

  static bool isFavorite(String matchId) {
    return _favorites.contains(matchId);
  }

  static Future<void> toggleFavorite(String matchId) async {
    if (_favorites.contains(matchId)) {
      _favorites.remove(matchId);
    } else {
      _favorites.add(matchId);
    }
    await _saveToStorage();
  }

  static List<String> get favorites {
    return _favorites.toList(growable: false);
  }

  static Future<void> clear() async {
    _favorites.clear();
    await _saveToStorage();
  }

  static Future<void> _saveToStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favorites.toList());
    } catch (_) {
      // Mentési hiba elnyelése a stabil működésért
    }
  }
}
