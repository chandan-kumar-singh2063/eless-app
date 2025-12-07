import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/theme/app_theme.dart';

/// QR Scanner Screen using mobile_scanner
/// Scans QR codes containing unique_id for JWT authentication
class QRLoginScreen extends StatefulWidget {
  const QRLoginScreen({super.key});

  @override
  State<QRLoginScreen> createState() => _QRLoginScreenState();
}

class _QRLoginScreenState extends State<QRLoginScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _hasShownError = false; // Prevent duplicate error messages
  String? _lastProcessedCode; // Prevent processing same QR twice

  @override
  void dispose() {
    // Stop scanner and dispose controller properly
    _scannerController.stop();
    _scannerController.dispose();
    super.dispose();
  }

  /// 🎯 DEBOUNCED QR DETECTION - Production Implementation
  ///
  /// Flow:
  /// 1. Detect QR → Immediately STOP scanner
  /// 2. Validate QR format locally (prevent bad API calls)
  /// 3. Make exactly ONE API request
  /// 4. On failure → Show error ONCE → Resume scanner
  /// 5. On success → Navigate & close screen
  void _onDetect(BarcodeCapture capture) async {
    // ✅ CRITICAL: Block ALL processing if already working
    if (_isProcessing) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;

    // ✅ Validate QR code locally BEFORE making API call
    if (code == null || code.isEmpty) {
      _showErrorOnce('Invalid QR code - empty');
      return;
    }

    // ✅ Prevent processing the same QR code twice
    if (_lastProcessedCode == code) {
      return;
    }

    // ✅ Basic format validation (adjust pattern to your QR format)
    if (!_isValidQRFormat(code)) {
      _showErrorOnce('Invalid QR code format');
      return;
    }

    // 🔥 CRITICAL: Stop scanner IMMEDIATELY before any async work
    await _scannerController.stop();

    // Mark as processing
    setState(() {
      _isProcessing = true;
      _lastProcessedCode = code;
      _hasShownError = false;
    });

    await _handleQRCode(code);
  }

  /// Validate QR code format locally (prevent useless API calls)
  bool _isValidQRFormat(String code) {
    // Example validation - adjust to your QR code format
    // For unique_id, you might check length, allowed characters, etc.

    // Basic checks:
    if (code.length < 10) return false; // Too short
    if (code.length > 100) return false; // Too long

    // Add your specific validation here
    // e.g., check for prefix, UUID format, etc.

    return true; // Valid format
  }

  /// Process QR code and attempt login (EXACTLY ONCE)
  Future<void> _handleQRCode(String uniqueId) async {
    try {
      final result = await authController.loginWithQRCode(uniqueId);

      // ✅ Check result and handle accordingly
      if (result == 'SUCCESS') {
        // Stop scanner before closing
        await _scannerController.stop();

        if (mounted) {
          // Close scanner screen
          Get.back();

          // Small delay to ensure scanner is fully closed
          await Future.delayed(const Duration(milliseconds: 200));

          // Force rebuild all screens by triggering GetX update
          // This ensures all Obx() widgets rebuild with new auth state
          authController.user.refresh();

          // Show success message
          Get.snackbar(
            'Welcome!',
            'You are now logged in',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        }
        return;
      } else if (result == 'ALREADY_IN_PROGRESS') {
        _resumeScannerAfterError('Please wait, authenticating...');
        return;
      } else {
        // Failed authentication
        _resumeScannerAfterError('Login failed - scan again');
      }
    } catch (e) {
      _resumeScannerAfterError('Login error - try again');
    }
  }

  /// Resume scanner after error (with single error message)
  void _resumeScannerAfterError(String message) {
    _showErrorOnce(message);

    // Reset state and restart scanner
    setState(() {
      _isProcessing = false;
      _lastProcessedCode = null; // Allow re-scanning the same QR
    });

    // Small delay before resuming to prevent immediate re-detection
    Future.delayed(const Duration(milliseconds: 500), () {
      _scannerController.start();
    });
  }

  /// Show error ONCE (prevent rapid snackbar spam)
  void _showErrorOnce(String message) {
    if (_hasShownError) {
      return;
    }

    _hasShownError = true;

    // Close any existing snackbar first
    Get.closeCurrentSnackbar();

    Get.snackbar(
      'Scan Failed',
      message,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      isDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _scannerController.torchEnabled
                  ? Icons.flash_on
                  : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          // Scanning Overlay
          _buildScanningOverlay(),

          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  if (_isProcessing)
                    Column(
                      children: [
                        // 🎨 ORANGE THEME - Consistent with app
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightPrimaryColor,
                          ),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Authenticating...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Position the QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build scanning frame overlay
  Widget _buildScanningOverlay() {
    final scanFrameSize = MediaQuery.of(context).size.width * 0.65;
    return Center(
      child: Container(
        width: scanFrameSize,
        height: scanFrameSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isProcessing ? Colors.green : Colors.white,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Corner decorations
            _buildCorner(Alignment.topLeft),
            _buildCorner(Alignment.topRight),
            _buildCorner(Alignment.bottomLeft),
            _buildCorner(Alignment.bottomRight),

            // Success indicator
            if (_isProcessing)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 60),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build corner decoration
  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? BorderSide(
                    color: _isProcessing ? Colors.green : Colors.white,
                    width: 4,
                  )
                : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? BorderSide(
                    color: _isProcessing ? Colors.green : Colors.white,
                    width: 4,
                  )
                : BorderSide.none,
            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? BorderSide(
                    color: _isProcessing ? Colors.green : Colors.white,
                    width: 4,
                  )
                : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? BorderSide(
                    color: _isProcessing ? Colors.green : Colors.white,
                    width: 4,
                  )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
