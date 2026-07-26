// ===========================================
// Zsolt Pro AI
// Version: v0.16.0 - Livescore & Results Extension
// File: lib/models/app_match.dart
// ===========================================

enum MatchDataSource {
  sportMonks,
  theSportsDb,
  demo,
  unknown,
}

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

  /// Élő eredmények és végeredmény mezők
  final int homeScore;
  final int awayScore;
  final String minute;

  /// Az alkalmazáson belüli adatforrás.
  final MatchDataSource dataSource;

  /// Az eredeti mérkőzésazonosító az API-ban.
  final String externalMatchId;

  /// Az eredeti ligaazonosító az API-ban.
  final String externalLeagueId;

  /// A hazai csapat eredeti API-azonosítója.
  final String homeTeamId;

  /// A vendégcsapat eredeti API-azonosítója.
  final String awayTeamId;

  /// Opcionális szezonazonosító.
  final String seasonId;

  /// Opcionális ország.
  final String country;

  /// Opcionális stadion vagy helyszín.
  final String venue;

  /// Opcionális mérkőzésállapot (NS, LIVE, HT, FT, POSTP stb.).
  final String status;

  /// Van-e már részletes statisztikai adat a meccshez.
  final bool hasStatistics;

  /// Van-e már valódi oddsadat a meccshez.
  final bool hasOdds;

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
    this.homeScore = 0,
    this.awayScore = 0,
    this.minute = '',
    this.dataSource = MatchDataSource.unknown,
    this.externalMatchId = '',
    this.externalLeagueId = '',
    this.homeTeamId = '',
    this.awayTeamId = '',
    this.seasonId = '',
    this.country = '',
    this.venue = '',
    this.status = '',
    this.hasStatistics = false,
    this.hasOdds = false,
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
    String? homeTeamLogoUrl,
    String? awayTeamLogoUrl,
    String? leagueLogoUrl,
    int? homeScore,
    int? awayScore,
    String? minute,
    MatchDataSource? dataSource,
    String? externalMatchId,
    String? externalLeagueId,
    String? homeTeamId,
    String? awayTeamId,
    String? seasonId,
    String? country,
    String? venue,
    String? status,
    bool? hasStatistics,
    bool? hasOdds,
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
      homeTeamLogoUrl: homeTeamLogoUrl ?? this.homeTeamLogoUrl,
      awayTeamLogoUrl: awayTeamLogoUrl ?? this.awayTeamLogoUrl,
      leagueLogoUrl: leagueLogoUrl ?? this.leagueLogoUrl,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      minute: minute ?? this.minute,
      dataSource: dataSource ?? this.dataSource,
      externalMatchId: externalMatchId ?? this.externalMatchId,
      externalLeagueId: externalLeagueId ?? this.externalLeagueId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      seasonId: seasonId ?? this.seasonId,
      country: country ?? this.country,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      hasStatistics: hasStatistics ?? this.hasStatistics,
      hasOdds: hasOdds ?? this.hasOdds,
    );
  }

  /// Igaz, ha a mérkőzés már véget ért.
  bool get isFinished {
    final String s = status.trim().toUpperCase();
    return s == 'FT' || s == 'AET' || s == 'PEN' || s == 'FINISHED';
  }

  bool get hasExternalMatchId {
    return externalMatchId.trim().isNotEmpty;
  }

  bool get hasTeamIds {
    return homeTeamId.trim().isNotEmpty && awayTeamId.trim().isNotEmpty;
  }

  bool get isSportMonksMatch {
    return dataSource == MatchDataSource.sportMonks;
  }

  bool get isTheSportsDbMatch {
    return dataSource == MatchDataSource.theSportsDb;
  }

  bool get canLoadDetailedStatistics {
    return hasExternalMatchId || hasTeamIds;
  }

  String get dataSourceLabel {
    return switch (dataSource) {
      MatchDataSource.sportMonks => 'SportMonks',
      MatchDataSource.theSportsDb => 'TheSportsDB',
      MatchDataSource.demo => 'Tesztadat',
      MatchDataSource.unknown => 'Ismeretlen',
    };
  }

  String get matchTitle {
    return '$homeTeam – $awayTeam';
  }

  String get uniqueComparisonKey {
    final String normalizedHome = _normalizeText(homeTeam);
    final String normalizedAway = _normalizeText(awayTeam);

    final String year = matchDate.year.toString().padLeft(4, '0');
    final String month = matchDate.month.toString().padLeft(2, '0');
    final String day = matchDate.day.toString().padLeft(2, '0');

    return '$normalizedHome|$normalizedAway|$year-$month-$day';
  }

  static String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ő', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ű', 'u')
        .replaceAll('æ', 'ae')
        .replaceAll('ø', 'o')
        .replaceAll('å', 'a')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  String toString() {
    return 'AppMatch('
        'id: $id, '
        'match: $homeTeam - $awayTeam, '
        'league: $league, '
        'date: $matchDate, '
        'time: $matchTime, '
        'aiScore: $aiScore, '
        'source: $dataSourceLabel'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppMatch && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
