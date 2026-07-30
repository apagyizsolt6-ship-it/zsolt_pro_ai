// ============================================================================
// Zsolt Pro AI - StatPal Data Models
// File: lib/models/statpal_models.dart
// ============================================================================

class StatLeague {
  final String id;
  final String country;
  final String name;
  final String? season;
  final String? dateStart;
  final String? dateEnd;

  StatLeague({
    required this.id,
    required this.country,
    required this.name,
    this.season,
    this.dateStart,
    this.dateEnd,
  });

  factory StatLeague.fromJson(Map<String, dynamic> json) {
    return StatLeague(
      id: json['id']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      season: json['season']?.toString(),
      dateStart: json['date_start']?.toString(),
      dateEnd: json['date_end']?.toString(),
    );
  }
}

class StatTeamInfo {
  final String id;
  final String name;
  final String? goals;
  final String? score;

  StatTeamInfo({
    required this.id,
    required this.name,
    this.goals,
    this.score,
  });

  factory StatTeamInfo.fromJson(Map<String, dynamic> json) {
    return StatTeamInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      goals: json['goals']?.toString(),
      score: json['score']?.toString(),
    );
  }
}

class StatMatch {
  final String mainId;
  final String status;
  final String date;
  final String time;
  final String? venue;
  final StatTeamInfo home;
  final StatTeamInfo away;

  StatMatch({
    required this.mainId,
    required this.status,
    required this.date,
    required this.time,
    this.venue,
    required this.home,
    required this.away,
  });

  factory StatMatch.fromJson(Map<String, dynamic> json) {
    return StatMatch(
      mainId: json['main_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      venue: json['venue']?.toString(),
      home: StatTeamInfo.fromJson(json['home'] ?? {}),
      away: StatTeamInfo.fromJson(json['away'] ?? {}),
    );
  }
}
