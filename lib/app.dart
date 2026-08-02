// ===========================================
// Zsolt Pro AI - Fő alkalmazás keret (StatPal PRO Integrációval)
// File: lib/app.dart
// ===========================================

import 'package:flutter/material.dart';

import 'screens/ai_top5_screen.dart';
import 'screens/betslip_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statpal_dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_bottom_nav.dart';

class ZsoltProApp extends StatefulWidget {
  const ZsoltProApp({super.key});

  @override
  State<ZsoltProApp> createState() => _ZsoltProAppState();
}

class _ZsoltProAppState extends State<ZsoltProApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AITop5Screen(),
    StatPalDashboardScreen(), // Cserélve a tiszta, szűrt PRO képernyőre
    BetslipScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
