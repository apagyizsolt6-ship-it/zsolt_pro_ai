// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/app.dart
// ===========================================

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/ai_top5_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/betslip_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_bottom_nav.dart';

class ZsoltProApp extends StatefulWidget {
  const ZsoltProApp({super.key});

  @override
  State<ZsoltProApp> createState() => _ZsoltProAppState();
}

class _ZsoltProAppState extends State<ZsoltProApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AITop5Screen(),
    MatchesScreen(),
    BetslipScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
