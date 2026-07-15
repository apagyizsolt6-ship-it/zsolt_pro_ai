// ===========================================
// Zsolt Pro AI
// Version: v0.20.6
// File: lib/services/parser/parser_barcode_service.dart
// ===========================================

import '../../models/recognized_betslip.dart';

/// OCR és vonalkód összehasonlító szolgáltatás.
///
/// Feladata:
/// - OCR szelvényszám ellenőrzése
/// - Vonalkód ellenőrzése
/// - Egyezés vizsgálata
/// - Confidence bónusz/büntetés
/// - Figyelmeztetések előállítása
class ParserBarcodeService {
  const ParserBarcodeService();

  bool barcodeMatches({
    required RecognizedBetslip slip,
  }) {
    if (!slip.hasBarcode) {
      return false;
    }

    if (!slip.hasBetslipNumber) {
      return false;
    }

    return slip.barcodeValue!.trim() ==
        slip.betslipNumber!.trim();
  }

  int calculateConfidence({
    required RecognizedBetslip slip,
    required int currentConfidence,
  }) {
    int confidence = currentConfidence;

    if (barcodeMatches(slip: slip)) {
      confidence += 8;
    } else {
      if (slip.hasBarcode &&
          slip.hasBetslipNumber) {
        confidence -= 12;
      }
    }

    if (confidence < 0) {
      confidence = 0;
    }

    if (confidence > 100) {
      confidence = 100;
    }

    return confidence;
  }

  List<String> buildWarnings({
    required RecognizedBetslip slip,
  }) {
    final List<String> warnings = [];

    if (!slip.hasBarcode) {
      warnings.add(
        'Nem sikerült vonalkódot beolvasni.',
      );
    }

    if (!slip.hasBetslipNumber) {
      warnings.add(
        'OCR-rel nem sikerült szelvényszámot felismerni.',
      );
    }

    if (slip.hasBarcode &&
        slip.hasBetslipNumber &&
        !barcodeMatches(slip: slip)) {
      warnings.add(
        'A vonalkód és az OCR szelvényszáma nem egyezik.',
      );
    }

    return warnings;
  }

  bool isVerified({
    required RecognizedBetslip slip,
  }) {
    return barcodeMatches(slip: slip);
  }
}
