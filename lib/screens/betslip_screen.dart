// ===========================================
// Zsolt Pro AI
// Version: v0.9.3
// File: lib/screens/betslip_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/bet_builder_selection.dart';
import '../models/betslip_item.dart';
import '../services/betslip_service.dart';

class BetslipScreen extends StatelessWidget {
  const BetslipScreen({super.key});

  BetslipService get _betslipService {
    return BetslipService.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎫 Szelvény',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          AnimatedBuilder(
            animation: _betslipService,
            builder: (context, child) {
              if (_betslipService.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Szelvény ürítése',
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                ),
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
            final List<BetslipItem> items =
                _betslipService.items;

            if (items.isEmpty) {
              return _buildEmptyState();
            }

            return _buildBetslipContent(
              context: context,
              items: items,
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
              'A szelvényed jelenleg üres.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'A Meccsek képernyőről tudsz tippeket hozzáadni.',
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
    required List<BetslipItem> items,
  }) {
    return Column(
      children: [
        _buildSummaryCard(
          context: context,
          matchCount: items.length,
          selectionCount:
              _betslipService.totalSelectionCount,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24,
            ),
            itemCount: items.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              final BetslipItem item = items[index];

              return _buildItemCard(
                context: context,
                item: item,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required int matchCount,
    required int selectionCount,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final double totalOdds =
        _betslipService.totalOdds;

    final int averageAiScore =
        _betslipService.averageAiScore;

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
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: colors.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktuális szelvény',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$matchCount mérkőzés • '
                      '$selectionCount kiválasztás',
                      style: TextStyle(
                        color:
                            colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  '$matchCount db',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: colors.outlineVariant,
            height: 1,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Átlagos AI értékelés',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$averageAiScore%',
                style: TextStyle(
                  color: _getAiScoreColor(
                    averageAiScore,
                  ),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Kombinált odds',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                totalOdds > 0
                    ? totalOdds.toStringAsFixed(2)
                    : 'Nincs odds adat',
                style: TextStyle(
                  color: totalOdds > 0
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({
    required BuildContext context,
    required BetslipItem item,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final match = item.match;

    final int displayedAiScore =
        item.isBetBuilder
            ? item.builderAiScore
            : match.aiScore;

    final double displayedOdds =
        item.isBetBuilder
            ? item.builderOdds
            : item.odds;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          10,
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.league.isEmpty
                        ? 'Ismeretlen bajnokság'
                        : match.league,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Eltávolítás',
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    _removeItem(
                      context: context,
                      item: item,
                    );
                  },
                ),
              ],
            ),
            Text(
              '${match.homeTeam} – '
              '${match.awayTeam}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 17,
                  color:
                      colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatMatchDate(item),
                  style: TextStyle(
                    color:
                        colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                if (match.isLive) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ÉLŐ',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color: colors.outlineVariant,
              height: 1,
            ),
            const SizedBox(height: 14),

            if (item.isBetBuilder)
              _buildBetBuilderDetails(
                context: context,
                item: item,
              )
            else
              _buildSingleBetDetails(
                context: context,
                item: item,
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _getAiScoreColor(
                      displayedAiScore,
                    ).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(
                    'AI $displayedAiScore%',
                    style: TextStyle(
                      color: _getAiScoreColor(
                        displayedAiScore,
                      ),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: displayedOdds > 0
                        ? Colors.green.withValues(
                            alpha: 0.15,
                          )
                        : colors
                            .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(
                    displayedOdds > 0
                        ? 'Odds '
                            '${displayedOdds.toStringAsFixed(2)}'
                        : 'Odds később',
                    style: TextStyle(
                      color: displayedOdds > 0
                          ? Colors.greenAccent
                          : colors
                              .onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleBetDetails({
    required BuildContext context,
    required BetslipItem item,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            _marketIcon(item.market),
            color: colors.onPrimaryContainer,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                item.market,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.selection,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBetBuilderDetails({
    required BuildContext context,
    required BetslipItem item,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(
          alpha: 0.18,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.construction_outlined,
                  color:
                      colors.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fogadáskészítő',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.builderSelections.length} '
                      'kiválasztott tipp',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            color: colors.outlineVariant,
            height: 1,
          ),
          const SizedBox(height: 10),
          ...item.builderSelections.map(
            (BetBuilderSelection selection) {
              return _buildBuilderSelectionRow(
                context: context,
                selection: selection,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBuilderSelectionRow({
    required BuildContext context,
    required BetBuilderSelection selection,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin:
                const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: Colors.green.withValues(
                alpha: 0.15,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  selection.selection,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selection.market,
                  style: TextStyle(
                    color:
                        colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: _getAiScoreColor(
                selection.aiScore,
              ).withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Text(
              '${selection.aiScore}%',
              style: TextStyle(
                color: _getAiScoreColor(
                  selection.aiScore,
                ),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMatchDate(
    BetslipItem item,
  ) {
    final match = item.match;

    final String day =
        match.matchDate.day
            .toString()
            .padLeft(2, '0');

    final String month =
        match.matchDate.month
            .toString()
            .padLeft(2, '0');

    if (match.matchTime.trim().isEmpty) {
      return '$month.$day.';
    }

    return '$month.$day.  ${match.matchTime}';
  }

  IconData _marketIcon(String market) {
    final String value =
        market.toLowerCase();

    if (value.contains('fogadáskészítő')) {
      return Icons.construction_outlined;
    }

    if (value.contains('szöglet')) {
      return Icons.flag_outlined;
    }

    if (value.contains('lap')) {
      return Icons.style_outlined;
    }

    if (value.contains('les')) {
      return Icons.block_outlined;
    }

    if (value.contains(
      'szabálytalanság',
    )) {
      return Icons.warning_amber_rounded;
    }

    if (value.contains('gól')) {
      return Icons.sports_soccer;
    }

    if (value.contains('mindkét')) {
      return Icons.groups_outlined;
    }

    if (value.contains('dupla')) {
      return Icons.compare_arrows;
    }

    if (value.contains('győztese')) {
      return Icons.emoji_events_outlined;
    }

    if (value.contains('ai')) {
      return Icons.psychology;
    }

    return Icons.sports_soccer;
  }

  Color _getAiScoreColor(int score) {
    if (score >= 85) {
      return Colors.greenAccent;
    }

    if (score >= 75) {
      return Colors.lightGreenAccent;
    }

    if (score >= 60) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  void _removeItem({
    required BuildContext context,
    required BetslipItem item,
  }) {
    final bool removed =
        _betslipService.removeMatch(item.id);

    if (!removed) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${item.match.homeTeam} – '
            '${item.match.awayTeam} eltávolítva.',
          ),
          action: SnackBarAction(
            label: 'Vissza',
            onPressed: () {
              _betslipService.addItem(item);
            },
          ),
        ),
      );
  }

  Future<void> _showClearConfirmation(
    BuildContext context,
  ) async {
    final bool? shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Szelvény ürítése',
          ),
          content: const Text(
            'Biztosan eltávolítod az összes '
            'tippet a szelvényről?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Mégse'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text('Ürítés'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true ||
        !context.mounted) {
      return;
    }

    _betslipService.clear();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'A szelvényt kiürítettük.',
          ),
        ),
      );
  }
}
