// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/screens/ai_top5_screen.dart
// ===========================================

import 'package:flutter/material.dart';

class AITop5Screen extends StatelessWidget {
  const AITop5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = [
      {
        "home": "Arsenal",
        "away": "Chelsea",
        "score": 94,
        "tip": "1X + Over 1.5"
      },
      {
        "home": "Barcelona",
        "away": "Sevilla",
        "score": 91,
        "tip": "Hazai győzelem"
      },
      {
        "home": "Bayern",
        "away": "Leipzig",
        "score": 89,
        "tip": "BTTS - Igen"
      },
      {
        "home": "PSG",
        "away": "Lyon",
        "score": 87,
        "tip": "Over 2.5"
      },
      {
        "home": "Inter",
        "away": "Milan",
        "score": 85,
        "tip": "1X"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 AI Top 5"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "${match["home"]} - ${match["away"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  LinearProgressIndicator(
                    value: (match["score"] as int) / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "AI Pontszám: ${match["score"]}/100",
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Ajánlott tipp: ${match["tip"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
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
