// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
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

  static const List<Map<String, String>> days = [
    {"day": "P", "date": "10.07"},
    {"day": "Szo", "date": "11.07"},
    {"day": "V", "date": "12.07"},
    {"day": "H", "date": "13.07"},
    {"day": "K", "date": "14.07"},
    {"day": "Sze", "date": "15.07"},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              width: 82,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blue
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index]["day"]!,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index]["date"]!,
                    style: TextStyle(
                      color: selected
                          ? Colors.white70
                          : Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
