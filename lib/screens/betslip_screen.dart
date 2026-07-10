// ===========================================
// Zsolt Pro AI
// Version: v0.5.5
// File: lib/screens/betslip_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../services/betslip_service.dart';

class BetslipScreen extends StatelessWidget {
  const BetslipScreen({super.key});

  BetslipService get _betslipService => BetslipService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎫 Szelvény"),
        centerTitle: true,
        actions: [
          AnimatedBuilder(
            animation: _betslipService,
            builder: (context, child) {
              if (_betslipService.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: "Szelvény ürítése",
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () {
                  _showClearConfirmation(context);
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _betslipService,
          builder: (context, child) {
            final List<AppMatch> matches = _betslipService.matches;

            if (matches.isEmpty) {
              return _buildEmptyState();
            }

            return _buildBetslipContent(
              context: context,
              matches: matches,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 90,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              "A szelvényed jelenleg üres.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "A Meccsek képernyőről tudsz tippeket hozzáadni.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBetslipContent({
    required BuildContext context,
    required List<AppMatch> matches,
  }) {
    return Column(
      children: [
        _buildSummaryCard(matches.length),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24,
            ),
            itemCount: matches.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              final AppMatch match = matches[index];

              return _buildMatchCard(
                context: context,
                match: match,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int itemCount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2B3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Aktuális szelvény",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$itemCount kiválasztott mérkőzés",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$itemCount db",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard({
    required BuildContext context,
    required AppMatch match,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2B3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              8,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match.league.isEmpty
                        ? "Ismeretlen bajnokság"
                        : match.league,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Eltávolítás",
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    _removeMatch(
                      context: context,
                      match: match,
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 20,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.homeTeam,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.flight_outlined,
                      size: 20,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match.awayTeam,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.white.withValues(alpha: 0.10),
                  height: 1,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatMatchDate(match),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getAiScoreColor(match.aiScore)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "AI ${match.aiScore}%",
                        style: TextStyle(
                          color: _getAiScoreColor(match.aiScore),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (match.isLive) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "● ÉLŐ MÉRKŐZÉS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMatchDate(AppMatch match) {
    final String day = match.matchDate.day.toString().padLeft(2, '0');
    final String month = match.matchDate.month.toString().padLeft(2, '0');

    if (match.matchTime.trim().isEmpty) {
      return "$month.$day.";
    }

    return "$month.$day.  ${match.matchTime}";
  }

  Color _getAiScoreColor(int score) {
    if (score >= 80) {
      return Colors.greenAccent;
    }

    if (score >= 60) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  void _removeMatch({
    required BuildContext context,
    required AppMatch match,
  }) {
    final bool removed = _betslipService.removeMatch(match.id);

    if (!removed) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            "${match.homeTeam} – ${match.awayTeam} eltávolítva.",
          ),
          action: SnackBarAction(
            label: "Vissza",
            onPressed: () {
              _betslipService.addMatch(match);
            },
          ),
        ),
      );
  }

  Future<void> _showClearConfirmation(
    BuildContext context,
  ) async {
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Szelvény ürítése"),
          content: const Text(
            "Biztosan eltávolítod az összes mérkőzést a szelvényről?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Mégse"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text("Ürítés"),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) {
      return;
    }

    _betslipService.clear();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("A szelvényt kiürítettük."),
        ),
      );
  }
}
