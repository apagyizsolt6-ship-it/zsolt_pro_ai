// ============================================================================
// Zsolt Pro AI - Settings Screen (Working Theme Toggle)
// File: lib/screens/settings_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../services/notification_settings_service.dart';
import '../services/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationSettingsService _settings = NotificationSettingsService.instance;
  final ThemeNotifier _themeNotifier = ThemeNotifier.instance;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.initialize();
    await _themeNotifier.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeNotifier.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Beállítások',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Megjelenés',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                    'Sötét Mód',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  subtitle: Text(
                    'Sötét vizuális téma használata az alkalmazásban',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  value: isDark,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (bool value) async {
                    await _themeNotifier.toggleTheme(value);
                    setState(() {});
                  },
                ),
                const Divider(color: Colors.white24, height: 32),
                const Text(
                  'Értesítési és Riasztási Beállítások',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                    'Sharp Money Riasztások',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  subtitle: Text(
                    'Értesítés jelentős piaci odds-mozgásokról',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  value: _settings.sharpMoneyEnabled,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (bool value) async {
                    await _settings.setSharpMoneyEnabled(value);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(
                    'Magas AI Értékű Tippek',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  subtitle: Text(
                    'Értesítés a kiemelkedő valószínűségű meccsekről',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  value: _settings.highAiEnabled,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (bool value) async {
                    await _settings.setHighAiEnabled(value);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(
                    'Csak Kedvencek Szűrése',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  subtitle: Text(
                    'Csak a kedvencnek jelölt mérkőzésekről küldjön jelzést',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  value: _settings.favoritesOnly,
                  activeThumbColor: Colors.blueAccent,
                  onChanged: (bool value) async {
                    await _settings.setFavoritesOnly(value);
                    setState(() {});
                  },
                ),
                const Divider(color: Colors.white24, height: 32),
                const Text(
                  'Alkalmazás Információ',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    'Verzió',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  trailing: const Text(
                    '0.1.0+1 (Release)',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Motor',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  trailing: const Text(
                    'Zsolt Pro AI Core',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
    );
  }
}
