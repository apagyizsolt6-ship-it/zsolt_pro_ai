// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/models/app_match.dart
// ===========================================

class AppMatch {
  final String id;
  final String league;
  final String homeTeam;
  final String awayTeam;
  final DateTime matchDate;
  final String matchTime;
  final int aiScore;
  final bool isFavorite;
  final bool isLive;

  const AppMatch({
    required this.id,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchDate,
    required this.matchTime,
    this.aiScore = 0,
    this.isFavorite = false,
    this.isLive = false,
  });

  AppMatch copyWith({
    String? id,
    String? league,
    String? homeTeam,
    String? awayTeam,
    DateTime? matchDate,
    String? matchTime,
    int? aiScore,
    bool? isFavorite,
    bool? isLive,
  }) {
    return AppMatch(
      id: id ?? this.id,
      league: league ?? this.league,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      matchDate: matchDate ?? this.matchDate,
      matchTime: matchTime ?? this.matchTime,
      aiScore: aiScore ?? this.aiScore,
      isFavorite: isFavorite ?? this.isFavorite,
      isLive: isLive ?? this.isLive,
    );
  }
}
