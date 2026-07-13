// ===========================================
// Zsolt Pro AI
// Version: v0.19.1
// File: lib/services/betslip_parser_v5_service.dart
// ===========================================

import '../models/recognized_betslip.dart';

/// A Zsolt Pro AI új generációs
/// Tippmix-szelvény feldolgozója.
///
/// A Parser V5 jelenleg a működő Parser 4.0
/// mellett készül, ezért biztonságosan fejleszthető.
///
/// A v0.19.1 verzió feladata:
/// - OCR-szöveg tisztítása;
/// - sorok egységesítése;
/// - gyakori OCR-hibák javítása;
/// - pénzértékek előkészítése;
/// - oddsformátumok előkészítése;
/// - dátumformátumok egységesítése;
/// - felesleges és üres sorok eltávolítása.
///
/// A következő verzióban erre épül majd:
/// - Money Detector;
/// - Odds Detector;
/// - Date Detector;
/// - Smart Math Engine;
/// - mérkőzés- és tippfelismerés.
class BetslipParserV5Service {
  BetslipParserV5Service._();

  static final BetslipParserV5Service instance =
      BetslipParserV5Service._();

  /// Feldolgozza az OCR által visszaadott szöveget.
  ///
  /// Ebben a verzióban még csak az előfeldolgozás
  /// történik meg. A konkrét szelvényadatok felismerése
  /// a következő fejlesztési lépésekben kerül be.
  RecognizedBetslip parse(
    String rawText,
  ) {
    final String cleanedText =
        cleanOcrText(rawText);

    final List<String> cleanLines =
        extractCleanLines(cleanedText);

    final int confidence =
        _calculatePreprocessingConfidence(
      rawText: rawText,
      cleanedText: cleanedText,
      lines: cleanLines,
    );

    final List<String> warnings =
        _buildPreprocessingWarnings(
      rawText: rawText,
      cleanedText: cleanedText,
      lines: cleanLines,
    );

    return RecognizedBetslip(
      rawText: rawText,
      cleanedText: cleanedText,
      confidence: confidence,
      totalOdds: null,
      stake: null,
      possibleWin: null,
      matchCount: null,
      betslipNumber: null,
      submittedAt: null,
      warnings: warnings,
      matches: const <RecognizedMatch>[],
    );
  }

  /// A teljes OCR-szöveg megtisztítása.
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
    result = _normalizeOddsFormats(result);
    result = _normalizeDateFormats(result);
    result = _normalizeTeamSeparators(result);
    result = _removeUselessLines(result);

    return result.trim();
  }

  /// A megtisztított szövegből visszaadja
  /// a használható, nem üres sorokat.
  List<String> extractCleanLines(
    String value,
  ) {
    final String cleaned =
        cleanOcrText(value);

    if (cleaned.isEmpty) {
      return const <String>[];
    }

    return cleaned
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

  /// Megvizsgálja, hogy a megtisztított szöveg
  /// valószínűleg Tippmix-szelvényből származik-e.
  bool looksLikeTippmixBetslip(
    String value,
  ) {
    final String normalized =
        normalizeForSearch(value);

    if (normalized.isEmpty) {
      return false;
    }

    const List<String> strongKeywords =
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
    ];

    int foundKeywords = 0;

    for (final String keyword
        in strongKeywords) {
      if (normalized.contains(keyword)) {
        foundKeywords++;
      }
    }

    final bool containsMoney =
        RegExp(
          r'\b\d[\d .]*\s*ft\b',
        ).hasMatch(
      normalized,
    );

    final bool containsOdds =
        RegExp(
          r'\b\d+[,.]\d{2}\b',
        ).hasMatch(
      normalized,
    );

    return foundKeywords >= 2 ||
        (foundKeywords >= 1 &&
            containsMoney &&
            containsOdds);
  }

  /// Kereséshez egységesített szöveget készít.
  String normalizeForSearch(
    String value,
  ) {
    return cleanOcrText(value)
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

  /// A számok közé tévesen felismert
  /// betűket javítja.
  ///
  /// Példák:
  /// - 1O00 → 1000
  /// - 39,2O → 39,20
  /// - 4,9O → 4,90
  /// - 1l34 → 1134
  String _fixDigitOcrErrors(
    String value,
  ) {
    String result = value;

    for (int index = 0;
        index < 4;
        index++) {
      result = result
          .replaceAllMapped(
        RegExp(
          r'(\d)[oO](\d)',
        ),
        (
          RegExpMatch match,
        ) {
          return '${match.group(1)}0'
              '${match.group(2)}';
        },
      ).replaceAllMapped(
        RegExp(
          r'(\d)[lI|](\d)',
        ),
        (
          RegExpMatch match,
        ) {
          return '${match.group(1)}1'
              '${match.group(2)}';
        },
      );
    }

    result = result
        .replaceAllMapped(
      RegExp(
        r'(\d)[oO]\b',
      ),
      (
        RegExpMatch match,
      ) {
        return '${match.group(1)}0';
      },
    ).replaceAllMapped(
      RegExp(
        r'\b[oO](\d)',
      ),
      (
        RegExpMatch match,
      ) {
        return '0${match.group(1)}';
      },
    );

    return result;
  }

  /// Gyakori Tippmix OCR-szóhibákat javít.
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

  /// A pénzösszegeket egységes formára alakítja.
  ///
  /// Példák:
  /// - 1 OOO Ft → 1000 Ft
  /// - 1.000,- Ft → 1000 Ft
  /// - 39 200,- → 39200 Ft
  /// - 500Ft → 500 Ft
  String _normalizeMoneyFormats(
    String value,
  ) {
    String result = value;

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{1,3}(?:[ .][0O]{3})+)\b',
      ),
      (
        RegExpMatch match,
      ) {
        final String raw =
            match.group(1) ?? '';

        return raw
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
      (
        RegExpMatch match,
      ) {
        return (match.group(1) ?? '')
            .replaceAll(' ', '')
            .replaceAll('.', '');
      },
    );

    result = result
        .replaceAll(
          RegExp(
            r'(\d)\s*,\s*-\s*(?:Ft)?',
            caseSensitive: false,
          ),
          r'$1 Ft',
        )
        .replaceAll(
          RegExp(
            r'(\d)\s*Ft\b',
            caseSensitive: false,
          ),
          r'$1 Ft',
        )
        .replaceAll(
          RegExp(
            r'\bFt\s*(\d)',
            caseSensitive: false,
          ),
          r'$1 Ft',
        )
        .replaceAll(
          RegExp(
            r'\s+Ft\b',
            caseSensitive: false,
          ),
          ' Ft',
        );

    return result;
  }

  /// Az oddsok tizedesjelét egységesíti.
  ///
  /// Minden odds vesszős formára kerül:
  /// - 39.20 → 39,20
  /// - 8.00 → 8,00
  /// - 4.90 → 4,90
  String _normalizeOddsFormats(
    String value,
  ) {
    return value.replaceAllMapped(
      RegExp(
        r'\b(\d{1,5})[.](\d{2,3})\b',
      ),
      (
        RegExpMatch match,
      ) {
        final String whole =
            match.group(1) ?? '';

        final String decimal =
            match.group(2) ?? '';

        if (whole.length == 4 &&
            decimal.length == 2) {
          return '$whole.$decimal';
        }

        return '$whole,$decimal';
      },
    );
  }

  /// A dátumok és időpontok írásmódját
  /// egységesíti.
  ///
  /// Példák:
  /// - 2026-05-16 → 2026.05.16
  /// - 2026/05/16 → 2026.05.16
  /// - 11.34 → 11:34
  String _normalizeDateFormats(
    String value,
  ) {
    String result = value.replaceAllMapped(
      RegExp(
        r'\b(20\d{2})[-/](\d{1,2})[-/](\d{1,2})\b',
      ),
      (
        RegExpMatch match,
      ) {
        final String year =
            match.group(1) ?? '';

        final String month =
            (match.group(2) ?? '')
                .padLeft(2, '0');

        final String day =
            (match.group(3) ?? '')
                .padLeft(2, '0');

        return '$year.$month.$day';
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b(\d{1,2})[.](\d{2})\b',
      ),
      (
        RegExpMatch match,
      ) {
        final int? hour =
            int.tryParse(
          match.group(1) ?? '',
        );

        final int? minute =
            int.tryParse(
          match.group(2) ?? '',
        );

        if (hour == null ||
            minute == null ||
            hour > 23 ||
            minute > 59) {
          return match.group(0) ?? '';
        }

        return '${hour.toString().padLeft(2, '0')}:'
            '${minute.toString().padLeft(2, '0')}';
      },
    );

    return result;
  }

  /// Egységesíti a csapatnevek közötti
  /// elválasztójeleket.
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
        )
        .replaceAll(
          RegExp(
            r'\s{2,}-\s{2,}',
          ),
          ' - ',
        );
  }

  /// Eltávolítja az OCR által létrehozott,
  /// teljesen használhatatlan sorokat.
  String _removeUselessLines(
    String value,
  ) {
    final List<String> lines =
        value.split('\n');

    final List<String> cleanedLines =
        <String>[];

    for (final String rawLine in lines) {
      final String line =
          rawLine.trim();

      if (line.isEmpty) {
        continue;
      }

      final String withoutSymbols =
          line.replaceAll(
        RegExp(
          r'[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű0-9]',
        ),
        '',
      );

      if (withoutSymbols.isEmpty) {
        continue;
      }

      if (line.length == 1 &&
          !RegExp(r'[0-9Xx]')
              .hasMatch(line)) {
        continue;
      }

      cleanedLines.add(line);
    }

    return cleanedLines.join('\n');
  }

  int _calculatePreprocessingConfidence({
    required String rawText,
    required String cleanedText,
    required List<String> lines,
  }) {
    if (rawText.trim().isEmpty ||
        cleanedText.trim().isEmpty) {
      return 0;
    }

    int score = 25;

    final int cleanedCharacters =
        cleanedText
            .replaceAll(
              RegExp(r'\s'),
              '',
            )
            .length;

    if (cleanedCharacters >= 40) {
      score += 10;
    }

    if (cleanedCharacters >= 100) {
      score += 10;
    }

    if (cleanedCharacters >= 200) {
      score += 10;
    }

    if (lines.length >= 5) {
      score += 10;
    }

    if (lines.length >= 15) {
      score += 10;
    }

    if (looksLikeTippmixBetslip(
      cleanedText,
    )) {
      score += 25;
    }

    return score.clamp(
      0,
      100,
    );
  }

  List<String> _buildPreprocessingWarnings({
    required String rawText,
    required String cleanedText,
    required List<String> lines,
  }) {
    final List<String> warnings =
        <String>[];

    if (rawText.trim().isEmpty) {
      warnings.add(
        'Az OCR nem adott vissza feldolgozható szöveget.',
      );

      return warnings;
    }

    if (cleanedText.trim().isEmpty) {
      warnings.add(
        'A megtisztított OCR-szöveg üres lett.',
      );
    }

    if (lines.length < 5) {
      warnings.add(
        'Nagyon kevés használható OCR-sor található.',
      );
    }

    if (!looksLikeTippmixBetslip(
      cleanedText,
    )) {
      warnings.add(
        'A szöveg nem tűnik egyértelműen '
        'Tippmix-szelvénynek.',
      );
    }

    return warnings;
  }
}
