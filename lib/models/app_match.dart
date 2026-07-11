// ===========================================
// Zsolt Pro AI
// Version: v0.13.5
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

  final String homeTeamLogoUrl;
  final String awayTeamLogoUrl;
  final String leagueLogoUrl;

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
    this.homeTeamLogoUrl = '',
    this.awayTeamLogoUrl = '',
    this.leagueLogoUrl = '',
  });

  bool get hasHomeTeamLogo {
    return homeTeamLogoUrl.trim().isNotEmpty;
  }

  bool get hasAwayTeamLogo {
    return awayTeamLogoUrl.trim().isNotEmpty;
  }

  bool get hasLeagueLogo {
    return leagueLogoUrl.trim().isNotEmpty;
  }

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
    String? homeTeamLogoUrl,
    String? awayTeamLogoUrl,
    String? leagueLogoUrl,
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
      homeTeamLogoUrl:
          homeTeamLogoUrl ?? this.homeTeamLogoUrl,
      awayTeamLogoUrl:
          awayTeamLogoUrl ?? this.awayTeamLogoUrl,
      leagueLogoUrl:
          leagueLogoUrl ?? this.leagueLogoUrl,
    );
  }
}
