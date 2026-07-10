// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/widgets/app_bottom_nav.dart
// ===========================================

import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 70,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: "Főoldal",
        ),
        NavigationDestination(
          icon: Icon(Icons.psychology_outlined),
          selectedIcon: Icon(Icons.psychology),
          label: "AI Top 5",
        ),
        NavigationDestination(
          icon: Icon(Icons.sports_soccer_outlined),
          selectedIcon: Icon(Icons.sports_soccer),
          label: "Meccsek",
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: "Szelvény",
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: "Beállítások",
        ),
      ],
    );
  }
}
