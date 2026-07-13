// ===========================================
// Zsolt Pro AI
// Version: v0.19.6
// File: lib/services/betslip_parser_v5_service.dart
// Parser: V5.3
// ===========================================

import 'dart:math' as math;

import '../models/recognized_betslip.dart';

/// Zsolt Pro AI – Tippmix Parser V5.3.
///
/// A V5.3 fő javításai:
/// - mérkőzésenkénti oddsok keresése a mérkőzés előtt és után is;
/// - a mérkőzésenkénti oddsok sorrendje nem csúszik el;
/// - ugyanaz az odds nem rendelhető több mérkőzéshez;
/// - az eredő odds segítségével matematikai ellenőrzést végez;
/// - felismeri a 8,00 / 8.00 / 8 00 formátumokat;
/// - felismeri az önálló OCR-sorba került oddsokat;
/// - pontosabb „Játékba küldve” dátum- és időfelismerés;
/// - felismeri a 2026,05,16,11:34 formátumot is;
/// - felismeri a 2026,05,16,11,34 formátumot is;
/// - megvédi a dátumokat a decimális normalizálástól;
/// - a címke előtt szereplő dátumokat is megvizsgálja;
/// - előnyben részesíti a pontos perccel rendelkező időpontot;
/// - kizárja a mérkőzések kezdési időpontjait;
/// - tét, eredő odds és nyeremény matematikai ellenőrzése.
class BetslipParserV5Service {
  BetslipParserV5Service._();

  static final BetslipParserV5Service instance =
      BetslipParserV5Service._();

  RecognizedBetslip parse(String rawText) {
    final String cleanedText = cleanOcrText(rawText);
    final List<String> lines = extractCleanLines(cleanedText);

    final List<_DetectedMatch> detectedMatches =
        _detectMatches(lines);

    final List<_DecimalCandidate> decimalCandidates =
        _collectDecimalCandidates(lines);

    final List<_MoneyCandidate> moneyCandidates =
        _collectMoneyCandidates(lines);

    final double? preliminaryTotalOdds =
        _detectPrintedTotalOdds(
      lines: lines,
      decimals: decimalCandidates,
    );

    final List<double?> matchOdds = _detectMatchOdds(
      lines: lines,
      matches: detectedMatches,
      decimals: decimalCandidates,
      expectedTotalOdds: preliminaryTotalOdds,
    );

    final double? totalOdds = _detectTotalOdds(
      lines: lines,
      decimals: decimalCandidates,
      matchOdds: matchOdds,
      printedTotalOdds: preliminaryTotalOdds,
    );

    double? stake = _detectStake(
      lines: lines,
      moneyCandidates: moneyCandidates,
    );

    double? possibleWin = _detectPossibleWin(
      lines: lines,
      moneyCandidates: moneyCandidates,
    );

    final _MoneyResolution moneyResolution =
        _resolveMoneyValues(
      stake: stake,
      possibleWin: possibleWin,
      totalOdds: totalOdds,
      moneyCandidates: moneyCandidates,
    );

    stake = moneyResolution.stake;
    possibleWin = moneyResolution.possibleWin;

    final String? betslipNumber =
        _detectBetslipNumber(lines);

    final DateTime? submittedAt =
        _detectSubmittedAt(
      lines: lines,
      detectedMatches: detectedMatches,
    );

    final int? printedMatchCount =
        _detectPrintedMatchCount(lines);

    final List<RecognizedMatch> matches =
        _buildRecognizedMatches(
      detectedMatches: detectedMatches,
      matchOdds: matchOdds,
    );

    final int? matchCount = matches.isNotEmpty
        ? math.max(
            matches.length,
            printedMatchCount ?? 0,
          )
        : printedMatchCount;

    final int confidence = _calculateConfidence(
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

    final List<String> warnings = _buildWarnings(
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

  String cleanOcrText(String value) {
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
        .replaceAll(RegExp(r'[ ]{2,}'), ' ')
        .replaceAll(RegExp(r' *\n *'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    result = _fixDigitOcrErrors(result);
    result = _fixCommonTippmixWords(result);
    result = _normalizeMoneyFormats(result);
    result = _normalizeDecimalFormats(result);
    result = _normalizeTeamSeparators(result);
    result = _removeUselessLines(result);

    return result.trim();
  }

  List<String> extractCleanLines(String value) {
    if (value.trim().isEmpty) {
      return const <String>[];
    }

    return value
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
  }

  bool looksLikeTippmixBetslip(String value) {
    final String normalized = normalizeForSearch(value);

    if (normalized.isEmpty) {
      return false;
    }

    const List<String> keywords = <String>[
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

  String normalizeForSearch(String value) {
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
          RegExp(r'[^a-z0-9,.%:+\-\s]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _fixDigitOcrErrors(String value) {
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

  String _fixCommonTippmixWords(String value) {
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
            r'\bmaxim[aá]lis\s+nyerem[eé]ny\b',
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

  String _normalizeMoneyFormats(String value) {
    String result = value
        .replaceAll('\$', '')
        .replaceAll('§', '')
        .replaceAll('¢', '');

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{1,3})[ .,:](\d{3})\s*,?\s*-\s*(?:Ft)?\b',
        caseSensitive: false,
      ),
      (Match match) {
        final String first = match.group(1) ?? '';
        final String second = match.group(2) ?? '';

        return '$first$second Ft';
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{1,3}(?:[ .]\d{3})+)\s*(Ft)?\b',
        caseSensitive: false,
      ),
      (Match match) {
        final String digits = (match.group(1) ?? '')
            .replaceAll(' ', '')
            .replaceAll('.', '');

        final bool hasFt = match.group(2) != null;

        return hasFt ? '$digits Ft' : digits;
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{1,3})[,.](\d{2})\s*(\d)\s*(?:Ft)?\b',
        caseSensitive: false,
      ),
      (Match match) {
        final String first = match.group(1) ?? '';
        final String middle = match.group(2) ?? '';
        final String last = match.group(3) ?? '';

        return '$first$middle$last Ft';
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{2,9})\s*,?\s*-\s*(?:Ft)?\b',
        caseSensitive: false,
      ),
      (Match match) {
        return '${match.group(1)} Ft';
      },
    );

    result = result.replaceAll(
      RegExp(
        r'\s+Ft\b',
        caseSensitive: false,
      ),
      ' Ft',
    );

    return result;
  }

  String _normalizeDecimalFormats(String value) {
    String result = value;

    final Map<String, String> protectedDateTimes =
        <String, String>{};

    int protectedIndex = 0;

    result = result.replaceAllMapped(
      RegExp(
        r'(20\d{2}[.,/\-]+'
        r'\d{1,2}[.,/\-]+'
        r'\d{1,2}[.,\s\-]+'
        r'\d{1,2})\s*:\s*(\d{2})',
      ),
      (Match match) {
        final String key =
            'PROTECTEDDATETIME$protectedIndex';

        protectedDateTimes[key] =
            '${match.group(1)}:${match.group(2)}';

        protectedIndex++;

        return key;
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'(?<!\d)(\d{1,2})\s*[,:;]\s*(\d{2,3})(?!\d)',
      ),
      (Match match) {
        final String whole = match.group(1) ?? '';
        final String decimal = match.group(2) ?? '';

        return '$whole,$decimal';
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'(?<!\d)(\d{1,2})\s+(\d{2})(?!\d)',
      ),
      (Match match) {
        final String whole = match.group(1) ?? '';
        final String decimal = match.group(2) ?? '';

        return '$whole,$decimal';
      },
    );

    for (final MapEntry<String, String> entry
        in protectedDateTimes.entries) {
      result = result.replaceAll(
        entry.key,
        entry.value,
      );
    }

    return result;
  }

  String _normalizeTeamSeparators(String value) {
    return value
        .replaceAll(
          RegExp(r'\s+[vV][sS]\.?\s+'),
          ' - ',
        )
        .replaceAll(
          RegExp(r'\s+[vV]\s+'),
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

  String _removeUselessLines(String value) {
    final List<String> result = <String>[];

    for (final String rawLine in value.split('\n')) {
      final String line = rawLine.trim();

      if (line.isEmpty) {
        continue;
      }

      final String content = line.replaceAll(
        RegExp(
          r'[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű0-9]',
        ),
        '',
      );

      if (content.isEmpty) {
        continue;
      }

      if (line.length == 1 &&
          !RegExp(r'[0-9Xx]').hasMatch(line)) {
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

    for (int index = 0; index < lines.length; index++) {
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

      final bool duplicate = result.any(
        (_DetectedMatch item) {
          return normalizeForSearch(item.homeTeam) ==
                  normalizeForSearch(homeTeam) &&
              normalizeForSearch(item.awayTeam) ==
                  normalizeForSearch(awayTeam);
        },
      );

      if (duplicate) {
        continue;
      }

      String market = '';
      String tip = 'Ismeretlen tipp';

      final List<String> sourceLines = <String>[];

      final int start = math.max(0, index - 5);
      final int end =
          math.min(lines.length - 1, index + 8);

      for (int nearby = start; nearby <= end; nearby++) {
        final String nearbyLine = lines[nearby];

        sourceLines.add(nearbyLine);

        if (market.isEmpty) {
          market = _detectMarket(nearbyLine);
        }

        if (tip == 'Ismeretlen tipp') {
          final String detectedTip = _detectTip(
            line: nearbyLine,
            market: market,
          );

          if (detectedTip.isNotEmpty) {
            tip = detectedTip;
          }
        }
      }

      if (market.isEmpty &&
          (tip == '6+' || tip.contains('gól'))) {
        market = 'Gólok';
      }

      if (market == 'Gólok' && tip == '6+') {
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

  List<String>? _splitMatchLine(String line) {
    String value = line.trim();

    if (value.length < 5 || value.length > 120) {
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

    final RegExp expression = RegExp(
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

    return <String>[home, away];
  }

  String _cleanTeamName(String value) {
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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (RegExp(
      r'^Super\s+No$',
      caseSensitive: false,
    ).hasMatch(result)) {
      result = 'Super Nova';
    }

    return result;
  }

  String _detectMarket(String line) {
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

    if (normalized.contains('dupla esely')) {
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
      return market == 'Gólok' ? '6+ gól' : '6+';
    }

    final RegExp overUnder = RegExp(
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

      final String number =
          (match.group(2) ?? '').replaceAll('.', ',');

      return '$direction $number';
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
  // ODDSOK
  // =========================================================

  List<_DecimalCandidate> _collectDecimalCandidates(
    List<String> lines,
  ) {
    final List<_DecimalCandidate> result =
        <_DecimalCandidate>[];

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];

      if (_looksLikeDateLine(line) ||
          _looksLikeBarcodeLine(line) ||
          _looksLikeAddressLine(line) ||
          _looksLikeMoneyLine(line)) {
        continue;
      }

      final Set<String> addedValues = <String>{};

      final Iterable<RegExpMatch> normalMatches =
          RegExp(
        r'(^|[^0-9])'
        r'(\d{1,6}[,.]\d{1,3})'
        r'(?=$|[^0-9])',
      ).allMatches(line);

      for (final RegExpMatch match in normalMatches) {
        final String rawValue =
            match.group(2) ?? '';

        final double? value = double.tryParse(
          rawValue.replaceAll(',', '.'),
        );

        if (value == null ||
            value < 1.01 ||
            value > 1000000) {
          continue;
        }

        final String key =
            value.toStringAsFixed(3);

        if (!addedValues.add(key)) {
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

      final RegExpMatch? spacedMatch =
          RegExp(
        r'^\s*(\d{1,2})\s+(\d{2,3})\s*$',
      ).firstMatch(line);

      if (spacedMatch != null) {
        final String whole =
            spacedMatch.group(1) ?? '';

        final String decimal =
            spacedMatch.group(2) ?? '';

        final double? value = double.tryParse(
          '$whole.$decimal',
        );

        if (value != null &&
            value >= 1.01 &&
            value <= 1000) {
          final String key =
              value.toStringAsFixed(3);

          if (addedValues.add(key)) {
            result.add(
              _DecimalCandidate(
                value: value,
                lineIndex: index,
                line: line,
              ),
            );
          }
        }
      }

      final String trimmed = line.trim();

      if (RegExp(r'^\d{3}$').hasMatch(trimmed)) {
        final int? number = int.tryParse(trimmed);

        if (number != null &&
            number >= 101 &&
            number <= 999) {
          final double value = number / 100;

          final String key =
              value.toStringAsFixed(3);

          if (addedValues.add(key)) {
            result.add(
              _DecimalCandidate(
                value: value,
                lineIndex: index,
                line: line,
                isImpliedDecimal: true,
              ),
            );
          }
        }
      }

      if (RegExp(r'^\d{4}$').hasMatch(trimmed)) {
        final int? number = int.tryParse(trimmed);

        if (number != null &&
            number >= 1000 &&
            number <= 9999) {
          final double twoDecimalValue =
              number / 100;

          final double threeDecimalValue =
              number / 1000;

          if (twoDecimalValue >= 1.01 &&
              twoDecimalValue <= 100) {
            final String key =
                twoDecimalValue.toStringAsFixed(3);

            if (addedValues.add(key)) {
              result.add(
                _DecimalCandidate(
                  value: twoDecimalValue,
                  lineIndex: index,
                  line: line,
                  isImpliedDecimal: true,
                ),
              );
            }
          }

          if (threeDecimalValue >= 1.01 &&
              threeDecimalValue <= 30) {
            final String key =
                threeDecimalValue.toStringAsFixed(3);

            if (addedValues.add(key)) {
              result.add(
                _DecimalCandidate(
                  value: threeDecimalValue,
                  lineIndex: index,
                  line: line,
                  isImpliedDecimal: true,
                ),
              );
            }
          }
        }
      }
    }

    return result;
  }

  double? _detectPrintedTotalOdds({
    required List<String> lines,
    required List<_DecimalCandidate> decimals,
  }) {
    final int labelIndex = _findLabelIndex(
      lines,
      const <String>[
        'eredo odds',
        'eredő odds',
        'ossz odds',
        'össz odds',
      ],
    );

    if (labelIndex < 0) {
      return null;
    }

    final List<_DecimalCandidate> candidates =
        decimals.where(
      (_DecimalCandidate candidate) {
        final int distance =
            (candidate.lineIndex - labelIndex).abs();

        return distance <= 8 &&
            candidate.value >= 1.01 &&
            candidate.value <= 100000;
      },
    ).toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        _DecimalCandidate first,
        _DecimalCandidate second,
      ) {
        final int firstDistance =
            (first.lineIndex - labelIndex).abs();

        final int secondDistance =
            (second.lineIndex - labelIndex).abs();

        if (firstDistance != secondDistance) {
          return firstDistance.compareTo(
            secondDistance,
          );
        }

        if (first.isImpliedDecimal !=
            second.isImpliedDecimal) {
          return first.isImpliedDecimal ? 1 : -1;
        }

        return second.value.compareTo(first.value);
      },
    );

    return candidates.first.value;
  }

  List<double?> _detectMatchOdds({
    required List<String> lines,
    required List<_DetectedMatch> matches,
    required List<_DecimalCandidate> decimals,
    required double? expectedTotalOdds,
  }) {
    if (matches.isEmpty) {
      return const <double?>[];
    }

    final List<double?> result =
        List<double?>.filled(
      matches.length,
      null,
      growable: false,
    );

    final Set<int> usedCandidateIndexes = <int>{};

    final List<List<_ScoredDecimalCandidate>>
        candidatesPerMatch =
        <List<_ScoredDecimalCandidate>>[];

    for (int matchIndex = 0;
        matchIndex < matches.length;
        matchIndex++) {
      final _DetectedMatch detectedMatch =
          matches[matchIndex];

      final List<_ScoredDecimalCandidate> scored =
          <_ScoredDecimalCandidate>[];

      for (int decimalIndex = 0;
          decimalIndex < decimals.length;
          decimalIndex++) {
        final _DecimalCandidate candidate =
            decimals[decimalIndex];

        if (candidate.value < 1.01 ||
            candidate.value > 100) {
          continue;
        }

        final String normalized =
            normalizeForSearch(candidate.line);

        if (_isRejectedOddsLine(normalized)) {
          continue;
        }

        final int distance =
            (candidate.lineIndex -
                    detectedMatch.lineIndex)
                .abs();

        if (distance > 10) {
          continue;
        }

        int score = 100 - (distance * 9);

        if (candidate.lineIndex >=
            detectedMatch.lineIndex) {
          score += 6;
        }

        if (candidate.lineIndex ==
            detectedMatch.lineIndex) {
          score += 18;
        }

        if (distance <= 3) {
          score += 20;
        }

        if (_lineLooksLikeStandaloneOdds(
          candidate.line,
        )) {
          score += 25;
        }

        if (candidate.isImpliedDecimal) {
          score -= 12;
        }

        final int nearestMatchIndex =
            _findNearestMatchIndex(
          candidate.lineIndex,
          matches,
        );

        if (nearestMatchIndex == matchIndex) {
          score += 30;
        } else {
          score -= 35;
        }

        scored.add(
          _ScoredDecimalCandidate(
            decimalIndex: decimalIndex,
            candidate: candidate,
            score: score,
          ),
        );
      }

      scored.sort(
        (
          _ScoredDecimalCandidate first,
          _ScoredDecimalCandidate second,
        ) {
          return second.score.compareTo(first.score);
        },
      );

      candidatesPerMatch.add(scored);
    }

    if (matches.length == 2 &&
        expectedTotalOdds != null) {
      final _OddsPairResolution? pairResolution =
          _findBestOddsPair(
        firstCandidates: candidatesPerMatch[0],
        secondCandidates: candidatesPerMatch[1],
        expectedTotalOdds: expectedTotalOdds,
      );

      if (pairResolution != null) {
        result[0] =
            pairResolution.first.candidate.value;

        result[1] =
            pairResolution.second.candidate.value;

        usedCandidateIndexes.add(
          pairResolution.first.decimalIndex,
        );

        usedCandidateIndexes.add(
          pairResolution.second.decimalIndex,
        );
      }
    }

    for (int matchIndex = 0;
        matchIndex < matches.length;
        matchIndex++) {
      if (result[matchIndex] != null) {
        continue;
      }

      final List<_ScoredDecimalCandidate> candidates =
          candidatesPerMatch[matchIndex];

      for (final _ScoredDecimalCandidate candidate
          in candidates) {
        if (usedCandidateIndexes.contains(
          candidate.decimalIndex,
        )) {
          continue;
        }

        if (candidate.score < 20) {
          continue;
        }

        result[matchIndex] =
            candidate.candidate.value;

        usedCandidateIndexes.add(
          candidate.decimalIndex,
        );

        break;
      }
    }

    return result;
  }

  _OddsPairResolution? _findBestOddsPair({
    required List<_ScoredDecimalCandidate>
        firstCandidates,
    required List<_ScoredDecimalCandidate>
        secondCandidates,
    required double expectedTotalOdds,
  }) {
    if (firstCandidates.isEmpty ||
        secondCandidates.isEmpty) {
      return null;
    }

    _OddsPairResolution? bestResolution;
    double bestCombinedScore =
        double.negativeInfinity;

    final List<_ScoredDecimalCandidate> firstLimited =
        firstCandidates.take(12).toList();

    final List<_ScoredDecimalCandidate> secondLimited =
        secondCandidates.take(12).toList();

    for (final _ScoredDecimalCandidate first
        in firstLimited) {
      for (final _ScoredDecimalCandidate second
          in secondLimited) {
        if (first.decimalIndex ==
            second.decimalIndex) {
          continue;
        }

        final double product =
            first.candidate.value *
                second.candidate.value;

        final double difference =
            (product - expectedTotalOdds).abs();

        final double tolerance = math.max(
          expectedTotalOdds * 0.035,
          0.12,
        );

        final double mathematicalScore =
            difference <= tolerance
                ? 180 - (difference * 100)
                : -(difference * 20);

        final double combinedScore =
            first.score +
                second.score +
                mathematicalScore;

        if (combinedScore > bestCombinedScore) {
          bestCombinedScore = combinedScore;

          bestResolution = _OddsPairResolution(
            first: first,
            second: second,
            difference: difference,
          );
        }
      }
    }

    if (bestResolution == null) {
      return null;
    }

    final double tolerance = math.max(
      expectedTotalOdds * 0.05,
      0.20,
    );

    if (bestResolution.difference > tolerance) {
      return null;
    }

    return bestResolution;
  }

  int _findNearestMatchIndex(
    int lineIndex,
    List<_DetectedMatch> matches,
  ) {
    int bestIndex = 0;
    int bestDistance =
        (matches.first.lineIndex - lineIndex).abs();

    for (int index = 1;
        index < matches.length;
        index++) {
      final int distance =
          (matches[index].lineIndex - lineIndex).abs();

      if (distance < bestDistance) {
        bestIndex = index;
        bestDistance = distance;
      }
    }

    return bestIndex;
  }

  bool _isRejectedOddsLine(String normalized) {
    const List<String> blocked = <String>[
      'eredo odds',
      'max nyeremeny',
      'ervenyesseg',
      'akcio',
      'szelveny',
      'jatekba kuldve',
      'jatek ara',
      'alaptet',
      'fogadasszam',
      'kombinacio',
      'adoszam',
      'telefon',
    ];

    return blocked.any(normalized.contains);
  }

  bool _lineLooksLikeStandaloneOdds(String line) {
    final String trimmed = line.trim();

    return RegExp(
      r'^\d{1,2}[,.]\d{1,3}$',
    ).hasMatch(trimmed) ||
        RegExp(
          r'^\d{1,2}\s+\d{2,3}$',
        ).hasMatch(trimmed) ||
        RegExp(
          r'^\d{3,4}$',
        ).hasMatch(trimmed);
  }

  double? _detectTotalOdds({
    required List<String> lines,
    required List<_DecimalCandidate> decimals,
    required List<double?> matchOdds,
    required double? printedTotalOdds,
  }) {
    final List<double> validMatchOdds = matchOdds
        .whereType<double>()
        .where(
          (double value) =>
              value >= 1.01 && value <= 100,
        )
        .toList();

    if (printedTotalOdds != null) {
      return printedTotalOdds;
    }

    if (validMatchOdds.length >= 2) {
      final double product =
          validMatchOdds.fold<double>(
        1,
        (
          double current,
          double value,
        ) {
          return current * value;
        },
      );

      _DecimalCandidate? closest;
      double closestDifference = double.infinity;

      for (final _DecimalCandidate candidate
          in decimals) {
        final String normalized =
            normalizeForSearch(candidate.line);

        if (_looksLikeDateLine(candidate.line) ||
            _looksLikeMoneyLine(candidate.line) ||
            _looksLikeBarcodeLine(candidate.line) ||
            _looksLikeAddressLine(candidate.line)) {
          continue;
        }

        if (normalized.contains('akcio')) {
          continue;
        }

        final double difference =
            (candidate.value - product).abs();

        if (difference < closestDifference) {
          closestDifference = difference;
          closest = candidate;
        }
      }

      final double tolerance =
          math.max(product * 0.03, 0.10);

      if (closest != null &&
          closestDifference <= tolerance) {
        return closest.value;
      }

      return double.parse(
        product.toStringAsFixed(2),
      );
    }

    final int labelIndex = _findLabelIndex(
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
        (_DecimalCandidate candidate) {
          return (candidate.lineIndex - labelIndex)
                      .abs() <=
                  8 &&
              candidate.value >= 1.01 &&
              candidate.value <= 100000;
        },
      ).toList();

      if (nearby.isNotEmpty) {
        nearby.sort(
          (
            _DecimalCandidate first,
            _DecimalCandidate second,
          ) {
            final int firstDistance =
                (first.lineIndex - labelIndex).abs();

            final int secondDistance =
                (second.lineIndex - labelIndex).abs();

            return firstDistance.compareTo(
              secondDistance,
            );
          },
        );

        return nearby.first.value;
      }
    }

    final List<double> candidates = decimals
        .map(
          (_DecimalCandidate item) => item.value,
        )
        .where(
          (double value) =>
              value >= 10 && value <= 100000,
        )
        .toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort();

    return candidates.last;
  }

  // =========================================================
  // PÉNZÉRTÉKEK
  // =========================================================

  List<_MoneyCandidate> _collectMoneyCandidates(
    List<String> lines,
  ) {
    final List<_MoneyCandidate> result =
        <_MoneyCandidate>[];

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];

      if (!_looksLikeMoneyLine(line) ||
          _looksLikeAddressLine(line) ||
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

  List<double> _extractMoneyValues(String line) {
    final List<double> result = <double>[];

    final String cleaned = line
        .replaceAll(
          RegExp(
            r'\bFt\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(',-', '')
        .replaceAll(' ', '');

    final Iterable<RegExpMatch> matches = RegExp(
      r'\d+(?:[,.]\d{1,2})?',
    ).allMatches(cleaned);

    for (final RegExpMatch match in matches) {
      final String rawValue =
          match.group(0) ?? '';

      final double? value = double.tryParse(
        rawValue.replaceAll(',', '.'),
      );

      if (value != null) {
        result.add(value);
      }
    }

    return result;
  }

  double? _detectStake({
    required List<String> lines,
    required List<_MoneyCandidate> moneyCandidates,
  }) {
    const List<String> labels = <String>[
      'alaptet',
      'alaptét',
      'a jatek ara',
      'a játék ára',
      'fogadasi tet',
      'fogadási tét',
    ];

    for (final String label in labels) {
      final int labelIndex = _findLabelIndex(
        lines,
        <String>[label],
      );

      if (labelIndex < 0) {
        continue;
      }

      final List<_MoneyCandidate> nearby =
          moneyCandidates.where(
        (_MoneyCandidate candidate) {
          final int distance =
              (candidate.lineIndex - labelIndex).abs();

          return distance <= 10 &&
              candidate.value >= 50 &&
              candidate.value <= 10000000;
        },
      ).toList();

      if (nearby.isEmpty) {
        continue;
      }

      nearby.sort(
        (
          _MoneyCandidate first,
          _MoneyCandidate second,
        ) {
          final int firstDistance =
              (first.lineIndex - labelIndex).abs();

          final int secondDistance =
              (second.lineIndex - labelIndex).abs();

          if (firstDistance != secondDistance) {
            return firstDistance.compareTo(
              secondDistance,
            );
          }

          return first.value.compareTo(
            second.value,
          );
        },
      );

      return nearby.first.value;
    }

    return null;
  }

  double? _detectPossibleWin({
    required List<String> lines,
    required List<_MoneyCandidate> moneyCandidates,
  }) {
    final int labelIndex = _findLabelIndex(
      lines,
      const <String>[
        'max nyeremeny',
        'max nyeremény',
        'maximalis nyeremeny',
        'maximális nyeremény',
      ],
    );

    if (labelIndex < 0) {
      return null;
    }

    final List<_MoneyCandidate> nearby =
        moneyCandidates.where(
      (_MoneyCandidate candidate) {
        final int distance =
            (candidate.lineIndex - labelIndex).abs();

        return distance <= 10 &&
            candidate.value >= 100;
      },
    ).toList();

    if (nearby.isEmpty) {
      return null;
    }

    nearby.sort(
      (
        _MoneyCandidate first,
        _MoneyCandidate second,
      ) {
        final int firstDistance =
            (first.lineIndex - labelIndex).abs();

        final int secondDistance =
            (second.lineIndex - labelIndex).abs();

        if (firstDistance != secondDistance) {
          return firstDistance.compareTo(
            secondDistance,
          );
        }

        return second.value.compareTo(
          first.value,
        );
      },
    );

    return nearby.first.value;
  }

  _MoneyResolution _resolveMoneyValues({
    required double? stake,
    required double? possibleWin,
    required double? totalOdds,
    required List<_MoneyCandidate> moneyCandidates,
  }) {
    if (totalOdds == null || totalOdds <= 1) {
      return _MoneyResolution(
        stake: stake,
        possibleWin: possibleWin,
      );
    }

    double? resolvedStake = stake;
    double? resolvedPossibleWin = possibleWin;

    if (resolvedStake != null &&
        resolvedPossibleWin != null) {
      final double expectedWin =
          resolvedStake * totalOdds;

      final double tolerance = math.max(
        resolvedPossibleWin * 0.03,
        20,
      );

      if ((expectedWin - resolvedPossibleWin).abs() <=
          tolerance) {
        return _MoneyResolution(
          stake: resolvedStake,
          possibleWin: resolvedPossibleWin,
        );
      }
    }

    final List<double> moneyValues = moneyCandidates
        .map(
          (_MoneyCandidate candidate) =>
              candidate.value,
        )
        .where(
          (double value) =>
              value >= 50 &&
              value <= 1000000000,
        )
        .toSet()
        .toList();

    double bestDifference = double.infinity;
    double? bestStake;
    double? bestPossibleWin;

    for (final double stakeCandidate in moneyValues) {
      for (final double winCandidate in moneyValues) {
        if (winCandidate <= stakeCandidate) {
          continue;
        }

        final double calculatedWin =
            stakeCandidate * totalOdds;

        final double difference =
            (calculatedWin - winCandidate).abs();

        if (difference < bestDifference) {
          bestDifference = difference;
          bestStake = stakeCandidate;
          bestPossibleWin = winCandidate;
        }
      }
    }

    if (bestStake != null &&
        bestPossibleWin != null) {
      final double tolerance = math.max(
        bestPossibleWin * 0.03,
        20,
      );

      if (bestDifference <= tolerance) {
        resolvedStake = bestStake;
        resolvedPossibleWin = bestPossibleWin;
      }
    }

    if (resolvedStake != null &&
        resolvedPossibleWin == null) {
      resolvedPossibleWin = double.parse(
        (resolvedStake * totalOdds)
            .toStringAsFixed(0),
      );
    }

    if (resolvedPossibleWin != null &&
        resolvedStake == null) {
      final double calculatedStake =
          resolvedPossibleWin / totalOdds;

      resolvedStake = _findNearestMoneyValue(
        calculatedStake,
        moneyValues,
      );
    }

    return _MoneyResolution(
      stake: resolvedStake,
      possibleWin: resolvedPossibleWin,
    );
  }

  double? _findNearestMoneyValue(
    double target,
    List<double> values,
  ) {
    if (values.isEmpty) {
      return null;
    }

    double bestValue = values.first;
    double bestDifference =
        (bestValue - target).abs();

    for (final double value in values.skip(1)) {
      final double difference =
          (value - target).abs();

      if (difference < bestDifference) {
        bestValue = value;
        bestDifference = difference;
      }
    }

    final double tolerance =
        math.max(target * 0.10, 30);

    if (bestDifference <= tolerance) {
      return bestValue;
    }

    return null;
  }

  // =========================================================
  // SZELVÉNYSZÁM
  // =========================================================

  String? _detectBetslipNumber(
    List<String> lines,
  ) {
    final int labelIndex = _findLabelIndex(
      lines,
      const <String>[
        'szelveny szama',
        'szelvény száma',
        'szelvenyszam',
        'szelvényszám',
      ],
    );

    if (labelIndex >= 0) {
      final int start =
          math.max(0, labelIndex - 5);

      final int end =
          math.min(lines.length - 1, labelIndex + 8);

      final List<_TextCandidate> nearby =
          <_TextCandidate>[];

      for (int index = start;
          index <= end;
          index++) {
        final String line = lines[index];

        if (_looksLikeBarcodeLine(line)) {
          continue;
        }

        final Iterable<RegExpMatch> matches =
            RegExp(
          r'(?<!\d)(0\d{6,7})(?!\d)',
        ).allMatches(line);

        for (final RegExpMatch match in matches) {
          final String value = match.group(1) ?? '';

          if (value.isEmpty) {
            continue;
          }

          nearby.add(
            _TextCandidate(
              value: value,
              lineIndex: index,
            ),
          );
        }
      }

      if (nearby.isNotEmpty) {
        nearby.sort(
          (
            _TextCandidate first,
            _TextCandidate second,
          ) {
            final int firstDistance =
                (first.lineIndex - labelIndex).abs();

            final int secondDistance =
                (second.lineIndex - labelIndex).abs();

            return firstDistance.compareTo(
              secondDistance,
            );
          },
        );

        return nearby.first.value;
      }
    }

    final List<_TextCandidate> candidates =
        <_TextCandidate>[];

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];

      if (_looksLikeMoneyLine(line) ||
          _looksLikeBarcodeLine(line) ||
          _looksLikeAddressLine(line) ||
          _looksLikeDateLine(line)) {
        continue;
      }

      final Iterable<RegExpMatch> matches =
          RegExp(
        r'(?<!\d)(0?\d{6,7})(?!\d)',
      ).allMatches(line);

      for (final RegExpMatch match in matches) {
        final String value = match.group(1) ?? '';

        if (value.isEmpty) {
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
        final bool firstStartsWithZero =
            first.value.startsWith('0');

        final bool secondStartsWithZero =
            second.value.startsWith('0');

        if (firstStartsWithZero &&
            !secondStartsWithZero) {
          return -1;
        }

        if (!firstStartsWithZero &&
            secondStartsWithZero) {
          return 1;
        }

        return first.lineIndex.compareTo(
          second.lineIndex,
        );
      },
    );

    return candidates.first.value;
  }

  // =========================================================
  // JÁTÉKBA KÜLDÉS IDŐPONTJA
  // =========================================================

  DateTime? _detectSubmittedAt({
    required List<String> lines,
    required List<_DetectedMatch> detectedMatches,
  }) {
    final List<_DateCandidate> dateCandidates =
        <_DateCandidate>[];

    for (int index = 0; index < lines.length; index++) {
      final List<DateTime> dates =
          _parseAllDateTimes(lines[index]);

      for (final DateTime date in dates) {
        dateCandidates.add(
          _DateCandidate(
            value: date,
            lineIndex: index,
            sourceLine: lines[index],
          ),
        );
      }
    }

    if (dateCandidates.isEmpty) {
      return null;
    }

    final int labelIndex = _findLabelIndex(
      lines,
      const <String>[
        'jatekba kuldve',
        'játékba küldve',
        'kuldve',
        'küldve',
      ],
    );

    final Set<String> probableMatchDateKeys =
        _collectProbableMatchDateKeys(
      lines: lines,
      detectedMatches: detectedMatches,
    );

    final List<_ScoredDateCandidate> scored =
        <_ScoredDateCandidate>[];

    for (final _DateCandidate candidate
        in dateCandidates) {
      int score = 0;

      final bool hasExplicitTime =
          candidate.value.hour != 0 ||
              candidate.value.minute != 0;

      final bool hasExactMinute =
          candidate.value.minute != 0;

      if (hasExplicitTime) {
        score += 30;
      }

      if (hasExactMinute) {
        score += 55;
      }

      if (candidate.value.minute == 0) {
        score -= 15;
      }

      if (candidate.value.hour >= 6 &&
          candidate.value.hour <= 23) {
        score += 8;
      }

      if (labelIndex >= 0) {
        final int distance =
            (candidate.lineIndex - labelIndex).abs();

        if (distance <= 20) {
          score += math.max(
            0,
            100 - (distance * 5),
          );
        }

        if (candidate.lineIndex <= labelIndex) {
          score += 10;
        }
      }

      final String candidateKey =
          _dateKey(candidate.value);

      if (probableMatchDateKeys.contains(
        candidateKey,
      )) {
        score -= 90;
      }

      final String normalizedSource =
          normalizeForSearch(candidate.sourceLine);

      if (normalizedSource.contains(
            'jatekba kuldve',
          ) ||
          normalizedSource.contains('kuldve')) {
        score += 100;
      }

      if (normalizedSource.contains(
            'ervenyesseg',
          ) ||
          normalizedSource.contains('akcio')) {
        score -= 50;
      }

      scored.add(
        _ScoredDateCandidate(
          candidate: candidate,
          score: score,
        ),
      );
    }

    scored.sort(
      (
        _ScoredDateCandidate first,
        _ScoredDateCandidate second,
      ) {
        if (first.score != second.score) {
          return second.score.compareTo(
            first.score,
          );
        }

        final bool firstHasMinute =
            first.candidate.value.minute != 0;

        final bool secondHasMinute =
            second.candidate.value.minute != 0;

        if (firstHasMinute && !secondHasMinute) {
          return -1;
        }

        if (!firstHasMinute && secondHasMinute) {
          return 1;
        }

        if (labelIndex >= 0) {
          final int firstDistance =
              (first.candidate.lineIndex - labelIndex)
                  .abs();

          final int secondDistance =
              (second.candidate.lineIndex - labelIndex)
                  .abs();

          if (firstDistance != secondDistance) {
            return firstDistance.compareTo(
              secondDistance,
            );
          }
        }

        return second.candidate.lineIndex.compareTo(
          first.candidate.lineIndex,
        );
      },
    );

    if (scored.isEmpty) {
      return null;
    }

    final DateTime selected =
        scored.first.candidate.value;

    if (selected.hour == 0 &&
        selected.minute == 0) {
      return null;
    }

    return selected;
  }

  Set<String> _collectProbableMatchDateKeys({
    required List<String> lines,
    required List<_DetectedMatch> detectedMatches,
  }) {
    final Set<String> result = <String>{};

    for (final _DetectedMatch match
        in detectedMatches) {
      final int start =
          math.max(0, match.lineIndex - 4);

      final int end =
          math.min(
        lines.length - 1,
        match.lineIndex + 4,
      );

      for (int index = start;
          index <= end;
          index++) {
        final List<DateTime> dates =
            _parseAllDateTimes(lines[index]);

        for (final DateTime date in dates) {
          if (date.minute == 0) {
            result.add(_dateKey(date));
          }
        }
      }
    }

    return result;
  }

  List<DateTime> _parseAllDateTimes(
    String text,
  ) {
    final List<DateTime> result = <DateTime>[];

    final RegExp fullExpression = RegExp(
      r'(20\d{2})[.,/\-]+'
      r'(\d{1,2})[.,/\-]+'
      r'(\d{1,2})'
      r'(?:[.,\s\-]+'
      r'(\d{1,2})[:.,]'
      r'(\d{2}))?',
    );

    final Iterable<RegExpMatch> fullMatches =
        fullExpression.allMatches(text);

    for (final RegExpMatch match in fullMatches) {
      final DateTime? value =
          _buildValidDateTime(
        yearText: match.group(1),
        monthText: match.group(2),
        dayText: match.group(3),
        hourText: match.group(4),
        minuteText: match.group(5),
      );

      if (value != null &&
          !result.any(
            (DateTime item) =>
                item.year == value.year &&
                item.month == value.month &&
                item.day == value.day &&
                item.hour == value.hour &&
                item.minute == value.minute,
          )) {
        result.add(value);
      }
    }

    final RegExp spacedExpression = RegExp(
      r'(20\d{2})\s+'
      r'(\d{1,2})\s+'
      r'(\d{1,2})\s+'
      r'(\d{1,2})[:.,]\s*'
      r'(\d{2})',
    );

    final Iterable<RegExpMatch> spacedMatches =
        spacedExpression.allMatches(text);

    for (final RegExpMatch match
        in spacedMatches) {
      final DateTime? value =
          _buildValidDateTime(
        yearText: match.group(1),
        monthText: match.group(2),
        dayText: match.group(3),
        hourText: match.group(4),
        minuteText: match.group(5),
      );

      if (value != null &&
          !result.any(
            (DateTime item) =>
                item.year == value.year &&
                item.month == value.month &&
                item.day == value.day &&
                item.hour == value.hour &&
                item.minute == value.minute,
          )) {
        result.add(value);
      }
    }

    return result;
  }

  DateTime? _buildValidDateTime({
    required String? yearText,
    required String? monthText,
    required String? dayText,
    required String? hourText,
    required String? minuteText,
  }) {
    final int? year =
        int.tryParse(yearText ?? '');

    final int? month =
        int.tryParse(monthText ?? '');

    final int? day =
        int.tryParse(dayText ?? '');

    final int hour =
        int.tryParse(hourText ?? '') ?? 0;

    final int minute =
        int.tryParse(minuteText ?? '') ?? 0;

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

    final DateTime value = DateTime(
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

  String _dateKey(DateTime value) {
    return '${value.year}-'
        '${value.month}-'
        '${value.day}-'
        '${value.hour}-'
        '${value.minute}';
  }

  // =========================================================
  // FOGADÁSOK SZÁMA
  // =========================================================

  int? _detectPrintedMatchCount(
    List<String> lines,
  ) {
    final int labelIndex = _findLabelIndex(
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

    final List<int> values = <int>[];

    final int start =
        math.max(0, labelIndex - 3);

    final int end =
        math.min(lines.length - 1, labelIndex + 8);

    for (int index = start; index <= end; index++) {
      final String line = lines[index];

      if (!RegExp(r'^\d{1,2}$').hasMatch(line)) {
        continue;
      }

      final int? value = int.tryParse(line);

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
  // MODELLÉPÍTÉS
  // =========================================================

  List<RecognizedMatch> _buildRecognizedMatches({
    required List<_DetectedMatch> detectedMatches,
    required List<double?> matchOdds,
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

      if (detected.tip != 'Ismeretlen tipp') {
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
          confidence: confidence.clamp(0, 100),
          sourceLines: detected.sourceLines,
        ),
      );
    }

    return result;
  }

  // =========================================================
  // MEGBÍZHATÓSÁG
  // =========================================================

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

    if (looksLikeTippmixBetslip(cleanedText)) {
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

    if (matchCount != null && matchCount > 0) {
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

    if (matches.isNotEmpty &&
        matches.every(
          (RecognizedMatch match) => match.hasOdds,
        )) {
      score += 5;
    }

    if (stake != null &&
        totalOdds != null &&
        possibleWin != null) {
      final double calculatedWin =
          stake * totalOdds;

      final double difference =
          (calculatedWin - possibleWin).abs();

      final double tolerance =
          math.max(possibleWin * 0.03, 10);

      if (difference <= tolerance) {
        score += 10;
      } else {
        score -= 10;
      }
    }

    final List<double> validOdds = matches
        .where(
          (RecognizedMatch match) => match.hasOdds,
        )
        .map(
          (RecognizedMatch match) => match.odds!,
        )
        .toList();

    if (totalOdds != null &&
        validOdds.length == matches.length &&
        validOdds.length >= 2) {
      final double product =
          validOdds.fold<double>(
        1,
        (
          double current,
          double value,
        ) {
          return current * value;
        },
      );

      final double tolerance =
          math.max(totalOdds * 0.04, 0.15);

      if ((product - totalOdds).abs() <=
          tolerance) {
        score += 5;
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
    required String? betslipNumber,
    required DateTime? submittedAt,
    required int? matchCount,
    required List<RecognizedMatch> matches,
    required int confidence,
  }) {
    final List<String> warnings = <String>[];

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

    if (matchCount == null || matchCount <= 0) {
      warnings.add(
        'A fogadások számát nem sikerült felismerni.',
      );
    }

    if (matches.isEmpty) {
      warnings.add(
        'A mérkőzéseket nem sikerült elkülöníteni.',
      );
    }

    for (final RecognizedMatch match in matches) {
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
      final double calculatedWin =
          stake * totalOdds;

      final double difference =
          (calculatedWin - possibleWin).abs();

      final double tolerance =
          math.max(possibleWin * 0.03, 10);

      if (difference > tolerance) {
        warnings.add(
          'A tét, az eredő odds és a maximális '
          'nyeremény matematikailag nem egyezik.',
        );
      }
    }

    final List<double> recognizedOdds = matches
        .where(
          (RecognizedMatch match) => match.hasOdds,
        )
        .map(
          (RecognizedMatch match) => match.odds!,
        )
        .toList();

    if (totalOdds != null &&
        recognizedOdds.length == matches.length &&
        recognizedOdds.length >= 2) {
      final double calculatedTotal =
          recognizedOdds.fold<double>(
        1,
        (
          double current,
          double value,
        ) {
          return current * value;
        },
      );

      final double tolerance =
          math.max(totalOdds * 0.04, 0.15);

      if ((calculatedTotal - totalOdds).abs() >
          tolerance) {
        warnings.add(
          'A mérkőzések oddsainak szorzata nem '
          'egyezik az eredő oddsszal.',
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
  // SEGÉDFÜGGVÉNYEK
  // =========================================================

  int _findLabelIndex(
    List<String> lines,
    List<String> labels,
  ) {
    for (int index = 0; index < lines.length; index++) {
      final String normalized =
          normalizeForSearch(lines[index]);

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

  bool _looksLikeDateLine(String line) {
    return RegExp(
      r'20\d{2}[.,/\-\s]+'
      r'\d{1,2}[.,/\-\s]+'
      r'\d{1,2}',
    ).hasMatch(line);
  }

  bool _looksLikeMoneyLine(String line) {
    return RegExp(
      r'\b\d[\d .]*'
      r'(?:[,.]\d{1,2})?'
      r'\s*(?:,-\s*)?Ft\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  bool _looksLikeBarcodeLine(String line) {
    final String digits = line.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (digits.length >= 11) {
      return true;
    }

    final int letters = _countLetters(line);

    return digits.length >= 9 && letters == 0;
  }

  bool _looksLikeAddressLine(String line) {
    final String normalized =
        normalizeForSearch(line);

    const List<String> keywords = <String>[
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

  bool _isMetadataLine(String line) {
    final String normalized =
        normalizeForSearch(line);

    const List<String> keywords = <String>[
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

  int _countLetters(String value) {
    return RegExp(
      r'[A-Za-zÁÉÍÓÖŐÚÜŰ'
      r'áéíóöőúüű]',
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
  final bool isImpliedDecimal;

  const _DecimalCandidate({
    required this.value,
    required this.lineIndex,
    required this.line,
    this.isImpliedDecimal = false,
  });
}

class _ScoredDecimalCandidate {
  final int decimalIndex;
  final _DecimalCandidate candidate;
  final int score;

  const _ScoredDecimalCandidate({
    required this.decimalIndex,
    required this.candidate,
    required this.score,
  });
}

class _OddsPairResolution {
  final _ScoredDecimalCandidate first;
  final _ScoredDecimalCandidate second;
  final double difference;

  const _OddsPairResolution({
    required this.first,
    required this.second,
    required this.difference,
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
  final String sourceLine;

  const _DateCandidate({
    required this.value,
    required this.lineIndex,
    required this.sourceLine,
  });
}

class _ScoredDateCandidate {
  final _DateCandidate candidate;
  final int score;

  const _ScoredDateCandidate({
    required this.candidate,
    required this.score,
  });
}

class _MoneyResolution {
  final double? stake;
  final double? possibleWin;

  const _MoneyResolution({
    required this.stake,
    required this.possibleWin,
  });
}
