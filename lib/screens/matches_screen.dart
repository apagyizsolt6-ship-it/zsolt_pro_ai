// ===========================================
// Zsolt Pro AI
// Version: v0.2.5
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

  int _selectedDayIndex = 0;
  String _searchText = '';

  DateTime get _today {
    final DateTime now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  DateTime get _selectedDate {
    return _today.add(
      Duration(days: _selectedDayIndex),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<AppMatch> get _filteredMatches {
    final String normalizedSearch = _searchText.trim().toLowerCase();

    final List<AppMatch> matches = DemoMatches.matches.where((match) {
      final bool correctDate = _isSameDay(
        match.matchDate,
        _selectedDate,
      );

      final bool correctSearch = normalizedSearch.isEmpty ||
          match.homeTeam.toLowerCase().contains(normalizedSearch) ||
          match.awayTeam.toLowerCase().contains(normalizedSearch) ||
          match.league.toLowerCase().contains(normalizedSearch);

      return correctDate && correctSearch;
    }).toList();

    matches.sort(
      (first, second) => first.matchTime.compareTo(second.matchTime),
    );

    return matches;
  }

  Map<String, List<AppMatch>> _groupMatchesByLeague(
    List<AppMatch> matches,
  ) {
    final Map<String, List<AppMatch>> groupedMatches = {};

    for (final AppMatch match in matches) {
      groupedMatches.putIfAbsent(
        match.league,
        () => <AppMatch>[],
      );

      groupedMatches[match.league]!.add(match);
    }

    return groupedMatches;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<AppMatch> matches = _filteredMatches;

    final Map<String, List<AppMatch>> groupedMatches =
        _groupMatchesByLeague(matches);

    final List<String> leagues = groupedMatches.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meccsek',
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
          const SizedBox(height: 8),
          Expanded(
            child: matches.isEmpty
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
                      final String leagueName = leagues[leagueIndex];

                      final List<AppMatch> leagueMatches =
                          groupedMatches[leagueName] ?? <AppMatch>[];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LeagueHeader(
                            leagueName: leagueName,
                          ),
                          ...leagueMatches.map(
                            (match) {
                              return MatchCard(
                                match: match,
                                onTap: () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${match.homeTeam} – '
                                        '${match.awayTeam}',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer_outlined,
              size: 76,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 18),
            const Text(
              'Nincs megjeleníthető mérkőzés',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Válassz másik napot, vagy módosítsd a keresést.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
