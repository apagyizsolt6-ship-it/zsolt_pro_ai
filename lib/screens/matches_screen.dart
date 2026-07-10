// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("⚽ Meccsek"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Kereső
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Keresés csapatra vagy ligára...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // Napválasztó
          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _dayCard("P", "10.07", true),
                _dayCard("Szo", "11.07", false),
                _dayCard("V", "12.07", false),
                _dayCard("H", "13.07", false),
                _dayCard("K", "14.07", false),
                _dayCard("Sze", "15.07", false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [

                const Text(
                  "🏆 Premier League",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _matchCard(
                  "Arsenal",
                  "Chelsea",
                  "18:30",
                  92,
                ),

                const SizedBox(height: 20),

                const Text(
                  "🏆 La Liga",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _matchCard(
                  "Barcelona",
                  "Sevilla",
                  "21:00",
                  88,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(
    String day,
    String date,
    bool selected,
  ) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(
    String home,
    String away,
    String time,
    int ai,
  ) {
    return Card(
      child: ListTile(
        title: Text("$home  -  $away"),
        subtitle: Text("🕒 $time"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "🤖 $ai",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.star_border,
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }
}
