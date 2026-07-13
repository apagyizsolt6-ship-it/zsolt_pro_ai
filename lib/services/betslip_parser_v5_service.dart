// ===========================================
// Zsolt Pro AI
// Version: v0.19.0
// File: lib/services/betslip_parser_v5_service.dart
// ===========================================

import '../models/recognized_betslip.dart';

///
/// Parser V5
///
/// Új generációs OCR feldolgozó.
/// A Parser 4.0 mellett fut,
/// ezért biztonságosan fejleszthető.
///
class BetslipParserV5Service {
  BetslipParserV5Service._();

  static final BetslipParserV5Service instance =
      BetslipParserV5Service._();

  RecognizedBetslip parse(
    String rawText,
  ) {
    return RecognizedBetslip(
      rawText: rawText,
      cleanedText: rawText,

      confidence: 0,

      totalOdds: null,
      stake: null,
      possibleWin: null,

      matchCount: null,

      betslipNumber: null,

      submittedAt: null,

      warnings: const [],

      matches: const [],
    );
  }
}
