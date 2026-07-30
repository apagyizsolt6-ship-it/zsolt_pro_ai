// ============================================================================
// Zsolt Pro AI - Settings Screen (Clean & Stable)
// File: lib/screens/settings_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../services/notification_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationSettingsService _settings = NotificationSettingsService.instance;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Beállítások',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
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
                  title: const Text(
                    'Sharp Money Riasztások',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Értesítés jelentős piaci odds-mozgásokról',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  value: _settings.sharpMoneyEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: (bool value) async {
                    setState(() {
                      _settings.sharpMoneyEnabled = value;
                    });
                    await _settings.saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text(
                    'Magas AI Értékű Tippek',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Értesítés a kiemelkedő valószínűségű meccsekről',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  value: _settings.highAiEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: (bool value) async {
                    setState(() {
                      _settings.highAiEnabled = value;
                    });
                    await _settings.saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text(
                    'Csak Kedvencek Szűrése',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Csak a kedvencnek jelölt mérkőzésekről küldjön jelzést',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  value: _settings.favoritesOnly,
                  activeColor: Colors.blueAccent,
                  onChanged: (bool value) async {
                    setState(() {
                      _settings.favoritesOnly = value;
                    });
                    await _settings.saveSettings();
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
                const ListTile(
                  title: Text(
                    'Verzió',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    '0.1.0+1 (Release)',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const ListTile(
                  title: Text(
                    'Motor',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    'Zsolt Pro AI Core',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
    );
  }
}
