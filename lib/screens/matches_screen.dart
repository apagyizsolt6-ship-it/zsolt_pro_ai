// ===========================================
// Zsolt Pro AI
// Version: v0.2.3
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../data/demo_matches.dart';
import '../models/app_match.dart';
import '../widgets/day_selector.dart';
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

  int selectedDay = 0;
  String search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime get _selectedDate {
    return DateTime(2026, 7, 10).add(
      Duration(days: selectedDay),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedSearch = search.trim().toLowerCase();

    final List<AppMatch> filteredMatches = DemoMatches.matches.where((match) {
      final bool matchesSelectedDate = _isSameDay(
        match.matchDate,
        _selectedDate,
      );

      final bool matchesSearch = normalizedSearch.isEmpty ||
          match.homeTeam.toLowerCase().contains(normalizedSearch) ||
          match.awayTeam.toLowerCase().contains(normalizedSearch) ||
          match.league.toLowerCase().contains(normalizedSearch);

      return matchesSelectedDate && matchesSearch;
    }).toList();

    final Map<String, List<AppMatch>> groupedMatches = {};

    for (final match in filteredMatches) {
      groupedMatches.putIfAbsent(
        match.league,
        () => [],
      );

      groupedMatches[match.league]!.add(match);
    }

    final List<String> leagues = groupedMatches.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚽ Meccsek',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
          ),
          DaySelector(
            selectedIndex: selectedDay,
            onChanged: (index) {
              setState(() {
                selectedDay = index;
              });
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredMatches.isEmpty
                ? const _EmptyMatchesView()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      24,
                    ),
                    itemCount: leagues.length,
                    itemBuilder: (context, leagueIndex) {
                      final String league = leagues[leagueIndex];
                      final List<AppMatch> matches =
                          groupedMatches[league] ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LeagueHeader(
                            leagueName: league,
                          ),
                          ...matches.map(
                            (match) => MatchCard(
                              match: match,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${match.homeTeam} – ${match.awayTeam}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMatchesView extends StatelessWidget {
  const _EmptyMatchesView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Erre a napra nincs található mérkőzés.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Válassz másik napot, vagy módosítsd a keresést.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
