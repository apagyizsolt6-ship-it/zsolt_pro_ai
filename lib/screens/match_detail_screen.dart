// ===========================================
// Zsolt Pro AI
// Version: v0.3.0
// File: lib/screens/match_detail_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';

class MatchDetailScreen extends StatelessWidget {
  final AppMatch match;

  const MatchDetailScreen({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meccselemzés',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _MatchHeaderCard(
            match: match,
          ),
          const SizedBox(height: 16),
          _AiRecommendationCard(
            aiScore: match.aiScore,
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            icon: Icons.auto_graph,
            title: 'Forma – utolsó 5 mérkőzés',
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _FormCard(
                  title: 'Hazai csapat',
                  form: ['G', 'G', 'D', 'G', 'V'],
                  score: 78,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _FormCard(
                  title: 'Vendég csapat',
                  form: ['V', 'D', 'G', 'V', 'D'],
                  score: 54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.compare_arrows,
            title: 'Egymás elleni mérleg',
          ),
          const SizedBox(height: 10),
          const _StatisticsCard(
            rows: [
              _StatisticRowData(
                label: 'Hazai győzelem',
                value: '4',
              ),
              _StatisticRowData(
                label: 'Döntetlen',
                value: '2',
              ),
              _StatisticRowData(
                label: 'Vendég győzelem',
                value: '2',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.sports_soccer,
            title: 'Gólstatisztikák',
          ),
          const SizedBox(height: 10),
          const _StatisticsCard(
            rows: [
              _StatisticRowData(
                label: 'Átlagos gólszám',
                value: '2,8',
              ),
              _StatisticRowData(
                label: 'Over 1,5',
                value: '82%',
              ),
              _StatisticRowData(
                label: 'Over 2,5',
                value: '64%',
              ),
              _StatisticRowData(
                label: 'Mindkét csapat szerez gólt',
                value: '61%',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.flag_outlined,
            title: 'Szögletek és lapok',
          ),
          const SizedBox(height: 10),
          const _StatisticsCard(
            rows: [
              _StatisticRowData(
                label: 'Várható szögletek',
                value: '9–12',
              ),
              _StatisticRowData(
                label: 'Várható lapok',
                value: '3–5',
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${match.homeTeam} – ${match.awayTeam} '
                    'hozzáadva a szelvényhez.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.add_circle_outline,
            ),
            label: const Text(
              'Hozzáadás a szelvényhez',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHeaderCard extends StatelessWidget {
  final AppMatch match;

  const _MatchHeaderCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    match.league,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _TeamColumn(
                    icon: Icons.shield,
                    teamName: match.homeTeam,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Column(
                    children: [
                      Text(
                        match.matchTime,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'VS',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _TeamColumn(
                    icon: Icons.shield_outlined,
                    teamName: match.awayTeam,
                  ),
                ),
              ],
            ),
            if (match.isLive) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ÉLŐ MÉRKŐZÉS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final IconData icon;
  final String teamName;

  const _TeamColumn({
    required this.icon,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 46,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 10),
        Text(
          teamName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _AiRecommendationCard extends StatelessWidget {
  final int aiScore;

  const _AiRecommendationCard({
    required this.aiScore,
  });

  String get _riskText {
    if (aiScore >= 90) {
      return 'Kiemelt AI ajánlás';
    }

    if (aiScore >= 80) {
      return 'Erős AI ajánlás';
    }

    if (aiScore >= 65) {
      return 'Közepes AI ajánlás';
    }

    return 'Kockázatos tipp';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double progress = (aiScore.clamp(0, 100)) / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI elemzés',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$aiScore/100',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 14),
            Text(
              _riskText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajánlott piac: 1X és több mint 1,5 gól',
              style: TextStyle(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<String> form;
  final int score;

  const _FormCard({
    required this.title,
    required this.form,
    required this.score,
  });

  Color _formColor(String result) {
    switch (result) {
      case 'G':
        return Colors.green;
      case 'D':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 5,
              children: form.map((result) {
                return CircleAvatar(
                  radius: 13,
                  backgroundColor: _formColor(result),
                  child: Text(
                    result,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              '$score%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final List<_StatisticRowData> rows;

  const _StatisticsCard({
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          children: List.generate(
            rows.length,
            (index) {
              final _StatisticRowData row = rows[index];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          row.value,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < rows.length - 1)
                    const Divider(
                      height: 1,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatisticRowData {
  final String label;
  final String value;

  const _StatisticRowData({
    required this.label,
    required this.value,
  });
}
