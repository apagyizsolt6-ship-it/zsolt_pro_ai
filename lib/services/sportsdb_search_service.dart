// ===========================================
// Zsolt Pro AI
// Version: v0.21.0
// File: lib/services/sportsdb_search_service.dart
// ===========================================

import 'dart:convert';
import 'package:dio/dio.dart';

class SportsDbSearchService {
  SportsDbSearchService._privateConstructor();
  static final SportsDbSearchService instance = SportsDbSearchService._privateConstructor();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://thesportsdb.com',
      headers: {
        'X-API-KEY': '3', // Ingyenes fejlesztői kulcs
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Megkeresi egy csapat egyedi azonosítóját (ID) a neve alapján.
  /// Ha a magyar szelvényen pl. "Manc. United" van, ez a függvény 
  /// megpróbálja intelligensen párosítani a hivatalos névvel.
  Future<String?> findTeamId(String ticketTeamName) async {
    try {
      final String cleanName = _normalizeTeamName(ticketTeamName);
      if (cleanName.isEmpty) return null;

      // TheSportsDB V2 csapatkereső végpont: /search/teams.php?t=Csapatnév
      final response = await _dio.get(
        '/search/teams.php',
        queryParameters: {'t': cleanName},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic>? teams = response.data['teams'];
        if (teams != null && teams.isNotEmpty) {
          // Visszaadjuk a legelső talált csapat egyedi ID-ját
          return teams.first['idTeam']?.toString();
        }
      }
    } catch (_) {
      // Hálózati vagy parsing hiba esetén csendben null-t adunk vissza
    }
    return null;
  }
  /// Lekéri egy adott bajnokság (pl. Premier League) aktuális tabelláját.
  Future<List<dynamic>> getLeagueTable(String leagueId, String season) async {
    try {
      final response = await _dio.get(
        '/livescore/table.php',
        queryParameters: {
          'l': leagueId,
          's': season,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['table'] ?? [];
      }
    } catch (_) {
      // Hiba esetén üres listával térünk vissza, hogy ne omoljon össze az app
    }
    return [];
  }

  /// Tisztítja és átalakítja a magyar Tippmix szelvényeken található 
  /// csapatneveket az API által érthető formátumra.
  String _normalizeTeamName(String name) {
    String clean = name.trim().toLowerCase();

    // Leggyakoribb magyar Tippmix rövidítések cseréje globális megfelelőkre
    final Map<String, String> replacements = {
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

    for (final entry in replacements.entries) {
      if (clean.contains(entry.key)) {
        return entry.value;
      }
    }

    // Írásjelek és felesleges pontok eltávolítása, ha nincs a listában
    clean = clean.replaceAll('.', '').replaceAll('-', ' ');
    return clean;
  }
}
