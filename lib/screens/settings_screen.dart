// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/screens/settings_screen.dart
// ===========================================

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = true;
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("⚙️ Beállítások"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            value: darkMode,
            title: const Text("Sötét mód"),
            subtitle: const Text("Világos / Sötét téma"),
            secondary: const Icon(Icons.dark_mode),
            onChanged: (value) {
              setState(() {
                darkMode = value;
              });
            },
          ),
          SwitchListTile(
            value: notifications,
            title: const Text("Értesítések"),
            subtitle: const Text("AI tippek és meccsértesítések"),
            secondary: const Icon(Icons.notifications_active),
            onChanged: (value) {
              setState(() {
                notifications = value;
              });
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Alkalmazás verzió"),
            subtitle: Text("v0.1.0 Foundation"),
          ),
          const ListTile(
            leading: Icon(Icons.flag),
            title: Text("Nyelv"),
            subtitle: Text("Magyar"),
          ),
        ],
      ),
    );
  }
}
