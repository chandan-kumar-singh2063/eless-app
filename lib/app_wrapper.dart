import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/controller/auth_controller.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/view/account/auth/sign_in_screen.dart';
import 'package:eless/view/dashboard/dashboard_screen.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      init: authController,
      builder: (controller) {
        // Show sign-in screen on first launch with close button
        return FutureBuilder<bool>(
          future: _shouldShowSignInScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            bool shouldShowSignIn = snapshot.data ?? true;
            
            if (shouldShowSignIn && !controller.isLoggedIn) {
              return const SignInScreen(showCloseButton: true);
            } else {
              return const DashboardScreen();
            }
          },
        );
      },
    );
  }

  Future<bool> _shouldShowSignInScreen() async {
    // You can add logic here to check if this is the first time
    // the app is opened or if you want to show sign-in screen
    // For now, we'll show it if user is not logged in
    await authController.checkExistingUser();
    return true; // Always show sign-in screen if not logged in
  }
}
