// ===========================================
// Zsolt Pro AI
// Version: v0.4.3
// File: lib/services/theme_service.dart
// ===========================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeService._();

  static final ThemeService instance = ThemeService._();

  static const String _darkModeKey = 'dark_mode_enabled';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final bool darkModeEnabled =
        preferences.getBool(_darkModeKey) ?? true;

    _themeMode = darkModeEnabled
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setBool(
      _darkModeKey,
      enabled,
    );
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode);
  }
}
