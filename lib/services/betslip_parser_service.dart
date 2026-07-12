// ===========================================
// Zsolt Pro AI
// Version: v0.18.8
// File: lib/services/betslip_parser_service.dart
// ===========================================

import 'dart:math' as math;

import '../models/recognized_betslip.dart';

/// Tippmix papíralapú szelvények OCR-szövegének
/// feldolgozására szolgáló Parser 3.0.
///
/// Főbb fejlesztések:
/// - a címke előtti és utáni értékeket is felismeri;
/// - helyesen keresi az eredő oddsot;
/// - helyesen keresi a maximális nyereményt;
/// - az Alaptét és A játék ára mezőket külön kezeli;
/// - felismeri a játékba küldés időpontját;
/// - a meccsek előtt megjelenő oddsokat is hozzárendeli;
/// - javítja a gyakori Tippmix OCR-hibákat;
/// - külön kezeli a Gólszám, szöglet, lap és les piacokat.
class BetslipParserService {
  BetslipParserService._();

  static final BetslipParserService instance =
      BetslipParserService._();

  RecognizedBetslip parse(
    String rawText,
  ) {
    final String cleanedText =
        cleanText(rawText);

    final List<String> lines =
        _extractLines(cleanedText);

    final double? totalOdds =
        _extractTotalOdds(lines);

    final double? possibleWin =
        _extractPossibleWin(lines);

    final double? stake =
        _extractStake(
      lines,
      possibleWin: possibleWin,
    );

    final String? betslipNumber =
        _extractBetslipNumber(lines);

    final DateTime? submittedAt =
        _extractSubmittedAt(lines);

    List<RecognizedMatch> matches =
        _extractMatches(lines);

    matches = _assignDetachedOdds(
      lines: lines,
      matches: matches,
      totalOdds: totalOdds,
    );

    final int? detectedMatchCount =
        _extractMatchCount(lines);

    final int? matchCount =
        matches.isNotEmpty
            ? math.max(
                matches.length,
                detectedMatchCount ?? 0,
              )
            : detectedMatchCount;

    final int confidence =
        _calculateConfidence(
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      matchCount: matchCount,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      matches: matches,
    );

    final List<String> warnings =
        _buildWarnings(
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      matchCount: matchCount,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      matches: matches,
      confidence: confidence,
    );

    return RecognizedBetslip(
      rawText: rawText,
      cleanedText: cleanedText,
      totalOdds: totalOdds,
      stake: stake,
      possibleWin: possibleWin,
      matchCount: matchCount,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      confidence: confidence,
      warnings: warnings,
      matches: matches,
    );
  }

  String cleanText(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return '';
    }

    String result = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('−', '-')
        .replaceAll('„', '"')
        .replaceAll('”', '"')
        .replaceAll('’', '\'')
        .replaceAll(
          RegExp(r'[ \t]+'),
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

    result = _fixCommonOcrErrors(
      result,
    );

    return result;
  }

  bool looksLikeTippmixBetslip(
    String text,
  ) {
    final String normalized =
        _normalizeForSearch(text);

    if (normalized.isEmpty) {
      return false;
    }

    const List<String> keywords =
        <String>[
      'tippmix',
      'szelveny',
      'jatekba kuldve',
      'ervenyesseg',
      'jatek ara',
      'eredo odds',
      'max nyeremeny',
      'kombinacio',
      'fogadasszam',
      'alaptet',
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

  List<String> _extractLines(
    String text,
  ) {
    if (text.trim().isEmpty) {
      return const <String>[];
    }

    return text
        .split('\n')
        .map(
          (String line) => line.trim(),
        )
        .where(
          (String line) => line.isNotEmpty,
        )
        .toList(growable: false);
  }

  double? _extractTotalOdds(
    List<String> lines,
  ) {
    final int labelIndex =
        _findLabelIndex(
      lines,
      const <String>[
        'eredo odds',
        'eredő odds',
        'eredo odas',
        'eredő odas',
        'ossz odds',
        'össz odds',
        'kombinalt odds',
        'kombinált odds',
      ],
    );

    if (labelIndex >= 0) {
      final double? nearbyValue =
          _findNearbyDecimal(
        lines: lines,
        centerIndex: labelIndex,
        backwardDistance: 5,
        forwardDistance: 5,
        minimum: 1.01,
        maximum: 100000,
        rejectMoneyLines: true,
        rejectDateLines: true,
      );

      if (nearbyValue != null) {
        return nearbyValue;
      }
    }

    final List<double> candidates =
        <double>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String line =
          lines[index];

      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line)) {
        continue;
      }

      for (final double value
          in _extractDecimalNumbers(line)) {
        if (value >= 10 &&
            value <= 100000) {
          candidates.add(value);
        }
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort();

    return candidates.last;
  }

  double? _extractPossibleWin(
    List<String> lines,
  ) {
    final int labelIndex =
        _findLabelIndex(
      lines,
      const <String>[
        'max nyeremeny',
        'max nyeremény',
        'maximalis nyeremeny',
        'maximális nyeremény',
        'varhato nyeremeny',
        'várható nyeremény',
      ],
    );

    if (labelIndex >= 0) {
      final double? nearbyValue =
          _findNearbyMoney(
        lines: lines,
        centerIndex: labelIndex,
        backwardDistance: 5,
        forwardDistance: 5,
        minimum: 1,
        maximum: 1000000000,
        preferLargest: true,
      );

      if (nearbyValue != null) {
        return nearbyValue;
      }
    }

    final List<double> moneyValues =
        _extractAllMoneyValues(lines);

    if (moneyValues.isEmpty) {
      return null;
    }

    moneyValues.sort();

    return moneyValues.last;
  }

  double? _extractStake(
    List<String> lines, {
    required double? possibleWin,
  }) {
    final List<String> stakeLabels =
        <String>[
      'alaptet',
      'alaptét',
      'a jatek ara',
      'a játék ára',
      'fogadasi tet',
      'fogadási tét',
      'ossz tet',
      'össz tét',
    ];

    for (final String label in stakeLabels) {
      final int labelIndex =
          _findLabelIndex(
        lines,
        <String>[label],
      );

      if (labelIndex < 0) {
        continue;
      }

      final double? nearbyValue =
          _findNearbyMoney(
        lines: lines,
        centerIndex: labelIndex,
        backwardDistance: 4,
        forwardDistance: 5,
        minimum: 50,
        maximum: 10000000,
        preferLargest: false,
        rejectedValue: possibleWin,
      );

      if (nearbyValue != null) {
        return nearbyValue;
      }
    }

    final List<double> moneyValues =
        _extractAllMoneyValues(lines)
            .where(
              (double value) {
                if (value < 50 ||
                    value > 10000000) {
                  return false;
                }

                if (possibleWin != null &&
                    (value - possibleWin).abs() <
                        0.01) {
                  return false;
                }

                return true;
              },
            )
            .toList();

    if (moneyValues.isEmpty) {
      return null;
    }

    final Map<int, int> frequencies =
        <int, int>{};

    for (final double value
        in moneyValues) {
      final int rounded =
          value.round();

      frequencies[rounded] =
          (frequencies[rounded] ?? 0) + 1;
    }

    int? bestValue;
    int bestFrequency = 0;

    frequencies.forEach(
      (
        int value,
        int frequency,
      ) {
        if (frequency > bestFrequency) {
          bestValue = value;
          bestFrequency = frequency;
        } else if (frequency ==
                bestFrequency &&
            bestValue != null &&
            value < bestValue!) {
          bestValue = value;
        }
      },
    );

    return bestValue?.toDouble();
  }

  List<double> _extractAllMoneyValues(
    List<String> lines,
  ) {
    final List<double> result =
        <double>[];

    for (final String line in lines) {
      if (!_looksLikeMoneyLine(line)) {
        continue;
      }

      final List<double> values =
          _extractMoneyValues(line);

      for (final double value in values) {
        if (value >= 1 &&
            value <= 1000000000) {
          result.add(value);
        }
      }
    }

    return result;
  }

  int? _extractMatchCount(
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

    final List<int> candidates =
        <int>[];

    final int startIndex =
        math.max(
      0,
      labelIndex - 4,
    );

    final int endIndex =
        math.min(
      lines.length,
      labelIndex + 8,
    );

    for (int index = startIndex;
        index < endIndex;
        index++) {
      final String line =
          lines[index].trim();

      if (!RegExp(r'^\d{1,2}$')
          .hasMatch(line)) {
        continue;
      }

      final int? value =
          int.tryParse(line);

      if (value != null &&
          value >= 1 &&
          value <= 50) {
        candidates.add(value);
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort();

    return candidates.last;
  }

  String? _extractBetslipNumber(
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

    if (labelIndex >= 0) {
      final String? nearby =
          _findNearbyDigitSequence(
        lines: lines,
        centerIndex: labelIndex,
        backwardDistance: 4,
        forwardDistance: 5,
        minimumLength: 6,
        maximumLength: 10,
        preferLeadingZero: true,
      );

      if (nearby != null) {
        return nearby;
      }
    }

    final List<String> candidates =
        <String>[];

    for (final String line in lines) {
      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line)) {
        continue;
      }

      final String digits =
          line.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (digits.length >= 6 &&
          digits.length <= 8) {
        candidates.add(digits);
      }
    }

    for (final String candidate
        in candidates) {
      if (candidate.startsWith('0')) {
        return candidate;
      }
    }

    if (candidates.isNotEmpty) {
      return candidates.first;
    }

    return null;
  }

  DateTime? _extractSubmittedAt(
    List<String> lines,
  ) {
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
      final DateTime? nearby =
          _findNearbyDateTime(
        lines: lines,
        centerIndex: labelIndex,
        backwardDistance: 6,
        forwardDistance: 5,
      );

      if (nearby != null) {
        return nearby;
      }
    }

    final List<DateTime> candidates =
        <DateTime>[];

    for (final String line in lines) {
      final DateTime? parsed =
          _parseDateTimeFromText(line);

      if (parsed == null) {
        continue;
      }

      if (parsed.hour == 0 &&
          parsed.minute == 0) {
        continue;
      }

      candidates.add(parsed);
    }

    if (candidates.isEmpty) {
      return null;
    }

    final List<DateTime> likelySubmissionTimes =
        candidates.where(
      (DateTime value) {
        return value.hour != 15 &&
            value.hour != 18;
      },
    ).toList();

    if (likelySubmissionTimes.isNotEmpty) {
      return likelySubmissionTimes.last;
    }

    return candidates.last;
  }

  List<RecognizedMatch> _extractMatches(
    List<String> lines,
  ) {
    final List<RecognizedMatch> result =
        <RecognizedMatch>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final List<String>? teams =
          _splitMatchLine(
        lines[index],
      );

      if (teams == null) {
        continue;
      }

      final String homeTeam =
          _cleanTeamName(
        teams.first,
      );

      final String awayTeam =
          _cleanTeamName(
        teams.last,
      );

      final int startIndex =
          math.max(
        0,
        index - 4,
      );

      final int endIndex =
          math.min(
        lines.length,
        index + 8,
      );

      String market = '';
      String tip =
          'Ismeretlen tipp';
      double? odds;

      final List<String> sourceLines =
          <String>[];

      for (int nearbyIndex = startIndex;
          nearbyIndex < endIndex;
          nearbyIndex++) {
        final String nearbyLine =
            lines[nearbyIndex];

        sourceLines.add(nearbyLine);

        if (market.isEmpty) {
          final String detectedMarket =
              _detectMarket(
            nearbyLine,
          );

          if (detectedMarket.isNotEmpty) {
            market = detectedMarket;
          }
        }

        if (tip ==
            'Ismeretlen tipp') {
          final String detectedTip =
              _detectTip(
            nearbyLine,
            market,
          );

          if (detectedTip.isNotEmpty) {
            tip = detectedTip;
          }
        }

        if (odds == null &&
            !_looksLikeDateLine(nearbyLine) &&
            !_looksLikeMoneyLine(nearbyLine) &&
            !_looksLikeBarcodeLine(
              nearbyLine,
            )) {
          final List<double> decimals =
              _extractDecimalNumbers(
            nearbyLine,
          );

          for (final double value
              in decimals) {
            if (value >= 1.01 &&
                value <= 1000) {
              odds = value;
              break;
            }
          }
        }
      }

      if (market.isEmpty &&
          tip.contains('gól')) {
        market = 'Gólok';
      }

      if (tip == '6+' &&
          market == 'Gólok') {
        tip = '6+ gól';
      }

      int confidence = 50;

      if (market.isNotEmpty) {
        confidence += 15;
      }

      if (tip !=
          'Ismeretlen tipp') {
        confidence += 15;
      }

      if (odds != null) {
        confidence += 20;
      }

      final bool duplicate =
          result.any(
        (RecognizedMatch match) {
          return _normalizeForSearch(
                    match.homeTeam,
                  ) ==
                  _normalizeForSearch(
                    homeTeam,
                  ) &&
              _normalizeForSearch(
                    match.awayTeam,
                  ) ==
                  _normalizeForSearch(
                    awayTeam,
                  );
        },
      );

      if (duplicate) {
        continue;
      }

      result.add(
        RecognizedMatch(
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          market: market,
          tip: tip,
          odds: odds,
          confidence:
              confidence.clamp(0, 100),
          sourceLines: sourceLines,
        ),
      );
    }

    return result;
  }

  List<RecognizedMatch> _assignDetachedOdds({
    required List<String> lines,
    required List<RecognizedMatch> matches,
    required double? totalOdds,
  }) {
    if (matches.isEmpty) {
      return matches;
    }

    final List<double> candidates =
        <double>[];

    for (final String line in lines) {
      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line)) {
        continue;
      }

      for (final double value
          in _extractDecimalNumbers(line)) {
        if (value < 1.01 ||
            value > 1000) {
          continue;
        }

        if (totalOdds != null &&
            (value - totalOdds).abs() <
                0.01) {
          continue;
        }

        if (!candidates.any(
          (double existing) =>
              (existing - value).abs() <
              0.001,
        )) {
          candidates.add(value);
        }
      }
    }

    final List<double> likelyMatchOdds =
        candidates.where(
      (double value) {
        return value >= 1.01 &&
            value <= 30;
      },
    ).toList();

    if (likelyMatchOdds.isEmpty) {
      return matches;
    }

    final List<RecognizedMatch> updated =
        <RecognizedMatch>[];

    int candidateIndex = 0;

    for (final RecognizedMatch match
        in matches) {
      if (match.odds != null) {
        updated.add(match);
        continue;
      }

      if (candidateIndex >=
          likelyMatchOdds.length) {
        updated.add(match);
        continue;
      }

      final double odds =
          likelyMatchOdds[candidateIndex];

      candidateIndex++;

      updated.add(
        match.copyWith(
          odds: odds,
          confidence:
              math.min(
            100,
            match.confidence + 20,
          ),
        ),
      );
    }

    return updated;
  }

  List<String>? _splitMatchLine(
    String line,
  ) {
    String trimmed =
        line.trim();

    if (trimmed.length < 5 ||
        trimmed.length > 120) {
      return null;
    }

    if (_looksLikeDateLine(trimmed) ||
        _looksLikeMoneyLine(trimmed) ||
        _looksLikeBarcodeLine(trimmed) ||
        _isMetadataLine(trimmed)) {
      return null;
    }

    trimmed = trimmed
        .replaceAll(
          RegExp(
            r'\bNo\s*-\s*a-',
            caseSensitive: false,
          ),
          'Nova - ',
        )
        .replaceAll(
          RegExp(r'\s+-\s+a-'),
          ' - ',
        )
        .replaceAll(
          RegExp(r'\s+-a-'),
          ' - ',
        );

    final RegExp expression =
        RegExp(
      r'^(.+?[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű])'
      r'\s*(?:-|vs\.?|v)\s*'
      r'([A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű].+)$',
      caseSensitive: false,
    );

    final RegExpMatch? match =
        expression.firstMatch(trimmed);

    if (match == null) {
      return null;
    }

    final String home =
        (match.group(1) ?? '').trim();

    final String away =
        (match.group(2) ?? '').trim();

    if (home.length < 2 ||
        away.length < 2) {
      return null;
    }

    if (!_containsEnoughLetters(home) ||
        !_containsEnoughLetters(away)) {
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
        .trim()
        .replaceAll(
          RegExp(r'^[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]+'),
          '',
        )
        .replaceAll(
          RegExp(r'[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű0-9. ]+$'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    if (result.startsWith('a-') &&
        result.length > 2) {
      result = result.substring(2).trim();
    }

    return result;
  }

  bool _containsEnoughLetters(
    String value,
  ) {
    final int count =
        RegExp(
      r'[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]',
    ).allMatches(value).length;

    return count >= 2;
  }

  String _detectMarket(
    String line,
  ) {
    final String normalized =
        _normalizeForSearch(line);

    if (normalized.contains('golszam') ||
        normalized.contains('golszan') ||
        normalized.contains('gol szam') ||
        normalized.contains('golok')) {
      return 'Gólok';
    }

    if (normalized.contains('szoglet')) {
      return 'Szögletek';
    }

    if (normalized.contains(
          'buntetolap',
        ) ||
        normalized.contains('lap')) {
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

  String _detectTip(
    String line,
    String market,
  ) {
    final String normalized =
        _normalizeForSearch(line);

    final RegExp sixPlus =
        RegExp(
      r'(^|[^0-9])6\+($|[^0-9])',
    );

    if (sixPlus.hasMatch(normalized)) {
      return market == 'Gólok'
          ? '6+ gól'
          : '6+';
    }

    final RegExp overUnder =
        RegExp(
      r'(tobb|kevesebb)\s+mint\s+'
      r'(\d+[,.]\d+)',
    );

    final RegExpMatch? overUnderMatch =
        overUnder.firstMatch(normalized);

    if (overUnderMatch != null) {
      final String direction =
          overUnderMatch.group(1) ==
                  'tobb'
              ? 'Több mint'
              : 'Kevesebb mint';

      final String value =
          (overUnderMatch.group(2) ?? '')
              .replaceAll('.', ',');

      return '$direction $value';
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

    if (normalized == '1' ||
        normalized == 'x' ||
        normalized == '2' ||
        normalized == '1x' ||
        normalized == 'x2' ||
        normalized == '12') {
      return normalized.toUpperCase();
    }

    return '';
  }

  double? _findNearbyDecimal({
    required List<String> lines,
    required int centerIndex,
    required int backwardDistance,
    required int forwardDistance,
    required double minimum,
    required double maximum,
    required bool rejectMoneyLines,
    required bool rejectDateLines,
  }) {
    final List<_IndexedDouble> candidates =
        <_IndexedDouble>[];

    final int startIndex =
        math.max(
      0,
      centerIndex - backwardDistance,
    );

    final int endIndex =
        math.min(
      lines.length - 1,
      centerIndex + forwardDistance,
    );

    for (int index = startIndex;
        index <= endIndex;
        index++) {
      final String line =
          lines[index];

      if (rejectMoneyLines &&
          _looksLikeMoneyLine(line)) {
        continue;
      }

      if (rejectDateLines &&
          _looksLikeDateLine(line)) {
        continue;
      }

      if (_looksLikeBarcodeLine(line)) {
        continue;
      }

      for (final double value
          in _extractDecimalNumbers(line)) {
        if (value >= minimum &&
            value <= maximum) {
          candidates.add(
            _IndexedDouble(
              value: value,
              distance:
                  (index - centerIndex).abs(),
            ),
          );
        }
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        _IndexedDouble first,
        _IndexedDouble second,
      ) {
        final int distanceCompare =
            first.distance.compareTo(
          second.distance,
        );

        if (distanceCompare != 0) {
          return distanceCompare;
        }

        return second.value.compareTo(
          first.value,
        );
      },
    );

    return candidates.first.value;
  }

  double? _findNearbyMoney({
    required List<String> lines,
    required int centerIndex,
    required int backwardDistance,
    required int forwardDistance,
    required double minimum,
    required double maximum,
    required bool preferLargest,
    double? rejectedValue,
  }) {
    final List<_IndexedDouble> candidates =
        <_IndexedDouble>[];

    final int startIndex =
        math.max(
      0,
      centerIndex - backwardDistance,
    );

    final int endIndex =
        math.min(
      lines.length - 1,
      centerIndex + forwardDistance,
    );

    for (int index = startIndex;
        index <= endIndex;
        index++) {
      final String line =
          lines[index];

      if (!_looksLikeMoneyLine(line)) {
        continue;
      }

      for (final double value
          in _extractMoneyValues(line)) {
        if (value < minimum ||
            value > maximum) {
          continue;
        }

        if (rejectedValue != null &&
            (value - rejectedValue).abs() <
                0.01) {
          continue;
        }

        candidates.add(
          _IndexedDouble(
            value: value,
            distance:
                (index - centerIndex).abs(),
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        _IndexedDouble first,
        _IndexedDouble second,
      ) {
        final int distanceCompare =
            first.distance.compareTo(
          second.distance,
        );

        if (distanceCompare != 0) {
          return distanceCompare;
        }

        if (preferLargest) {
          return second.value.compareTo(
            first.value,
          );
        }

        return first.value.compareTo(
          second.value,
        );
      },
    );

    if (preferLargest) {
      final int closestDistance =
          candidates.first.distance;

      final List<_IndexedDouble> closest =
          candidates.where(
        (_IndexedDouble item) {
          return item.distance <=
              closestDistance + 2;
        },
      ).toList();

      closest.sort(
        (
          _IndexedDouble first,
          _IndexedDouble second,
        ) {
          return second.value.compareTo(
            first.value,
          );
        },
      );

      return closest.first.value;
    }

    return candidates.first.value;
  }

  String? _findNearbyDigitSequence({
    required List<String> lines,
    required int centerIndex,
    required int backwardDistance,
    required int forwardDistance,
    required int minimumLength,
    required int maximumLength,
    required bool preferLeadingZero,
  }) {
    final List<_IndexedString> candidates =
        <_IndexedString>[];

    final int startIndex =
        math.max(
      0,
      centerIndex - backwardDistance,
    );

    final int endIndex =
        math.min(
      lines.length - 1,
      centerIndex + forwardDistance,
    );

    for (int index = startIndex;
        index <= endIndex;
        index++) {
      final String line =
          lines[index];

      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line)) {
        continue;
      }

      final Iterable<RegExpMatch> matches =
          RegExp(r'\d+').allMatches(line);

      for (final RegExpMatch match
          in matches) {
        final String value =
            match.group(0) ?? '';

        if (value.length >= minimumLength &&
            value.length <= maximumLength) {
          candidates.add(
            _IndexedString(
              value: value,
              distance:
                  (index - centerIndex).abs(),
            ),
          );
        }
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        _IndexedString first,
        _IndexedString second,
      ) {
        if (preferLeadingZero) {
          final bool firstStartsZero =
              first.value.startsWith('0');

          final bool secondStartsZero =
              second.value.startsWith('0');

          if (firstStartsZero &&
              !secondStartsZero) {
            return -1;
          }

          if (!firstStartsZero &&
              secondStartsZero) {
            return 1;
          }
        }

        return first.distance.compareTo(
          second.distance,
        );
      },
    );

    return candidates.first.value;
  }

  DateTime? _findNearbyDateTime({
    required List<String> lines,
    required int centerIndex,
    required int backwardDistance,
    required int forwardDistance,
  }) {
    final List<_IndexedDateTime> candidates =
        <_IndexedDateTime>[];

    final int startIndex =
        math.max(
      0,
      centerIndex - backwardDistance,
    );

    final int endIndex =
        math.min(
      lines.length - 1,
      centerIndex + forwardDistance,
    );

    for (int index = startIndex;
        index <= endIndex;
        index++) {
      final DateTime? value =
          _parseDateTimeFromText(
        lines[index],
      );

      if (value == null) {
        continue;
      }

      if (value.hour == 0 &&
          value.minute == 0) {
        continue;
      }

      candidates.add(
        _IndexedDateTime(
          value: value,
          distance:
              (index - centerIndex).abs(),
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        _IndexedDateTime first,
        _IndexedDateTime second,
      ) {
        return first.distance.compareTo(
          second.distance,
        );
      },
    );

    return candidates.first.value;
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
    final String normalized =
        _normalizeForSearch(line);

    return normalized.contains('ft') ||
        RegExp(
          r'\d[\s.]?\d{3}\s*,?\s*-',
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

    final int letterCount =
        RegExp(
      r'[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]',
    ).allMatches(line).length;

    return digits.length >= 9 &&
        letterCount == 0;
  }

  bool _isMetadataLine(
    String line,
  ) {
    final String normalized =
        _normalizeForSearch(line);

    const List<String> metadata =
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
      'budapest',
      'szerencse sarok',
    ];

    return metadata.any(
      normalized.contains,
    );
  }

  int _findLabelIndex(
    List<String> lines,
    List<String> labels,
  ) {
    for (int index = 0;
        index < lines.length;
        index++) {
      final String normalized =
          _normalizeForSearch(
        lines[index],
      );

      for (final String label
          in labels) {
        if (normalized.contains(
          _normalizeForSearch(label),
        )) {
          return index;
        }
      }
    }

    return -1;
  }

  List<double> _extractMoneyValues(
    String text,
  ) {
    final List<double> result =
        <double>[];

    String candidate =
        text.replaceAll(
      RegExp(
        r'\bft\b',
        caseSensitive: false,
      ),
      '',
    );

    candidate = candidate
        .replaceAll(',-', '')
        .replaceAll(',-', '')
        .trim();

    final RegExp expression =
        RegExp(
      r'(\d{1,3}(?:[ .]\d{3})+|\d+)'
      r'(?:[,.](\d{1,2}))?',
    );

    for (final RegExpMatch match
        in expression.allMatches(
      candidate,
    )) {
      String whole =
          match.group(1) ?? '';

      final String decimals =
          match.group(2) ?? '';

      whole = whole.replaceAll(
        RegExp(r'[ .]'),
        '',
      );

      if (whole.isEmpty) {
        continue;
      }

      final String normalizedValue =
          decimals.isEmpty
              ? whole
              : '$whole.$decimals';

      final double? parsed =
          double.tryParse(
        normalizedValue,
      );

      if (parsed != null) {
        result.add(parsed);
      }
    }

    return result;
  }

  List<double> _extractDecimalNumbers(
    String text,
  ) {
    final List<double> result =
        <double>[];

    final RegExp expression =
        RegExp(
      r'(^|[^0-9])'
      r'(\d{1,7}[,.]\d{1,3})'
      r'(?=$|[^0-9])',
    );

    for (final RegExpMatch match
        in expression.allMatches(text)) {
      final String value =
          (match.group(2) ?? '')
              .replaceAll(',', '.');

      final double? parsed =
          double.tryParse(value);

      if (parsed != null) {
        result.add(parsed);
      }
    }

    return result;
  }

  DateTime? _parseDateTimeFromText(
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
        int.tryParse(
      match.group(1) ?? '',
    );

    final int? month =
        int.tryParse(
      match.group(2) ?? '',
    );

    final int? day =
        int.tryParse(
      match.group(3) ?? '',
    );

    final int hour =
        int.tryParse(
              match.group(4) ?? '',
            ) ??
            0;

    final int minute =
        int.tryParse(
              match.group(5) ?? '',
            ) ??
            0;

    if (year == null ||
        month == null ||
        day == null) {
      return null;
    }

    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    final DateTime result =
        DateTime(
      year,
      month,
      day,
      hour,
      minute,
    );

    if (result.year != year ||
        result.month != month ||
        result.day != day) {
      return null;
    }

    return result;
  }

  int _calculateConfidence({
    required double? totalOdds,
    required double? stake,
    required double? possibleWin,
    required int? matchCount,
    required String? betslipNumber,
    required DateTime? submittedAt,
    required List<RecognizedMatch> matches,
  }) {
    int score = 0;

    if (stake != null) {
      score += 15;
    }

    if (totalOdds != null) {
      score += 15;
    }

    if (possibleWin != null) {
      score += 15;
    }

    if (matchCount != null &&
        matchCount > 0) {
      score += 10;
    }

    if (betslipNumber != null) {
      score += 10;
    }

    if (submittedAt != null) {
      score += 10;
    }

    if (matches.isNotEmpty) {
      score += 15;
    }

    if (matches.length >= 2) {
      score += 5;
    }

    if (stake != null &&
        totalOdds != null &&
        possibleWin != null) {
      final double calculatedWin =
          stake * totalOdds;

      final double difference =
          (calculatedWin - possibleWin)
              .abs();

      final double tolerance =
          math.max(
        possibleWin * 0.08,
        10,
      );

      if (difference <= tolerance) {
        score += 10;
      } else {
        score -= 5;
      }
    }

    return score.clamp(0, 100);
  }

  List<String> _buildWarnings({
    required double? totalOdds,
    required double? stake,
    required double? possibleWin,
    required int? matchCount,
    required String? betslipNumber,
    required DateTime? submittedAt,
    required List<RecognizedMatch> matches,
    required int confidence,
  }) {
    final List<String> warnings =
        <String>[];

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
      final double expectedWin =
          stake * totalOdds;

      final double difference =
          (expectedWin - possibleWin)
              .abs();

      final double tolerance =
          math.max(
        possibleWin * 0.08,
        10,
      );

      if (difference > tolerance) {
        warnings.add(
          'A tét, az eredő odds és a maximális '
          'nyeremény nem teljesen egyezik egymással.',
        );
      }
    }

    if (confidence < 50) {
      warnings.add(
        'A felismerés bizonytalan. Készíts élesebb képet.',
      );
    }

    return warnings;
  }

  String _fixCommonOcrErrors(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(
            r'(\d)[oO](\d)',
          ),
          r'$10$2',
        )
        .replaceAll(
          RegExp(
            r'(\d)[lI](\d)',
          ),
          r'$11$2',
        )
        .replaceAll(
          RegExp(
            r'(\d)\s*[,.]\s*(\d)',
          ),
          r'$1,$2',
        )
        .replaceAll(
          RegExp(
            r'\bered[oó]\s+odds\b',
            caseSensitive: false,
          ),
          'Eredő odds',
        )
        .replaceAll(
          RegExp(
            r'\bmax\s+nyerem[eé]ny\b',
            caseSensitive: false,
          ),
          'Max nyeremény',
        )
        .replaceAll(
          RegExp(
            r'\bg[oó]lsz[aá]n\b',
            caseSensitive: false,
          ),
          'Gólszám',
        )
        .replaceAll(
          RegExp(
            r'\bSuper\s+No\s*-\s*a-Ogre\b',
            caseSensitive: false,
          ),
          'Super Nova - Ogre',
        );
  }

  String _normalizeForSearch(
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
            r'[^a-z0-9,.%+\-\s]',
          ),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }
}

class _IndexedDouble {
  final double value;
  final int distance;

  const _IndexedDouble({
    required this.value,
    required this.distance,
  });
}

class _IndexedString {
  final String value;
  final int distance;

  const _IndexedString({
    required this.value,
    required this.distance,
  });
}

class _IndexedDateTime {
  final DateTime value;
  final int distance;

  const _IndexedDateTime({
    required this.value,
    required this.distance,
  });
}
