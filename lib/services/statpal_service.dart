// ============================================================================
// Zsolt Pro AI - StatPal (Soccerdata API) Integration Service
// File: lib/services/statpal_service.dart
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatPalService {
  StatPalService._();
  static final StatPalService instance = StatPalService._();

  String? _apiKey;
  bool get hasApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;

  static const String _baseUrl = 'https://api.statpal.io/v1';

  /// Kulcs betöltése indításkor
  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('statpal_api_key');
  }

  /// Kulcs mentése és beállítása
  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('statpal_api_key', _apiKey!);
  }

  Future<List<Map<String, dynamic>>> fetchLiveMatches() async {
    if (!hasApiKey) return [];

    try {
      final Uri uri = Uri.parse('$_baseUrl/matches/live');
      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> matches = data['data'] ?? [];
        return matches.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    return [];
  }

  Future<Map<String, dynamic>?> fetchTeamStatistics({required String teamId}) async {
    if (!hasApiKey) return null;

    try {
      final Uri uri = Uri.parse('$_baseUrl/teams/$teamId/statistics');
      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['statistics'] as Map<String, dynamic>?;
      }
    } catch (_) {}

    return null;
  }
}
