/*
===========================================
ZSOLT PRO AI
Build: #016
Version: v1.0.0
File: api_cache_service.dart
===========================================
*/

class ApiCacheEntry<T> {
  final T data;
  final DateTime createdAt;

  ApiCacheEntry({
    required this.data,
    required this.createdAt,
  });

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(createdAt) > ttl;
  }
}

class ApiCacheService {
  ApiCacheService._();

  static final ApiCacheService instance = ApiCacheService._();

  /// 5 perc cache
  static const Duration defaultTtl = Duration(minutes: 5);

  final Map<String, ApiCacheEntry<dynamic>> _cache = {};

  /// Lekérés cache-ből
  T? get<T>(
    String key, {
    Duration ttl = defaultTtl,
  }) {
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired(ttl)) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  /// Mentés cache-be
  void put<T>(
    String key,
    T value,
  ) {
    _cache[key] = ApiCacheEntry<T>(
      data: value,
      createdAt: DateTime.now(),
    );
  }

  /// Van-e érvényes cache
  bool contains(
    String key, {
    Duration ttl = defaultTtl,
  }) {
    return get(key, ttl: ttl) != null;
  }

  /// Egy elem törlése
  void remove(String key) {
    _cache.remove(key);
  }

  /// Minden cache törlése
  void clear() {
    _cache.clear();
  }

  /// Lejárt elemek törlése
  void clearExpired({
    Duration ttl = defaultTtl,
  }) {
    final keys = <String>[];

    for (final item in _cache.entries) {
      if (item.value.isExpired(ttl)) {
        keys.add(item.key);
      }
    }

    for (final key in keys) {
      _cache.remove(key);
    }
  }

  /// Cache mérete
  int get size => _cache.length;

  /// Debug lista
  List<String> get keys => _cache.keys.toList();
}
