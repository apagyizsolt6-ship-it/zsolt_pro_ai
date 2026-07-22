// ignore_for_file: unused_field, prefer_final_fields, unused_element

// ===========================================
// Zsolt Pro AI
// Version: v0.20.4
// File: lib/screens/betslip_scanner_screen.dart
// ===========================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recognized_betslip.dart';
import '../services/betslip_parser_v5_service.dart';
import '../services/ocr_service.dart';
import 'barcode_scanner_screen.dart';
import '../services/ai_engine_v2_service.dart';
class BetslipScannerScreen extends StatefulWidget {
  final String? initialBarcode;

  const BetslipScannerScreen({
    super.key,
    this.initialBarcode,
  });

  @override
  State<BetslipScannerScreen> createState() {
    return _BetslipScannerScreenState();
  }
}

class _BetslipScannerScreenState extends State<BetslipScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  final OcrService _ocrService = OcrService.instance;

  final BetslipParserV5Service _parserService =
      BetslipParserV5Service.instance;
  final AiEngineV2Service _aiEngine = AiEngineV2Service.instance;
  XFile? _selectedImage;
  _ScannerSource? _selectedSource;

  OcrRecognitionResult? _ocrResult;
  RecognizedBetslip? _parsedBetslip;
String? _aiSummary;
double? _aiScore;
String? _riskLevel;
bool _isValueBet = false;
  String? _barcodeValue;
  String? _recognitionError;

  bool _isSelectingImage = false;
  bool _isAnalyzing = false;
  bool _isScanningBarcode = false;
  bool _showRawText = false;

  bool get _hasSelectedImage {
    return _selectedImage != null;
  }

  bool get _hasOcrResult {
    return _ocrResult != null;
  }

  bool get _hasParsedBetslip {
    return _parsedBetslip != null;
  }

  bool get _hasBarcode {
    return _barcodeValue != null &&
        _barcodeValue!.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    final String initialBarcode =
        widget.initialBarcode?.trim() ?? '';

    if (initialBarcode.isNotEmpty) {
      _barcodeValue = initialBarcode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Szelvény Felismerő',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasSelectedImage ||
              _hasOcrResult ||
              _hasParsedBetslip)
            IconButton(
              tooltip: 'Kép és OCR-eredmény törlése',
              onPressed: _isAnalyzing ||
                      _isSelectingImage ||
                      _isScanningBarcode
                  ? null
                  : _clearSelectedImage,
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshRecognition,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              28,
            ),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 18),
              _buildSourceSection(),
              const SizedBox(height: 18),
              _buildBarcodeSection(),
              const SizedBox(height: 18),
              _buildImagePreview(),
              const SizedBox(height: 18),
              _buildAnalyzeButton(),
              const SizedBox(height: 18),
              _buildOcrResultCard(),
              if (_hasParsedBetslip) ...[
                const SizedBox(height: 18),
                _buildParsedSummaryCard(),
              ],
              if (_hasParsedBetslip &&
                  _parsedBetslip!.matches.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildRecognizedMatchesSection(),
              ],
              if (_hasOcrResult) ...[
                const SizedBox(height: 18),
                _buildRecognizedTextCard(),
              ],
              if (_hasParsedBetslip &&
                  _parsedBetslip!.hasWarnings) ...[
                const SizedBox(height: 18),
                _buildParserWarningsCard(),
              ],
              if (_hasOcrResult && _ocrResult!.hasWarnings) ...[
                const SizedBox(height: 18),
                _buildOcrWarningsCard(),
              ],
              const SizedBox(height: 18),
              _buildInformationCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 40,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Szelvény Felismerő PRO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Fotózd le vagy válaszd ki a Tippmix '
              'szelvényedet, majd olvasd be a rajta '
              'található vonalkódot. A Zsolt Pro AI '
              'OCR és Parser V5 együtt dolgozza fel '
              'a szelvény adatait.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.add_a_photo_outlined,
          title: 'Szelvény hozzáadása',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SourceCard(
                icon: Icons.camera_alt_outlined,
                title: 'Fotó készítése',
                subtitle: 'Kamera használata',
                selected:
                    _selectedSource == _ScannerSource.camera,
                disabled: _isSelectingImage ||
                    _isAnalyzing ||
                    _isScanningBarcode,
                onTap: () {
                  _pickImage(
                    source: ImageSource.camera,
                    scannerSource: _ScannerSource.camera,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceCard(
                icon: Icons.photo_library_outlined,
                title: 'Galéria',
                subtitle: 'Kép kiválasztása',
                selected:
                    _selectedSource == _ScannerSource.gallery,
                disabled: _isSelectingImage ||
                    _isAnalyzing ||
                    _isScanningBarcode,
                onTap: () {
                  _pickImage(
                    source: ImageSource.gallery,
                    scannerSource: _ScannerSource.gallery,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarcodeSection() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.qr_code_scanner,
          title: 'Vonalkód',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _hasBarcode
                ? _buildDetectedBarcode(colors)
                : _buildEmptyBarcode(colors),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyBarcode(
    ColorScheme colors,
  ) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            color: colors.onPrimaryContainer,
            size: 32,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Még nincs beolvasott vonalkód',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'A Tippmix-szelvény alján található '
          'CODE 128 vonalkódot külön is beolvashatod.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isAnalyzing ||
                    _isSelectingImage ||
                    _isScanningBarcode
                ? null
                : _scanBarcode,
            icon: _isScanningBarcode
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                    ),
                  )
                : const Icon(
                    Icons.qr_code_scanner,
                  ),
            label: Text(
              _isScanningBarcode
                  ? 'Vonalkódolvasó megnyitása...'
                  : 'Vonalkód beolvasása',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedBarcode(
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.withValues(
                  alpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: Colors.green,
                size: 29,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vonalkód sikeresen beolvasva',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tippmix-szelvény azonosító',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: SelectableText(
            _barcodeValue!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: colors.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'A beolvasott vonalkód az OCR-felismerés '
                'után is megmarad.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isScanningBarcode
                    ? null
                    : _copyBarcode,
                icon: const Icon(
                  Icons.copy_outlined,
                ),
                label: const Text(
                  'Másolás',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ||
                        _isSelectingImage ||
                        _isScanningBarcode
                    ? null
                    : _scanBarcode,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Újraolvasás',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _isAnalyzing ||
                    _isSelectingImage ||
                    _isScanningBarcode
                ? null
                : _clearBarcode,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
            label: const Text(
              'Vonalkód törlése',
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.image_outlined,
          title: 'Kiválasztott kép',
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(
            milliseconds: 200,
          ),
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 230,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hasSelectedImage
                  ? colors.primary
                  : colors.outlineVariant,
              width: _hasSelectedImage ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isSelectingImage
              ? _buildLoadingPlaceholder()
              : _hasSelectedImage
                  ? _buildSelectedImage()
                  : _buildEmptyPlaceholder(),
        ),
      ],
    );
  }

  Widget _buildLoadingPlaceholder() {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Kép betöltése...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 62,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          const Text(
            'Még nincs kiválasztott szelvény',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Készíts fotót vagy válassz ki '
            'egy képet a galériából.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    final XFile image =
        _selectedImage!;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Image.file(
            File(image.path),
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'A kép nem jeleníthető meg.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            10,
            14,
            12,
          ),
          child: Row(
            children: [
              Icon(
                _selectedSource == _ScannerSource.camera
                    ? Icons.camera_alt_outlined
                    : Icons.photo_library_outlined,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedSource == _ScannerSource.camera
                      ? 'Kamerával készített kép'
                      : 'Galériából kiválasztott kép',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Kép törlése',
                onPressed:
                    _isAnalyzing ? null : _clearSelectedImage,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return FilledButton.icon(
      onPressed: !_hasSelectedImage ||
              _isAnalyzing ||
              _isSelectingImage ||
              _isScanningBarcode
          ? null
          : _startAnalysis,
      icon: _isAnalyzing
          ? const SizedBox(
              width: 21,
              height: 21,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            )
          : const Icon(
              Icons.psychology_outlined,
            ),
      label: Text(
        _isAnalyzing
            ? 'Parser V5 feldolgozás...'
            : _hasOcrResult
                ? 'Felismerés újrafuttatása'
                : 'AI felismerés indítása',
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOcrResultCard() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    String title;
    String subtitle;
    IconData icon;
    Color statusColor;

    if (_isAnalyzing) {
      title = 'Felismerés folyamatban';
      subtitle = 'Az OCR és a Parser V5 dolgozik.';
      icon = Icons.hourglass_top;
      statusColor = colors.primary;
    } else if (_recognitionError != null) {
      title = 'A felismerés nem sikerült';
      subtitle = _recognitionError!;
      icon = Icons.error_outline;
      statusColor = Colors.redAccent;
    } else if (_hasOcrResult && _ocrResult!.hasText) {
      title = 'Szöveg sikeresen felismerve';
      subtitle = _ocrResult!.confidenceLabel;
      icon = Icons.verified_outlined;
      statusColor = Colors.green;
    } else if (_hasOcrResult) {
      title = 'Nem található olvasható szöveg';
      subtitle = 'Próbálj élesebb vagy közelebbi képet.';
      icon = Icons.warning_amber_rounded;
      statusColor = Colors.orangeAccent;
    } else if (_hasSelectedImage) {
      title = 'Kép készen áll';
      subtitle = 'Indítsd el az AI felismerést.';
      icon = Icons.receipt_long_outlined;
      statusColor = colors.primary;
    } else {
      title = 'Elemzésre vár';
      subtitle = 'A felismert adatok itt jelennek meg.';
      icon = Icons.receipt_long_outlined;
      statusColor = colors.onSurfaceVariant;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.analytics_outlined,
          title: 'OCR felismerési eredmény',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Divider(
                  color: colors.outlineVariant,
                  height: 1,
                ),
                const SizedBox(height: 15),
                _ResultRow(
                  icon: Icons.text_fields,
                  title: 'Felismert karakterek',
                  value: _hasOcrResult
                      ? '${_ocrResult!.characterCount}'
                      : '—',
                ),
                const SizedBox(height: 12),
                _ResultRow(
                  icon: Icons.format_list_numbered,
                  title: 'Felismert sorok',
                  value: _hasOcrResult
                      ? '${_ocrResult!.lineCount}'
                      : '—',
                ),
                const SizedBox(height: 12),
                _ResultRow(
                  icon: Icons.view_agenda_outlined,
                  title: 'Szövegblokkok',
                  value: _hasOcrResult
                      ? '${_ocrResult!.blockCount}'
                      : '—',
                ),
                const SizedBox(height: 12),
                _ResultRow(
                  icon: Icons.fact_check_outlined,
                  title: 'OCR megbízhatóság',
                  value: _hasOcrResult
                      ? '${_ocrResult!.confidence}%'
                      : '—',
                ),
                const SizedBox(height: 12),
                _ResultRow(
                  icon: Icons.sports_soccer,
                  title: 'Tippmix szelvény',
                  value: _hasOcrResult
                      ? _parserService.looksLikeTippmixBetslip(
                          _ocrResult!.normalizedText,
                        )
                          ? 'Felismerve'
                          : 'Bizonytalan'
                      : '—',
                ),
                const SizedBox(height: 12),
                _ResultRow(
                  icon: Icons.qr_code_scanner,
                  title: 'Vonalkód',
                  value: _hasBarcode
                      ? 'Sikeresen beolvasva'
                      : 'Nincs beolvasva',
                ),
                const SizedBox(height: 12),
                const _ResultRow(
                  icon: Icons.memory_outlined,
                  title: 'Feldolgozó motor',
                  value: 'Parser V5',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParsedSummaryCard() {
    final RecognizedBetslip betslip =
        _parsedBetslip!;

    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final Color confidenceColor =
        betslip.confidence >= 70
            ? Colors.green
            : betslip.confidence >= 50
                ? Colors.orange
                : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.receipt_long_outlined,
          title: 'Felismert szelvényadatok',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.document_scanner,
                        color: confidenceColor,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tippmix szelvény',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            betslip.confidenceLabel,
                            style: TextStyle(
                              color: confidenceColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${betslip.confidence}%',
                        style: TextStyle(
                          color: confidenceColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(
                  color: colors.outlineVariant,
                  height: 1,
                ),
                const SizedBox(height: 15),
                _SummaryRow(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Szelvényszám',
                  value: betslip.hasBetslipNumber
                      ? betslip.betslipNumber!
                      : 'Nem felismerhető',
                ),
                if (_hasBarcode) ...[
                  const SizedBox(height: 12),
                  _SummaryRow(
                    icon: Icons.qr_code_scanner,
                    title: 'Vonalkód',
                    value: _barcodeValue!,
                  ),
                  const SizedBox(height: 12),
                  const _SummaryRow(
                    icon: Icons.verified_outlined,
                    title: 'Vonalkód állapota',
                    value: 'Sikeresen beolvasva',
                  ),
                ],
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.schedule_outlined,
                  title: 'Játékba küldve',
                  value: betslip.hasSubmittedAt
                      ? _formatDateTime(
                          betslip.submittedAt!,
                        )
                      : 'Nem felismerhető',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.payments_outlined,
                  title: 'Tét',
                  value: betslip.hasStake
                      ? '${_formatMoney(betslip.stake!)} Ft'
                      : 'Nem felismerhető',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.percent_outlined,
                  title: 'Eredő odds',
                  value: betslip.hasOdds
                      ? _formatOdds(
                          betslip.totalOdds!,
                        )
                      : 'Nem felismerhető',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.emoji_events_outlined,
                  title: 'Maximális nyeremény',
                  value: betslip.hasPossibleWin
                      ? '${_formatMoney(betslip.possibleWin!)} Ft'
                      : 'Nem felismerhető',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.format_list_numbered,
                  title: 'Fogadások száma',
                  value: betslip.matchCount != null
                      ? '${betslip.matchCount}'
                      : betslip.matches.isNotEmpty
                          ? '${betslip.matches.length}'
                          : 'Nem felismerhető',
                ),
                if (betslip.calculatedPossibleWin != null) ...[
                  const SizedBox(height: 12),
                  _SummaryRow(
                    icon: Icons.calculate_outlined,
                    title: 'Számított nyeremény',
                    value:
                        '${_formatMoney(betslip.calculatedPossibleWin!)} Ft',
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: confidenceColor.withValues(
                        alpha: 0.32,
                      ),
                    ),
                  ),
                  child: Text(
                    _buildParserSummaryMessage(
                      betslip,
                    ),
                    style: TextStyle(
                      color: confidenceColor,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildParserSummaryMessage(
    RecognizedBetslip betslip,
  ) {
    if (betslip.isReliable && _hasBarcode) {
      return 'A Parser V5 jó megbízhatósággal '
          'felismerte a szelvény alapadatait, '
          'és a vonalkód is sikeresen hozzá lett '
          'kapcsolva a felismeréshez.';
    }

    if (betslip.isReliable) {
      return 'A Parser V5 jó megbízhatósággal '
          'felismerte a szelvény alapadatait.';
    }

    if (_hasBarcode) {
      return 'A vonalkód sikeresen beolvasva. '
          'A Parser V5 többi eredményét érdemes '
          'kézzel is ellenőrizni.';
    }

    return 'A Parser V5 eredményeit érdemes '
        'kézzel is ellenőrizni.';
  }

  Widget _buildRecognizedMatchesSection() {
    final List<RecognizedMatch> matches =
        _parsedBetslip!.matches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.sports_soccer,
          title:
              'Felismert mérkőzések (${matches.length})',
        ),
        const SizedBox(height: 12),
        ...matches.asMap().entries.map(
          (
            MapEntry<int, RecognizedMatch> entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _RecognizedMatchCard(
                position: entry.key + 1,
                match: entry.value,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecognizedTextCard() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final OcrRecognitionResult result =
        _ocrResult!;

    final String displayedText =
        _showRawText
            ? result.rawText
            : _parsedBetslip?.cleanedText ??
                result.normalizedText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.description_outlined,
          title: 'Felismert szöveg',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showRawText
                            ? 'Eredeti OCR szöveg'
                            : 'Parser V5 tisztított szöveg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Szöveg másolása',
                      onPressed:
                          displayedText.trim().isEmpty
                              ? null
                              : _copyRecognizedText,
                      icon: const Icon(
                        Icons.copy_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(
                        'Tisztított',
                      ),
                      icon: Icon(
                        Icons.auto_fix_high_outlined,
                      ),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(
                        'Eredeti',
                      ),
                      icon: Icon(
                        Icons.text_snippet_outlined,
                      ),
                    ),
                  ],
                  selected: <bool>{
                    _showRawText,
                  },
                  onSelectionChanged: (
                    Set<bool> selection,
                  ) {
                    if (selection.isEmpty) {
                      return;
                    }

                    setState(() {
                      _showRawText = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 150,
                    maxHeight: 420,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.outlineVariant,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      displayedText.trim().isEmpty
                          ? 'A képen nem sikerült '
                              'szöveget felismerni.'
                          : displayedText,
                      style: TextStyle(
                        color: displayedText.trim().isEmpty
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                if (result.hasText) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _copyRecognizedText,
                      icon: const Icon(
                        Icons.copy,
                      ),
                      label: const Text(
                        'Felismert szöveg másolása',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParserWarningsCard() {
    final List<String> warnings =
        _parsedBetslip!.warnings;

    return _WarningCard(
      title: 'Parser V5 ellenőrzendő adatok',
      warnings: warnings,
      color: Colors.orangeAccent,
    );
  }

  Widget _buildOcrWarningsCard() {
    final List<String> warnings =
        _ocrResult!.warnings;

    return _WarningCard(
      title: 'OCR ellenőrzendő információk',
      warnings: warnings,
      color: Colors.amber,
    );
  }

  Widget _buildInformationCard() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    String message;

    if (_hasParsedBetslip && _hasBarcode) {
      message =
          'Az OCR, a Parser V5 és a CODE 128 '
          'vonalkódolvasás már együtt működik. '
          'A következő fejlesztésben a vonalkód '
          'és az OCR-rel felismert szelvényszám '
          'automatikus összehasonlítása következik.';
    } else if (_hasParsedBetslip) {
      message =
          'A Parser V5 felismerte a szelvény '
          'adatait. A szelvény pontosabb '
          'azonosításához olvasd be a rajta '
          'található vonalkódot is.';
    } else if (_hasBarcode) {
      message =
          'A vonalkód sikeresen beolvasva. '
          'Most készíts fotót vagy válaszd ki '
          'a szelvény képét, majd indítsd el '
          'az AI felismerést.';
    } else {
      message =
          'A jó eredményhez a teljes szelvény '
          'legyen éles és jól megvilágított. '
          'A vonalkódot külön is olvasd be, '
          'hogy az OCR-eredményhez kapcsolhassuk.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(
          alpha: 0.24,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    if (_isScanningBarcode ||
        _isAnalyzing ||
        _isSelectingImage) {
      return;
    }

    setState(() {
      _isScanningBarcode = true;
    });

    try {
      final String? barcode =
          await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (
            BuildContext context,
          ) {
            return const BarcodeScannerScreen();
          },
        ),
      );

      if (!mounted) {
        return;
      }

      final String value =
          barcode?.trim() ?? '';

      if (value.isEmpty) {
        return;
      }

      setState(() {
        _barcodeValue = value;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A vonalkód sikeresen hozzá lett '
              'kapcsolva a szelvényhez.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A vonalkód beolvasása nem sikerült.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isScanningBarcode = false;
        });
      }
    }
  }

  Future<void> _copyBarcode() async {
    final String? barcode =
        _barcodeValue;

    if (barcode == null ||
        barcode.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: barcode,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'A vonalkód a vágólapra került.',
          ),
        ),
      );
  }

  void _clearBarcode() {
    if (_isScanningBarcode ||
        _isAnalyzing ||
        _isSelectingImage) {
      return;
    }

    setState(() {
      _barcodeValue = null;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'A vonalkód törölve.',
          ),
        ),
      );
  }

  Future<void> _pickImage({
    required ImageSource source,
    required _ScannerSource scannerSource,
  }) async {
    if (_isSelectingImage ||
        _isAnalyzing ||
        _isScanningBarcode) {
      return;
    }

    setState(() {
      _isSelectingImage = true;
      _recognitionError = null;
    });

    try {
      final XFile? image =
          await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );

      if (!mounted) {
        return;
      }

      if (image == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Nem választottál ki képet.',
              ),
            ),
          );

        return;
      }

      setState(() {
        _selectedImage = image;
        _selectedSource = scannerSource;
        _ocrResult = null;
        _parsedBetslip = null;
        _recognitionError = null;
        _showRawText = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              scannerSource == _ScannerSource.camera
                  ? 'A fénykép sikeresen elkészült.'
                  : 'A kép sikeresen betöltődött.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recognitionError =
            'A kép kiválasztása nem sikerült.';
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A kép kiválasztása nem sikerült. '
              'Ellenőrizd az alkalmazás engedélyeit.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingImage = false;
        });
      }
    }
  }

  Future<void> _startAnalysis() async {
    final XFile? selectedImage =
        _selectedImage;

    if (selectedImage == null ||
        _isAnalyzing) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _ocrResult = null;
      _parsedBetslip = null;
      _recognitionError = null;
      _showRawText = false;
    });

    try {
      final OcrRecognitionResult ocrResult =
          await _ocrService.recognizeImage(
        selectedImage.path,
      );

      final RecognizedBetslip? parsedResult =
          ocrResult.hasText
              ? _parserService.parse(
                  ocrResult.normalizedText,
                )
              : null;

      if (!mounted) {
        return;
      }

      setState(() {
        _ocrResult = ocrResult;
        _parsedBetslip = parsedResult;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ocrResult.hasText
                  ? parsedResult != null
                      ? 'A Parser V5 feldolgozása '
                          'sikerült: '
                          '${parsedResult.matches.length} '
                          'mérkőzés felismerve.'
                      : 'A szövegfelismerés sikerült.'
                  : 'Nem sikerült olvasható '
                      'szöveget találni.',
            ),
          ),
        );
    } on OcrException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recognitionError = error.message;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.message,
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recognitionError =
            'Váratlan felismerési hiba: $error';
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A szelvény felismerése váratlan '
              'hiba miatt nem sikerült.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _refreshRecognition() async {
    if (!_hasSelectedImage ||
        _isAnalyzing ||
        _isSelectingImage ||
        _isScanningBarcode) {
      return;
    }

    await _startAnalysis();
  }

  Future<void> _copyRecognizedText() async {
    final OcrRecognitionResult? result =
        _ocrResult;

    if (result == null) {
      return;
    }

    final String text =
        _showRawText
            ? result.rawText
            : _parsedBetslip?.cleanedText ??
                result.normalizedText;

    if (text.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: text,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'A felismert szöveg a vágólapra került.',
          ),
        ),
      );
  }

  void _clearSelectedImage() {
    if (_isAnalyzing ||
        _isSelectingImage ||
        _isScanningBarcode) {
      return;
    }

    setState(() {
      _selectedImage = null;
      _selectedSource = null;
      _ocrResult = null;
      _parsedBetslip = null;
      _recognitionError = null;
      _isAnalyzing = false;
      _showRawText = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _hasBarcode
                ? 'A kép és az OCR-eredmények törölve. '
                    'A vonalkód megmaradt.'
                : 'A kiválasztott kép és az '
                    'eredmények törölve.',
          ),
        ),
      );
  }

  String _formatMoney(
    double value,
  ) {
    final int rounded =
        value.round();

    final String digits =
        rounded.toString();

    final StringBuffer buffer =
        StringBuffer();

    for (
      int index = 0;
      index < digits.length;
      index++
    ) {
      final int remaining =
          digits.length - index;

      buffer.write(
        digits[index],
      );

      if (remaining > 1 &&
          remaining % 3 == 1) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  String _formatOdds(
    double value,
  ) {
    return value
        .toStringAsFixed(2)
        .replaceAll(
          '.',
          ',',
        );
  }

  String _formatDateTime(
    DateTime value,
  ) {
    final String year =
        value.year.toString();

    final String month =
        value.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String day =
        value.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String hour =
        value.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String minute =
        value.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year.$month.$day. '
        '$hour:$minute';
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: colors.onPrimaryContainer,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(
              alpha: 0.45,
            )
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedOpacity(
          duration: const Duration(
            milliseconds: 150,
          ),
          opacity: disabled ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: colors.onPrimaryContainer,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ResultRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 19,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecognizedMatchCard extends StatelessWidget {
  final int position;
  final RecognizedMatch match;

  const _RecognizedMatchCard({
    required this.position,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final Color confidenceColor =
        match.confidence >= 75
            ? Colors.green
            : match.confidence >= 50
                ? Colors.orange
                : Colors.redAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      colors.primaryContainer,
                  child: Text(
                    '$position',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    match.matchTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MatchInformationLine(
              label: 'Piac',
              value: match.market.isEmpty
                  ? 'Nem felismerhető'
                  : match.market,
            ),
            const SizedBox(height: 8),
            _MatchInformationLine(
              label: 'Tipp',
              value: match.tip,
            ),
            const SizedBox(height: 8),
            _MatchInformationLine(
              label: 'Odds',
              value: match.hasOdds
                  ? match.odds!
                      .toStringAsFixed(2)
                      .replaceAll(
                        '.',
                        ',',
                      )
                  : '—',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: match.confidence.clamp(
                    0,
                    100,
                  ) /
                  100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
              color: confidenceColor,
            ),
            const SizedBox(height: 7),
            Text(
              'Felismerési megbízhatóság: '
              '${match.confidence}%',
              style: TextStyle(
                color: confidenceColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchInformationLine extends StatelessWidget {
  final String label;
  final String value;

  const _MatchInformationLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final List<String> warnings;
  final Color color;

  const _WarningCard({
    required this.title,
    required this.warnings,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: 0.50,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map(
            (String warning) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _ScannerSource {
  camera,
  gallery,
}
