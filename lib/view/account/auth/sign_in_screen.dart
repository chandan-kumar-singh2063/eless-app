import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/route/app_route.dart';
import 'package:eless/theme/app_theme.dart';

class SignInScreen extends StatelessWidget {
  final bool showCloseButton;

  const SignInScreen({super.key, this.showCloseButton = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Close button (if needed)
              if (showCloseButton)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 30),
                      onPressed: () {
                        // Navigate to dashboard as guest
                        Get.offAllNamed(AppRoute.dashboard);
                      },
                    ),
                  ),
                ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo or Title
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: MediaQuery.of(context).size.width * 0.25,
                      decoration: BoxDecoration(
                        color: AppTheme.lightPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.125,
                        ),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: MediaQuery.of(context).size.width * 0.15,
                        color: AppTheme.lightPrimaryColor,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Welcome Text
                    const Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Sign in to access exclusive features\nand manage your devices',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // QR Login Button (styled like "Get Device" button)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
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

                    const SizedBox(height: 20),

                    // Skip text (if close button is shown)
                    if (showCloseButton)
                      TextButton(
                        onPressed: () {
                          // Navigate to dashboard as guest
                          Get.offAllNamed(AppRoute.dashboard);
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
                  ],
                ),
              ),

              // Bottom text
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  showCloseButton
                      ? 'You can browse the app without signing in,\nbut some features require authentication.'
                      : 'Scan your QR code to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
