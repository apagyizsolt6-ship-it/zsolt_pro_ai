// ===========================================
// Zsolt Pro AI
// Version: v0.14.0
// File: lib/models/recognized_betslip.dart
// ===========================================

class RecognizedBetslip {
  final String rawText;

  final String cleanedText;

  final double? totalOdds;

  final double? stake;

  final double? possibleWin;

  final int? matchCount;

  final List<RecognizedMatch> matches;

  const RecognizedBetslip({
    required this.rawText,
    required this.cleanedText,
    required this.matches,
    this.totalOdds,
    this.stake,
    this.possibleWin,
    this.matchCount,
  });

  bool get hasMatches {
    return matches.isNotEmpty;
  }

  bool get hasOdds {
    return totalOdds != null;
  }

  bool get hasStake {
    return stake != null;
  }

  bool get hasPossibleWin {
    return possibleWin != null;
  }

  RecognizedBetslip copyWith({
    String? rawText,
    String? cleanedText,
    double? totalOdds,
    double? stake,
    double? possibleWin,
    int? matchCount,
    List<RecognizedMatch>? matches,
  }) {
    return RecognizedBetslip(
      rawText: rawText ?? this.rawText,
      cleanedText: cleanedText ?? this.cleanedText,
      totalOdds: totalOdds ?? this.totalOdds,
      stake: stake ?? this.stake,
      possibleWin: possibleWin ?? this.possibleWin,
      matchCount: matchCount ?? this.matchCount,
      matches: matches ?? this.matches,
    );
  }
}

class RecognizedMatch {
  final String homeTeam;

  final String awayTeam;

  final String tip;

  final double? odds;

  const RecognizedMatch({
    required this.homeTeam,
    required this.awayTeam,
    required this.tip,
    this.odds,
  });
}
