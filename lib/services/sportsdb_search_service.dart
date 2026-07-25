// ignore_for_file: depend_on_referenced_packages

// ===========================================
// Zsolt Pro AI
// Version: v0.22.0
// File: lib/services/sportsdb_search_service.dart
// ===========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_cache_service.dart';
import 'api_rate_limiter.dart';

class SportsDbSearchService {
  SportsDbSearchService._privateConstructor();

  static final SportsDbSearchService instance =
      SportsDbSearchService._privateConstructor();

  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json';

  static const String _environmentApiKey = String.fromEnvironment(
    'THESPORTSDB_API_KEY',
    defaultValue: String.fromEnvironment('THE_SPORTS_DB_API_KEY'),
  );

  static const String _freeApiKey = '3';

  static const Duration _connectionTimeout = Duration(seconds: 20);
  static const Duration _responseTimeout = Duration(seconds: 30);

  final ApiCacheService _cacheService = ApiCacheService.instance;
  final ApiRateLimiter _rateLimiter = ApiRateLimiter.instance;

  String get apiKey {
    final String configuredKey = _environmentApiKey.trim();
    if (configuredKey.isNotEmpty) {
      return configuredKey;
    }
    return _freeApiKey;
  }

  /// Megkeresi egy csapat egyedi azonosítóját (ID) a neve alapján.
  Future<String?> findTeamId(String ticketTeamName) async {
    try {
      final String cleanName = _normalizeTeamName(ticketTeamName);
      if (cleanName.isEmpty) return null;

      final Uri uri = Uri.parse('$_baseUrl/$apiKey/searchteams.php').replace(
        queryParameters: <String, String>{
          't': cleanName,
        },
      );

      final dynamic decoded = await _getJsonWithCacheAndRateLimit(uri);

      if (decoded is Map<String, dynamic>) {
        final dynamic teams = decoded['teams'];
        if (teams is List<dynamic> && teams.isNotEmpty) {
          final dynamic firstTeam = teams.first;
          if (firstTeam is Map<String, dynamic>) {
            return firstTeam['idTeam']?.toString();
          }
        }
      }
    } catch (_) {
      // Hibakezelés csendben az app stabilitásáért
    }
    return null;
  }

  /// Lekéri egy adott bajnokság (pl. Premier League) aktuális tabelláját.
  Future<List<dynamic>> getLeagueTable(String leagueId, String season) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/$apiKey/lookuptable.php').replace(
        queryParameters: <String, String>{
          'l': leagueId,
          's': season.trim(),
        },
      );

      final dynamic decoded = await _getJsonWithCacheAndRateLimit(uri);

      if (decoded is Map<String, dynamic>) {
        final dynamic table = decoded['table'];
        if (table is List<dynamic>) {
          return table;
        }
      }
    } catch (_) {
      // Hiba esetén üres listával térünk vissza az app stabilitásáért
    }
    return const [];
  }

  /// Belső segédmetódus a Cache és a RateLimiter használatához
  Future<dynamic> _getJsonWithCacheAndRateLimit(Uri uri) async {
    final String cacheKey = uri.toString();

    // 1. Gyors ellenőrzés a gyorsítótárban
    final dynamic cachedResponse = _cacheService.get<dynamic>(cacheKey);
    if (cachedResponse != null) {
      return cachedResponse;
    }

    // 2. Kérés ütemezése a Rate Limiter execute metódusán keresztül
    return await _rateLimiter.execute(() async {
      final dynamic recheckedCache = _cacheService.get<dynamic>(cacheKey);
      if (recheckedCache != null) {
        return recheckedCache;
      }

      final dynamic networkResult = await _getJson(uri);

      if (networkResult != null) {
        _cacheService.put(cacheKey, networkResult);
      }

      return networkResult;
    });
  }

  Future<dynamic> _getJson(Uri uri) async {
    final HttpClient client = HttpClient();
    client.connectionTimeout = _connectionTimeout;

    try {
      final HttpClientRequest request =
          await client.getUrl(uri).timeout(_connectionTimeout);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Zsolt-Pro-AI/0.22.0',
      );

      final HttpClientResponse response =
          await request.close().timeout(_responseTimeout);

      final String body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_responseTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      try {
        return jsonDecode(body);
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Tisztítja és átalakítja a magyar Tippmix szelvényeken található
  /// csapatneveket az API által érthető formátumra.
  String _normalizeTeamName(String name) {
    String clean = name.trim().toLowerCase();

    final Map<String, String> replacements = <String, String>{
      'manc. utd': 'manchester united',
      'manc. city': 'manchester city',
      'birmingh.': 'birmingham',
      'wolverh.': 'wolverhampton',
      'fradi': 'ferencvaros',
      'ujpest': 'ujpest',
      'puskas ak.': 'puskas',
      'madrid': 'madrid',
      'chelsea': 'chelsea',
      'arsenal': 'arsenal',
      'bayern': 'bayern',
      'dortmund': 'dortmund',
    };

    for (final MapEntry<String, String> entry in replacements.entries) {
      if (clean.contains(entry.key)) {
        return entry.value;
      }
    }

    clean = clean.replaceAll('.', '').replaceAll('-', ' ');
    return clean;
  }
}
