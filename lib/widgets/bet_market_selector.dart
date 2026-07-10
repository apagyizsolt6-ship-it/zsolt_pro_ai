// ===========================================
// Zsolt Pro AI
// Version: v0.7.0
// File: lib/widgets/bet_market_selector.dart
// ===========================================

import 'package:flutter/material.dart';

class BetSelection {
  final String market;
  final String selection;
  final IconData icon;

  const BetSelection({
    required this.market,
    required this.selection,
    required this.icon,
  });
}

class BetMarketSelector extends StatelessWidget {
  final BetSelection? selectedBet;
  final ValueChanged<BetSelection> onSelected;

  const BetMarketSelector({
    super.key,
    required this.selectedBet,
    required this.onSelected,
  });

  static const List<_BetMarketGroup> _marketGroups = [
    _BetMarketGroup(
      title: 'AI ajánlás',
      icon: Icons.psychology,
      options: [
        BetSelection(
          market: 'AI ajánlott piac',
          selection: '1X és több mint 1,5 gól',
          icon: Icons.auto_awesome,
        ),
        BetSelection(
          market: 'AI biztonságos tipp',
          selection: 'Több mint 1,5 gól',
          icon: Icons.verified_outlined,
        ),
      ],
    ),
    _BetMarketGroup(
      title: '1X2',
      icon: Icons.emoji_events_outlined,
      options: [
        BetSelection(
          market: 'Mérkőzés győztese',
          selection: 'Hazai győzelem',
          icon: Icons.home_outlined,
        ),
        BetSelection(
          market: 'Mérkőzés győztese',
          selection: 'Döntetlen',
          icon: Icons.handshake_outlined,
        ),
        BetSelection(
          market: 'Mérkőzés győztese',
          selection: 'Vendég győzelem',
          icon: Icons.flight_outlined,
        ),
      ],
    ),
    _BetMarketGroup(
      title: 'Dupla esély',
      icon: Icons.compare_arrows,
      options: [
        BetSelection(
          market: 'Dupla esély',
          selection: '1X – Hazai vagy döntetlen',
          icon: Icons.looks_one_outlined,
        ),
        BetSelection(
          market: 'Dupla esély',
          selection: 'X2 – Döntetlen vagy vendég',
          icon: Icons.looks_two_outlined,
        ),
        BetSelection(
          market: 'Dupla esély',
          selection: '12 – Hazai vagy vendég',
          icon: Icons.swap_horiz,
        ),
      ],
    ),
    _BetMarketGroup(
      title: 'Gólok',
      icon: Icons.sports_soccer,
      options: [
        BetSelection(
          market: 'Összes gól',
          selection: 'Több mint 1,5 gól',
          icon: Icons.trending_up,
        ),
        BetSelection(
          market: 'Összes gól',
          selection: 'Több mint 2,5 gól',
          icon: Icons.trending_up,
        ),
        BetSelection(
          market: 'Összes gól',
          selection: 'Több mint 3,5 gól',
          icon: Icons.trending_up,
        ),
        BetSelection(
          market: 'Összes gól',
          selection: 'Kevesebb mint 2,5 gól',
          icon: Icons.trending_down,
        ),
      ],
    ),
    _BetMarketGroup(
      title: 'Mindkét csapat szerez gólt',
      icon: Icons.groups_outlined,
      options: [
        BetSelection(
          market: 'Mindkét csapat szerez gólt',
          selection: 'Igen',
          icon: Icons.check_circle_outline,
        ),
        BetSelection(
          market: 'Mindkét csapat szerez gólt',
          selection: 'Nem',
          icon: Icons.cancel_outlined,
        ),
      ],
    ),
    _BetMarketGroup(
      title: 'Büntetőlapok',
      icon: Icons.style_outlined,
      options: [
        BetSelection(
          market: 'Összes büntetőlap',
          selection: 'Több mint 2,5 lap',
          icon: Icons.style_outlined,
        ),
        BetSelection(
          market: 'Összes büntetőlap',
          selection: 'Több mint 3,5 lap',
          icon: Icons.style_outlined,
        ),
        BetSelection(
          market: 'Összes büntetőlap',
          selection: 'Több mint 4,5 lap',
          icon: Icons.style_outlined,
        ),
        BetSelection(
          market: 'Csapat büntetőlapjai',
          selection: 'Hazai csapat kap több lapot',
          icon: Icons.home_outlined,
        ),
        BetSelection(
          market: 'Csapat büntetőlapjai',
          selection: 'Vendégcsapat kap több lapot',
          icon: Icons.flight_outlined,
        ),
      ],
    ),
    _BetMarketGroup(
      title: 'Szögletek',
      icon: Icons.flag_outlined,
      options: [
        BetSelection(
          market: 'Összes szöglet',
          selection: 'Több mint 8,5 szöglet',
          icon: Icons.flag_outlined,
        ),
        BetSelection(
          market: 'Összes szöglet',
          selection: 'Több mint 9,5 szöglet',
          icon: Icons.flag_outlined,
        ),
        BetSelection(
          market: 'Összes szöglet',
          selection: 'Több mint 10,5 szöglet',
          icon: Icons.flag_outlined,
        ),
        BetSelection(
          market: 'Csapat szögletei',
          selection: 'Hazai csapat végez el több szögletet',
          icon: Icons.home_outlined,
        ),
        BetSelection(
          market: 'Csapat szögletei',
          selection: 'Vendégcsapat végez el több szögletet',
          icon: Icons.flight_outlined,
        ),
      ],
    ),
    _BetMarketGroup(
      title: 'Lesek',
      icon: Icons.block_outlined,
      options: [
        BetSelection(
          market: 'Összes les',
          selection: 'Több mint 2,5 les',
          icon: Icons.block_outlined,
        ),
        BetSelection(
          market: 'Összes les',
          selection: 'Több mint 3,5 les',
          icon: Icons.block_outlined,
        ),
        BetSelection(
          market: 'Csapat lesei',
          selection: 'Hazai csapat kerül többször lesre',
          icon: Icons.home_outlined,
        ),
        BetSelection(
          market: 'Csapat lesei',
          selection: 'Vendégcsapat kerül többször lesre',
          icon: Icons.flight_outlined,
        ),
      ],
    ),
    _BetMarketGroup(
      title: 'Szabálytalanságok',
      icon: Icons.warning_amber_rounded,
      options: [
        BetSelection(
          market: 'Összes szabálytalanság',
          selection: 'Több mint 20,5 szabálytalanság',
          icon: Icons.warning_amber_rounded,
        ),
        BetSelection(
          market: 'Összes szabálytalanság',
          selection: 'Több mint 24,5 szabálytalanság',
          icon: Icons.warning_amber_rounded,
        ),
        BetSelection(
          market: 'Összes szabálytalanság',
          selection: 'Több mint 28,5 szabálytalanság',
          icon: Icons.warning_amber_rounded,
        ),
        BetSelection(
          market: 'Csapat szabálytalanságai',
          selection: 'Hazai csapat követ el többet',
          icon: Icons.home_outlined,
        ),
        BetSelection(
          market: 'Csapat szabálytalanságai',
          selection: 'Vendégcsapat követ el többet',
          icon: Icons.flight_outlined,
        ),
      ],
    ),
  ];

  bool _isSelected(BetSelection option) {
    return selectedBet?.market == option.market &&
        selectedBet?.selection == option.selection;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _marketGroups.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MarketExpansionCard(
            group: group,
            selectedBet: selectedBet,
            isSelected: _isSelected,
            onSelected: onSelected,
          ),
        );
      }).toList(),
    );
  }
}

class _MarketExpansionCard extends StatelessWidget {
  final _BetMarketGroup group;
  final BetSelection? selectedBet;
  final bool Function(BetSelection option) isSelected;
  final ValueChanged<BetSelection> onSelected;

  const _MarketExpansionCard({
    required this.group,
    required this.selectedBet,
    required this.isSelected,
    required this.onSelected,
  });

  bool get _containsSelectedOption {
    return group.options.any(isSelected);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: _containsSelectedOption,
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
        subtitle: _containsSelectedOption
            ? Text(
                selectedBet!.selection,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : const Text('Koppints a tippek megnyitásához'),
        children: [
          const Divider(height: 1),
          ...group.options.map((option) {
            final bool selected = isSelected(option);

            return InkWell(
              onTap: () {
                onSelected(option);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                color: selected
                    ? colors.primaryContainer.withValues(alpha: 0.45)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.selection,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        color: colors.primary,
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked,
                        color: colors.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BetMarketGroup {
  final String title;
  final IconData icon;
  final List<BetSelection> options;

  const _BetMarketGroup({
    required this.title,
    required this.icon,
    required this.options,
  });
}
