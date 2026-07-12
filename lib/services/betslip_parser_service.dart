// ===========================================
// Zsolt Pro AI
// Version: v0.18.7
// File: lib/services/betslip_parser_service.dart
// ===========================================

import 'dart:math' as math;

import '../models/recognized_betslip.dart';

/// Tippmix szelvények OCR-szövegének
/// feldolgozására szolgáló Parser 2.0.
///
/// A Tippmix szelvényeknél az OCR gyakran külön
/// blokkba rendezi a megnevezéseket és az értékeket.
/// Ezért a szolgáltatás nemcsak a következő sort nézi,
/// hanem a teljes szöveget elemzi és összefüggéseket keres.
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

    final List<RecognizedMatch> matches =
        _extractMatches(lines);

    final double? totalOdds =
        _extractTotalOdds(
      lines,
      matches,
    );

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

    result = _fixCommonOcrErrors(result);

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
    ];

    int matches = 0;

    for (final String keyword in keywords) {
      if (normalized.contains(keyword)) {
        matches++;
      }
    }

    return matches >= 2;
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
    List<RecognizedMatch> matches,
  ) {
    final List<double> decimalCandidates =
        <double>[];

    for (final String line in lines) {
      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line)) {
        continue;
      }

      for (final double value
          in _extractDecimalNumbers(line)) {
        if (value >= 1.01 &&
            value <= 100000) {
          decimalCandidates.add(value);
        }
      }
    }

    if (decimalCandidates.isEmpty) {
      return null;
    }

    final List<double> matchOdds =
        matches
            .where(
              (RecognizedMatch match) =>
                  match.odds != null,
            )
            .map(
              (RecognizedMatch match) =>
                  match.odds!,
            )
            .toList(growable: false);

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

      double? closest;
      double closestDifference =
          double.infinity;

      for (final double candidate
          in decimalCandidates) {
        final double difference =
            (candidate - product).abs();

        if (difference <
            closestDifference) {
          closestDifference =
              difference;
          closest = candidate;
        }
      }

      final double tolerance =
          math.max(
        product * 0.08,
        0.15,
      );

      if (closest != null &&
          closestDifference <= tolerance) {
        return closest;
      }
    }

    decimalCandidates.sort();

    return decimalCandidates.last;
  }

  double? _extractStake(
    List<String> lines, {
    required double? possibleWin,
  }) {
    final List<double> moneyValues =
        _extractAllMoneyValues(lines);

    if (moneyValues.isEmpty) {
      return null;
    }

    final List<double> possibleStakes =
        moneyValues.where(
      (double value) {
        if (value < 10 ||
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
    ).toList();

    if (possibleStakes.isEmpty) {
      return null;
    }

    final Map<int, int> frequencies =
        <int, int>{};

    for (final double value
        in possibleStakes) {
      final int rounded =
          value.round();

      frequencies[rounded] =
          (frequencies[rounded] ?? 0) + 1;
    }

    int? mostFrequentValue;
    int highestFrequency = 0;

    frequencies.forEach(
      (
        int value,
        int frequency,
      ) {
        if (frequency >
            highestFrequency) {
          highestFrequency = frequency;
          mostFrequentValue = value;
        } else if (frequency ==
                highestFrequency &&
            mostFrequentValue != null &&
            value < mostFrequentValue!) {
          mostFrequentValue = value;
        }
      },
    );

    if (mostFrequentValue != null) {
      return mostFrequentValue!
          .toDouble();
    }

    possibleStakes.sort();

    return possibleStakes.first;
  }

  double? _extractPossibleWin(
    List<String> lines,
  ) {
    final List<double> moneyValues =
        _extractAllMoneyValues(lines);

    if (moneyValues.isEmpty) {
      return null;
    }

    moneyValues.sort();

    return moneyValues.last;
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

      final double? value =
          _extractMoneyValue(line);

      if (value != null &&
          value >= 1 &&
          value <= 1000000000) {
        result.add(value);
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
      ],
    );

    if (labelIndex >= 0) {
      final int endIndex =
          math.min(
        labelIndex + 12,
        lines.length,
      );

      final List<int> candidates =
          <int>[];

      for (int index =
              labelIndex + 1;
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

      if (candidates.isNotEmpty) {
        candidates.sort();

        return candidates.last;
      }
    }

    return null;
  }

  String? _extractBetslipNumber(
    List<String> lines,
  ) {
    final List<String> candidates =
        <String>[];

    for (final String line in lines) {
      final String compact =
          line.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (compact.length < 6 ||
          compact.length > 10) {
        continue;
      }

      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line)) {
        continue;
      }

      candidates.add(compact);
    }

    if (candidates.isEmpty) {
      return null;
    }

    for (final String candidate
        in candidates) {
      if (candidate.startsWith('0') &&
          candidate.length >= 6 &&
          candidate.length <= 8) {
        return candidate;
      }
    }

    for (final String candidate
        in candidates) {
      if (candidate.length == 7 ||
          candidate.length == 8) {
        return candidate;
      }
    }

    return null;
  }

  DateTime? _extractSubmittedAt(
    List<String> lines,
  ) {
    final List<DateTime> candidates =
        <DateTime>[];

    for (final String line in lines) {
      final DateTime? parsed =
          _parseDateTimeFromText(line);

      if (parsed != null) {
        candidates.add(parsed);
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    final List<DateTime> exactTimes =
        candidates.where(
      (DateTime value) {
        return value.minute != 0 ||
            value.second != 0;
      },
    ).toList();

    if (exactTimes.isNotEmpty) {
      exactTimes.sort();

      return exactTimes.last;
    }

    candidates.sort();

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
          teams.first;

      final String awayTeam =
          teams.last;

      final int endIndex =
          math.min(
        index + 6,
        lines.length,
      );

      String market = '';
      String tip =
          'Ismeretlen tipp';
      double? odds;

      final List<String> sourceLines =
          <String>[
        lines[index],
      ];

      for (int nearbyIndex =
              index + 1;
          nearbyIndex < endIndex;
          nearbyIndex++) {
        final String nearbyLine =
            lines[nearbyIndex];

        if (_splitMatchLine(
              nearbyLine,
            ) !=
            null) {
          break;
        }

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
            !_looksLikeMoneyLine(
              nearbyLine,
            ) &&
            !_looksLikeDateLine(
              nearbyLine,
            )) {
          final List<double> numbers =
              _extractDecimalNumbers(
            nearbyLine,
          );

          for (final double value
              in numbers) {
            if (value >= 1.01 &&
                value <= 1000) {
              odds = value;
              break;
            }
          }
        }
      }

      if (market == 'Gólok' &&
          tip == '6+') {
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

  List<String>? _splitMatchLine(
    String line,
  ) {
    final String trimmed =
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

    if (normalized.contains(
          'golszam',
        ) ||
        normalized.contains('golok')) {
      return 'Gólok';
    }

    if (normalized.contains(
      'szoglet',
    )) {
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

    return normalized.contains('ft');
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

  double? _extractMoneyValue(
    String text,
  ) {
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
        .replaceAll('-', ' ')
        .trim();

    final RegExp expression =
        RegExp(
      r'(\d{1,3}(?:[ .]\d{3})+|\d+)'
      r'(?:[,.](\d{1,2}))?',
    );

    final List<double> values =
        <double>[];

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
        values.add(parsed);
      }
    }

    if (values.isEmpty) {
      return null;
    }

    return values.reduce(math.max);
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
