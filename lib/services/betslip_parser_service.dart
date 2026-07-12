// ===========================================
// Zsolt Pro AI
// Version: v0.18.4
// File: lib/services/betslip_parser_service.dart
// ===========================================

import '../models/recognized_betslip.dart';

/// A Zsolt Pro AI Tippmix-szelvény feldolgozó szolgáltatása.
///
/// Feladatai:
/// - az OCR által felismert szöveg megtisztítása;
/// - a szelvényszám felismerése;
/// - a tét felismerése;
/// - az eredő odds felismerése;
/// - a maximális nyeremény felismerése;
/// - a fogadások számának felismerése;
/// - a mérkőzések és tippek előzetes elkülönítése;
/// - a felismerés minőségének értékelése.
///
/// Ez a szolgáltatás kizárólag a már felismert OCR-szöveget
/// dolgozza fel. A képbeolvasást az OcrService végzi.
class BetslipParserService {
  BetslipParserService._();

  static final BetslipParserService instance =
      BetslipParserService._();

  /// Egy teljes OCR-szöveg feldolgozása.
  RecognizedBetslip parse(
    String rawText,
  ) {
    final String cleanedText =
        cleanText(
      rawText,
    );

    final List<String> lines =
        _extractLines(
      cleanedText,
    );

    final double? totalOdds =
        _extractTotalOdds(
      lines,
    );

    final double? stake =
        _extractStake(
      lines,
    );

    final double? possibleWin =
        _extractPossibleWin(
      lines,
    );

    final int? matchCount =
        _extractMatchCount(
      lines,
    );

    final String? betslipNumber =
        _extractBetslipNumber(
      lines,
    );

    final DateTime? submittedAt =
        _extractSubmittedAt(
      lines,
    );

    final List<RecognizedMatch> matches =
        _extractMatches(
      lines,
    );

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
      matches: matches,
      betslipNumber: betslipNumber,
      submittedAt: submittedAt,
      confidence: confidence,
      warnings: warnings,
    );
  }

  /// Egységesíti az OCR-szöveget.
  String cleanText(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return '';
    }

    String result =
        value
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

  /// Megvizsgálja, hogy a szöveg valószínűleg
  /// Tippmix-szelvényből származik-e.
  bool looksLikeTippmixBetslip(
    String text,
  ) {
    final String normalized =
        _normalizeForSearch(
      text,
    );

    if (normalized.isEmpty) {
      return false;
    }

    final List<String> keywords =
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
      'osszesen',
    ];

    int found = 0;

    for (final String keyword
        in keywords) {
      if (normalized.contains(
        keyword,
      )) {
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
          (String line) {
            return line.trim();
          },
        )
        .where(
          (String line) {
            return line.isNotEmpty;
          },
        )
        .toList(
          growable: false,
        );
  }

  double? _extractTotalOdds(
    List<String> lines,
  ) {
    final List<String> labels =
        <String>[
      'eredo odds',
      'eredő odds',
      'ossz odds',
      'össz odds',
      'teljes odds',
      'kombinalt odds',
      'kombinált odds',
    ];

    return _extractNumberAfterLabels(
      lines: lines,
      labels: labels,
      allowThousandsSeparator: false,
      minimumValue: 1.0,
      maximumValue: 1000000.0,
    );
  }

  double? _extractStake(
    List<String> lines,
  ) {
    final List<String> labels =
        <String>[
      'a jatek ara',
      'a játék ára',
      'alaptet',
      'alaptét',
      'tet',
      'tét',
      'fogadasi tet',
      'fogadási tét',
      'ossz tet',
      'össz tét',
    ];

    final double? result =
        _extractMoneyAfterLabels(
      lines: lines,
      labels: labels,
    );

    if (result != null) {
      return result;
    }

    return _findLikelyStake(
      lines,
    );
  }

  double? _extractPossibleWin(
    List<String> lines,
  ) {
    final List<String> labels =
        <String>[
      'max nyeremeny',
      'max nyeremény',
      'maximalis nyeremeny',
      'maximális nyeremény',
      'varhato nyeremeny',
      'várható nyeremény',
      'lehetseges nyeremeny',
      'lehetséges nyeremény',
      'nyeremeny',
      'nyeremény',
    ];

    return _extractMoneyAfterLabels(
      lines: lines,
      labels: labels,
    );
  }

  int? _extractMatchCount(
    List<String> lines,
  ) {
    final List<String> labels =
        <String>[
      'fogadasszam',
      'fogadásszám',
      'esemenyszam',
      'eseményszám',
      'merkozesek szama',
      'mérkőzések száma',
      'kivalasztasok szama',
      'kiválasztások száma',
    ];

    final double? value =
        _extractNumberAfterLabels(
      lines: lines,
      labels: labels,
      allowThousandsSeparator: false,
      minimumValue: 1,
      maximumValue: 100,
    );

    if (value != null) {
      return value.round();
    }

    for (int index = 0;
        index < lines.length;
        index++) {
      final String normalized =
          _normalizeForSearch(
        lines[index],
      );

      if (normalized == 'ossz' ||
          normalized == 'osszes' ||
          normalized ==
              'fogadasszam') {
        final int? following =
            _findFollowingInteger(
          lines,
          index,
          maxDistance: 3,
          minimum: 1,
          maximum: 100,
        );

        if (following != null) {
          return following;
        }
      }
    }

    return null;
  }

  String? _extractBetslipNumber(
    List<String> lines,
  ) {
    final List<String> labels =
        <String>[
      'szelveny szama',
      'szelvény száma',
      'szelvenyszam',
      'szelvényszám',
    ];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String normalized =
          _normalizeForSearch(
        lines[index],
      );

      final bool hasLabel =
          labels.any(
        (String label) {
          return normalized.contains(
            _normalizeForSearch(
              label,
            ),
          );
        },
      );

      if (!hasLabel) {
        continue;
      }

      final String sameLineNumber =
          _extractLongestDigitSequence(
        lines[index],
      );

      if (sameLineNumber.length >= 5) {
        return sameLineNumber;
      }

      for (int distance = 1;
          distance <= 3;
          distance++) {
        final int target =
            index + distance;

        if (target >= lines.length) {
          break;
        }

        final String candidate =
            _extractLongestDigitSequence(
          lines[target],
        );

        if (candidate.length >= 5 &&
            candidate.length <= 30) {
          return candidate;
        }
      }
    }

    return null;
  }

  DateTime? _extractSubmittedAt(
    List<String> lines,
  ) {
    final List<String> labels =
        <String>[
      'jatekba kuldve',
      'játékba küldve',
      'fogadas ideje',
      'fogadás ideje',
    ];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String normalized =
          _normalizeForSearch(
        lines[index],
      );

      final bool hasLabel =
          labels.any(
        (String label) {
          return normalized.contains(
            _normalizeForSearch(
              label,
            ),
          );
        },
      );

      if (!hasLabel) {
        continue;
      }

      final DateTime? sameLine =
          _parseDateTimeFromText(
        lines[index],
      );

      if (sameLine != null) {
        return sameLine;
      }

      for (int distance = 1;
          distance <= 3;
          distance++) {
        final int target =
            index + distance;

        if (target >= lines.length) {
          break;
        }

        final DateTime? parsed =
            _parseDateTimeFromText(
          lines[target],
        );

        if (parsed != null) {
          return parsed;
        }
      }
    }

    for (final String line in lines) {
      final DateTime? parsed =
          _parseDateTimeFromText(
        line,
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  List<RecognizedMatch> _extractMatches(
    List<String> lines,
  ) {
    final List<RecognizedMatch> matches =
        <RecognizedMatch>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String line =
          lines[index].trim();

      if (!_looksLikeMatchLine(
        line,
      )) {
        continue;
      }

      final List<String>? teams =
          _splitTeams(
        line,
      );

      if (teams == null ||
          teams.length != 2) {
        continue;
      }

      final String homeTeam =
          teams[0].trim();

      final String awayTeam =
          teams[1].trim();

      if (homeTeam.length < 2 ||
          awayTeam.length < 2) {
        continue;
      }

      final String tip =
          _findNearbyTip(
        lines: lines,
        matchLineIndex: index,
      );

      final double? odds =
          _findNearbyOdds(
        lines: lines,
        matchLineIndex: index,
      );

      final bool alreadyExists =
          matches.any(
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

      if (alreadyExists) {
        continue;
      }

      matches.add(
        RecognizedMatch(
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          tip: tip,
          odds: odds,
        ),
      );
    }

    return matches;
  }

  bool _looksLikeMatchLine(
    String line,
  ) {
    final String normalized =
        _normalizeForSearch(
      line,
    );

    if (normalized.length < 5 ||
        normalized.length > 100) {
      return false;
    }

    if (_isMetadataLine(
      normalized,
    )) {
      return false;
    }

    final bool hasSeparator =
        RegExp(
          r'\s(?:-|–|—|vs\.?|v)\s',
          caseSensitive: false,
        ).hasMatch(
      line,
    );

    if (!hasSeparator) {
      return false;
    }

    final int letterCount =
        RegExp(
          r'[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]',
        ).allMatches(
          line,
        ).length;

    return letterCount >= 5;
  }

  List<String>? _splitTeams(
    String line,
  ) {
    final RegExp separator =
        RegExp(
      r'\s+(?:-|–|—|vs\.?|v)\s+',
      caseSensitive: false,
    );

    final List<String> parts =
        line.split(
      separator,
    );

    if (parts.length < 2) {
      return null;
    }

    final String home =
        parts.first.trim();

    final String away =
        parts
            .sublist(1)
            .join(' - ')
            .trim();

    if (home.isEmpty ||
        away.isEmpty) {
      return null;
    }

    return <String>[
      home,
      away,
    ];
  }

  String _findNearbyTip({
    required List<String> lines,
    required int matchLineIndex,
  }) {
    final int endIndex =
        (matchLineIndex + 5).clamp(
      0,
      lines.length,
    );

    for (int index =
            matchLineIndex + 1;
        index < endIndex;
        index++) {
      final String line =
          lines[index].trim();

      if (_looksLikeTip(
        line,
      )) {
        return line;
      }

      if (_looksLikeMatchLine(
        line,
      )) {
        break;
      }
    }

    return 'Ismeretlen tipp';
  }

  double? _findNearbyOdds({
    required List<String> lines,
    required int matchLineIndex,
  }) {
    final int endIndex =
        (matchLineIndex + 6).clamp(
      0,
      lines.length,
    );

    for (int index =
            matchLineIndex + 1;
        index < endIndex;
        index++) {
      final String line =
          lines[index];

      if (_looksLikeMatchLine(
        line,
      )) {
        break;
      }

      final List<double> numbers =
          _extractDecimalNumbers(
        line,
      );

      for (final double value
          in numbers) {
        if (value >= 1.01 &&
            value <= 1000) {
          return value;
        }
      }
    }

    return null;
  }

  bool _looksLikeTip(
    String line,
  ) {
    final String normalized =
        _normalizeForSearch(
      line,
    );

    final List<String> tipKeywords =
        <String>[
      'hazai',
      'vendeg',
      'dontetlen',
      'tobb mint',
      'kevesebb mint',
      'mindket csapat',
      'gol',
      'szoglet',
      'lap',
      'buntetolap',
      'les',
      'szabalytalansag',
      'dupla esely',
      'felido',
      'vegeredmeny',
      'igen',
      'nem',
      '1x',
      'x2',
      '12',
    ];

    return tipKeywords.any(
      (String keyword) {
        return normalized.contains(
          keyword,
        );
      },
    );
  }

  bool _isMetadataLine(
    String normalized,
  ) {
    final List<String> metadata =
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
      'vonalkod',
    ];

    return metadata.any(
      (String value) {
        return normalized.contains(
          value,
        );
      },
    );
  }

  double? _extractMoneyAfterLabels({
    required List<String> lines,
    required List<String> labels,
  }) {
    for (int index = 0;
        index < lines.length;
        index++) {
      final String normalizedLine =
          _normalizeForSearch(
        lines[index],
      );

      final bool matchesLabel =
          labels.any(
        (String label) {
          return normalizedLine.contains(
            _normalizeForSearch(
              label,
            ),
          );
        },
      );

      if (!matchesLabel) {
        continue;
      }

      final double? sameLine =
          _extractMoneyValue(
        lines[index],
      );

      if (sameLine != null) {
        return sameLine;
      }

      for (int distance = 1;
          distance <= 4;
          distance++) {
        final int target =
            index + distance;

        if (target >= lines.length) {
          break;
        }

        final double? value =
            _extractMoneyValue(
          lines[target],
        );

        if (value != null) {
          return value;
        }
      }
    }

    return null;
  }

  double? _extractNumberAfterLabels({
    required List<String> lines,
    required List<String> labels,
    required bool allowThousandsSeparator,
    required double minimumValue,
    required double maximumValue,
  }) {
    for (int index = 0;
        index < lines.length;
        index++) {
      final String normalizedLine =
          _normalizeForSearch(
        lines[index],
      );

      final bool matchesLabel =
          labels.any(
        (String label) {
          return normalizedLine.contains(
            _normalizeForSearch(
              label,
            ),
          );
        },
      );

      if (!matchesLabel) {
        continue;
      }

      final List<double> sameLineNumbers =
          _extractDecimalNumbers(
        lines[index],
        allowThousandsSeparator:
            allowThousandsSeparator,
      );

      for (final double value
          in sameLineNumbers) {
        if (value >= minimumValue &&
            value <= maximumValue) {
          return value;
        }
      }

      for (int distance = 1;
          distance <= 4;
          distance++) {
        final int target =
            index + distance;

        if (target >= lines.length) {
          break;
        }

        final List<double> values =
            _extractDecimalNumbers(
          lines[target],
          allowThousandsSeparator:
              allowThousandsSeparator,
        );

        for (final double value
            in values) {
          if (value >= minimumValue &&
              value <= maximumValue) {
            return value;
          }
        }
      }
    }

    return null;
  }

  double? _findLikelyStake(
    List<String> lines,
  ) {
    for (final String line in lines) {
      final String normalized =
          _normalizeForSearch(
        line,
      );

      if (!normalized.contains('ft')) {
        continue;
      }

      final double? value =
          _extractMoneyValue(
        line,
      );

      if (value != null &&
          value >= 10 &&
          value <= 1000000) {
        return value;
      }
    }

    return null;
  }

  double? _extractMoneyValue(
    String text,
  ) {
    String candidate =
        text
            .replaceAll(
              RegExp(
                r'(?i)\bft\b',
              ),
              '',
            )
            .replaceAll('-', ' ')
            .trim();

    final RegExp expression =
        RegExp(
      r'(\d{1,3}(?:[ .]\d{3})+|\d+)(?:[,.](\d{1,2}))?',
    );

    final Iterable<RegExpMatch> matches =
        expression.allMatches(
      candidate,
    );

    final List<double> values =
        <double>[];

    for (final RegExpMatch match
        in matches) {
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

    return values.reduce(
      (
        double first,
        double second,
      ) {
        return first > second
            ? first
            : second;
      },
    );
  }

  List<double> _extractDecimalNumbers(
    String text, {
    bool allowThousandsSeparator = false,
  }) {
    final List<double> results =
        <double>[];

    final RegExp expression =
        RegExp(
      r'(?<!\d)(\d{1,7}(?:[,.]\d{1,3})?)(?!\d)',
    );

    for (final RegExpMatch match
        in expression.allMatches(
      text,
    )) {
      String value =
          match.group(1) ?? '';

      if (value.isEmpty) {
        continue;
      }

      if (allowThousandsSeparator) {
        value = value.replaceAll(
          RegExp(r'(?<=\d)[. ](?=\d{3}\b)'),
          '',
        );
      }

      value = value.replaceAll(
        ',',
        '.',
      );

      final double? parsed =
          double.tryParse(
        value,
      );

      if (parsed != null) {
        results.add(parsed);
      }
    }

    return results;
  }

  int? _findFollowingInteger(
    List<String> lines,
    int startIndex, {
    required int maxDistance,
    required int minimum,
    required int maximum,
  }) {
    for (int distance = 1;
        distance <= maxDistance;
        distance++) {
      final int target =
          startIndex + distance;

      if (target >= lines.length) {
        break;
      }

      final RegExpMatch? result =
          RegExp(
        r'(?<!\d)(\d{1,3})(?!\d)',
      ).firstMatch(
        lines[target],
      );

      if (result == null) {
        continue;
      }

      final int? value =
          int.tryParse(
        result.group(1) ?? '',
      );

      if (value != null &&
          value >= minimum &&
          value <= maximum) {
        return value;
      }
    }

    return null;
  }

  String _extractLongestDigitSequence(
    String text,
  ) {
    final Iterable<RegExpMatch> matches =
        RegExp(
      r'\d+',
    ).allMatches(
      text,
    );

    String longest = '';

    for (final RegExpMatch match
        in matches) {
      final String candidate =
          match.group(0) ?? '';

      if (candidate.length >
          longest.length) {
        longest = candidate;
      }
    }

    return longest;
  }

  DateTime? _parseDateTimeFromText(
    String text,
  ) {
    final RegExp expression =
        RegExp(
      r'(20\d{2})[.\-/, ]+'
      r'(\d{1,2})[.\-/, ]+'
      r'(\d{1,2})'
      r'(?:[., ]+'
      r'(\d{1,2})[:.]'
      r'(\d{2}))?',
    );

    final RegExpMatch? match =
        expression.firstMatch(
      text,
    );

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

    try {
      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
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
      score += 18;
    }

    if (totalOdds != null) {
      score += 18;
    }

    if (possibleWin != null) {
      score += 18;
    }

    if (matchCount != null) {
      score += 12;
    }

    if (betslipNumber != null) {
      score += 12;
    }

    if (submittedAt != null) {
      score += 8;
    }

    if (matches.isNotEmpty) {
      score += 8;
    }

    if (matches.length >= 2) {
      score += 6;
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
          possibleWin * 0.08;

      if (difference <= tolerance) {
        score += 10;
      } else {
        score -= 8;
      }
    }

    return score.clamp(
      0,
      100,
    );
  }

  List<String> _buildWarnings({
    required double? totalOdds,
    required double? stake,
    required double? possibleWin,
    required int? matchCount,
    required String? betslipNumber,
    required List<RecognizedMatch> matches,
    required int confidence,
  }) {
    final List<String> warnings =
        <String>[];

    if (stake == null) {
      warnings.add(
        'A tétet nem sikerült egyértelműen felismerni.',
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

    if (matchCount == null) {
      warnings.add(
        'A fogadások számát nem sikerült felismerni.',
      );
    }

    if (betslipNumber == null) {
      warnings.add(
        'A szelvény azonosítóját nem sikerült felismerni.',
      );
    }

    if (matches.isEmpty) {
      warnings.add(
        'A mérkőzések automatikus elkülönítése még '
        'nem adott biztos eredményt.',
      );
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
          possibleWin * 0.08;

      if (difference > tolerance) {
        warnings.add(
          'A felismert tét, odds és nyeremény nem teljesen '
          'egyezik egymással. Kézi ellenőrzés szükséges.',
        );
      }
    }

    if (confidence < 50) {
      warnings.add(
        'A szelvényadatok felismerése bizonytalan.',
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
            r'(?<=\d)[oO](?=\d)',
          ),
          '0',
        )
        .replaceAll(
          RegExp(
            r'(?<=\d)[lI](?=\d)',
          ),
          '1',
        )
        .replaceAll(
          RegExp(
            r'(?<=\d)\s*[,.]\s*(?=\d)',
          ),
          ',',
        )
        .replaceAll(
          RegExp(
            r'(?i)\bered[oó]\s+odds\b',
          ),
          'Eredő odds',
        )
        .replaceAll(
          RegExp(
            r'(?i)\bmax\s+nyerem[eé]ny\b',
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
          RegExp(r'[^a-z0-9,.%+\-\s]'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }
}
