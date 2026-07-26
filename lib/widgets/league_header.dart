// ===========================================
// Zsolt Pro AI
// Version: v0.2.3 - Translated League Header
// File: lib/widgets/league_header.dart
// ===========================================

import 'package:flutter/material.dart';

import '../utils/league_translator.dart';

class LeagueHeader extends StatelessWidget {
  final String leagueName;

  const LeagueHeader({
    super.key,
    required this.leagueName,
  });

  @override
  Widget build(BuildContext context) {
    final String translatedLeague = LeagueTranslator.translate(leagueName);

    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 10,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              translatedLeague.isEmpty ? 'Ismeretlen bajnokság' : translatedLeague,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
