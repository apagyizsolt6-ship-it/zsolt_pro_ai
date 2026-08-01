// ============================================================================
// Zsolt Pro AI - Home Screen (Végleges, Minden Const-ot Kiszűrő Verzió)
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
        title: const Text('Zsolt Pro AI', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                    'Magyar nyelvű AI sportfogadási elemző- és tőkekezelő rendszer',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Chip(
                    label: Text('Smart Bankroll + ROI + StatPal', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.white24,
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
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.psychology, color: Colors.amber, size: 28),
                title: const Text('AI Top 5', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('A legjobb AI tippek'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AITop5Screen()));
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.sports_soccer, color: Colors.amber, size: 28),
                title: const Text('Meccsek, Élő & Ligák', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Mai meccsek, élő eredmények, tabellák és kedvenc ligák'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Chip(
                      label: Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StatPalDashboardScreen()));
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.amber, size: 28),
                title: const Text('Szelvény', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Fogadásaid kezelése'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BetslipScreen()));
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tőke & Menedzsment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 28),
                title: const Text('Smart Bankroll & ROI', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Virtuális egyenleg, fogadási előzmények és ROI statisztikák'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Chip(
                      label: Text('PRO', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BankrollScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
