// ignore_for_file: depend_on_referenced_packages

// ===========================================
// Zsolt Pro AI
// Version: v0.21.1
// File: lib/services/sportsdb_search_service.dart
// ===========================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class SportsDbSearchService {
  SportsDbSearchService._privateConstructor();
  static final SportsDbSearchService instance = SportsDbSearchService._privateConstructor();

  final String _baseUrl = 'https://thesportsdb.com';
  final Map<String, String> _headers = {
    'X-API-KEY': '3', // Ingyenes fejlesztői kulcs
    'Accept': 'application/json',
  };

  /// Megkeresi egy csapat egyedi azonosítóját (ID) a neve alapján.
  Future<String?> findTeamId(String ticketTeamName) async {
    try {
      final String cleanName = _normalizeTeamName(ticketTeamName);
      if (cleanName.isEmpty) return null;

      final Uri url = Uri.parse('$_baseUrl/search/teams.php?t=${Uri.encodeComponent(cleanName)}');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic>? teams = data['teams'];
        if (teams != null && teams.isNotEmpty) {
          return teams.first['idTeam']?.toString();
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
      final Uri url = Uri.parse('$_baseUrl/livescore/table.php?l=$leagueId&s=${Uri.encodeComponent(season)}');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['table'] ?? [];
      }
    } catch (_) {
      // Hiba esetén üres listával térünk vissza az app stabilitásáért
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
