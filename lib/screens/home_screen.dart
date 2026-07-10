// ===========================================
// Zsolt Pro AI
// Version: v0.3.6
// File: lib/screens/home_screen.dart
// ===========================================

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Zsolt Pro AI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.psychology,
                  color: colorScheme.onPrimary,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  "Üdv a Zsolt Pro AI alkalmazásban!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "AI alapú sportfogadási elemző rendszer",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Gyorsmenü",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _menuCard(
            context,
            Icons.psychology,
            "AI Top 5",
            "A legjobb AI tippek",
          ),

          _menuCard(
            context,
            Icons.sports_soccer,
            "Meccsek",
            "Mai és következő mérkőzések",
          ),

          _menuCard(
            context,
            Icons.receipt_long,
            "Szelvény",
            "Fogadásaid kezelése",
          ),

          _menuCard(
            context,
            Icons.settings,
            "Beállítások",
            "Alkalmazás beállításai",
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
