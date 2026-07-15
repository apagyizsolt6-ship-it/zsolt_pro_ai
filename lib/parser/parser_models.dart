// ===========================================
// Zsolt Pro AI
// Parser V6.0
// File: parser_models.dart
// ===========================================

class ParsedMatch {
  ParsedMatch({
    required this.homeTeam,
    required this.awayTeam,
    this.market = '',
    this.tip = '',
    this.odds,
    this.lineIndex = -1,
  });

  String homeTeam;
  String awayTeam;

  String market;
  String tip;

  double? odds;

  int lineIndex;

  bool get hasOdds => odds != null;

  bool get hasMarket => market.trim().isNotEmpty;

  bool get isComplete =>
      homeTeam.isNotEmpty &&
      awayTeam.isNotEmpty &&
      hasOdds &&
      hasMarket;
}

class ParsedStake {
  ParsedStake({
    this.amount,
    this.totalOdds,
    this.maxWin,
  });

  double? amount;
  double? totalOdds;
  double? maxWin;
}

class OcrLine {
  OcrLine({
    required this.original,
    required this.cleaned,
    required this.index,
  });

  final String original;
  final String cleaned;
  final int index;
}

class ParserWarnings {
  final List<String> warnings = [];

  void add(String warning) {
    if (!warnings.contains(warning)) {
      warnings.add(warning);
    }
  }

  bool get hasWarnings => warnings.isNotEmpty;
}

class ParserContext {
  ParserContext({
    required this.lines,
  });

  final List<OcrLine> lines;

  final List<ParsedMatch> matches = [];

  final ParsedStake stake = ParsedStake();

  final ParserWarnings warnings = ParserWarnings();

  double confidence = 0.0;
}
