// ===========================================
// Zsolt Pro AI
// Version: v0.10.1
// File: lib/screens/betslip_scanner_screen.dart
// ===========================================

import 'package:flutter/material.dart';

class BetslipScannerScreen extends StatefulWidget {
  const BetslipScannerScreen({super.key});

  @override
  State<BetslipScannerScreen> createState() {
    return _BetslipScannerScreenState();
  }
}

class _BetslipScannerScreenState
    extends State<BetslipScannerScreen> {
  _ScannerSource? _selectedSource;
  bool _isAnalyzing = false;

  bool get _hasSelectedImage {
    return _selectedSource != null;
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            28,
          ),
          children: [
            _buildHeaderCard(
              context: context,
            ),
            const SizedBox(height: 18),
            _buildSourceSection(
              context: context,
            ),
            const SizedBox(height: 18),
            _buildImagePreview(
              context: context,
            ),
            const SizedBox(height: 18),
            _buildAnalyzeButton(
              context: context,
            ),
            const SizedBox(height: 18),
            _buildResultCard(
              context: context,
            ),
            const SizedBox(height: 18),
            _buildInformationCard(
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required BuildContext context,
  }) {
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
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 40,
                color: colors.onPrimaryContainer,
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
              'felismeri majd a mérkőzéseket, piacokat, '
              'tippeket és oddsokat.',
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

  Widget _buildSourceSection({
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
                    _selectedSource ==
                    _ScannerSource.camera,
                onTap: () {
                  _selectSource(
                    _ScannerSource.camera,
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
                    _selectedSource ==
                    _ScannerSource.gallery,
                onTap: () {
                  _selectSource(
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

  Widget _buildImagePreview({
    required BuildContext context,
  }) {
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
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 210,
          ),
          decoration: BoxDecoration(
            color:
                colors.surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: _hasSelectedImage
                  ? colors.primary
                  : colors.outlineVariant,
              width: _hasSelectedImage
                  ? 1.5
                  : 1,
            ),
          ),
          child: _hasSelectedImage
              ? _buildSelectedImagePlaceholder(
                  context: context,
                )
              : _buildEmptyImagePlaceholder(
                  context: context,
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyImagePlaceholder({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
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

  Widget _buildSelectedImagePlaceholder({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool cameraSelected =
        _selectedSource ==
        _ScannerSource.camera;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              cameraSelected
                  ? Icons.camera_alt_outlined
                  : Icons.photo_library_outlined,
              size: 34,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            cameraSelected
                ? 'Kamera kiválasztva'
                : 'Galéria kiválasztva',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'A következő fejlesztési lépésben '
            'bekötjük a tényleges képkezelést.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedSource = null;
              });
            },
            icon: const Icon(
              Icons.close,
            ),
            label: const Text(
              'Kiválasztás törlése',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton({
    required BuildContext context,
  }) {
    return FilledButton.icon(
      onPressed:
          !_hasSelectedImage ||
              _isAnalyzing
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
              Icons.psychology_outlined,
            ),
      label: Text(
        _isAnalyzing
            ? 'AI elemzés folyamatban...'
            : 'AI elemzés indítása',
      ),
      style: FilledButton.styleFrom(
        minimumSize:
            const Size.fromHeight(58),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(17),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.analytics_outlined,
          title: 'Felismerési eredmény',
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            colors.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: colors
                            .onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Elemzésre vár',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A felismert mérkőzések '
                            'és tippek itt jelennek meg.',
                            style: TextStyle(
                              color: colors
                                  .onSurfaceVariant,
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
                const _ResultPlaceholderRow(
                  icon: Icons.sports_soccer,
                  title:
                      'Felismert mérkőzések',
                  value: '—',
                ),
                const SizedBox(height: 12),
                const _ResultPlaceholderRow(
                  icon:
                      Icons.checklist_outlined,
                  title: 'Felismert tippek',
                  value: '—',
                ),
                const SizedBox(height: 12),
                const _ResultPlaceholderRow(
                  icon:
                      Icons.percent_outlined,
                  title: 'Összesített odds',
                  value: '—',
                ),
                const SizedBox(height: 12),
                const _ResultPlaceholderRow(
                  icon:
                      Icons.payments_outlined,
                  title: 'Tét',
                  value: '—',
                ),
                const SizedBox(height: 12),
                const _ResultPlaceholderRow(
                  icon:
                      Icons.emoji_events_outlined,
                  title: 'Szelvény állapota',
                  value: 'Nincs adat',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCard({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer
            .withValues(
          alpha: 0.24,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: colors.primary.withValues(
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
              'A felismerő később azt is '
              'ellenőrizni fogja, hogy a '
              'mérkőzések véget értek-e, és '
              'a szelvény nyertes vagy vesztes lett-e.',
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

  void _selectSource(
    _ScannerSource source,
  ) {
    setState(() {
      _selectedSource = source;
    });

    final String message =
        source == _ScannerSource.camera
            ? 'A kamera bekötése lesz a következő lépés.'
            : 'A galéria bekötése lesz a következő lépés.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzing = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Az AI képfelismerést a következő '
            'lépésekben kötjük be.',
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
            color: colors.primaryContainer,
            borderRadius:
                BorderRadius.circular(11),
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
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
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
          : colors.surfaceContainerHighest,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
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
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color:
                      colors.onPrimaryContainer,
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
                  color:
                      colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons
                        .radio_button_unchecked,
                color: selected
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ],
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
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
