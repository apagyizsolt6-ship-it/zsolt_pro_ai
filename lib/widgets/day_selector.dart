// ===========================================
// Zsolt Pro AI
// Version: v0.2.4
// File: lib/widgets/day_selector.dart
// ===========================================

import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const DaySelector({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const List<String> _hungarianWeekdays = [
    'H',
    'K',
    'Sze',
    'Cs',
    'P',
    'Szo',
    'V',
  ];

  String _dayName(DateTime date) {
    return _hungarianWeekdays[date.weekday - 1];
  }

  String _dateText(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day.$month';
  }

  List<DateTime> _nextSixDays() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return List<DateTime>.generate(
      6,
      (index) => today.add(
        Duration(days: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = _nextSixDays();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final DateTime date = days[index];
          final bool selected = index == selectedIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 76,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayName(date),
                      style: TextStyle(
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateText(date),
                      style: TextStyle(
                        color: selected
                            ? colorScheme.onPrimary.withValues(alpha: 0.8)
                            : colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
