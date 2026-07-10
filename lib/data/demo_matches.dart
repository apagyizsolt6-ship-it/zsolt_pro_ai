// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/data/demo_matches.dart
// ===========================================

import '../models/app_match.dart';

class DemoMatches {
  static List<AppMatch> get matches => [
        AppMatch(
          id: "1",
          league: "Premier League",
          homeTeam: "Arsenal",
          awayTeam: "Chelsea",
          matchDate: DateTime(2026, 7, 10),
          matchTime: "18:30",
          aiScore: 94,
        ),
        AppMatch(
          id: "2",
          league: "La Liga",
          homeTeam: "Barcelona",
          awayTeam: "Sevilla",
          matchDate: DateTime(2026, 7, 10),
          matchTime: "21:00",
          aiScore: 91,
        ),
        AppMatch(
          id: "3",
          league: "Serie A",
          homeTeam: "Inter",
          awayTeam: "Milan",
          matchDate: DateTime(2026, 7, 11),
          matchTime: "20:45",
          aiScore: 89,
        ),
        AppMatch(
          id: "4",
          league: "Bundesliga",
          homeTeam: "Bayern München",
          awayTeam: "RB Leipzig",
          matchDate: DateTime(2026, 7, 12),
          matchTime: "18:30",
          aiScore: 87,
        ),
        AppMatch(
          id: "5",
          league: "Ligue 1",
          homeTeam: "PSG",
          awayTeam: "Lyon",
          matchDate: DateTime(2026, 7, 13),
          matchTime: "21:00",
          aiScore: 90,
        ),
      ];
}
