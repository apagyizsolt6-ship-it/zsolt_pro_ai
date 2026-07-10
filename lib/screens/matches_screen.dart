// ===========================================
// Zsolt Pro AI
// Version: v0.2.1
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../data/demo_matches.dart';
import '../models/app_match.dart';
import '../widgets/day_selector.dart';
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
  String search = "";

  @override
  Widget build(BuildContext context) {
    final List<AppMatch> matches = DemoMatches.matches.where((match) {
      if (search.isEmpty) return true;

      return match.homeTeam.toLowerCase().contains(search.toLowerCase()) ||
          match.awayTeam.toLowerCase().contains(search.toLowerCase()) ||
          match.league.toLowerCase().contains(search.toLowerCase());
    }).toList();

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

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return MatchCard(
                  match: matches[index],
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${matches[index].homeTeam} - ${matches[index].awayTeam}",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
