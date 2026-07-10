// ===========================================
// Zsolt Pro AI
// Version: v0.9.1
// File: lib/screens/match_detail_screen.dart
// 1. rész / 4
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../models/bet_builder_selection.dart';
import '../models/betslip_item.dart';
import '../services/betslip_service.dart';
import '../widgets/bet_builder_selector.dart';
import '../widgets/bet_market_selector.dart';

class MatchDetailScreen extends StatefulWidget {
  final AppMatch match;

  const MatchDetailScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchDetailScreen> createState() {
    return _MatchDetailScreenState();
  }
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  static const BetSelection _defaultSingleSelection = BetSelection(
    market: 'AI ajánlott piac',
    selection: '1X és több mint 1,5 gól',
    icon: Icons.auto_awesome,
  );

  BetSelection? _selectedSingleBet;

  List<BetBuilderSelection> _builderSelections =
      <BetBuilderSelection>[];

  AppMatch get match => widget.match;

  BetslipService get _betslipService {
    return BetslipService.instance;
  }

  @override
  void initState() {
    super.initState();

    final BetslipItem? savedItem =
        _betslipService.getItem(match.id);

    if (savedItem == null) {
      _selectedSingleBet = _defaultSingleSelection;
      return;
    }

    if (savedItem.isBetBuilder) {
      _builderSelections =
          List<BetBuilderSelection>.from(
        savedItem.builderSelections,
      );

      _selectedSingleBet = _defaultSingleSelection;
      return;
    }

    _selectedSingleBet = BetSelection(
      market: savedItem.market,
      selection: savedItem.selection,
      icon: _iconForMarket(savedItem.market),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

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
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          28,
        ),
        children: [
          _MatchHeaderCard(
            match: match,
          ),
          const SizedBox(height: 16),

          _AiRecommendationCard(
            aiScore: match.aiScore,
          ),
          const SizedBox(height: 18),

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
                  form: [
                    'G',
                    'G',
                    'D',
                    'G',
                    'V',
                  ],
                  score: 78,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _FormCard(
                  title: 'Vendég csapat',
                  form: [
                    'V',
                    'D',
                    'G',
                    'V',
                    'D',
                  ],
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
                label: 'Több mint 1,5 gól',
                value: '82%',
              ),
              _StatisticRowData(
                label: 'Több mint 2,5 gól',
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
            title: 'Speciális statisztikák',
          ),
          const SizedBox(height: 10),

          const _StatisticsCard(
            rows: [
              _StatisticRowData(
                label: 'Várható szögletek',
                value: '9–12',
              ),
              _StatisticRowData(
                label: 'Várható büntetőlapok',
                value: '3–5',
              ),
              _StatisticRowData(
                label: 'Várható lesek',
                value: '2–4',
              ),
              _StatisticRowData(
                label: 'Várható szabálytalanságok',
                value: '21–27',
              ),
            ],
          ),
          const SizedBox(height: 28),

          _ModeInformationCard(
            singleBetSelected:
                _builderSelections.isEmpty,
            builderSelectionCount:
                _builderSelections.length,
          ),
          const SizedBox(height: 22),

          const _SectionTitle(
            icon: Icons.touch_app_outlined,
            title: 'Egyedi tipp',
          ),
          const SizedBox(height: 8),

          Text(
            'Válassz egyetlen fogadási piacot, '
            'ha nem Fogadáskészítőt szeretnél használni.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),

          BetMarketSelector(
            selectedBet: _selectedSingleBet,
            onSelected: (
              BetSelection selection,
            ) {
              setState(() {
                _selectedSingleBet = selection;
                _builderSelections =
                    <BetBuilderSelection>[];
              });
            },
          ),
          const SizedBox(height: 10),

          if (_selectedSingleBet != null &&
              _builderSelections.isEmpty)
            _SelectedSingleBetCard(
              selectedBet: _selectedSingleBet!,
              aiScore: match.aiScore,
            ),

          const SizedBox(height: 26),

          const _SectionTitle(
            icon: Icons.construction_outlined,
            title: 'Fogadáskészítő PRO',
          ),
          const SizedBox(height: 8),

          Text(
            'Jelölj ki több piacot ugyanahhoz a '
            'mérkőzéshez. A kiválasztások egyetlen '
            'Fogadáskészítőként kerülnek a szelvényre.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),

          BetBuilderSelector(
            selectedSelections:
                _builderSelections,
            onChanged: (
              List<BetBuilderSelection> selections,
            ) {
              setState(() {
                _builderSelections =
                    List<BetBuilderSelection>.from(
                  selections,
                );
              });
            },
          ),          const SizedBox(height: 18),

          AnimatedBuilder(
            animation: _betslipService,
            builder: (context, child) {
              final BetslipItem? savedItem =
                  _betslipService.getItem(match.id);

              final bool hasSavedItem =
                  savedItem != null;

              final bool builderMode =
                  _builderSelections.isNotEmpty;

              return Column(
                children: [
                  if (builderMode)
                    FilledButton.icon(
                      onPressed: _saveBetBuilder,
                      icon: Icon(
                        hasSavedItem &&
                                savedItem.isBetBuilder
                            ? Icons.sync
                            : Icons.add_circle_outline,
                      ),
                      label: Text(
                        hasSavedItem &&
                                savedItem.isBetBuilder
                            ? 'Fogadáskészítő frissítése'
                            : 'Fogadáskészítő hozzáadása',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(58),
                        backgroundColor:
                            Colors.green,
                        foregroundColor:
                            Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        textStyle:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed:
                          _selectedSingleBet == null
                              ? null
                              : _saveSingleBet,
                      icon: Icon(
                        hasSavedItem &&
                                !savedItem.isBetBuilder
                            ? Icons.sync
                            : Icons.add_circle_outline,
                      ),
                      label: Text(
                        hasSavedItem &&
                                !savedItem.isBetBuilder
                            ? 'Egyedi tipp frissítése'
                            : 'Egyedi tipp hozzáadása',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(58),
                        backgroundColor:
                            colors.primary,
                        foregroundColor:
                            Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        textStyle:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                  if (hasSavedItem) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _removeFromBetslip,
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      label: const Text(
                        'Eltávolítás a szelvényről',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(52),
                        foregroundColor:
                            Colors.redAccent,
                        side: const BorderSide(
                          color: Colors.redAccent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        textStyle:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _saveSingleBet() {
    final BetSelection? selectedBet =
        _selectedSingleBet;

    if (selectedBet == null) {
      return;
    }

    final BetslipItem? existingItem =
        _betslipService.getItem(match.id);

    final bool alreadySaved =
        existingItem != null;

    if (alreadySaved) {
      _betslipService.updateItem(
        matchId: match.id,
        market: selectedBet.market,
        selection: selectedBet.selection,
        builderSelections:
            const <BetBuilderSelection>[],
        odds: 0.0,
      );
    } else {
      _betslipService.addMatch(
        match,
        market: selectedBet.market,
        selection: selectedBet.selection,
      );
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved
                ? '${match.homeTeam} – '
                    '${match.awayTeam} egyedi tippje '
                    'frissítve: ${selectedBet.selection}'
                : '${match.homeTeam} – '
                    '${match.awayTeam} hozzáadva: '
                    '${selectedBet.selection}',
          ),
        ),
      );
  }

  void _saveBetBuilder() {
    if (_builderSelections.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Válassz ki legalább egy '
              'Fogadáskészítő tippet.',
            ),
          ),
        );

      return;
    }

    final bool alreadySaved =
        _betslipService.contains(match.id);

    final bool saved =
        _betslipService.saveBetBuilder(
      match,
      selections: _builderSelections,
    );

    if (!saved) {
      return;
    }

    final int averageAi =
        _calculateBuilderAiScore(
      _builderSelections,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved
                ? 'Fogadáskészítő frissítve: '
                    '${_builderSelections.length} tipp, '
                    'AI $averageAi%.'
                : 'Fogadáskészítő hozzáadva: '
                    '${_builderSelections.length} tipp, '
                    'AI $averageAi%.',
          ),
        ),
      );
  }

  void _removeFromBetslip() {
    final bool removed =
        _betslipService.removeMatch(match.id);

    if (!removed) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${match.homeTeam} – '
            '${match.awayTeam} eltávolítva '
            'a szelvényről.',
          ),
        ),
      );
  }

  int _calculateBuilderAiScore(
    List<BetBuilderSelection> selections,
  ) {
    if (selections.isEmpty) {
      return 0;
    }

    final int total =
        selections.fold<int>(
      0,
      (
        int sum,
        BetBuilderSelection selection,
      ) {
        return sum + selection.aiScore;
      },
    );

    return (total / selections.length).round();
  }

  IconData _iconForMarket(
    String market,
  ) {
    final String value =
        market.toLowerCase();

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
}

class _ModeInformationCard
    extends StatelessWidget {
  final bool singleBetSelected;
  final int builderSelectionCount;

  const _ModeInformationCard({
    required this.singleBetSelected,
    required this.builderSelectionCount,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool builderMode =
        builderSelectionCount > 0;

    return Card(
      color: builderMode
          ? Colors.green.withValues(
              alpha: 0.12,
            )
          : colors.primaryContainer
              .withValues(
              alpha: 0.28,
            ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: builderMode
                    ? Colors.green.withValues(
                        alpha: 0.18,
                      )
                    : colors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                builderMode
                    ? Icons.construction_outlined
                    : Icons.touch_app_outlined,
                color: builderMode
                    ? Colors.greenAccent
                    : colors
                        .onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    builderMode
                        ? 'Fogadáskészítő mód'
                        : 'Egyedi tipp mód',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    builderMode
                        ? '$builderSelectionCount '
                            'kiválasztás aktív'
                        : singleBetSelected
                            ? 'Egyetlen tipp kerül '
                                'a szelvényre'
                            : 'Válassz egy tippet',
                    style: TextStyle(
                      color:
                          colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              builderMode
                  ? Icons.check_circle
                  : Icons.radio_button_checked,
              color: builderMode
                  ? Colors.greenAccent
                  : colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedSingleBetCard
    extends StatelessWidget {
  final BetSelection selectedBet;
  final int aiScore;

  const _SelectedSingleBetCard({
    required this.selectedBet,
    required this.aiScore,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer
          .withValues(
        alpha: 0.35,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                selectedBet.icon,
                color:
                    colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kiválasztott egyedi tipp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    selectedBet.market,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedBet.selection,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                '$aiScore%',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}class _MatchHeaderCard extends StatelessWidget {
  final AppMatch match;

  const _MatchHeaderCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    match.league.isEmpty
                        ? 'Ismeretlen bajnokság'
                        : match.league,
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
                        match.matchTime.isEmpty
                            ? '--:--'
                            : match.matchTime,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'VS',
                        style: TextStyle(
                          color:
                              colors.onSurfaceVariant,
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
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  _formatDate(match.matchDate),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (match.isLive) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(
                    alpha: 0.16,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.redAccent,
                  ),
                ),
                child: const Text(
                  '● ÉLŐ MÉRKŐZÉS',
                  style: TextStyle(
                    color: Colors.redAccent,
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

  String _formatDate(DateTime date) {
    final String year =
        date.year.toString();
    final String month =
        date.month.toString().padLeft(2, '0');
    final String day =
        date.day.toString().padLeft(2, '0');

    return '$year.$month.$day.';
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
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 34,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 11),
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

class _AiRecommendationCard
    extends StatelessWidget {
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

  String get _description {
    if (aiScore >= 90) {
      return 'Az AI több elemzési tényező '
          'alapján kiemelkedően erősnek '
          'értékeli ezt a mérkőzést.';
    }

    if (aiScore >= 80) {
      return 'A forma és a várható '
          'mérkőzéskép alapján erős '
          'fogadási lehetőség lehet.';
    }

    if (aiScore >= 65) {
      return 'A tipp használható lehet, '
          'de több kockázati tényezőt '
          'is érdemes figyelembe venni.';
    }

    return 'Az AI szerint ezen a '
        'mérkőzésen fokozott óvatosság '
        'indokolt.';
  }

  Color _scoreColor() {
    if (aiScore >= 85) {
      return Colors.greenAccent;
    }

    if (aiScore >= 70) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final double progress =
        aiScore.clamp(0, 100) / 100;

    final Color scoreColor =
        _scoreColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                    Icons.psychology,
                    color:
                        colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Zsolt Pro AI elemzés',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$aiScore%',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor:
                    colors.surfaceContainerHighest,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _riskText,
              style: TextStyle(
                color: scoreColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _description,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.primaryContainer
                    .withValues(
                  alpha: 0.28,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'AI alapajánlás: '
                      '1X és több mint 1,5 gól',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer,
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
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
  }class _FormCard extends StatelessWidget {
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
    final ColorScheme colors =
        Theme.of(context).colorScheme;

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
              children: form.map(
                (String result) {
                  return CircleAvatar(
                    radius: 13,
                    backgroundColor:
                        _formColor(result),
                    child: Text(
                      result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              '$score%',
              style: TextStyle(
                color: colors.primary,
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
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          children: List.generate(
            rows.length,
            (int index) {
              final _StatisticRowData row =
                  rows[index];

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
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          row.value,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < rows.length - 1)
                    Divider(
                      height: 1,
                      color: colors.outlineVariant,
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
}
