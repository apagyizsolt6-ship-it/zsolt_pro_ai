// ===========================================
// Zsolt Pro AI
// Version: v0.20.5
// File: lib/models/recognized_betslip.dart
// ===========================================

/// A vonalkód és az OCR-felismerés
/// összekapcsolásának aktuális állapota.
enum BetslipIdentificationStatus {
  /// Sem OCR-rel felismert szelvényszám,
  /// sem beolvasott vonalkód nem áll rendelkezésre.
  noIdentification,

  /// Az OCR felismerte a szelvény adatait,
  /// de vonalkód még nincs beolvasva.
  ocrOnly,

  /// A vonalkód beolvasása megtörtént,
  /// de OCR-rel felismert szelvényszám még nincs.
  barcodeOnly,

  /// Az OCR-eredmény és a vonalkód is rendelkezésre áll,
  /// ezért ugyanahhoz a felismeréshez vannak kapcsolva.
  linked,
}

class RecognizedBetslip {
  final String rawText;
  final String cleanedText;

  final double? totalOdds;
  final double? stake;
  final double? possibleWin;

  final int? matchCount;

  final String? betslipNumber;
  final DateTime? submittedAt;

  /// A Tippmix-szelvény kamerával beolvasott
  /// vonalkódjának szöveges értéke.
  final String? barcodeValue;

  /// A beolvasott vonalkód formátuma.
  ///
  /// Példa:
  /// `CODE 128`
  final String? barcodeFormat;

  /// A vonalkód beolvasásának időpontja.
  final DateTime? barcodeScannedAt;

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
    this.barcodeValue,
    this.barcodeFormat,
    this.barcodeScannedAt,
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

  bool get hasBarcode {
    return barcodeValue != null &&
        barcodeValue!.trim().isNotEmpty;
  }

  bool get hasBarcodeFormat {
    return barcodeFormat != null &&
        barcodeFormat!.trim().isNotEmpty;
  }

  bool get hasBarcodeScannedAt {
    return barcodeScannedAt != null;
  }

  bool get hasWarnings {
    return warnings.isNotEmpty;
  }

  bool get isReliable {
    return confidence >= 70;
  }

  /// Megadja, hogy a vonalkód és az OCR-adatok
  /// milyen azonosítási állapotban vannak.
  BetslipIdentificationStatus
      get identificationStatus {
    if (hasBarcode && hasBetslipNumber) {
      return BetslipIdentificationStatus.linked;
    }

    if (hasBarcode) {
      return BetslipIdentificationStatus.barcodeOnly;
    }

    if (hasBetslipNumber) {
      return BetslipIdentificationStatus.ocrOnly;
    }

    return BetslipIdentificationStatus.noIdentification;
  }

  /// Felhasználóbarát magyar szöveg
  /// az aktuális azonosítási állapothoz.
  String get identificationStatusLabel {
    switch (identificationStatus) {
      case BetslipIdentificationStatus.linked:
        return 'Vonalkód és OCR összekapcsolva';

      case BetslipIdentificationStatus.barcodeOnly:
        return 'Vonalkód beolvasva, OCR még nincs';

      case BetslipIdentificationStatus.ocrOnly:
        return 'OCR felismerve, vonalkód nincs';

      case BetslipIdentificationStatus.noIdentification:
        return 'Azonosítás még nem történt';
    }
  }

  /// Rövidebb állapotszöveg olyan helyekhez,
  /// ahol kevés hely áll rendelkezésre.
  String get shortIdentificationStatusLabel {
    switch (identificationStatus) {
      case BetslipIdentificationStatus.linked:
        return 'Összekapcsolva';

      case BetslipIdentificationStatus.barcodeOnly:
        return 'Csak vonalkód';

      case BetslipIdentificationStatus.ocrOnly:
        return 'Csak OCR';

      case BetslipIdentificationStatus.noIdentification:
        return 'Nincs azonosítás';
    }
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

  /// Új vonalkódot kapcsol a felismert szelvényhez.
  RecognizedBetslip attachBarcode({
    required String value,
    String format = 'CODE 128',
    DateTime? scannedAt,
  }) {
    final String cleanedValue =
        value.trim();

    if (cleanedValue.isEmpty) {
      return this;
    }

    return RecognizedBetslip(
      rawText: rawText,
      cleanedText: cleanedText,
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      matchCount: matchCount,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      barcodeValue: cleanedValue,
      barcodeFormat: format.trim().isEmpty
          ? 'CODE 128'
          : format.trim(),
      barcodeScannedAt:
          scannedAt ?? DateTime.now(),
      confidence: confidence,
      warnings: warnings,
      matches: matches,
    );
  }

  /// Eltávolítja a szelvényhez kapcsolt vonalkódot.
  RecognizedBetslip removeBarcode() {
    return RecognizedBetslip(
      rawText: rawText,
      cleanedText: cleanedText,
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      matchCount: matchCount,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      barcodeValue: null,
      barcodeFormat: null,
      barcodeScannedAt: null,
      confidence: confidence,
      warnings: warnings,
      matches: matches,
    );
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
    String? barcodeValue,
    String? barcodeFormat,
    DateTime? barcodeScannedAt,
    int? confidence,
    List<String>? warnings,
    List<RecognizedMatch>? matches,
  }) {
    return RecognizedBetslip(
      rawText:
          rawText ?? this.rawText,
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
      barcodeValue:
          barcodeValue ?? this.barcodeValue,
      barcodeFormat:
          barcodeFormat ?? this.barcodeFormat,
      barcodeScannedAt:
          barcodeScannedAt ??
              this.barcodeScannedAt,
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
        'barcodeValue: $barcodeValue, '
        'barcodeFormat: $barcodeFormat, '
        'identificationStatus: '
        '${identificationStatus.name}, '
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
    return odds != null &&
        odds! > 1;
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
