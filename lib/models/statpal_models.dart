// ============================================================================
// Zsolt Pro AI - StatPal Data Models (Teljes fájl)
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

class StatStandingTeam {
  final String position;
  final String name;
  final String id;
  final String recentForm;
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsScored;
  final int goalsAllowed;
  final int goalDifference;
  final int points;
  final String? description;

  StatStandingTeam({
    required this.position,
    required this.name,
    required this.id,
    required this.recentForm,
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsScored,
    required this.goalsAllowed,
    required this.goalDifference,
    required this.points,
    this.description,
  });

  factory StatStandingTeam.fromJson(Map<String, dynamic> json) {
    final overall = json['overall'] ?? {};
    final total = json['total'] ?? {};
    final descObj = json['description'];

    return StatStandingTeam(
      position: json['position']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      recentForm: json['recent_form']?.toString() ?? '',
      gamesPlayed: int.tryParse(overall['games_played']?.toString() ?? '0') ?? 0,
      wins: int.tryParse(overall['wins']?.toString() ?? '0') ?? 0,
      draws: int.tryParse(overall['draws']?.toString() ?? '0') ?? 0,
      losses: int.tryParse(overall['losses']?.toString() ?? '0') ?? 0,
      goalsScored: int.tryParse(overall['goals_scored']?.toString() ?? '0') ?? 0,
      goalsAllowed: int.tryParse(overall['goals_allowed']?.toString() ?? '0') ?? 0,
      goalDifference: int.tryParse(total['goal_difference']?.toString() ?? '0') ?? 0,
      points: int.tryParse(total['points']?.toString() ?? '0') ?? 0,
      description: descObj is Map ? descObj['value']?.toString() : descObj?.toString(),
    );
  }
}

class StatPrediction {
  final String choice;
  final String reasoning;
  final String market;
  final String odd;

  StatPrediction({
    required this.choice,
    required this.reasoning,
    required this.market,
    required this.odd,
  });

  factory StatPrediction.fromJson(Map<String, dynamic> json) {
    final predictionObj = json['prediction'] ?? {};
    final oddsObj = predictionObj['prematch_odds'] ?? {};

    return StatPrediction(
      choice: predictionObj['choice']?.toString() ?? '',
      reasoning: predictionObj['reasoning']?.toString() ?? '',
      market: oddsObj['market']?.toString() ?? '',
      odd: oddsObj['odd']?.toString() ?? '',
    );
  }
}
