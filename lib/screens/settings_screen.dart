// ===========================================
// Zsolt Pro AI
// Version: v0.4.5
// File: lib/screens/settings_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "⚙️ Beállítások",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            children: [

              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text("Sötét mód"),
                subtitle: const Text(
                  "Világos és sötét téma",
                ),
                value: ThemeService.instance.isDarkMode,
                onChanged: (value) async {
                  await ThemeService.instance.setDarkMode(
                    value,
                  );
                },
              ),

              const Divider(),

              const ListTile(
                leading: Icon(Icons.notifications),
                title: Text("Értesítések"),
                subtitle: Text("Hamarosan"),
              ),

              const ListTile(
                leading: Icon(Icons.language),
                title: Text("Nyelv"),
                subtitle: Text("Magyar"),
              ),

              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("Verzió"),
                subtitle: Text("v0.4.5"),
              ),

              const SizedBox(height: 40),

              const Center(
                child: Text(
                  "© 2026 Zsolt Pro AI",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
