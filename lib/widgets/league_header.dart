// ===========================================
// Zsolt Pro AI
// Version: v0.3.0 - Favorite League Header
// File: lib/widgets/league_header.dart
// ===========================================

import 'package:flutter/material.dart';

import '../services/favorite_leagues_service.dart';
import '../utils/league_translator.dart';

class LeagueHeader extends StatefulWidget {
  final String leagueName;

  const LeagueHeader({
    super.key,
    required this.leagueName,
  });

  @override
  State<LeagueHeader> createState() => _LeagueHeaderState();
}

class _LeagueHeaderState extends State<LeagueHeader> {
  bool get _isFavorite {
    return FavoriteLeaguesService.isFavorite(widget.leagueName);
  }

  void _toggleFavorite() {
    FavoriteLeaguesService.toggleFavorite(widget.leagueName);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String translatedLeague = LeagueTranslator.translate(widget.leagueName);

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
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Kedvenc bajnokság eltávolítása' : 'Bajnokság hozzáadása a kedvencekhez',
          ),
        ],
      ),
    );
  }
}
