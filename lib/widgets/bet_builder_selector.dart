// ===========================================
// Zsolt Pro AI
// Version: v0.9.0
// File: lib/widgets/bet_builder_selector.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/bet_builder_selection.dart';

class BetBuilderSelector extends StatelessWidget {
  final List<BetBuilderSelection> selectedSelections;
  final ValueChanged<List<BetBuilderSelection>> onChanged;

  const BetBuilderSelector({
    super.key,
    required this.selectedSelections,
    required this.onChanged,
  });

  static const List<_BuilderMarketGroup> _marketGroups = [
    _BuilderMarketGroup(
      title: 'Gólok',
      icon: Icons.sports_soccer,
      options: [
        BetBuilderSelection(
          market: 'Összes gól',
          selection: 'Több mint 1,5 gól',
          aiScore: 84,
        ),
        BetBuilderSelection(
          market: 'Összes gól',
          selection: 'Több mint 2,5 gól',
          aiScore: 78,
        ),
        BetBuilderSelection(
          market: 'Összes gól',
          selection: 'Több mint 3,5 gól',
          aiScore: 66,
        ),
        BetBuilderSelection(
          market: 'Összes gól',
          selection: 'Kevesebb mint 3,5 gól',
          aiScore: 74,
        ),
      ],
    ),
    _BuilderMarketGroup(
      title: 'Mindkét csapat szerez gólt',
      icon: Icons.groups_outlined,
      options: [
        BetBuilderSelection(
          market: 'Mindkét csapat szerez gólt',
          selection: 'Igen',
          aiScore: 79,
        ),
        BetBuilderSelection(
          market: 'Mindkét csapat szerez gólt',
          selection: 'Nem',
          aiScore: 65,
        ),
      ],
    ),
    _BuilderMarketGroup(
      title: 'Dupla esély',
      icon: Icons.compare_arrows,
      options: [
        BetBuilderSelection(
          market: 'Dupla esély',
          selection: '1X – Hazai vagy döntetlen',
          aiScore: 82,
        ),
        BetBuilderSelection(
          market: 'Dupla esély',
          selection: 'X2 – Döntetlen vagy vendég',
          aiScore: 77,
        ),
        BetBuilderSelection(
          market: 'Dupla esély',
          selection: '12 – Hazai vagy vendég',
          aiScore: 73,
        ),
      ],
    ),
    _BuilderMarketGroup(
      title: 'Büntetőlapok',
      icon: Icons.style_outlined,
      options: [
        BetBuilderSelection(
          market: 'Összes büntetőlap',
          selection: 'Több mint 2,5 lap',
          aiScore: 86,
        ),
        BetBuilderSelection(
          market: 'Összes büntetőlap',
          selection: 'Több mint 3,5 lap',
          aiScore: 81,
        ),
        BetBuilderSelection(
          market: 'Összes büntetőlap',
          selection: 'Több mint 4,5 lap',
          aiScore: 73,
        ),
        BetBuilderSelection(
          market: 'Csapat büntetőlapjai',
          selection: 'Hazai csapat kap több lapot',
          aiScore: 68,
        ),
        BetBuilderSelection(
          market: 'Csapat büntetőlapjai',
          selection: 'Vendégcsapat kap több lapot',
          aiScore: 67,
        ),
      ],
    ),
    _BuilderMarketGroup(
      title: 'Szögletek',
      icon: Icons.flag_outlined,
      options: [
        BetBuilderSelection(
          market: 'Összes szöglet',
          selection: 'Több mint 8,5 szöglet',
          aiScore: 85,
        ),
        BetBuilderSelection(
          market: 'Összes szöglet',
          selection: 'Több mint 9,5 szöglet',
          aiScore: 79,
        ),
        BetBuilderSelection(
          market: 'Összes szöglet',
          selection: 'Több mint 10,5 szöglet',
          aiScore: 70,
        ),
        BetBuilderSelection(
          market: 'Csapat szögletei',
          selection: 'Hazai csapat végez el több szögletet',
          aiScore: 72,
        ),
        BetBuilderSelection(
          market: 'Csapat szögletei',
          selection: 'Vendégcsapat végez el több szögletet',
          aiScore: 69,
        ),
      ],
    ),
    _BuilderMarketGroup(
      title: 'Lesek',
      icon: Icons.block_outlined,
      options: [
        BetBuilderSelection(
          market: 'Összes les',
          selection: 'Több mint 2,5 les',
          aiScore: 76,
        ),
        BetBuilderSelection(
          market: 'Összes les',
          selection: 'Több mint 3,5 les',
          aiScore: 69,
        ),
        BetBuilderSelection(
          market: 'Csapat lesei',
          selection: 'Hazai csapat kerül többször lesre',
          aiScore: 64,
        ),
        BetBuilderSelection(
          market: 'Csapat lesei',
          selection: 'Vendégcsapat kerül többször lesre',
          aiScore: 63,
        ),
      ],
    ),
    _BuilderMarketGroup(
      title: 'Szabálytalanságok',
      icon: Icons.warning_amber_rounded,
      options: [
        BetBuilderSelection(
          market: 'Összes szabálytalanság',
          selection: 'Több mint 20,5 szabálytalanság',
          aiScore: 84,
        ),
        BetBuilderSelection(
          market: 'Összes szabálytalanság',
          selection: 'Több mint 24,5 szabálytalanság',
          aiScore: 77,
        ),
        BetBuilderSelection(
          market: 'Összes szabálytalanság',
          selection: 'Több mint 28,5 szabálytalanság',
          aiScore: 68,
        ),
        BetBuilderSelection(
          market: 'Csapat szabálytalanságai',
          selection: 'Hazai csapat követ el többet',
          aiScore: 70,
        ),
        BetBuilderSelection(
          market: 'Csapat szabálytalanságai',
          selection: 'Vendégcsapat követ el többet',
          aiScore: 69,
        ),
      ],
    ),
  ];

  bool _isSelected(BetBuilderSelection option) {
    return selectedSelections.any(
      (selected) =>
          selected.market == option.market &&
          selected.selection == option.selection,
    );
  }

  void _toggleSelection(BetBuilderSelection option) {
    final List<BetBuilderSelection> updatedSelections =
        List<BetBuilderSelection>.from(selectedSelections);

    final int existingIndex = updatedSelections.indexWhere(
      (selected) =>
          selected.market == option.market &&
          selected.selection == option.selection,
    );

    if (existingIndex >= 0) {
      updatedSelections.removeAt(existingIndex);
    } else {
      updatedSelections.add(option);
    }

    onChanged(
      List<BetBuilderSelection>.unmodifiable(updatedSelections),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BuilderSummaryCard(
          selectedSelections: selectedSelections,
        ),
        const SizedBox(height: 14),
        ..._marketGroups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BuilderMarketCard(
              group: group,
              isSelected: _isSelected,
              onToggle: _toggleSelection,
            ),
          ),
        ),
      ],
    );
  }
}

class _BuilderSummaryCard extends StatelessWidget {
  final List<BetBuilderSelection> selectedSelections;

  const _BuilderSummaryCard({
    required this.selectedSelections,
  });

  int get _averageAiScore {
    if (selectedSelections.isEmpty) {
      return 0;
    }

    final int total = selectedSelections.fold<int>(
      0,
      (sum, selection) => sum + selection.aiScore,
    );

    return (total / selectedSelections.length).round();
  }

  String get _riskText {
    if (_averageAiScore >= 85) {
      return 'Nagyon erős';
    }

    if (_averageAiScore >= 75) {
      return 'Jó';
    }

    if (_averageAiScore >= 60) {
      return 'Közepes kockázat';
    }

    return 'Magas kockázat';
  }

  Color _scoreColor() {
    if (_averageAiScore >= 85) {
      return Colors.greenAccent;
    }

    if (_averageAiScore >= 75) {
      return Colors.lightGreenAccent;
    }

    if (_averageAiScore >= 60) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.construction_outlined,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fogadáskészítő',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedSelections.isEmpty
                        ? 'Még nincs kiválasztott tipp'
                        : '${selectedSelections.length} kiválasztott tipp',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (selectedSelections.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'AI minősítés: $_riskText',
                      style: TextStyle(
                        color: _scoreColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _scoreColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                selectedSelections.isEmpty
                    ? '0 db'
                    : '$_averageAiScore%',
                style: TextStyle(
                  color: _scoreColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderMarketCard extends StatelessWidget {
  final _BuilderMarketGroup group;
  final bool Function(BetBuilderSelection option) isSelected;
  final ValueChanged<BetBuilderSelection> onToggle;

  const _BuilderMarketCard({
    required this.group,
    required this.isSelected,
    required this.onToggle,
  });

  int get _selectedCount {
    return group.options.where(isSelected).length;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            group.icon,
            color: colors.onPrimaryContainer,
          ),
        ),
        title: Text(
          group.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _selectedCount == 0
              ? 'Nincs kiválasztva'
              : '$_selectedCount kiválasztva',
          style: TextStyle(
            color: _selectedCount > 0
                ? colors.primary
                : colors.onSurfaceVariant,
            fontWeight: _selectedCount > 0
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        children: [
          const Divider(height: 1),
          ...group.options.map(
            (option) {
              final bool selected = isSelected(option);

              return InkWell(
                onTap: () {
                  onToggle(option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    10,
                  ),
                  color: selected
                      ? colors.primaryContainer.withValues(alpha: 0.35)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: (_) {
                          onToggle(option);
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.selection,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              option.market,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _aiColor(option.aiScore)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${option.aiScore}%',
                          style: TextStyle(
                            color: _aiColor(option.aiScore),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _aiColor(int score) {
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
}

class _BuilderMarketGroup {
  final String title;
  final IconData icon;
  final List<BetBuilderSelection> options;

  const _BuilderMarketGroup({
    required this.title,
    required this.icon,
    required this.options,
  });
}
