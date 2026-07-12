// ===========================================
// Zsolt Pro AI
// Version: v0.18.1
// File: lib/services/ocr_service.dart
// ===========================================

import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A Zsolt Pro AI központi OCR-szolgáltatása.
///
/// Feladatai:
/// - a kamerával vagy galériából kiválasztott kép feldolgozása;
/// - latin karakteres szöveg felismerése;
/// - a felismert blokkok, sorok és teljes szöveg visszaadása;
/// - alapvető adatminőségi ellenőrzés;
/// - jól kezelhető magyar hibaüzenetek létrehozása.
class OcrService {
  OcrService._();

  static final OcrService instance =
      OcrService._();

  final TextRecognizer _textRecognizer =
      TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isClosed = false;

  /// Egy kép teljes OCR-feldolgozása.
  Future<OcrRecognitionResult> recognizeImage(
    String imagePath,
  ) async {
    _ensureNotClosed();

    final String cleanPath =
        imagePath.trim();

    if (cleanPath.isEmpty) {
      throw const OcrException(
        'A kiválasztott kép elérési útja üres.',
      );
    }

    final File imageFile =
        File(cleanPath);

    final bool imageExists =
        await imageFile.exists();

    if (!imageExists) {
      throw const OcrException(
        'A kiválasztott kép nem található.',
      );
    }

    try {
      final InputImage inputImage =
          InputImage.fromFilePath(
        cleanPath,
      );

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(
        inputImage,
      );

      final List<OcrTextBlock> blocks =
          _convertBlocks(
        recognizedText.blocks,
      );

      final List<String> lines =
          _collectLines(
        blocks,
      );

      final String rawText =
          recognizedText.text.trim();

      final String normalizedText =
          normalizeRecognizedText(
        rawText,
      );

      final int characterCount =
          normalizedText.replaceAll(
        RegExp(r'\s'),
        '',
      ).length;

      final int wordCount =
          normalizedText.isEmpty
              ? 0
              : normalizedText
                  .split(
                    RegExp(r'\s+'),
                  )
                  .where(
                    (String word) {
                      return word
                          .trim()
                          .isNotEmpty;
                    },
                  )
                  .length;

      final int confidence =
          _calculateConfidence(
        rawText: rawText,
        blocks: blocks,
        lines: lines,
        characterCount:
            characterCount,
      );

      final List<String> warnings =
          _buildWarnings(
        rawText: rawText,
        lines: lines,
        characterCount:
            characterCount,
        confidence:
            confidence,
      );

      return OcrRecognitionResult(
        rawText: rawText,
        normalizedText:
            normalizedText,
        blocks: blocks,
        lines: lines,
        characterCount:
            characterCount,
        wordCount:
            wordCount,
        confidence:
            confidence,
        warnings:
            warnings,
        processedAt:
            DateTime.now(),
      );
    } on OcrException {
      rethrow;
    } catch (error) {
      throw OcrException(
        _createErrorMessage(
          error,
        ),
      );
    }
  }

  /// Egységesíti az OCR által visszaadott szöveget.
  ///
  /// A sorok megmaradnak, de:
  /// - eltávolítja a felesleges szóközöket;
  /// - egységesíti a gondolatjeleket;
  /// - eltávolítja a túl sok üres sort;
  /// - javít néhány gyakori OCR-karakterhibát.
  String normalizeRecognizedText(
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

  /// Visszaadja a nem üres szövegsorokat.
  List<String> extractCleanLines(
    String value,
  ) {
    final String normalized =
        normalizeRecognizedText(
      value,
    );

    if (normalized.isEmpty) {
      return const <String>[];
    }

    return normalized
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

  /// Megvizsgálja, hogy a kép valószínűleg
  /// sportfogadási szelvényt tartalmaz-e.
  bool looksLikeBetslip(
    String recognizedText,
  ) {
    final String normalized =
        _normalizeForSearch(
      recognizedText,
    );

    if (normalized.isEmpty) {
      return false;
    }

    final List<String> betslipKeywords =
        <String>[
      'tippmix',
      'tippmixpro',
      'fogadas',
      'fogadasi',
      'szelveny',
      'odds',
      'tet',
      'nyeremeny',
      'varhato nyeremeny',
      'kombinalt',
      'kotesszam',
      'esemeny',
      'merkozes',
      'hazai',
      'vendeg',
      'dontetlen',
      'mindket csapat',
      'tobb mint',
      'kevesebb mint',
      'szoglet',
      'buntetolap',
    ];

    int foundKeywords = 0;

    for (final String keyword
        in betslipKeywords) {
      if (normalized.contains(
        keyword,
      )) {
        foundKeywords++;
      }
    }

    final bool containsOdds =
        RegExp(
          r'\b\d+[,.]\d{2}\b',
        ).hasMatch(
      recognizedText,
    );

    return foundKeywords >= 2 ||
        (foundKeywords >= 1 &&
            containsOdds);
  }

  /// Felszabadítja a natív OCR-erőforrásokat.
  ///
  /// Az alkalmazás központi singleton szolgáltatást használ,
  /// ezért ezt csak az alkalmazás teljes bezárásakor érdemes
  /// meghívni.
  Future<void> close() async {
    if (_isClosed) {
      return;
    }

    await _textRecognizer.close();
    _isClosed = true;
  }

  void _ensureNotClosed() {
    if (_isClosed) {
      throw const OcrException(
        'Az OCR-szolgáltatás már le lett állítva.',
      );
    }
  }

  List<OcrTextBlock> _convertBlocks(
    List<TextBlock> sourceBlocks,
  ) {
    return sourceBlocks.map(
      (TextBlock block) {
        final List<OcrTextLine> lines =
            block.lines.map(
          (TextLine line) {
            return OcrTextLine(
              text:
                  line.text.trim(),
              left:
                  line.boundingBox.left,
              top:
                  line.boundingBox.top,
              right:
                  line.boundingBox.right,
              bottom:
                  line.boundingBox.bottom,
            );
          },
        ).where(
          (OcrTextLine line) {
            return line.text.isNotEmpty;
          },
        ).toList(
          growable: false,
        );

        return OcrTextBlock(
          text:
              block.text.trim(),
          lines:
              lines,
          left:
              block.boundingBox.left,
          top:
              block.boundingBox.top,
          right:
              block.boundingBox.right,
          bottom:
              block.boundingBox.bottom,
        );
      },
    ).where(
      (OcrTextBlock block) {
        return block.text.isNotEmpty ||
            block.lines.isNotEmpty;
      },
    ).toList(
      growable: false,
    );
  }

  List<String> _collectLines(
    List<OcrTextBlock> blocks,
  ) {
    final List<OcrTextLine> allLines =
        <OcrTextLine>[];

    for (final OcrTextBlock block
        in blocks) {
      allLines.addAll(
        block.lines,
      );
    }

    allLines.sort(
      (
        OcrTextLine first,
        OcrTextLine second,
      ) {
        final double verticalDifference =
            first.top -
                second.top;

        if (verticalDifference.abs() >
            8) {
          return first.top.compareTo(
            second.top,
          );
        }

        return first.left.compareTo(
          second.left,
        );
      },
    );

    return allLines
        .map(
          (OcrTextLine line) {
            return line.text.trim();
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

  int _calculateConfidence({
    required String rawText,
    required List<OcrTextBlock> blocks,
    required List<String> lines,
    required int characterCount,
  }) {
    if (rawText.trim().isEmpty ||
        characterCount == 0) {
      return 0;
    }

    int score = 25;

    if (characterCount >= 20) {
      score += 10;
    }

    if (characterCount >= 60) {
      score += 10;
    }

    if (characterCount >= 120) {
      score += 10;
    }

    if (blocks.length >= 2) {
      score += 8;
    }

    if (blocks.length >= 5) {
      score += 7;
    }

    if (lines.length >= 4) {
      score += 8;
    }

    if (lines.length >= 10) {
      score += 7;
    }

    if (looksLikeBetslip(
      rawText,
    )) {
      score += 15;
    }

    final int suspiciousCharacterCount =
        RegExp(
          r'[�□■◆]',
        ).allMatches(
          rawText,
        ).length;

    score -=
        suspiciousCharacterCount * 4;

    return score.clamp(
      0,
      100,
    );
  }

  List<String> _buildWarnings({
    required String rawText,
    required List<String> lines,
    required int characterCount,
    required int confidence,
  }) {
    final List<String> warnings =
        <String>[];

    if (rawText.trim().isEmpty) {
      warnings.add(
        'A képen nem sikerült szöveget felismerni.',
      );

      return warnings;
    }

    if (characterCount < 20) {
      warnings.add(
        'Nagyon kevés szöveg került felismerésre. '
        'Készíts élesebb és közelebbi képet.',
      );
    }

    if (lines.length < 3) {
      warnings.add(
        'Kevés elkülöníthető szövegsor található a képen.',
      );
    }

    if (!looksLikeBetslip(
      rawText,
    )) {
      warnings.add(
        'A kép nem tűnik egyértelműen sportfogadási '
        'szelvénynek.',
      );
    }

    if (confidence < 50) {
      warnings.add(
        'A felismerés bizonytalan. Ellenőrizd majd '
        'kézzel a meccseket, piacokat és oddsokat.',
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
        );
  }

  String _normalizeForSearch(
    String value,
  ) {
    return normalizeRecognizedText(
      value,
    )
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

  String _createErrorMessage(
    Object error,
  ) {
    final String message =
        error.toString().toLowerCase();

    if (message.contains(
          'permission',
        ) ||
        message.contains(
          'denied',
        )) {
      return 'Az OCR nem fér hozzá a kiválasztott képhez. '
          'Ellenőrizd az alkalmazás engedélyeit.';
    }

    if (message.contains(
          'image',
        ) &&
        message.contains(
          'format',
        )) {
      return 'A kép formátumát az OCR nem tudja feldolgozni.';
    }

    if (message.contains(
          'out of memory',
        ) ||
        message.contains(
          'memory',
        )) {
      return 'A kép túl nagy a feldolgozáshoz. '
          'Próbálj kisebb felbontású képet választani.';
    }

    if (message.contains(
          'closed',
        )) {
      return 'Az OCR-szolgáltatás jelenleg nem használható.';
    }

    return 'A szövegfelismerés nem sikerült. '
        'Részlet: $error';
  }
}

/// Egy teljes OCR-feldolgozás eredménye.
class OcrRecognitionResult {
  final String rawText;
  final String normalizedText;

  final List<OcrTextBlock> blocks;
  final List<String> lines;

  final int characterCount;
  final int wordCount;

  /// Becsült OCR-megbízhatóság 0 és 100 között.
  ///
  /// Ez nem az ML Kit hivatalos karakterpontossága,
  /// hanem a Zsolt Pro AI saját adatminőségi értékelése.
  final int confidence;

  final List<String> warnings;
  final DateTime processedAt;

  const OcrRecognitionResult({
    required this.rawText,
    required this.normalizedText,
    required this.blocks,
    required this.lines,
    required this.characterCount,
    required this.wordCount,
    required this.confidence,
    required this.warnings,
    required this.processedAt,
  });

  bool get hasText {
    return normalizedText.trim().isNotEmpty;
  }

  bool get isEmpty {
    return !hasText;
  }

  bool get hasWarnings {
    return warnings.isNotEmpty;
  }

  int get blockCount {
    return blocks.length;
  }

  int get lineCount {
    return lines.length;
  }

  String get confidenceLabel {
    if (confidence >= 85) {
      return 'Nagyon jó felismerés';
    }

    if (confidence >= 70) {
      return 'Jó felismerés';
    }

    if (confidence >= 50) {
      return 'Ellenőrzendő felismerés';
    }

    return 'Bizonytalan felismerés';
  }
}

/// Egy felismert szövegblokk.
class OcrTextBlock {
  final String text;
  final List<OcrTextLine> lines;

  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrTextBlock({
    required this.text,
    required this.lines,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width {
    return right - left;
  }

  double get height {
    return bottom - top;
  }
}

/// Egy felismert szövegsor.
class OcrTextLine {
  final String text;

  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrTextLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width {
    return right - left;
  }

  double get height {
    return bottom - top;
  }
}

class OcrException implements Exception {
  final String message;

  const OcrException(
    this.message,
  );

  @override
  String toString() {
    return message;
  }
}
