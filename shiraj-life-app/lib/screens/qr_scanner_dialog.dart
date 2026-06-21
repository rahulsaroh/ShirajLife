import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({Key? key}) : super(key: key);

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFA3E635);
    
    return Dialog(
      backgroundColor: const Color(0xFF14171D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 320,
        height: 420,
        child: Stack(
          children: [
            // Scanner Viewport
            Positioned.fill(
              child: MobileScanner(
                controller: controller,
                onDetect: (BarcodeCapture capture) {
                  if (_hasScanned) return;
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final rawValue = barcode.rawValue;
                    if (rawValue != null && rawValue.trim().isNotEmpty) {
                      setState(() {
                        _hasScanned = true;
                      });
                      Navigator.pop(context, rawValue);
                      break;
                    }
                  }
                },
                errorBuilder: (context, error, child) {
                  return Container(
                    color: const Color(0xFF0A0B0D),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 48,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera Access Denied',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please grant camera permissions in settings to scan linking QR codes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E94A0),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Custom overlay targeting area
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(scanAreaSize: 220),
              ),
            ),
            // Header Title overlay
            const Positioned(
              top: 16,
              left: 20,
              right: 64,
              child: Text(
                'Scan QR Code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Close / Cancel Button
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ),
            // Torch / Flash Button
            Positioned(
              top: 12,
              right: 56,
              child: ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, child) {
                  final isTorchOn = state.torchState == TorchState.on;
                  return IconButton(
                    icon: Icon(
                      isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: () => controller.toggleTorch(),
                    tooltip: 'Toggle Flash',
                  );
                },
              ),
            ),
            // Instruction footer text overlay
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align QR code inside the frame',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;

  ScannerOverlayPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw background overlay with transparent cut-out
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(24)),
        ),
      ),
      paint,
    );

    // Draw target corner borders
    final borderPaint = Paint()
      ..color = const Color(0xFFA3E635)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderPath = Path();
    const d = 24.0; // corner line length

    // Top Left corner
    borderPath.moveTo(scanAreaRect.left + d, scanAreaRect.top);
    borderPath.lineTo(scanAreaRect.left, scanAreaRect.top);
    borderPath.lineTo(scanAreaRect.left, scanAreaRect.top + d);

    // Top Right corner
    borderPath.moveTo(scanAreaRect.right - d, scanAreaRect.top);
    borderPath.lineTo(scanAreaRect.right, scanAreaRect.top);
    borderPath.lineTo(scanAreaRect.right, scanAreaRect.top + d);

    // Bottom Left corner
    borderPath.moveTo(scanAreaRect.left + d, scanAreaRect.bottom);
    borderPath.lineTo(scanAreaRect.left, scanAreaRect.bottom);
    borderPath.lineTo(scanAreaRect.left, scanAreaRect.bottom - d);

    // Bottom Right corner
    borderPath.moveTo(scanAreaRect.right - d, scanAreaRect.bottom);
    borderPath.lineTo(scanAreaRect.right, scanAreaRect.bottom);
    borderPath.lineTo(scanAreaRect.right, scanAreaRect.bottom - d);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
