import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/controller/dashboard_controller.dart';
import 'package:eless/view/account/auth/sign_in_bottom_sheet.dart';
import 'package:eless/view/dashboard/dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasShownSignIn = false;
  bool _hasNavigatedToHome = false;
  bool _wasLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    // Controllers are already initialized in main.dart
    // Just check auth state and show appropriate UI

    return Obx(() {
      final isLoggedIn = authController.isLoggedIn;

      // Reset sign-in flag when user logs out
      if (_wasLoggedIn && !isLoggedIn) {
        _hasShownSignIn = false;
        _hasNavigatedToHome = false;
      }
      _wasLoggedIn = isLoggedIn;

      // ⚡ OPTIMIZATION: Navigate to home ONCE after login success
      if (isLoggedIn && !_hasNavigatedToHome) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _hasNavigatedToHome = true;
          // Navigate to home tab after successful login
          Get.find<DashboardController>().updateIndex(0);
        });
      }

      // Always show dashboard - login status doesn't matter
      // Just show sign-in modal if not logged in
      if (!isLoggedIn && !_hasShownSignIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _hasShownSignIn = true;
          SignInBottomSheet.show(context, canDismiss: true);
        });
      }

      return const DashboardScreen();
    });
  }
}
