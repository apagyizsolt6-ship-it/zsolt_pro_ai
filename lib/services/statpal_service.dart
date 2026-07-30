// ============================================================================
// Zsolt Pro AI - StatPal API Integration Service
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

  // StatPal v2 alap URL soccer sporthoz
  static const String _baseUrl = 'https://statpal.io/api/v2/soccer';

  /// API kulcs inicializálása a tárhelyről
  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('statpal_api_key');
  }

  /// API kulcs mentése
  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('statpal_api_key', _apiKey!);
  }

  /// 1. Ligák lekérése (Get Leagues)
  Future<List<Map<String, dynamic>>> fetchLeagues() async {
    if (!hasApiKey) return [];
    try {
      final Uri uri = Uri.parse('$_baseUrl/leagues?access_key=$_apiKey');
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final leaguesObj = data['leagues'];
        if (leaguesObj != null && leaguesObj['league'] is List) {
          return List<Map<String, dynamic>>.from(leaguesObj['league']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// 2. Élő mérkőzések lekérése (Get Matches Today / Live)
  Future<List<Map<String, dynamic>>> fetchLiveMatches() async {
    if (!hasApiKey) return [];
    try {
      final Uri uri = Uri.parse('$_baseUrl/matches/live?access_key=$_apiKey');
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final liveMatchesObj = data['live_matches'];
        if (liveMatchesObj != null && liveMatchesObj['league'] is List) {
          return List<Map<String, dynamic>>.from(liveMatchesObj['league']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// 3. Tabella lekérése adott ligához (Get Standings By League / Season)
  Future<Map<String, dynamic>?> fetchStandings({required String leagueId, String? season}) async {
    if (!hasApiKey) return null;
    try {
      String url = '$_baseUrl/leagues/$leagueId/standings?access_key=$_apiKey';
      if (season != null && season.isNotEmpty) {
        url += '&season=$season';
      }
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['standings'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  /// 4. Sérülések és eltiltások lekérése (Get Injuries & Suspensions)
  Future<List<Map<String, dynamic>>> fetchInjuriesAndSuspensions() async {
    if (!hasApiKey) return [];
    try {
      final Uri uri = Uri.parse('$_baseUrl/injuries-suspensions?access_key=$_apiKey');
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final obj = data['injuries_suspensions'];
        if (obj != null && obj['league'] is List) {
          return List<Map<String, dynamic>>.from(obj['league']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// 5. Meccs előrejelzés lekérése (Get Match Prediction)
  Future<Map<String, dynamic>?> fetchMatchPrediction({required String matchId}) async {
    if (!hasApiKey) return null;
    try {
      final Uri uri = Uri.parse('$_baseUrl/predictions?match_id=$matchId&access_key=$_apiKey');
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }
}
