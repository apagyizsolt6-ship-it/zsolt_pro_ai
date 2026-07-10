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
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_006',
        league: 'Ligue 1',
        homeTeam: 'PSG',
        awayTeam: 'Lyon',
        matchDate: _day(2),
        matchTime: '21:00',
        aiScore: 90,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_007',
        league: 'Bajnokok Ligája',
        homeTeam: 'Real Madrid',
        awayTeam: 'Borussia Dortmund',
        matchDate: _day(2),
        matchTime: '21:00',
        aiScore: 93,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_008',
        league: 'Európa-liga',
        homeTeam: 'Roma',
        awayTeam: 'Tottenham',
        matchDate: _day(3),
        matchTime: '20:45',
        aiScore: 84,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_009',
        league: 'Premier League',
        homeTeam: 'Newcastle',
        awayTeam: 'Aston Villa',
        matchDate: _day(3),
        matchTime: '17:30',
        aiScore: 82,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_010',
        league: 'La Liga',
        homeTeam: 'Atlético Madrid',
        awayTeam: 'Valencia',
        matchDate: _day(4),
        matchTime: '19:00',
        aiScore: 86,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_011',
        league: 'Serie A',
        homeTeam: 'Juventus',
        awayTeam: 'Napoli',
        matchDate: _day(4),
        matchTime: '20:45',
        aiScore: 85,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_012',
        league: 'Bundesliga',
        homeTeam: 'Leverkusen',
        awayTeam: 'Frankfurt',
        matchDate: _day(5),
        matchTime: '18:30',
        aiScore: 83,
        isFavorite: false,
        isLive: false,
      ),
      AppMatch(
        id: 'match_013',
        league: 'Ligue 1',
        homeTeam: 'Marseille',
        awayTeam: 'Monaco',
        matchDate: _day(5),
        matchTime: '21:00',
        aiScore: 81,
        isFavorite: false,
        isLive: false,
      ),
    ];
  }
}
