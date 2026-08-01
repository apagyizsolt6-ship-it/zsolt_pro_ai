// ============================================================================
// Zsolt Pro AI - Home Screen (Teljesen Újragondolt, Tiszta Verzió)
// File: lib/screens/home_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'ai_top5_screen.dart';
import 'bankroll_screen.dart';
import 'betslip_screen.dart';
import 'statpal_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zsolt Pro AI'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  'Üdv a Zsolt Pro AI alkalmazásban!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Magyar nyelvű AI sportfogadási elemző rendszer',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gyorsmenü',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.amber, size: 28),
            title: const Text('AI Top 5'),
            subtitle: const Text('A legjobb AI tippek'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AITop5Screen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sports_soccer, color: Colors.amber, size: 28),
            title: const Text('Meccsek, Élő & Ligák'),
            subtitle: const Text('Mai meccsek és élő eredmények'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatPalDashboardScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.amber, size: 28),
            title: const Text('Szelvény'),
            subtitle: const Text('Fogadásaid kezelése'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BetslipScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 28),
            title: const Text('Smart Bankroll & ROI'),
            subtitle: const Text('Egyenleg és statisztikák'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BankrollScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
