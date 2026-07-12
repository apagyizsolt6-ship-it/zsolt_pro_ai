// ===========================================
// Zsolt Pro AI
// Version: v0.18.5
// File: lib/models/recognized_betslip.dart
// ===========================================

class RecognizedBetslip {
  final String rawText;
  final String cleanedText;

  final double? totalOdds;
  final double? stake;
  final double? possibleWin;

  final int? matchCount;

  final String? betslipNumber;
  final DateTime? submittedAt;

  final int confidence;
  final List<String> warnings;

  final List<RecognizedMatch> matches;

  const RecognizedBetslip({
    required this.rawText,
    required this.cleanedText,
    required this.matches,
    required this.confidence,
    required this.warnings,
    this.totalOdds,
    this.stake,
    this.possibleWin,
    this.matchCount,
    this.betslipNumber,
    this.submittedAt,
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

  bool get hasBetslipNumber {
    return betslipNumber != null &&
        betslipNumber!.trim().isNotEmpty;
  }

  bool get hasSubmittedAt {
    return submittedAt != null;
  }

  bool get hasWarnings {
    return warnings.isNotEmpty;
  }

  bool get isReliable {
    return confidence >= 70;
  }

  String get confidenceLabel {
    if (confidence >= 90) {
      return 'Nagyon megbízható';
    }

    if (confidence >= 70) {
      return 'Megbízható';
    }

    if (confidence >= 50) {
      return 'Ellenőrzendő';
    }

    return 'Bizonytalan';
  }

  double? get calculatedPossibleWin {
    if (stake == null || totalOdds == null) {
      return null;
    }

    return stake! * totalOdds!;
  }

  RecognizedBetslip copyWith({
    String? rawText,
    String? cleanedText,
    double? totalOdds,
    double? stake,
    double? possibleWin,
    int? matchCount,
    String? betslipNumber,
    DateTime? submittedAt,
    int? confidence,
    List<String>? warnings,
    List<RecognizedMatch>? matches,
  }) {
    return RecognizedBetslip(
      rawText: rawText ?? this.rawText,
      cleanedText:
          cleanedText ?? this.cleanedText,
      totalOdds:
          totalOdds ?? this.totalOdds,
      stake:
          stake ?? this.stake,
      possibleWin:
          possibleWin ?? this.possibleWin,
      matchCount:
          matchCount ?? this.matchCount,
      betslipNumber:
          betslipNumber ?? this.betslipNumber,
      submittedAt:
          submittedAt ?? this.submittedAt,
      confidence:
          confidence ?? this.confidence,
      warnings:
          warnings ?? this.warnings,
      matches:
          matches ?? this.matches,
    );
  }

  @override
  String toString() {
    return 'RecognizedBetslip('
        'betslipNumber: $betslipNumber, '
        'stake: $stake, '
        'totalOdds: $totalOdds, '
        'possibleWin: $possibleWin, '
        'matchCount: $matchCount, '
        'matches: ${matches.length}, '
        'confidence: $confidence'
        ')';
  }
}

class RecognizedMatch {
  final String homeTeam;
  final String awayTeam;

  final String tip;
  final String market;

  final double? odds;

  final int confidence;
  final List<String> sourceLines;

  const RecognizedMatch({
    required this.homeTeam,
    required this.awayTeam,
    required this.tip,
    this.market = '',
    this.odds,
    this.confidence = 0,
    this.sourceLines = const <String>[],
  });

  bool get hasTeams {
    return homeTeam.trim().isNotEmpty &&
        awayTeam.trim().isNotEmpty;
  }

  bool get hasTip {
    return tip.trim().isNotEmpty &&
        tip != 'Ismeretlen tipp';
  }

  bool get hasOdds {
    return odds != null && odds! > 1;
  }

  String get matchTitle {
    return '$homeTeam – $awayTeam';
  }

  RecognizedMatch copyWith({
    String? homeTeam,
    String? awayTeam,
    String? tip,
    String? market,
    double? odds,
    int? confidence,
    List<String>? sourceLines,
  }) {
    return RecognizedMatch(
      homeTeam:
          homeTeam ?? this.homeTeam,
      awayTeam:
          awayTeam ?? this.awayTeam,
      tip:
          tip ?? this.tip,
      market:
          market ?? this.market,
      odds:
          odds ?? this.odds,
      confidence:
          confidence ?? this.confidence,
      sourceLines:
          sourceLines ?? this.sourceLines,
    );
  }

  @override
  String toString() {
    return 'RecognizedMatch('
        '$homeTeam - $awayTeam, '
        'tip: $tip, '
        'odds: $odds'
        ')';
  }
}
