// ===========================================
// Zsolt Pro AI
// Version: v0.20.2
// File: lib/screens/barcode_scanner_screen.dart
// ===========================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() {
    return _BarcodeScannerScreenState();
  }
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  String? _detectedValue;
  String? _detectedFormat;
  final bool _isProcessing = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: true,
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const <BarcodeFormat>[
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.itf,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
      ],
    );

    _barcodeSubscription = _controller.barcodes.listen(
      _handleBarcodeCapture,
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        _showMessage('Vonalkódolvasási hiba: $error');
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopCamera();
        break;
      case AppLifecycleState.resumed:
        _startCamera();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Vonalkód beolvasása',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _torchEnabled ? 'Vaku kikapcsolása' : 'Vaku bekapcsolása',
            onPressed: _toggleTorch,
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            tooltip: 'Kamera megfordítása',
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error, Widget? child) {
                return _buildCameraError('Kamera hiba', error.toString());
              },
            ),
            _buildDarkOverlay(),
            Align(
              alignment: Alignment.center,
              child: _buildScannerFrame(colors),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildInstructionCard(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomPanel(colors),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScannerOverlayPainter(),
      ),
    );
  }
  Widget _buildScannerFrame(ColorScheme colors) {
    return Container(
      width: 320,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _detectedValue != null ? Colors.greenAccent : colors.primary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (_detectedValue != null ? Colors.greenAccent : colors.primary).withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(top: 12, left: 12, child: _CornerMarker(top: true, left: true)),
          const Positioned(top: 12, right: 12, child: _CornerMarker(top: true, left: false)),
          const Positioned(bottom: 12, left: 12, child: _CornerMarker(top: false, left: true)),
          const Positioned(bottom: 12, right: 12, child: _CornerMarker(top: false, left: false)),
          Center(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: _detectedValue != null ? Colors.greenAccent : colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_detectedValue != null ? Colors.greenAccent : colors.primary).withValues(alpha: 0.75),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Helyezze a Tippmix szelvény vonalkódját a kijelölt keretbe.',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _detectedValue != null ? 'Beolvasva ($_detectedFormat):' : 'Szkennelésre kész',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (_detectedValue != null) ...[
            const SizedBox(height: 8),
            Text(
              _detectedValue!,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _scanAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Újra'),
                ),
                TextButton.icon(
                  onPressed: _copyBarcode,
                  icon: const Icon(Icons.copy),
                  label: const Text('Másolás'),
                ),
                ElevatedButton.icon(
                  onPressed: _acceptBarcode,
                  icon: const Icon(Icons.check),
                  label: const Text('Elfogadás'),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
