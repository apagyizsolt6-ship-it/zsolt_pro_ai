// ===========================================
// Zsolt Pro AI
// Version: v0.20.4
// File: lib/screens/home_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import 'ai_top5_screen.dart';
import 'barcode_scanner_screen.dart';
import 'betslip_scanner_screen.dart';
import 'betslip_screen.dart';
import 'matches_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
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
            _buildHeaderCard(
              colors,
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              icon: Icons.dashboard_outlined,
              title: 'Gyorsmenü',
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.psychology,
              title: 'AI Top 5',
              subtitle: 'A legjobb AI tippek',
              onTap: () {
                _openScreen(
                  context: context,
                  screen: const AITop5Screen(),
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
                  screen: const MatchesScreen(),
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
                  screen: const BetslipScreen(),
                );
              },
            ),
            const SizedBox(height: 12),
            const _SectionHeader(
              icon: Icons.auto_awesome,
              title: 'AI szelvényeszközök',
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.document_scanner_outlined,
              title: 'AI Szelvény Felismerő',
              subtitle:
                  'Teljes szelvény beolvasása OCR-rel, Parser V5-tel és vonalkóddal',
              badgeText: 'PRO',
              badgeColor: colors.primary,
              onTap: () {
                _openScreen(
                  context: context,
                  screen:
                      const BetslipScannerScreen(),
                );
              },
            ),
            _MenuCard(
              icon: Icons.qr_code_scanner,
              title: 'Vonalkód beolvasása',
              subtitle:
                  'Vonalkód beolvasása és továbbítás az AI felismerőnek',
              badgeText: 'ÚJ',
              badgeColor: Colors.green,
              onTap: () {
                _openBarcodeScanner(
                  context,
                );
              },
            ),
            const SizedBox(height: 12),
            const _SectionHeader(
              icon: Icons.settings_outlined,
              title: 'Alkalmazás',
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.settings,
              title: 'Beállítások',
              subtitle:
                  'Alkalmazás beállításai',
              onTap: () {
                _openScreen(
                  context: context,
                  screen: const SettingsScreen(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.primary,
            colors.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primary.withValues(
              alpha: 0.25,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(
                alpha: 0.16,
              ),
              borderRadius: BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color: colors.onPrimary.withValues(
                  alpha: 0.30,
                ),
              ),
            ),
            child: Icon(
              Icons.psychology,
              color: colors.onPrimary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Üdv a Zsolt Pro AI alkalmazásban!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Magyar nyelvű AI sportfogadási '
            'elemző- és szelvényfelismerő rendszer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onPrimary.withValues(
                alpha: 0.92,
              ),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 19,
                  color: colors.onPrimary,
                ),
                const SizedBox(width: 7),
                Text(
                  'OCR + Parser V5 + Vonalkód',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Future<void> _openBarcodeScanner(
    BuildContext context,
  ) async {
    final String? barcode =
        await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (
          BuildContext context,
        ) {
          return const BarcodeScannerScreen();
        },
      ),
    );

    if (!context.mounted) {
      return;
    }

    final String barcodeValue =
        barcode?.trim() ?? '';

    if (barcodeValue.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (
          BuildContext context,
        ) {
          return BetslipScannerScreen(
            initialBarcode: barcodeValue,
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
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
            vertical: 7,
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(
                  15,
                ),
              ),
              child: Icon(
                icon,
                color: colors.onPrimaryContainer,
                size: 27,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    margin: const EdgeInsets.only(
                      left: 8,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (
                        badgeColor ??
                            colors.primary
                      ).withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color: (
                          badgeColor ??
                              colors.primary
                        ).withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        color:
                            badgeColor ??
                                colors.primary,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(
                top: 4,
              ),
              child: Text(
                subtitle,
              ),
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
