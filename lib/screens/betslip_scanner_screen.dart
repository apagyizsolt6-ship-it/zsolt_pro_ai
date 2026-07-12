// ===========================================
// Zsolt Pro AI
// Version: v0.18.2
// File: lib/screens/betslip_scanner_screen.dart
// ===========================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';

class BetslipScannerScreen extends StatefulWidget {
  const BetslipScannerScreen({
    super.key,
  });

  @override
  State<BetslipScannerScreen> createState() {
    return _BetslipScannerScreenState();
  }
}

class _BetslipScannerScreenState
    extends State<BetslipScannerScreen> {
  final ImagePicker _imagePicker =
      ImagePicker();

  final OcrService _ocrService =
      OcrService.instance;

  XFile? _selectedImage;
  _ScannerSource? _selectedSource;

  OcrRecognitionResult? _ocrResult;

  String? _recognitionError;

  bool _isSelectingImage = false;
  bool _isAnalyzing = false;
  bool _showRawText = false;

  bool get _hasSelectedImage {
    return _selectedImage != null;
  }

  bool get _hasOcrResult {
    return _ocrResult != null;
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
          if (_hasSelectedImage)
            IconButton(
              tooltip: 'Kép és eredmény törlése',
              onPressed:
                  _isAnalyzing ||
                          _isSelectingImage
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
            physics:
                const AlwaysScrollableScrollPhysics(),
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
              _buildImagePreview(),
              const SizedBox(height: 18),
              _buildAnalyzeButton(),
              const SizedBox(height: 18),
              _buildResultCard(),
              if (_hasOcrResult) ...[
                const SizedBox(height: 18),
                _buildRecognizedTextCard(),
              ],
              if (_hasOcrResult &&
                  _ocrResult!.hasWarnings) ...[
                const SizedBox(height: 18),
                _buildWarningsCard(),
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
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color:
                    colors.primaryContainer,
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 40,
                color:
                    colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Szelvény Felismerő',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Fotózd le vagy válaszd ki a '
              'Tippmix szelvényedet. A Zsolt Pro AI '
              'kiolvassa a képen szereplő szöveget.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon:
              Icons.add_a_photo_outlined,
          title: 'Szelvény hozzáadása',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SourceCard(
                icon:
                    Icons.camera_alt_outlined,
                title: 'Fotó készítése',
                subtitle:
                    'Kamera használata',
                selected:
                    _selectedSource ==
                        _ScannerSource.camera,
                disabled:
                    _isSelectingImage ||
                        _isAnalyzing,
                onTap: () {
                  _pickImage(
                    source:
                        ImageSource.camera,
                    scannerSource:
                        _ScannerSource.camera,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceCard(
                icon:
                    Icons.photo_library_outlined,
                title: 'Galéria',
                subtitle:
                    'Kép kiválasztása',
                selected:
                    _selectedSource ==
                        _ScannerSource.gallery,
                disabled:
                    _isSelectingImage ||
                        _isAnalyzing,
                onTap: () {
                  _pickImage(
                    source:
                        ImageSource.gallery,
                    scannerSource:
                        _ScannerSource.gallery,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
            color:
                colors.surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: _hasSelectedImage
                  ? colors.primary
                  : colors.outlineVariant,
              width:
                  _hasSelectedImage
                      ? 1.5
                      : 1,
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
      padding: EdgeInsets.all(
        28,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
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
      padding: const EdgeInsets.all(
        28,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 62,
            color:
                colors.onSurfaceVariant,
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
              color:
                  colors.onSurfaceVariant,
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
            File(
              image.path,
            ),
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(
                    24,
                  ),
                  child: Text(
                    'A kép nem jeleníthető meg.',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            14,
            10,
            14,
            12,
          ),
          child: Row(
            children: [
              Icon(
                _selectedSource ==
                        _ScannerSource.camera
                    ? Icons
                        .camera_alt_outlined
                    : Icons
                        .photo_library_outlined,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedSource ==
                          _ScannerSource.camera
                      ? 'Kamerával készített kép'
                      : 'Galériából kiválasztott kép',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Kép törlése',
                onPressed:
                    _isAnalyzing
                        ? null
                        : _clearSelectedImage,
                icon: const Icon(
                  Icons.delete_outline,
                  color:
                      Colors.redAccent,
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
      onPressed:
          !_hasSelectedImage ||
                  _isAnalyzing ||
                  _isSelectingImage
              ? null
              : _startAnalysis,
      icon: _isAnalyzing
          ? const SizedBox(
              width: 21,
              height: 21,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            )
          : const Icon(
              Icons
                  .document_scanner_outlined,
            ),
      label: Text(
        _isAnalyzing
            ? 'Szöveg felismerése...'
            : _hasOcrResult
                ? 'OCR újrafuttatása'
                : 'Szelvény szövegének felismerése',
      ),
      style: FilledButton.styleFrom(
        minimumSize:
            const Size.fromHeight(
          58,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    String title;
    String subtitle;
    IconData icon;
    Color statusColor;

    if (_isAnalyzing) {
      title =
          'OCR felismerés folyamatban';
      subtitle =
          'A kép szövegét dolgozzuk fel.';
      icon = Icons.hourglass_top;
      statusColor =
          colors.primary;
    } else if (_recognitionError != null) {
      title =
          'A felismerés nem sikerült';
      subtitle =
          _recognitionError!;
      icon = Icons.error_outline;
      statusColor =
          Colors.redAccent;
    } else if (_hasOcrResult &&
        _ocrResult!.hasText) {
      title =
          'Szöveg sikeresen felismerve';
      subtitle =
          _ocrResult!
              .confidenceLabel;
      icon =
          Icons.verified_outlined;
      statusColor =
          Colors.green;
    } else if (_hasOcrResult) {
      title =
          'Nem található olvasható szöveg';
      subtitle =
          'Próbálj élesebb vagy közelebbi képet.';
      icon =
          Icons.warning_amber_rounded;
      statusColor =
          Colors.orangeAccent;
    } else if (_hasSelectedImage) {
      title =
          'Kép készen áll';
      subtitle =
          'Indítsd el az OCR felismerést.';
      icon =
          Icons.receipt_long_outlined;
      statusColor =
          colors.primary;
    } else {
      title =
          'Elemzésre vár';
      subtitle =
          'A felismert szöveg itt jelenik meg.';
      icon =
          Icons.receipt_long_outlined;
      statusColor =
          colors.onSurfaceVariant;
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.analytics_outlined,
          title:
              'Felismerési eredmény',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(
              18,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color: statusColor
                            .withValues(
                          alpha: 0.14,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color:
                            statusColor,
                      ),
                    ),
                    const SizedBox(
                      width: 13,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            title,
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            subtitle,
                            style:
                                TextStyle(
                              color: colors
                                  .onSurfaceVariant,
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
                  color:
                      colors.outlineVariant,
                  height: 1,
                ),
                const SizedBox(height: 15),
                _ResultPlaceholderRow(
                  icon:
                      Icons.text_fields,
                  title:
                      'Felismert karakterek',
                  value:
                      _hasOcrResult
                          ? '${_ocrResult!.characterCount}'
                          : '—',
                ),
                const SizedBox(height: 12),
                _ResultPlaceholderRow(
                  icon:
                      Icons.format_list_numbered,
                  title:
                      'Felismert sorok',
                  value:
                      _hasOcrResult
                          ? '${_ocrResult!.lineCount}'
                          : '—',
                ),
                const SizedBox(height: 12),
                _ResultPlaceholderRow(
                  icon:
                      Icons.view_agenda_outlined,
                  title:
                      'Szövegblokkok',
                  value:
                      _hasOcrResult
                          ? '${_ocrResult!.blockCount}'
                          : '—',
                ),
                const SizedBox(height: 12),
                _ResultPlaceholderRow(
                  icon:
                      Icons.fact_check_outlined,
                  title:
                      'OCR megbízhatóság',
                  value:
                      _hasOcrResult
                          ? '${_ocrResult!.confidence}%'
                          : '—',
                ),
                const SizedBox(height: 12),
                _ResultPlaceholderRow(
                  icon:
                      Icons.sports_soccer,
                  title:
                      'Szelvény felismerés',
                  value:
                      _hasOcrResult
                          ? _ocrService
                                  .looksLikeBetslip(
                                _ocrResult!
                                    .normalizedText,
                              )
                              ? 'Valószínű'
                              : 'Bizonytalan'
                          : '—',
                ),
              ],
            ),
          ),
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
            : result.normalizedText;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon:
              Icons.description_outlined,
          title: 'Felismert szöveg',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showRawText
                            ? 'Eredeti OCR szöveg'
                            : 'Tisztított OCR szöveg',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          'Szöveg másolása',
                      onPressed:
                          displayedText
                                  .trim()
                                  .isEmpty
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
                  segments:
                      const <
                          ButtonSegment<
                              bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(
                        'Tisztított',
                      ),
                      icon: Icon(
                        Icons
                            .auto_fix_high_outlined,
                      ),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(
                        'Eredeti',
                      ),
                      icon: Icon(
                        Icons
                            .text_snippet_outlined,
                      ),
                    ),
                  ],
                  selected: <bool>{
                    _showRawText,
                  },
                  onSelectionChanged:
                      (
                    Set<bool> selection,
                  ) {
                    if (selection.isEmpty) {
                      return;
                    }

                    setState(() {
                      _showRawText =
                          selection.first;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  constraints:
                      const BoxConstraints(
                    minHeight: 150,
                    maxHeight: 420,
                  ),
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: colors
                        .surfaceContainerHighest,
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    border: Border.all(
                      color: colors
                          .outlineVariant,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      displayedText
                              .trim()
                              .isEmpty
                          ? 'A képen nem sikerült '
                              'szöveget felismerni.'
                          : displayedText,
                      style: TextStyle(
                        color: displayedText
                                .trim()
                                .isEmpty
                            ? colors
                                .onSurfaceVariant
                            : colors.onSurface,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                if (result.hasText) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _copyRecognizedText,
                      icon:
                          const Icon(
                        Icons.copy,
                      ),
                      label:
                          const Text(
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

  Widget _buildWarningsCard() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final List<String> warnings =
        _ocrResult!.warnings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color:
            Colors.orange.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              Colors.orangeAccent.withValues(
            alpha: 0.50,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .warning_amber_rounded,
                color:
                    Colors.orangeAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ellenőrzendő információk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map(
            (String warning) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        color:
                            colors.onSurfaceVariant,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          color: colors
                              .onSurfaceVariant,
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

  Widget _buildInformationCard() {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer
            .withValues(
          alpha: 0.24,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              colors.primary.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hasOcrResult
                  ? 'Az OCR már működik. A következő '
                      'fejlesztésben a felismert szövegből '
                      'automatikusan kiolvassuk a '
                      'mérkőzéseket, piacokat, oddsokat, '
                      'tétet és várható nyereményt.'
                  : 'A jó eredményhez a teljes szelvény '
                      'legyen éles, jól megvilágított és '
                      'egyenesen lefotózva.',
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage({
    required ImageSource source,
    required _ScannerSource scannerSource,
  }) async {
    if (_isSelectingImage ||
        _isAnalyzing) {
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
        _selectedSource =
            scannerSource;
        _ocrResult = null;
        _recognitionError = null;
        _showRawText = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              scannerSource ==
                      _ScannerSource.camera
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
              'Ellenőrizd az alkalmazás '
              'engedélyeit.',
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
      _recognitionError = null;
      _showRawText = false;
    });

    try {
      final OcrRecognitionResult result =
          await _ocrService
              .recognizeImage(
        selectedImage.path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ocrResult = result;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.hasText
                  ? 'A szövegfelismerés sikerült: '
                      '${result.lineCount} sor.'
                  : 'Nem sikerült olvasható szöveget '
                      'találni a képen.',
            ),
          ),
        );
    } on OcrException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recognitionError =
            error.message;
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
            'Váratlan OCR-hiba történt: $error';
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A szövegfelismerés váratlan '
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
        _isSelectingImage) {
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
            : result.normalizedText;

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
        _isSelectingImage) {
      return;
    }

    setState(() {
      _selectedImage = null;
      _selectedSource = null;
      _ocrResult = null;
      _recognitionError = null;
      _isAnalyzing = false;
      _showRawText = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'A kiválasztott kép és az OCR-eredmény törölve.',
          ),
        ),
      );
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
            color:
                colors.primaryContainer,
            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            icon,
            color:
                colors.onPrimaryContainer,
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
          ? colors.primaryContainer
              .withValues(
              alpha: 0.45,
            )
          : colors
              .surfaceContainerHighest,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap:
            disabled
                ? null
                : onTap,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child: AnimatedOpacity(
          duration: const Duration(
            milliseconds: 150,
          ),
          opacity:
              disabled
                  ? 0.55
                  : 1,
          child: Container(
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors
                        .outlineVariant,
                width:
                    selected
                        ? 1.5
                        : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration:
                      BoxDecoration(
                    color: colors
                        .primaryContainer,
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: colors
                        .onPrimaryContainer,
                    size: 27,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  subtitle,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: colors
                        .onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons
                          .radio_button_unchecked,
                  color: selected
                      ? colors.primary
                      : colors
                          .onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPlaceholderRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ResultPlaceholderRow({
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
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

enum _ScannerSource {
  camera,
  gallery,
}
