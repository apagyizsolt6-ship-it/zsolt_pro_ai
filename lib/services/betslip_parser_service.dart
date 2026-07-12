// ===========================================
// Zsolt Pro AI
// Version: v0.18.10
// File: lib/services/betslip_parser_service.dart
// ===========================================

import 'dart:math' as math;

import '../models/recognized_betslip.dart';

/// Tippmix papíralapú szelvények OCR-szövegének
/// feldolgozására szolgáló Parser 4.0.
///
/// Főbb funkciók:
/// - szelvényszám felismerése;
/// - játékba küldés időpontjának felismerése;
/// - tét felismerése;
/// - eredő odds felismerése;
/// - maximális nyeremény felismerése;
/// - mérkőzések felismerése;
/// - piac és tipp felismerése;
/// - meccsenkénti oddsok párosítása;
/// - matematikai keresztellenőrzés;
/// - címek, telefonszámok és adószámok kizárása;
/// - elfordított szelvény OCR-sorrendjének kezelése.
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

    final List<_DetectedMatch> detectedMatches =
        _detectMatches(lines);

    final List<_NumberCandidate> decimalCandidates =
        _collectDecimalCandidates(lines);

    final List<_MoneyCandidate> moneyCandidates =
        _collectMoneyCandidates(lines);

    final List<double> matchOdds =
        _detectMatchOdds(
      decimalCandidates: decimalCandidates,
      matchCount: detectedMatches.length,
    );

    final double? totalOdds =
        _detectTotalOdds(
      lines: lines,
      decimalCandidates: decimalCandidates,
      matchOdds: matchOdds,
    );

    final double? possibleWin =
        _detectPossibleWin(
      lines: lines,
      moneyCandidates: moneyCandidates,
      totalOdds: totalOdds,
    );

    final double? stake =
        _detectStake(
      lines: lines,
      moneyCandidates: moneyCandidates,
      totalOdds: totalOdds,
      possibleWin: possibleWin,
    );

    final String? betslipNumber =
        _detectBetslipNumber(lines);

    final DateTime? submittedAt =
        _detectSubmittedAt(
      lines,
      detectedMatches,
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
          return _normalizeForSearch(
                    item.homeTeam,
                  ) ==
                  _normalizeForSearch(
                    homeTeam,
                  ) &&
              _normalizeForSearch(
                    item.awayTeam,
                  ) ==
                  _normalizeForSearch(
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

      final int startIndex =
          math.max(0, index - 4);

      final int endIndex =
          math.min(
        lines.length - 1,
        index + 7,
      );

      final List<String> sourceLines =
          <String>[];

      for (int nearbyIndex = startIndex;
          nearbyIndex <= endIndex;
          nearbyIndex++) {
        final String nearbyLine =
            lines[nearbyIndex];

        sourceLines.add(nearbyLine);

        if (market.isEmpty) {
          final String detectedMarket =
              _detectMarket(nearbyLine);

          if (detectedMarket.isNotEmpty) {
            market = detectedMarket;
          }
        }

        if (tip == 'Ismeretlen tipp') {
          final String detectedTip =
              _detectTip(
            nearbyLine,
            market,
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

  List<_NumberCandidate>
      _collectDecimalCandidates(
    List<String> lines,
  ) {
    final List<_NumberCandidate> result =
        <_NumberCandidate>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String line =
          lines[index];

      if (_looksLikeDateLine(line) ||
          _looksLikeBarcodeLine(line) ||
          _looksLikeAddressOrTaxLine(line)) {
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
        final String rawValue =
            match.group(2) ?? '';

        final double? value =
            double.tryParse(
          rawValue.replaceAll(',', '.'),
        );

        if (value == null ||
            value < 1.01 ||
            value > 1000000) {
          continue;
        }

        result.add(
          _NumberCandidate(
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

      if (!_looksLikeMoneyLine(line)) {
        continue;
      }

      if (_looksLikeAddressOrTaxLine(line) ||
          _looksLikePhoneLine(line) ||
          _looksLikeBarcodeLine(line)) {
        continue;
      }

      final List<double> values =
          _extractMoneyValues(line);

      for (final double value in values) {
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
    required List<_NumberCandidate>
        decimalCandidates,
    required int matchCount,
  }) {
    if (matchCount <= 0) {
      return const <double>[];
    }

    final List<_NumberCandidate> candidates =
        decimalCandidates.where(
      (_NumberCandidate item) {
        if (item.value < 1.01 ||
            item.value > 30) {
          return false;
        }

        if (_looksLikeMoneyLine(item.line)) {
          return false;
        }

        return true;
      },
    ).toList();

    if (candidates.isEmpty) {
      return const <double>[];
    }

    final List<double> uniqueValues =
        <double>[];

    for (final _NumberCandidate candidate
        in candidates) {
      final bool exists =
          uniqueValues.any(
        (double value) {
          return (value -
                      candidate.value)
                  .abs() <
              0.001;
        },
      );

      if (!exists) {
        uniqueValues.add(
          candidate.value,
        );
      }
    }

    if (uniqueValues.length <=
        matchCount) {
      return uniqueValues;
    }

    return uniqueValues
        .take(matchCount)
        .toList(growable: false);
  }

  double? _detectTotalOdds({
    required List<String> lines,
    required List<_NumberCandidate>
        decimalCandidates,
    required List<double> matchOdds,
  }) {
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
      ],
    );

    final List<_NumberCandidate> candidates =
        decimalCandidates.where(
      (_NumberCandidate item) {
        if (item.value < 1.01 ||
            item.value > 100000) {
          return false;
        }

        if (_looksLikeMoneyLine(item.line)) {
          return false;
        }

        return true;
      },
    ).toList();

    if (candidates.isEmpty) {
      return null;
    }

    if (matchOdds.length >= 2) {
      final double product =
          matchOdds.fold<double>(
        1,
        (
          double current,
          double value,
        ) {
          return current * value;
        },
      );

      _NumberCandidate? best;
      double bestDifference =
          double.infinity;

      for (final _NumberCandidate candidate
          in candidates) {
        final double difference =
            (candidate.value - product)
                .abs();

        if (difference <
            bestDifference) {
          bestDifference = difference;
          best = candidate;
        }
      }

      final double tolerance =
          math.max(
        product * 0.04,
        0.10,
      );

      if (best != null &&
          bestDifference <= tolerance) {
        return best.value;
      }
    }

    if (labelIndex >= 0) {
      final List<_NumberCandidate> nearby =
          candidates.where(
        (_NumberCandidate item) {
          return (item.lineIndex -
                      labelIndex)
                  .abs() <=
              6;
        },
      ).toList();

      if (nearby.isNotEmpty) {
        nearby.sort(
          (
            _NumberCandidate first,
            _NumberCandidate second,
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

    final List<double> largerValues =
        candidates
            .map(
              (_NumberCandidate item) =>
                  item.value,
            )
            .where(
              (double value) =>
                  value >= 10,
            )
            .toList();

    if (largerValues.isEmpty) {
      return null;
    }

    largerValues.sort();

    return largerValues.last;
  }

  double? _detectPossibleWin({
    required List<String> lines,
    required List<_MoneyCandidate>
        moneyCandidates,
    required double? totalOdds,
  }) {
    if (moneyCandidates.isEmpty) {
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
          moneyCandidates.where(
        (_MoneyCandidate item) {
          return (item.lineIndex -
                      labelIndex)
                  .abs() <=
              7;
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

        final double largest =
            nearby.first.value;

        if (largest >= 1000) {
          return largest;
        }
      }
    }

    final List<double> values =
        moneyCandidates
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
        moneyCandidates,
    required double? totalOdds,
    required double? possibleWin,
  }) {
    if (moneyCandidates.isEmpty) {
      return null;
    }

    if (totalOdds != null &&
        possibleWin != null &&
        totalOdds > 1) {
      final double calculatedStake =
          possibleWin / totalOdds;

      _MoneyCandidate? closest;
      double closestDifference =
          double.infinity;

      for (final _MoneyCandidate candidate
          in moneyCandidates) {
        if ((candidate.value -
                    possibleWin)
                .abs() <
            0.01) {
          continue;
        }

        final double difference =
            (candidate.value -
                    calculatedStake)
                .abs();

        if (difference <
            closestDifference) {
          closestDifference = difference;
          closest = candidate;
        }
      }

      final double tolerance =
          math.max(
        calculatedStake * 0.08,
        25,
      );

      if (closest != null &&
          closestDifference <= tolerance) {
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
          moneyCandidates.where(
        (_MoneyCandidate item) {
          if ((item.lineIndex -
                      labelIndex)
                  .abs() >
              7) {
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
        final Map<int, int> frequency =
            <int, int>{};

        for (final _MoneyCandidate item
            in nearby) {
          final int rounded =
              item.value.round();

          frequency[rounded] =
              (frequency[rounded] ?? 0) +
                  1;
        }

        int? bestValue;
        int bestCount = 0;

        frequency.forEach(
          (
            int value,
            int count,
          ) {
            if (count > bestCount) {
              bestCount = count;
              bestValue = value;
            } else if (count ==
                    bestCount &&
                bestValue != null &&
                value < bestValue!) {
              bestValue = value;
            }
          },
        );

        if (bestValue != null) {
          return bestValue!.toDouble();
        }
      }
    }

    final List<double> candidates =
        moneyCandidates
            .map(
              (_MoneyCandidate item) =>
                  item.value,
            )
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

    if (candidates.isEmpty) {
      return null;
    }

    final Map<int, int> frequency =
        <int, int>{};

    for (final double value
        in candidates) {
      final int rounded = value.round();

      frequency[rounded] =
          (frequency[rounded] ?? 0) + 1;
    }

    int? bestValue;
    int bestCount = 0;

    frequency.forEach(
      (
        int value,
        int count,
      ) {
        if (count > bestCount) {
          bestCount = count;
          bestValue = value;
        } else if (count ==
                bestCount &&
            bestValue != null &&
            value < bestValue!) {
          bestValue = value;
        }
      },
    );

    return bestValue?.toDouble();
  }

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

    final List<_StringCandidate> candidates =
        <_StringCandidate>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final String line =
          lines[index];

      if (_looksLikeDateLine(line) ||
          _looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line) ||
          _looksLikeAddressOrTaxLine(line) ||
          _looksLikePhoneLine(line)) {
        continue;
      }

      final Iterable<RegExpMatch> matches =
          RegExp(r'\d+').allMatches(line);

      for (final RegExpMatch match
          in matches) {
        final String value =
            match.group(0) ?? '';

        if (value.length < 6 ||
            value.length > 8) {
          continue;
        }

        candidates.add(
          _StringCandidate(
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
        _StringCandidate first,
        _StringCandidate second,
      ) {
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

        if (labelIndex >= 0) {
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
        }

        return first.lineIndex.compareTo(
          second.lineIndex,
        );
      },
    );

    return candidates.first.value;
  }

  DateTime? _detectSubmittedAt(
    List<String> lines,
    List<_DetectedMatch> detectedMatches,
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

    final List<_DateCandidate> candidates =
        <_DateCandidate>[];

    for (int index = 0;
        index < lines.length;
        index++) {
      final DateTime? value =
          _parseDateTimeFromText(
        lines[index],
      );

      if (value == null ||
          (value.hour == 0 &&
              value.minute == 0)) {
        continue;
      }

      candidates.add(
        _DateCandidate(
          value: value,
          lineIndex: index,
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    if (labelIndex >= 0) {
      candidates.sort(
        (
          _DateCandidate first,
          _DateCandidate second,
        ) {
          final int firstDistance =
              (first.lineIndex -
                      labelIndex)
                  .abs();

          final int secondDistance =
              (second.lineIndex -
                      labelIndex)
                  .abs();

          final bool firstHasMinutes =
              first.value.minute != 0;

          final bool secondHasMinutes =
              second.value.minute != 0;

          if (firstHasMinutes &&
              !secondHasMinutes) {
            return -1;
          }

          if (!firstHasMinutes &&
              secondHasMinutes) {
            return 1;
          }

          return firstDistance.compareTo(
            secondDistance,
          );
        },
      );

      return candidates.first.value;
    }

    final List<_DateCandidate> exactMinutes =
        candidates.where(
      (_DateCandidate item) {
        return item.value.minute != 0;
      },
    ).toList();

    if (exactMinutes.isNotEmpty) {
      return exactMinutes.last.value;
    }

    return candidates.last.value;
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
        values.add(value);
      }
    }

    if (values.isEmpty) {
      return null;
    }

    values.sort();

    return values.last;
  }

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

  List<String>? _splitMatchLine(
    String line,
  ) {
    String value = line.trim();

    if (value.length < 5 ||
        value.length > 120) {
      return null;
    }

    if (_looksLikeDateLine(value) ||
        _looksLikeMoneyLine(value) ||
        _looksLikeBarcodeLine(value) ||
        _looksLikeAddressOrTaxLine(value) ||
        _looksLikePhoneLine(value) ||
        _isMetadataLine(value)) {
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
        )
        .replaceAll(
          RegExp(
            r'\s+-a-',
            caseSensitive: false,
          ),
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
        expression.firstMatch(value);

    if (match == null) {
      return null;
    }

    final String home =
        (match.group(1) ?? '').trim();

    final String away =
        (match.group(2) ?? '').trim();

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

    result = result
        .replaceAll(
          RegExp(
            r'^Super\s+No$',
            caseSensitive: false,
          ),
          'Super Nova',
        )
        .replaceAll(
          RegExp(
            r'^Super\s+No\s+a$',
            caseSensitive: false,
          ),
          'Super Nova',
        );

    if (result.startsWith('a-') &&
        result.length > 2) {
      result =
          result.substring(2).trim();
    }

    return result;
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

  bool _containsEnoughLetters(
    String value,
  ) {
    final int count =
        RegExp(
      r'[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]',
    ).allMatches(value).length;

    return count >= 2;
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
          r'\d{1,3}(?:[ .]\d{3})+\s*,?\s*-',
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
        RegExp(
      r'[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]',
    ).allMatches(line).length;

    return digits.length >= 9 &&
        letters == 0;
  }

  bool _looksLikePhoneLine(
    String line,
  ) {
    final String normalized =
        _normalizeForSearch(line);

    if (normalized.contains('tel') ||
        normalized.contains('telefon')) {
      return true;
    }

    return RegExp(
      r'\(\d{1,3}\)\s*\d{3}[- ]?\d{3,4}',
    ).hasMatch(line);
  }

  bool _looksLikeAddressOrTaxLine(
    String line,
  ) {
    final String normalized =
        _normalizeForSearch(line);

    const List<String> keywords =
        <String>[
      'adoszam',
      'utca',
      'u.',
      'budapest',
      'godollo',
      'szerencsejatek',
      'zrt',
      'sarok delikat',
      'csalogany',
      'erzsebet',
    ];

    return keywords.any(
      normalized.contains,
    );
  }

  bool _isMetadataLine(
    String line,
  ) {
    final String normalized =
        _normalizeForSearch(line);

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

      final double? value =
          double.tryParse(
        normalizedValue,
      );

      if (value != null) {
        result.add(value);
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
      score += 10;
    }

    if (matches.length >= 2) {
      score += 5;
    }

    final bool allMatchesComplete =
        matches.isNotEmpty &&
            matches.every(
              (RecognizedMatch match) {
                return match.hasOdds &&
                    match.hasTip &&
                    match.market.isNotEmpty;
              },
            );

    if (allMatchesComplete) {
      score += 10;
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
        possibleWin * 0.04,
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
        possibleWin * 0.04,
        10,
      );

      if (difference > tolerance) {
        warnings.add(
          'A felismert tét, eredő odds és '
          'maximális nyeremény matematikailag '
          'nem egyezik teljesen.',
        );
      }
    }

    if (confidence < 50) {
      warnings.add(
        'A felismerés bizonytalan. '
        'Készíts élesebb és egyenesebb képet.',
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
        )
        .replaceAll(
          RegExp(
            r'\bSuper\s+No\s*-\s*Ogre\b',
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

class _NumberCandidate {
  final double value;
  final int lineIndex;
  final String line;

  const _NumberCandidate({
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

class _StringCandidate {
  final String value;
  final int lineIndex;

  const _StringCandidate({
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
