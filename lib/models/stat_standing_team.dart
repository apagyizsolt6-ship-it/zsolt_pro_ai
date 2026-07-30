// ============================================================================
// Zsolt Pro AI - StatStandingTeam Model
// File: lib/models/stat_standing_team.dart
// ============================================================================

class StatStandingTeam {
  final int position;
  final String name;
  final int played;
  final int points;
  final int goalDifference;

  const StatStandingTeam({
    required this.position,
    required this.name,
    required this.played,
    required this.points,
    required this.goalDifference,
  });

  factory StatStandingTeam.fromJson(Map<String, dynamic> json) {
    return StatStandingTeam(
      position: json['position'] ?? 0,
      name: json['name'] ?? 'Ismeretlen',
      played: json['played'] ?? 0,
      points: json['points'] ?? 0,
      goalDifference: json['goal_difference'] ?? json['gd'] ?? 0,
    );
  }
}
