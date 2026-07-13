// ===========================================
// Zsolt Pro AI
// Version: v0.19.3
// File: lib/services/betslip_parser_v5_service.dart
// ===========================================

import 'dart:math' as math;

import '../models/recognized_betslip.dart';

/// Zsolt Pro AI – Tippmix Parser V5.
///
/// Ez a parser a korábbi Parser 4.0 mellett készül.
/// A fő alkalmazás egyelőre továbbra is a régi parsert
/// használja, így a V5 biztonságosan fejleszthető.
///
/// A v0.19.3 verzió már képes:
/// - az OCR-szöveg tisztítására;
/// - Tippmix-szelvény felismerésére;
/// - szelvényszám felismerésére;
/// - játékba küldés időpontjának felismerésére;
/// - fogadások számának felismerésére;
/// - mérkőzések felismerésére;
/// - piac és tipp felismerésére;
/// - meccsenkénti oddsok felismerésére;
/// - eredő odds felismerésére;
/// - tét felismerésére;
/// - maximális nyeremény felismerésére;
/// - matematikai keresztellenőrzésre.
class BetslipParserV5Service {
  BetslipParserV5Service._();

  static final BetslipParserV5Service instance =
      BetslipParserV5Service._();

  RecognizedBetslip parse(
    String rawText,
  ) {
    final String cleanedText =
        cleanOcrText(rawText);

    final List<String> lines =
        extractCleanLines(cleanedText);

    final List<_DetectedMatch> detectedMatches =
        _detectMatches(lines);

    final List<_DecimalCandidate> decimals =
        _collectDecimalCandidates(lines);

    final List<_MoneyCandidate> moneyValues =
        _collectMoneyCandidates(lines);

    final List<double> matchOdds =
        _detectMatchOdds(
      decimals: decimals,
      matchCount: detectedMatches.length,
    );

    final double? totalOdds =
        _detectTotalOdds(
      lines: lines,
      decimals: decimals,
      matchOdds: matchOdds,
    );

    final double? possibleWin =
        _detectPossibleWin(
      lines: lines,
      moneyValues: moneyValues,
      totalOdds: totalOdds,
    );

    final double? stake =
        _detectStake(
      lines: lines,
      moneyValues: moneyValues,
      totalOdds: totalOdds,
      possibleWin: possibleWin,
    );

    final String? betslipNumber =
        _detectBetslipNumber(lines);

    final DateTime? submittedAt =
        _detectSubmittedAt(
      lines: lines,
      matches: detectedMatches,
    );

    final int? printedMatchCount =
        _detectPrintedMatchCount(lines);

    final List<RecognizedMatch> matches =
        _buildRecognizedMatches(
      detectedMatches: detectedMatches,
      matchOdds: matchOdds,
    );

    final int? matchCount =
        matches.isNotEmpty
            ? math.max(
                matches.length,
                printedMatchCount ?? 0,
              )
            : printedMatchCount;

    final int confidence =
        _calculateConfidence(
      rawText: rawText,
      cleanedText: cleanedText,
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      matchCount: matchCount,
      matches: matches,
    );

    final List<String> warnings =
        _buildWarnings(
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      matchCount: matchCount,
      matches: matches,
      confidence: confidence,
    );

    return RecognizedBetslip(
      rawText: rawText,
      cleanedText: cleanedText,
      confidence: confidence,
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      matchCount: matchCount,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      warnings: warnings,
      matches: matches,
    );
  }

  // =========================================================
  // OCR ELŐFELDOLGOZÁS
  // =========================================================

  String cleanOcrText(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return '';
    }

    String result = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\t', ' ')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('−', '-')
        .replaceAll('„', '"')
        .replaceAll('”', '"')
        .replaceAll('“', '"')
        .replaceAll('’', '\'')
        .replaceAll('`', '\'')
        .replaceAll('…', '...')
        .replaceAll(
          RegExp(r'[ ]{2,}'),
          ' ',
        )
        .replaceAll(
          RegExp(r' *\n *'),
          '\n',
        )
        .replaceAll(
          RegExp(r'\n{3,}'),
          '\n\n',
        )
        .trim();

    result = _fixDigitOcrErrors(result);
    result = _fixCommonTippmixWords(result);
    result = _normalizeMoneyFormats(result);
    result = _normalizeTeamSeparators(result);
    result = _removeUselessLines(result);

    return result.trim();
  }

  List<String> extractCleanLines(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return const <String>[];
    }

    return value
        .split('\n')
        .map(
          (String line) => line.trim(),
        )
        .where(
          (String line) => line.isNotEmpty,
        )
        .toList(growable: false);
  }

  bool looksLikeTippmixBetslip(
    String value,
  ) {
    final String normalized =
        normalizeForSearch(value);

    if (normalized.isEmpty) {
      return false;
    }

    const List<String> keywords =
        <String>[
      'tippmix',
      'szelveny',
      'eredo odds',
      'max nyeremeny',
      'jatekba kuldve',
      'jatek ara',
      'alaptet',
      'fogadasszam',
      'ervenyesseg',
      'kombinacio',
      'golszam',
    ];

    int found = 0;

    for (final String keyword in keywords) {
      if (normalized.contains(keyword)) {
        found++;
      }
    }

    return found >= 2;
  }

  String normalizeForSearch(
    String value,
  ) {
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
        .replaceAll(
          RegExp(
            r'[^a-z0-9,.%:+\-\s]',
          ),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  String _fixDigitOcrErrors(
    String value,
  ) {
    String result = value;

    for (int index = 0; index < 4; index++) {
      result = result.replaceAllMapped(
        RegExp(r'(\d)[oO](\d)'),
        (Match match) {
          return '${match.group(1)}0${match.group(2)}';
        },
      );

      result = result.replaceAllMapped(
        RegExp(r'(\d)[lI|](\d)'),
        (Match match) {
          return '${match.group(1)}1${match.group(2)}';
        },
      );
    }

    result = result.replaceAllMapped(
      RegExp(r'(\d)[oO]\b'),
      (Match match) {
        return '${match.group(1)}0';
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'\b[oO](\d)'),
      (Match match) {
        return '0${match.group(1)}';
      },
    );

    return result;
  }

  String _fixCommonTippmixWords(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(
            r'\bered[oó]\s+odds\b',
            caseSensitive: false,
          ),
          'Eredő odds',
        )
        .replaceAll(
          RegExp(
            r'\bered[oó]\s+odas\b',
            caseSensitive: false,
          ),
          'Eredő odds',
        )
        .replaceAll(
          RegExp(
            r'\bmax\.?\s*nyerem[eé]ny\b',
            caseSensitive: false,
          ),
          'Max nyeremény',
        )
        .replaceAll(
          RegExp(
            r'\bj[aá]t[eé]kba\s+k[uü]ldve\b',
            caseSensitive: false,
          ),
          'Játékba küldve',
        )
        .replaceAll(
          RegExp(
            r'\bj[aá]t[eé]k\s+[aá]ra\b',
            caseSensitive: false,
          ),
          'A játék ára',
        )
        .replaceAll(
          RegExp(
            r'\balap\s*t[eé]t\b',
            caseSensitive: false,
          ),
          'Alaptét',
        )
        .replaceAll(
          RegExp(
            r'\bfogad[aá]s\s*sz[aá]m\b',
            caseSensitive: false,
          ),
          'Fogadásszám',
        )
        .replaceAll(
          RegExp(
            r'\bszelv[eé]ny\s+sz[aá]ma\b',
            caseSensitive: false,
          ),
          'Szelvény száma',
        )
        .replaceAll(
          RegExp(
            r'\bg[oó]lsz[aá][mn]\b',
            caseSensitive: false,
          ),
          'Gólszám',
        )
        .replaceAll(
          RegExp(
            r'\bSuper\s+No\s*-\s*a-',
            caseSensitive: false,
          ),
          'Super Nova - ',
        )
        .replaceAll(
          RegExp(
            r'\bSuper\s+No\s*-\s*',
            caseSensitive: false,
          ),
          'Super Nova - ',
        );
  }

  String _normalizeMoneyFormats(
    String value,
  ) {
    String result = value;

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{1,3}(?:[ .][0O]{3})+)\b',
      ),
      (Match match) {
        return (match.group(1) ?? '')
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll('O', '0')
            .replaceAll('o', '0');
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{1,3}(?:[ .]\d{3})+)\b',
      ),
      (Match match) {
        return (match.group(1) ?? '')
            .replaceAll(' ', '')
            .replaceAll('.', '');
      },
    );

    result = result.replaceAll(
      RegExp(
        r'(\d)\s*,\s*-\s*(?:Ft)?',
        caseSensitive: false,
      ),
      r'$1 Ft',
    );

    result = result.replaceAll(
      RegExp(
        r'(\d)\s*Ft\b',
        caseSensitive: false,
      ),
      r'$1 Ft',
    );

    return result;
  }

  String _normalizeTeamSeparators(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(
            r'\s+[vV][sS]\.?\s+',
          ),
          ' - ',
        )
        .replaceAll(
          RegExp(
            r'\s+[vV]\s+',
          ),
          ' - ',
        )
        .replaceAll(
          RegExp(
            r'\s*-\s*a-\s*',
            caseSensitive: false,
          ),
          ' - ',
        );
  }

  String _removeUselessLines(
    String value,
  ) {
    final List<String> result =
        <String>[];

    for (final String rawLine
        in value.split('\n')) {
      final String line =
          rawLine.trim();

      if (line.isEmpty) {
        continue;
      }

      final String content =
          line.replaceAll(
        RegExp(
          r'[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű0-9]',
        ),
        '',
      );

      if (content.isEmpty) {
        continue;
      }

      if (line.length == 1 &&
          !RegExp(r'[0-9Xx]')
              .hasMatch(line)) {
        continue;
      }

      result.add(line);
    }

    return result.join('\n');
  }

  // =========================================================
  // MÉRKŐZÉSEK
  // =========================================================

  List<_DetectedMatch> _detectMatches(
    List<String> lines,
  ) {
    final List<_DetectedMatch> result =
        <_DetectedMatch>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final List<String>? teams =
          _splitMatchLine(lines[index]);

      if (teams == null) {
        continue;
      }

      final String homeTeam =
          _cleanTeamName(teams.first);

      final String awayTeam =
          _cleanTeamName(teams.last);

      if (homeTeam.length < 2 ||
          awayTeam.length < 2) {
        continue;
      }

      final bool duplicate =
          result.any(
        (_DetectedMatch item) {
          return normalizeForSearch(
                    item.homeTeam,
                  ) ==
                  normalizeForSearch(
                    homeTeam,
                  ) &&
              normalizeForSearch(
                    item.awayTeam,
                  ) ==
                  normalizeForSearch(
                    awayTeam,
                  );
        },
      );

      if (duplicate) {
        continue;
      }

      String market = '';
      String tip =
          'Ismeretlen tipp';

      final List<String> sourceLines =
          <String>[];

      final int start =
          math.max(0, index - 4);

      final int end =
          math.min(
        lines.length - 1,
        index + 7,
      );

      for (int nearby = start;
          nearby <= end;
          nearby++) {
        final String line =
            lines[nearby];

        sourceLines.add(line);

        if (market.isEmpty) {
          market = _detectMarket(line);
        }

        if (tip == 'Ismeretlen tipp') {
          final String detectedTip =
              _detectTip(
            line: line,
            market: market,
          );

          if (detectedTip.isNotEmpty) {
            tip = detectedTip;
          }
        }
      }

      if (market.isEmpty &&
          (tip == '6+' ||
              tip.contains('gól'))) {
        market = 'Gólok';
      }

      if (market == 'Gólok' &&
          tip == '6+') {
        tip = '6+ gól';
      }

      result.add(
        _DetectedMatch(
          lineIndex: index,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          market: market,
          tip: tip,
          sourceLines: sourceLines,
        ),
      );
    }

    return result;
  }

  List<String>? _splitMatchLine(
    String line,
  ) {
    String value = line.trim();

    if (value.length < 5 ||
        value.length > 120) {
      return null;
    }

    if (_isMetadataLine(value) ||
        _looksLikeDateLine(value) ||
        _looksLikeMoneyLine(value) ||
        _looksLikeBarcodeLine(value) ||
        _looksLikeAddressLine(value)) {
      return null;
    }

    value = value
        .replaceAll(
          RegExp(
            r'\bSuper\s+No\s*-\s*a-',
            caseSensitive: false,
          ),
          'Super Nova - ',
        )
        .replaceAll(
          RegExp(
            r'\bSuper\s+No\s*-\s*',
            caseSensitive: false,
          ),
          'Super Nova - ',
        )
        .replaceAll(
          RegExp(
            r'\s+-\s+a-',
            caseSensitive: false,
          ),
          ' - ',
        );

    final RegExp expression =
        RegExp(
      r'^(.+?[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű])'
      r'\s*-\s*'
      r'([A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű].+)$',
      caseSensitive: false,
    );

    final RegExpMatch? match =
        expression.firstMatch(value);

    if (match == null) {
      return null;
    }

    final String home =
        (match.group(1) ?? '').trim();

    final String away =
        (match.group(2) ?? '').trim();

    if (_countLetters(home) < 2 ||
        _countLetters(away) < 2) {
      return null;
    }

    return <String>[
      home,
      away,
    ];
  }

  String _cleanTeamName(
    String value,
  ) {
    String result = value
        .replaceAll(
          RegExp(
            r'^[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]+',
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű0-9. ]+$',
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    if (RegExp(
      r'^Super\s+No$',
      caseSensitive: false,
    ).hasMatch(result)) {
      result = 'Super Nova';
    }

    return result;
  }

  String _detectMarket(
    String line,
  ) {
    final String normalized =
        normalizeForSearch(line);

    if (normalized.contains('golszam') ||
        normalized.contains('golszan') ||
        normalized.contains('golok')) {
      return 'Gólok';
    }

    if (normalized.contains('szoglet')) {
      return 'Szögletek';
    }

    if (normalized.contains('lap')) {
      return 'Büntetőlapok';
    }

    if (normalized.contains('les')) {
      return 'Lesek';
    }

    if (normalized.contains(
      'szabalytalansag',
    )) {
      return 'Szabálytalanságok';
    }

    if (normalized.contains(
      'mindket csapat',
    )) {
      return 'Mindkét csapat szerez gólt';
    }

    if (normalized.contains(
      'dupla esely',
    )) {
      return 'Dupla esély';
    }

    return '';
  }

  String _detectTip({
    required String line,
    required String market,
  }) {
    final String normalized =
        normalizeForSearch(line);

    if (RegExp(
      r'(^|[^0-9])6\+($|[^0-9])',
    ).hasMatch(normalized)) {
      return market == 'Gólok'
          ? '6+ gól'
          : '6+';
    }

    final RegExp overUnder =
        RegExp(
      r'(tobb|kevesebb)\s+mint\s+'
      r'(\d+[,.]\d+)',
    );

    final RegExpMatch? match =
        overUnder.firstMatch(normalized);

    if (match != null) {
      final String direction =
          match.group(1) == 'tobb'
              ? 'Több mint'
              : 'Kevesebb mint';

      final String value =
          (match.group(2) ?? '')
              .replaceAll('.', ',');

      return '$direction $value';
    }

    if (normalized == '1' ||
        normalized == 'x' ||
        normalized == '2' ||
        normalized == '1x' ||
        normalized == 'x2' ||
        normalized == '12') {
      return normalized.toUpperCase();
    }

    if (normalized.contains(
      'mindket csapat igen',
    )) {
      return 'Igen';
    }

    if (normalized.contains(
      'mindket csapat nem',
    )) {
      return 'Nem';
    }

    return '';
  }

  // =========================================================
  // SZÁMOK, ODDSOK ÉS PÉNZÉRTÉKEK
  // =========================================================

  List<_DecimalCandidate>
      _collectDecimalCandidates(
    List<String> lines,
  ) {
    final List<_DecimalCandidate> result =
        <_DecimalCandidate>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String line =
          lines[index];

      if (_looksLikeDateLine(line) ||
          _looksLikeBarcodeLine(line) ||
          _looksLikeAddressLine(line)) {
        continue;
      }

      final Iterable<RegExpMatch> matches =
          RegExp(
        r'(^|[^0-9])'
        r'(\d{1,6}[,.]\d{1,3})'
        r'(?=$|[^0-9])',
      ).allMatches(line);

      for (final RegExpMatch match
          in matches) {
        final String raw =
            match.group(2) ?? '';

        final double? value =
            double.tryParse(
          raw.replaceAll(',', '.'),
        );

        if (value == null ||
            value < 1.01 ||
            value > 1000000) {
          continue;
        }

        result.add(
          _DecimalCandidate(
            value: value,
            lineIndex: index,
            line: line,
          ),
        );
      }
    }

    return result;
  }

  List<_MoneyCandidate>
      _collectMoneyCandidates(
    List<String> lines,
  ) {
    final List<_MoneyCandidate> result =
        <_MoneyCandidate>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String line =
          lines[index];

      if (!_looksLikeMoneyLine(line) ||
          _looksLikeAddressLine(line) ||
          _looksLikeBarcodeLine(line)) {
        continue;
      }

      for (final double value
          in _extractMoneyValues(line)) {
        if (value < 10 ||
            value > 1000000000) {
          continue;
        }

        result.add(
          _MoneyCandidate(
            value: value,
            lineIndex: index,
            line: line,
          ),
        );
      }
    }

    return result;
  }

  List<double> _detectMatchOdds({
    required List<_DecimalCandidate>
        decimals,
    required int matchCount,
  }) {
    if (matchCount <= 0) {
      return const <double>[];
    }

    final List<double> result =
        <double>[];

    for (final _DecimalCandidate candidate
        in decimals) {
      if (candidate.value < 1.01 ||
          candidate.value > 30) {
        continue;
      }

      if (_looksLikeMoneyLine(
        candidate.line,
      )) {
        continue;
      }

      final bool duplicate =
          result.any(
        (double value) =>
            (value - candidate.value).abs() <
            0.001,
      );

      if (!duplicate) {
        result.add(candidate.value);
      }

      if (result.length >= matchCount) {
        break;
      }
    }

    return result;
  }

  double? _detectTotalOdds({
    required List<String> lines,
    required List<_DecimalCandidate>
        decimals,
    required List<double> matchOdds,
  }) {
    if (decimals.isEmpty) {
      return null;
    }

    if (matchOdds.length >= 2) {
      final double product =
          matchOdds.fold<double>(
        1,
        (
          double total,
          double value,
        ) {
          return total * value;
        },
      );

      _DecimalCandidate? closest;
      double difference =
          double.infinity;

      for (final _DecimalCandidate candidate
          in decimals) {
        final double currentDifference =
            (candidate.value - product).abs();

        if (currentDifference < difference) {
          difference = currentDifference;
          closest = candidate;
        }
      }

      final double tolerance =
          math.max(
        product * 0.05,
        0.15,
      );

      if (closest != null &&
          difference <= tolerance) {
        return closest.value;
      }
    }

    final int labelIndex =
        _findLabelIndex(
      lines,
      const <String>[
        'eredo odds',
        'eredő odds',
        'ossz odds',
        'össz odds',
      ],
    );

    if (labelIndex >= 0) {
      final List<_DecimalCandidate> nearby =
          decimals.where(
        (_DecimalCandidate item) {
          return (item.lineIndex -
                      labelIndex)
                  .abs() <=
              7;
        },
      ).toList();

      if (nearby.isNotEmpty) {
        nearby.sort(
          (
            _DecimalCandidate first,
            _DecimalCandidate second,
          ) {
            final int firstDistance =
                (first.lineIndex -
                        labelIndex)
                    .abs();

            final int secondDistance =
                (second.lineIndex -
                        labelIndex)
                    .abs();

            return firstDistance.compareTo(
              secondDistance,
            );
          },
        );

        return nearby.first.value;
      }
    }

    final List<double> candidates =
        decimals
            .map(
              (_DecimalCandidate item) =>
                  item.value,
            )
            .where(
              (double value) =>
                  value >= 10 &&
                  value <= 100000,
            )
            .toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort();

    return candidates.last;
  }

  double? _detectPossibleWin({
    required List<String> lines,
    required List<_MoneyCandidate>
        moneyValues,
    required double? totalOdds,
  }) {
    if (moneyValues.isEmpty) {
      return null;
    }

    final int labelIndex =
        _findLabelIndex(
      lines,
      const <String>[
        'max nyeremeny',
        'max nyeremény',
        'maximalis nyeremeny',
        'maximális nyeremény',
      ],
    );

    if (labelIndex >= 0) {
      final List<_MoneyCandidate> nearby =
          moneyValues.where(
        (_MoneyCandidate item) {
          return (item.lineIndex -
                      labelIndex)
                  .abs() <=
              8;
        },
      ).toList();

      if (nearby.isNotEmpty) {
        nearby.sort(
          (
            _MoneyCandidate first,
            _MoneyCandidate second,
          ) {
            return second.value.compareTo(
              first.value,
            );
          },
        );

        return nearby.first.value;
      }
    }

    final List<double> values =
        moneyValues
            .map(
              (_MoneyCandidate item) =>
                  item.value,
            )
            .where(
              (double value) =>
                  value >= 1000,
            )
            .toList();

    if (values.isEmpty) {
      return null;
    }

    values.sort();

    return values.last;
  }

  double? _detectStake({
    required List<String> lines,
    required List<_MoneyCandidate>
        moneyValues,
    required double? totalOdds,
    required double? possibleWin,
  }) {
    if (moneyValues.isEmpty) {
      return null;
    }

    if (totalOdds != null &&
        possibleWin != null &&
        totalOdds > 1) {
      final double expectedStake =
          possibleWin / totalOdds;

      _MoneyCandidate? closest;
      double difference =
          double.infinity;

      for (final _MoneyCandidate candidate
          in moneyValues) {
        if ((candidate.value -
                    possibleWin)
                .abs() <
            0.01) {
          continue;
        }

        final double currentDifference =
            (candidate.value -
                    expectedStake)
                .abs();

        if (currentDifference < difference) {
          difference = currentDifference;
          closest = candidate;
        }
      }

      final double tolerance =
          math.max(
        expectedStake * 0.10,
        30,
      );

      if (closest != null &&
          difference <= tolerance) {
        return closest.value;
      }
    }

    final List<String> labels =
        <String>[
      'alaptet',
      'alaptét',
      'a jatek ara',
      'a játék ára',
      'fogadasi tet',
      'fogadási tét',
    ];

    for (final String label in labels) {
      final int labelIndex =
          _findLabelIndex(
        lines,
        <String>[label],
      );

      if (labelIndex < 0) {
        continue;
      }

      final List<_MoneyCandidate> nearby =
          moneyValues.where(
        (_MoneyCandidate item) {
          if ((item.lineIndex -
                      labelIndex)
                  .abs() >
              8) {
            return false;
          }

          if (possibleWin != null &&
              (item.value -
                          possibleWin)
                      .abs() <
                  0.01) {
            return false;
          }

          return item.value >= 50 &&
              item.value <= 10000000;
        },
      ).toList();

      if (nearby.isNotEmpty) {
        return _mostFrequentMoneyValue(
          nearby,
        );
      }
    }

    final List<_MoneyCandidate> candidates =
        moneyValues.where(
      (_MoneyCandidate item) {
        if (item.value < 50 ||
            item.value > 10000000) {
          return false;
        }

        if (possibleWin != null &&
            (item.value -
                        possibleWin)
                    .abs() <
                0.01) {
          return false;
        }

        return true;
      },
    ).toList();

    if (candidates.isEmpty) {
      return null;
    }

    return _mostFrequentMoneyValue(
      candidates,
    );
  }

  double _mostFrequentMoneyValue(
    List<_MoneyCandidate> candidates,
  ) {
    final Map<int, int> frequency =
        <int, int>{};

    for (final _MoneyCandidate candidate
        in candidates) {
      final int value =
          candidate.value.round();

      frequency[value] =
          (frequency[value] ?? 0) + 1;
    }

    int bestValue =
        candidates.first.value.round();

    int bestCount = 0;

    frequency.forEach(
      (
        int value,
        int count,
      ) {
        if (count > bestCount) {
          bestCount = count;
          bestValue = value;
        } else if (count == bestCount &&
            value < bestValue) {
          bestValue = value;
        }
      },
    );

    return bestValue.toDouble();
  }

  List<double> _extractMoneyValues(
    String line,
  ) {
    final List<double> result =
        <double>[];

    final String cleaned =
        line
            .replaceAll(
              RegExp(
                r'\bFt\b',
                caseSensitive: false,
              ),
              '',
            )
            .replaceAll(',-', '')
            .replaceAll(' ', '');

    final Iterable<RegExpMatch> matches =
        RegExp(
      r'\d+(?:[,.]\d{1,2})?',
    ).allMatches(cleaned);

    for (final RegExpMatch match
        in matches) {
      final String raw =
          match.group(0) ?? '';

      final double? value =
          double.tryParse(
        raw.replaceAll(',', '.'),
      );

      if (value != null) {
        result.add(value);
      }
    }

    return result;
  }

  // =========================================================
  // SZELVÉNYSZÁM ÉS DÁTUM
  // =========================================================

  String? _detectBetslipNumber(
    List<String> lines,
  ) {
    final int labelIndex =
        _findLabelIndex(
      lines,
      const <String>[
        'szelveny szama',
        'szelvény száma',
        'szelvenyszam',
        'szelvényszám',
      ],
    );

    final List<_TextCandidate> candidates =
        <_TextCandidate>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String line =
          lines[index];

      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line) ||
          _looksLikeAddressLine(line)) {
        continue;
      }

      for (final RegExpMatch match
          in RegExp(r'\d+').allMatches(line)) {
        final String value =
            match.group(0) ?? '';

        if (value.length < 6 ||
            value.length > 8) {
          continue;
        }

        candidates.add(
          _TextCandidate(
            value: value,
            lineIndex: index,
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        _TextCandidate first,
        _TextCandidate second,
      ) {
        final bool firstZero =
            first.value.startsWith('0');

        final bool secondZero =
            second.value.startsWith('0');

        if (firstZero && !secondZero) {
          return -1;
        }

        if (!firstZero && secondZero) {
          return 1;
        }

        if (labelIndex >= 0) {
          return (first.lineIndex -
                  labelIndex)
              .abs()
              .compareTo(
                (second.lineIndex -
                        labelIndex)
                    .abs(),
              );
        }

        return first.lineIndex.compareTo(
          second.lineIndex,
        );
      },
    );

    return candidates.first.value;
  }

  DateTime? _detectSubmittedAt({
    required List<String> lines,
    required List<_DetectedMatch> matches,
  }) {
    final List<_DateCandidate> dates =
        <_DateCandidate>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final DateTime? date =
          _parseDateTime(lines[index]);

      if (date == null ||
          (date.hour == 0 &&
              date.minute == 0)) {
        continue;
      }

      dates.add(
        _DateCandidate(
          value: date,
          lineIndex: index,
        ),
      );
    }

    if (dates.isEmpty) {
      return null;
    }

    final int labelIndex =
        _findLabelIndex(
      lines,
      const <String>[
        'jatekba kuldve',
        'játékba küldve',
        'kuldve',
        'küldve',
      ],
    );

    if (labelIndex >= 0) {
      dates.sort(
        (
          _DateCandidate first,
          _DateCandidate second,
        ) {
          return (first.lineIndex -
                  labelIndex)
              .abs()
              .compareTo(
                (second.lineIndex -
                        labelIndex)
                    .abs(),
              );
        },
      );

      return dates.first.value;
    }

    final List<DateTime> matchDates =
        matches
            .map(
              (_DetectedMatch match) =>
                  _findDateInLines(
                match.sourceLines,
              ),
            )
            .whereType<DateTime>()
            .toList();

    final List<_DateCandidate> filtered =
        dates.where(
      (_DateCandidate candidate) {
        return !matchDates.any(
          (DateTime matchDate) =>
              matchDate == candidate.value,
        );
      },
    ).toList();

    if (filtered.isNotEmpty) {
      filtered.sort(
        (
          _DateCandidate first,
          _DateCandidate second,
        ) {
          final bool firstLikely =
              first.value.minute != 0;

          final bool secondLikely =
              second.value.minute != 0;

          if (firstLikely &&
              !secondLikely) {
            return -1;
          }

          if (!firstLikely &&
              secondLikely) {
            return 1;
          }

          return second.lineIndex.compareTo(
            first.lineIndex,
          );
        },
      );

      return filtered.first.value;
    }

    return dates.last.value;
  }

  DateTime? _findDateInLines(
    List<String> lines,
  ) {
    for (final String line in lines) {
      final DateTime? value =
          _parseDateTime(line);

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  DateTime? _parseDateTime(
    String text,
  ) {
    final RegExp expression =
        RegExp(
      r'(20\d{2})[.,/\-]+'
      r'(\d{1,2})[.,/\-]+'
      r'(\d{1,2})'
      r'(?:[., ]+'
      r'(\d{1,2})[:.]'
      r'(\d{2}))?',
    );

    final RegExpMatch? match =
        expression.firstMatch(text);

    if (match == null) {
      return null;
    }

    final int? year =
        int.tryParse(match.group(1) ?? '');

    final int? month =
        int.tryParse(match.group(2) ?? '');

    final int? day =
        int.tryParse(match.group(3) ?? '');

    final int hour =
        int.tryParse(match.group(4) ?? '') ??
            0;

    final int minute =
        int.tryParse(match.group(5) ?? '') ??
            0;

    if (year == null ||
        month == null ||
        day == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    final DateTime value =
        DateTime(
      year,
      month,
      day,
      hour,
      minute,
    );

    if (value.year != year ||
        value.month != month ||
        value.day != day) {
      return null;
    }

    return value;
  }

  int? _detectPrintedMatchCount(
    List<String> lines,
  ) {
    final int labelIndex =
        _findLabelIndex(
      lines,
      const <String>[
        'fogadasszam',
        'fogadásszám',
        'fogadas szam',
        'fogadás szám',
      ],
    );

    if (labelIndex < 0) {
      return null;
    }

    final List<int> values =
        <int>[];

    final int start =
        math.max(0, labelIndex - 5);

    final int end =
        math.min(
      lines.length - 1,
      labelIndex + 8,
    );

    for (int index = start;
        index <= end;
        index++) {
      final String line =
          lines[index];

      if (!RegExp(r'^\d{1,2}$')
          .hasMatch(line)) {
        continue;
      }

      final int? value =
          int.tryParse(line);

      if (value != null &&
          value >= 1 &&
          value <= 50) {
        values.add(value);
      }
    }

    if (values.isEmpty) {
      return null;
    }

    values.sort();

    return values.last;
  }

  // =========================================================
  // MODELL ÉS ELLENŐRZÉS
  // =========================================================

  List<RecognizedMatch>
      _buildRecognizedMatches({
    required List<_DetectedMatch>
        detectedMatches,
    required List<double> matchOdds,
  }) {
    final List<RecognizedMatch> result =
        <RecognizedMatch>[];

    for (int index = 0;
        index < detectedMatches.length;
        index++) {
      final _DetectedMatch detected =
          detectedMatches[index];

      final double? odds =
          index < matchOdds.length
              ? matchOdds[index]
              : null;

      int confidence = 50;

      if (detected.market.isNotEmpty) {
        confidence += 15;
      }

      if (detected.tip !=
          'Ismeretlen tipp') {
        confidence += 15;
      }

      if (odds != null) {
        confidence += 20;
      }

      result.add(
        RecognizedMatch(
          homeTeam: detected.homeTeam,
          awayTeam: detected.awayTeam,
          market: detected.market,
          tip: detected.tip,
          odds: odds,
          confidence:
              confidence.clamp(0, 100),
          sourceLines:
              detected.sourceLines,
        ),
      );
    }

    return result;
  }

  int _calculateConfidence({
    required String rawText,
    required String cleanedText,
    required double? totalOdds,
    required double? stake,
    required double? possibleWin,
    required String? betslipNumber,
    required DateTime? submittedAt,
    required int? matchCount,
    required List<RecognizedMatch> matches,
  }) {
    if (rawText.trim().isEmpty ||
        cleanedText.trim().isEmpty) {
      return 0;
    }

    int score = 10;

    if (looksLikeTippmixBetslip(
      cleanedText,
    )) {
      score += 15;
    }

    if (betslipNumber != null) {
      score += 10;
    }

    if (submittedAt != null) {
      score += 10;
    }

    if (stake != null) {
      score += 10;
    }

    if (totalOdds != null) {
      score += 10;
    }

    if (possibleWin != null) {
      score += 10;
    }

    if (matchCount != null &&
        matchCount > 0) {
      score += 10;
    }

    if (matches.isNotEmpty) {
      score += 10;
    }

    if (matches.isNotEmpty &&
        matches.every(
          (RecognizedMatch match) {
            return match.market.isNotEmpty &&
                match.hasTip;
          },
        )) {
      score += 5;
    }

    if (stake != null &&
        totalOdds != null &&
        possibleWin != null) {
      final double expected =
          stake * totalOdds;

      final double difference =
          (expected - possibleWin).abs();

      final double tolerance =
          math.max(
        possibleWin * 0.05,
        10,
      );

      if (difference <= tolerance) {
        score += 10;
      } else {
        score -= 10;
      }
    }

    return score.clamp(0, 100);
  }

  List<String> _buildWarnings({
    required double? totalOdds,
    required double? stake,
    required double? possibleWin,
    required String? betslipNumber,
    required DateTime? submittedAt,
    required int? matchCount,
    required List<RecognizedMatch> matches,
    required int confidence,
  }) {
    final List<String> warnings =
        <String>[];

    if (betslipNumber == null) {
      warnings.add(
        'A szelvényszámot nem sikerült felismerni.',
      );
    }

    if (submittedAt == null) {
      warnings.add(
        'A játékba küldés időpontját nem sikerült felismerni.',
      );
    }

    if (stake == null) {
      warnings.add(
        'A tétet nem sikerült felismerni.',
      );
    }

    if (totalOdds == null) {
      warnings.add(
        'Az eredő oddsot nem sikerült felismerni.',
      );
    }

    if (possibleWin == null) {
      warnings.add(
        'A maximális nyereményt nem sikerült felismerni.',
      );
    }

    if (matchCount == null ||
        matchCount <= 0) {
      warnings.add(
        'A fogadások számát nem sikerült felismerni.',
      );
    }

    if (matches.isEmpty) {
      warnings.add(
        'A mérkőzéseket nem sikerült elkülöníteni.',
      );
    }

    for (final RecognizedMatch match
        in matches) {
      if (!match.hasOdds) {
        warnings.add(
          '${match.matchTitle}: az odds ellenőrzése szükséges.',
        );
      }

      if (!match.hasTip) {
        warnings.add(
          '${match.matchTitle}: a tipp ellenőrzése szükséges.',
        );
      }

      if (match.market.isEmpty) {
        warnings.add(
          '${match.matchTitle}: a piac ellenőrzése szükséges.',
        );
      }
    }

    if (stake != null &&
        totalOdds != null &&
        possibleWin != null) {
      final double calculated =
          stake * totalOdds;

      final double difference =
          (calculated - possibleWin).abs();

      final double tolerance =
          math.max(
        possibleWin * 0.05,
        10,
      );

      if (difference > tolerance) {
        warnings.add(
          'A tét, az eredő odds és a maximális '
          'nyeremény matematikailag nem egyezik.',
        );
      }
    }

    if (confidence < 50) {
      warnings.add(
        'A felismerés bizonytalan. Készíts '
        'élesebb és egyenesebb képet.',
      );
    }

    return warnings;
  }

  // =========================================================
  // ÁLTALÁNOS SEGÉDFÜGGVÉNYEK
  // =========================================================

  int _findLabelIndex(
    List<String> lines,
    List<String> labels,
  ) {
    for (int index = 0;
        index < lines.length;
        index++) {
      final String normalized =
          normalizeForSearch(
        lines[index],
      );

      for (final String label in labels) {
        if (normalized.contains(
          normalizeForSearch(label),
        )) {
          return index;
        }
      }
    }

    return -1;
  }

  bool _looksLikeDateLine(
    String line,
  ) {
    return RegExp(
      r'20\d{2}[.,/\-]\d{1,2}[.,/\-]\d{1,2}',
    ).hasMatch(line);
  }

  bool _looksLikeMoneyLine(
    String line,
  ) {
    return RegExp(
      r'\b\d[\d .]*(?:[,.]\d{1,2})?\s*(?:,-\s*)?Ft\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  bool _looksLikeBarcodeLine(
    String line,
  ) {
    final String digits =
        line.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.length >= 11) {
      return true;
    }

    final int letters =
        _countLetters(line);

    return digits.length >= 9 &&
        letters == 0;
  }

  bool _looksLikeAddressLine(
    String line,
  ) {
    final String normalized =
        normalizeForSearch(line);

    const List<String> keywords =
        <String>[
      'adoszam',
      'telefon',
      'budapest',
      'godollo',
      'utca',
      'szerencsejatek',
      'zrt',
      'csalogany',
      'erzsebet',
      'sarok delikat',
    ];

    return keywords.any(
      normalized.contains,
    );
  }

  bool _isMetadataLine(
    String line,
  ) {
    final String normalized =
        normalizeForSearch(line);

    const List<String> keywords =
        <String>[
      'szelveny',
      'jatekba kuldve',
      'ervenyesseg',
      'jatek ara',
      'eredo odds',
      'max nyeremeny',
      'kombinacio',
      'fogadasszam',
      'alaptet',
      'osszesen',
      'tippmix',
      'adoszam',
      'legalabb',
      'akcio',
      'orizd meg',
      'szerencsejatek',
    ];

    return keywords.any(
      normalized.contains,
    );
  }

  int _countLetters(
    String value,
  ) {
    return RegExp(
      r'[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]',
    ).allMatches(value).length;
  }
}

// ===========================================================
// BELSŐ SEGÉDOSZTÁLYOK
// ===========================================================

class _DetectedMatch {
  final int lineIndex;
  final String homeTeam;
  final String awayTeam;
  final String market;
  final String tip;
  final List<String> sourceLines;

  const _DetectedMatch({
    required this.lineIndex,
    required this.homeTeam,
    required this.awayTeam,
    required this.market,
    required this.tip,
    required this.sourceLines,
  });
}

class _DecimalCandidate {
  final double value;
  final int lineIndex;
  final String line;

  const _DecimalCandidate({
    required this.value,
    required this.lineIndex,
    required this.line,
  });
}

class _MoneyCandidate {
  final double value;
  final int lineIndex;
  final String line;

  const _MoneyCandidate({
    required this.value,
    required this.lineIndex,
    required this.line,
  });
}

class _TextCandidate {
  final String value;
  final int lineIndex;

  const _TextCandidate({
    required this.value,
    required this.lineIndex,
  });
}

class _DateCandidate {
  final DateTime value;
  final int lineIndex;

  const _DateCandidate({
    required this.value,
    required this.lineIndex,
  });
}
