// ===========================================
// Zsolt Pro AI
// Version: v0.13.8
// File: lib/screens/home_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import 'ai_top5_screen.dart';
import 'betslip_screen.dart';
import 'matches_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius:
                    BorderRadius.circular(20),
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
                    'Üdv a Zsolt Pro AI alkalmazásban!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI alapú sportfogadási elemző rendszer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onPrimary
                          .withValues(
                        alpha: 0.9,
                      ),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gyorsmenü',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.psychology,
              title: 'AI Top 5',
              subtitle: 'A legjobb AI tippek',
              onTap: () {
                _openScreen(
                  context: context,
                  screen:
                      const AiTop5Screen(),
                );
              },
            ),

            _MenuCard(
              icon: Icons.sports_soccer,
              title: 'Meccsek',
              subtitle:
                  'Mai és következő mérkőzések',
              onTap: () {
                _openScreen(
                  context: context,
                  screen:
                      const MatchesScreen(),
                );
              },
            ),

            _MenuCard(
              icon: Icons.receipt_long,
              title: 'Szelvény',
              subtitle: 'Fogadásaid kezelése',
              onTap: () {
                _openScreen(
                  context: context,
                  screen:
                      const BetslipScreen(),
                );
              },
            ),

            _MenuCard(
              icon: Icons.settings,
              title: 'Beállítások',
              subtitle:
                  'Alkalmazás beállításai',
              onTap: () {
                _openScreen(
                  context: context,
                  screen:
                      const SettingsScreen(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openScreen({
    required BuildContext context,
    required Widget screen,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (
          BuildContext context,
        ) {
          return screen;
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color:
                    colors.onPrimaryContainer,
                size: 26,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              subtitle,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
