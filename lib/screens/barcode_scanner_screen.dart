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
  String? _errorMessage;

  bool _isProcessing = false;
  bool _isCameraRunning = true;
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
        setState(() {
          _errorMessage = 'Vonalkódolvasási hiba: $error';
        });
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
                color: Colors.black.withOpacity(0.35),
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
            color: (_detectedValue != null ? Colors.greenAccent : colors.primary).withOpacity(0.35),
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
                    color: (_detectedValue != null ? Colors.greenAccent : colors.primary).withOpacity(0.75),
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
        color: Colors.black.withOpacity(0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
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
  Widget _buildCameraError(String title, String message) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.redAccent, size: 62),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _startCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Újrapróbálkozás'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBarcodeCapture(BarcodeCapture capture) async {
    if (_isProcessing || _detectedValue != null) return;

    Barcode? selectedBarcode;
    for (final Barcode barcode in capture.barcodes) {
      final String value = barcode.rawValue?.trim() ?? '';
      if (value.isEmpty) continue;
      selectedBarcode = barcode;
      break;
    }

    if (selectedBarcode == null) return;
    final String value = selectedBarcode.rawValue!.trim();

    setState(() {
      _isProcessing = true;
      _detectedValue = value;
      _detectedFormat = _formatBarcodeType(selectedBarcode!.format);
      _errorMessage = null;
    });

    await HapticFeedback.mediumImpact();
    await _controller.stop();

    if (!mounted) return;

    setState(() {
      _isCameraRunning = false;
      _isProcessing = false;
    });
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (!mounted) return;
      setState(() {
        _torchEnabled = !_torchEnabled;
      });
    } catch (error) {
      _showMessage('A vaku nem kapcsolható ezen a készüléken.');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (error) {
      _showMessage('A kamera nem váltható át.');
    }
  }

  Future<void> _startCamera() async {
    try {
      await _controller.start();
      if (!mounted) return;
      setState(() {
        _isCameraRunning = true;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'A kamera elindítása nem sikerült.';
      });
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
      if (!mounted) return;
      setState(() {
        _isCameraRunning = false;
      });
    } catch (_) {}
  }

  Future<void> _scanAgain() async {
    setState(() {
      _detectedValue = null;
      _detectedFormat = null;
      _errorMessage = null;
      _isProcessing = false;
    });
    await _startCamera();
  }

  Future<void> _copyBarcode() async {
    final String? value = _detectedValue;
    if (value == null || value.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _showMessage('A vonalkód a vágólapra került.');
  }

  void _acceptBarcode() {
    final String? value = _detectedValue;
    if (value == null || value.isEmpty) return;
    Navigator.of(context).pop<String>(value);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatBarcodeType(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.code128: return 'CODE 128';
      case BarcodeFormat.code39: return 'CODE 39';
      case BarcodeFormat.code93: return 'CODE 93';
      case BarcodeFormat.codabar: return 'Codabar';
      case BarcodeFormat.ean13: return 'EAN-13';
      case BarcodeFormat.ean8: return 'EAN-8';
      case BarcodeFormat.itf: return 'ITF-14';
      case BarcodeFormat.upcA: return 'UPC-A';
      case BarcodeFormat.upcE: return 'UPC-E';
      case BarcodeFormat.qrCode: return 'QR-kód';
      case BarcodeFormat.dataMatrix: return 'Data Matrix';
      case BarcodeFormat.pdf417: return 'PDF417';
      case BarcodeFormat.aztec: return 'Aztec';
      default: return format.name;
    }
  }
}

class _CornerMarker extends StatelessWidget {
  final bool top;
  final bool left;

  const _CornerMarker({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _CornerMarkerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerMarkerPainter extends CustomPainter {
  final bool top;
  final bool left;

  const _CornerMarkerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    if (top && left) {
      path..moveTo(0, size.height)..lineTo(0, 0)..lineTo(size.width, 0);
    } else if (top && !left) {
      path..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width, size.height);
    } else if (!top && left) {
      path..moveTo(0, 0)..lineTo(0, size.height)..lineTo(size.width, size.height);
    } else {
      path..moveTo(0, size.height)..lineTo(size.width, size.height)..lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerMarkerPainter oldDelegate) {
    return oldDelegate.top != top || oldDelegate.left != left;
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 320,
      height: 180,
    );

    final Paint overlayPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final RRect roundedScanArea = RRect.fromRectAndRadius(scanArea, const Radius.circular(22));

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(roundedScanArea),
      ),
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
