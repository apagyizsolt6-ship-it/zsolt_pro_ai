// ===========================================
// Zsolt Pro AI
// Version: v0.3.5
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../data/demo_matches.dart';
import '../models/app_match.dart';
import '../screens/match_detail_screen.dart';
import '../services/favorites_service.dart';
import '../widgets/day_selector.dart';
import '../widgets/filter_bar.dart';
import '../widgets/league_header.dart';
import '../widgets/match_card.dart';
import '../widgets/search_bar_widget.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedDayIndex = 0;
  String _searchText = "";
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppMatch> get _matches {
    final DateTime today = DateTime.now();
    final DateTime selectedDate = DateTime(
      today.year,
      today.month,
      today.day + _selectedDayIndex,
    );

    return DemoMatches.matches.where((match) {
      final bool sameDay =
          match.matchDate.year == selectedDate.year &&
          match.matchDate.month == selectedDate.month &&
          match.matchDate.day == selectedDate.day;

      final bool searchOk =
          _searchText.isEmpty ||
          match.homeTeam.toLowerCase().contains(_searchText.toLowerCase()) ||
          match.awayTeam.toLowerCase().contains(_searchText.toLowerCase()) ||
          match.league.toLowerCase().contains(_searchText.toLowerCase());

      final bool favoriteOk = !_favoritesOnly ||
          FavoritesService.isFavorite(match.id);

      return sameDay && searchOk && favoriteOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;

    final Map<String, List<AppMatch>> grouped = {};

    for (final match in matches) {
      grouped.putIfAbsent(match.league, () => []);
      grouped[match.league]!.add(match);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("⚽ Meccsek"),
        centerTitle: true,
      ),
      body: Column(
        children: [

          SearchBarWidget(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),

          DaySelector(
            selectedIndex: _selectedDayIndex,
            onChanged: (index) {
              setState(() {
                _selectedDayIndex = index;
              });
            },
          ),

          FilterBar(
            favoritesOnly: _favoritesOnly,
            onChanged: (value) {
              setState(() {
                _favoritesOnly = value;
              });
            },
          ),

          Expanded(
            child: matches.isEmpty
                ? const Center(
                    child: Text(
                      "Nincs megjeleníthető mérkőzés.",
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          LeagueHeader(
                            leagueName: entry.key,
                          ),

                          ...entry.value.map(
                            (match) => MatchCard(
                              match: match,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MatchDetailScreen(
                                      match: match,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
