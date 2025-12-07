import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:get/get.dart';
import 'package:eless/controller/dashboard_controller.dart';
import 'package:eless/controller/auth_controller.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/Explore/explore_screen.dart';
import 'package:eless/view/home/home_screen.dart';
import 'package:eless/view/Devices/devices_screen.dart';

import '../account/account_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ⚡ OPTIMIZATION: Cache controller reference (don't call Get.find repeatedly)
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    // Get controller ONCE during init (not on every rebuild)
    _authController = Get.find<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      builder: (controller) => Stack(
        children: [
          // Main app content
          Scaffold(
            backgroundColor: Colors.grey.shade100,
            body: SafeArea(
              child: IndexedStack(
                index: controller.tabIndex,
                children: const [
                  HomeScreen(),
                  ExploreScreen(),
                  DevicesScreen(),
                  AccountScreen(),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 0.7,
                  ),
                ),
              ),
              child: SnakeNavigationBar.color(
                behaviour: SnakeBarBehaviour.floating,
                snakeShape: SnakeShape.circle,
                padding: const EdgeInsets.symmetric(vertical: 5),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                snakeViewColor: Theme.of(context).primaryColor,
                unselectedItemColor: Theme.of(context).colorScheme.secondary,
                showUnselectedLabels: true,
                currentIndex: controller.tabIndex,
                onTap: (val) {
                  controller.updateIndex(val);
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_rounded),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.flash_on_rounded),
                    label: 'Devices',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_circle_rounded),
                    label: 'Account',
                  ),
                ],
              ),
            ),
          ),

          // 🔒 BLOCKING OVERLAY - Prevents all user interaction during login/logout
          Obx(() {
            // ⚡ Use cached controller reference
            final isBlocked =
                _authController.isLoggingIn.value ||
                _authController.isLoggingOut.value;

            if (!isBlocked) return const SizedBox.shrink();

            return Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🎨 ORANGE THEME - Consistent with app
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _authController.isLoggingIn.value
                              ? 'Logging in...'
                              : 'Logging out...',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please wait',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
