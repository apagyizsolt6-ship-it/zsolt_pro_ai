// Zsolt Pro AI
// Version: v0.1.0
// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Zsolt Pro AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const SizedBox(height: 10),

          _menuCard(
            icon: Icons.psychology,
            title: "AI Top 5",
            subtitle: "A mai legjobb AI tippek",
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          _menuCard(
            icon: Icons.sports_soccer,
            title: "Meccsek",
            subtitle: "Mai, élő és következő 6 nap",
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          _menuCard(
            icon: Icons.receipt_long,
            title: "Szelvény",
            subtitle: "Fogadásaid kezelése",
            color: Colors.orange,
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              "Zsolt Pro AI v0.1",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            icon,
            color: Colors.white,
          ),
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
