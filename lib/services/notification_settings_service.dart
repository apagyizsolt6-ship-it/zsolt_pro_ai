// ============================================================================
// Zsolt Pro AI - Notification Settings Service
// File: lib/services/notification_settings_service.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService extends ChangeNotifier {
  NotificationSettingsService._();
  static final NotificationSettingsService instance = NotificationSettingsService._();

  static const String _keySharpMoneyEnabled = 'sharp_money_enabled';
  static const String _keyHighAiEnabled = 'high_ai_enabled';
  static const String _keyFavoritesOnly = 'favorites_only_enabled';
  static const String _keyMinAiScore = 'min_ai_score';

  bool _sharpMoneyEnabled = true;
  bool _highAiEnabled = true;
  bool _favoritesOnly = false;
  int _minAiScore = 85;

  bool get sharpMoneyEnabled => _sharpMoneyEnabled;
  bool get highAiEnabled => _highAiEnabled;
  bool get favoritesOnly => _favoritesOnly;
  int get minAiScore => _minAiScore;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    
    _sharpMoneyEnabled = prefs.getBool(_keySharpMoneyEnabled) ?? true;
    _highAiEnabled = prefs.getBool(_keyHighAiEnabled) ?? true;
    _favoritesOnly = prefs.getBool(_keyFavoritesOnly) ?? false;
    _minAiScore = prefs.getInt(_keyMinAiScore) ?? 85;
    
    _isInitialized = true;
    debugPrint('NotificationSettingsService initialized.');
    notifyListeners();
  }

  Future<void> setSharpMoneyEnabled(bool enabled) async {
    _sharpMoneyEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySharpMoneyEnabled, enabled);
    notifyListeners();
  }

  Future<void> setHighAiEnabled(bool enabled) async {
    _highAiEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighAiEnabled, enabled);
    notifyListeners();
  }

  Future<void> setFavoritesOnly(bool enabled) async {
    _favoritesOnly = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFavoritesOnly, enabled);
    notifyListeners();
  }

  Future<void> setMinAiScore(int score) async {
    _minAiScore = score.clamp(70, 100); // Ésszerű határok
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinAiScore, score);
    notifyListeners();
  }
}
