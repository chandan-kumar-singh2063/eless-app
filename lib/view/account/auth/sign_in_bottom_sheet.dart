import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:eless/theme/app_theme.dart';

class SignInBottomSheet {
  static void show(BuildContext context, {bool canDismiss = true}) {
    showMaterialModalBottomSheet(
      context: context,
      isDismissible: canDismiss,
      enableDrag: canDismiss,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SignInBottomSheetContent(canDismiss: canDismiss),
    );
  }
}

class _SignInBottomSheetContent extends StatelessWidget {
  final bool canDismiss;

  const _SignInBottomSheetContent({required this.canDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Close button (if dismissible)
              if (canDismiss)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),

              // App Logo or Title
              Container(
                width: MediaQuery.of(context).size.width * 0.22,
                height: MediaQuery.of(context).size.width * 0.22,
                decoration: BoxDecoration(
                  color: AppTheme.lightPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.11,
                  ),
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: MediaQuery.of(context).size.width * 0.12,
                  color: AppTheme.lightPrimaryColor,
                ),
              ),

              const SizedBox(height: 30),

              // Welcome Text
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Sign in to access exclusive features\nand get our devices',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),

              const SizedBox(height: 30),

              // QR Login Button (styled like "Get Device" button)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close bottom sheet first
                    Get.toNamed('/qr-login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Sign In with QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Skip text (if dismissible)
              if (canDismiss)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
