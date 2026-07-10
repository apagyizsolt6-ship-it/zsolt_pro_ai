// ===========================================
// Zsolt Pro AI
// Version: v0.3.4
// File: lib/widgets/filter_bar.dart
// ===========================================

import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final bool favoritesOnly;
  final ValueChanged<bool> onChanged;

  const FilterBar({
    super.key,
    required this.favoritesOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Csak kedvencek',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Switch(
            value: favoritesOnly,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
