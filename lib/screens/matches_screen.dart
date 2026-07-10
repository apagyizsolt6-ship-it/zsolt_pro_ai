// ===========================================
// Zsolt Pro AI
// Version: v0.2.0
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../data/demo_matches.dart';
import '../models/app_match.dart';
import '../widgets/day_selector.dart';
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

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      "${match.homeTeam} - ${match.awayTeam}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${match.league}\n🕒 ${match.matchTime}",
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "🤖 ${match.aiScore}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          match.isFavorite
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
