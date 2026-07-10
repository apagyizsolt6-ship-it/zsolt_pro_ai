// ===========================================
// Zsolt Pro AI
// Version: v0.4.2
// File: lib/screens/ai_top5_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../data/demo_matches.dart';
import '../models/app_match.dart';
import 'match_detail_screen.dart';

class AITop5Screen extends StatelessWidget {
  const AITop5Screen({super.key});

  List<AppMatch> get _topMatches {
    final List<AppMatch> matches = List<AppMatch>.from(
      DemoMatches.matches,
    );

    matches.sort(
      (first, second) => second.aiScore.compareTo(first.aiScore),
    );

    return matches.take(5).toList();
  }

  void _openMatchDetails(
    BuildContext context,
    AppMatch match,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return MatchDetailScreen(
            match: match,
          );
        },
      ),
    );
  }

  String _recommendation(int aiScore) {
    if (aiScore >= 93) {
      return '1X és több mint 1,5 gól';
    }

    if (aiScore >= 90) {
      return 'Több mint 2,5 gól';
    }

    if (aiScore >= 87) {
      return 'Mindkét csapat szerez gólt';
    }

    if (aiScore >= 84) {
      return 'Hazai csapat nem kap ki';
    }

    return 'Kevesebb mint 4,5 gól';
  }

  String _confidenceText(int aiScore) {
    if (aiScore >= 93) {
      return 'Kiemelt AI tipp';
    }

    if (aiScore >= 90) {
      return 'Nagyon erős tipp';
    }

    if (aiScore >= 87) {
      return 'Erős tipp';
    }

    if (aiScore >= 84) {
      return 'Jó tipp';
    }

    return 'Közepes tipp';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<AppMatch> matches = _topMatches;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Top 5',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          28,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(
                      alpha: 0.16,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: colors.onPrimary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A nap 5 legerősebb AI tippje',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mintaadatok alapján rangsorolva',
                        style: TextStyle(
                          color: colors.onPrimary.withValues(
                            alpha: 0.85,
                          ),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            matches.length,
            (index) {
              final AppMatch match = matches[index];

              return _TopMatchCard(
                position: index + 1,
                match: match,
                recommendation: _recommendation(
                  match.aiScore,
                ),
                confidenceText: _confidenceText(
                  match.aiScore,
                ),
                onTap: () {
                  _openMatchDetails(
                    context,
                    match,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopMatchCard extends StatelessWidget {
  final int position;
  final AppMatch match;
  final String recommendation;
  final String confidenceText;
  final VoidCallback onTap;

  const _TopMatchCard({
    required this.position,
    required this.match,
    required this.recommendation,
    required this.confidenceText,
    required this.onTap,
  });

  Color _positionColor() {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double progress = match.aiScore.clamp(0, 100) / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _positionColor(),
                    child: Text(
                      '$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      match.league,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${match.aiScore}/100',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                match.homeTeam,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                match.awayTeam,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      confidenceText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ajánlott tipp: $recommendation',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    match.matchTime,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
