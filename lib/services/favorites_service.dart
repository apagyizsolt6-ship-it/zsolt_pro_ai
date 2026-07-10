// ===========================================
// Zsolt Pro AI
// Version: v0.3.2
// File: lib/services/favorites_service.dart
// ===========================================

class FavoritesService {
  FavoritesService._();

  static final Set<String> _favorites = {};

  static bool isFavorite(String matchId) {
    return _favorites.contains(matchId);
  }

  static void toggleFavorite(String matchId) {
    if (_favorites.contains(matchId)) {
      _favorites.remove(matchId);
    } else {
      _favorites.add(matchId);
    }
  }

  static List<String> get favorites {
    return _favorites.toList();
  }

  static void clear() {
    _favorites.clear();
  }
}
