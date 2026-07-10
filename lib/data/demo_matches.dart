// ===========================================
// Zsolt Pro AI
// Version: v0.4.1
// File: lib/data/demo_matches.dart
// ===========================================

import '../models/app_match.dart';

class DemoMatches {
  DemoMatches._();

  static DateTime get _today {
    final DateTime now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  static DateTime _day(int offset) {
    return _today.add(
      Duration(days: offset),
    );
  }

  static List<AppMatch> get matches {
    return [
      AppMatch(
        id: 'match_001',
        league: 'Premier League',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        matchDate: _day(0),
        matchTime: '18:30',
        aiScore: 94,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_002',
        league: 'Premier League',
        homeTeam: 'Liverpool',
        awayTeam: 'Manchester City',
        matchDate: _day(0),
        matchTime: '20:45',
        aiScore: 91,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_003',
        league: 'La Liga',
        homeTeam: 'Barcelona',
        awayTeam: 'Sevilla',
        matchDate: _day(0),
        matchTime: '21:00',
        aiScore: 89,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_004',
        league: 'Serie A',
        homeTeam: 'Inter',
        awayTeam: 'Milan',
        matchDate: _day(1),
        matchTime: '20:45',
        aiScore: 88,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_005',
        league: 'Bundesliga',
        homeTeam: 'Bayern München',
        awayTeam: 'RB Leipzig',
        matchDate: _day(1),
        matchTime: '18:30',
        aiScore: 87,
        isFavorite:
