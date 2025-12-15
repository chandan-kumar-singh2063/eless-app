import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/controller/auth_controller.dart';
import 'package:eless/service/fcm_token_manager.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/notification/components/notification_card.dart';
import 'package:eless/view/notification/components/notification_loading_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late ScrollController _scrollController;
  bool _hasCheckedPermission = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Mark all notifications as clicked when user opens notification screen
    // This is standard badge behavior - badge disappears when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationController.instance.markAllAsClicked();
      // Check notification permission after screen fully loaded
      _checkAndRequestNotificationPermission();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Guard 1: Prevent duplicate calls while loading
    if (_isLoadingMore) return;

    final controller = NotificationController.instance;

    // Guard 2: Check if more data available before calculating position
    if (!controller.hasMoreData.value) return;

    // Guard 3: Only trigger when close to bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _isLoadingMore = true;
      controller.loadMoreNotifications().then((_) {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  /// Check notification permission and show dialog if denied
  /// Only checks once per screen visit to avoid annoying user
  Future<void> _checkAndRequestNotificationPermission() async {
    if (_hasCheckedPermission) return;
    _hasCheckedPermission = true;

    try {
      // Check current FCM notification settings
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();

      // If permission is denied, show alert dialog
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _showPermissionDeniedDialog();
      }
      // If permission is granted but token not registered, register it
      else if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _ensureTokenRegistered();
      }
    } catch (e) {
      // Silent fail - don't interrupt user experience
    }
  }

  /// Ensure FCM token is registered with backend
  /// Called when permission is granted but token might not be registered
  Future<void> _ensureTokenRegistered() async {
    try {
      final authController = AuthController.instance;
      if (authController.isLoggedIn &&
          authController.userUniqueId.value.isNotEmpty) {
        // IMPORTANT: Use userUniqueId (ROBO-2024-003 format) not user.id (database ID)
        final userUniqueId = authController.userUniqueId.value;
        final fcmTokenManager = FCMTokenManager();

        // Register token in background (won't show any UI)
        await fcmTokenManager.registerFCMToken(userUniqueId);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Show alert dialog when notification permission is denied
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: AppTheme.lightPrimaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Turn on Notifications!!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Turn on notifications to get notified with important notices',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not Now',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Open app settings so user can enable notifications
  /// Also listen for when user returns to re-check permission
  Future<void> _openAppSettings() async {
    try {
      // Open app settings
      await openAppSettings();

      // When user returns from settings, re-check permission
      // Wait a bit for settings to apply
      await Future.delayed(const Duration(seconds: 1));

      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();

      // If permission now granted, register token
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _ensureTokenRegistered();

        // Show success message
        if (mounted) {
          Get.snackbar(
            'Notifications Enabled',
            'You will now receive important notifications',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
          );
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header matching device details style
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Obx(
                    () => NotificationController.instance.unreadCount.value > 0
                        ? TextButton(
                            onPressed: () => NotificationController.instance
                                .markAllAsClicked(),
                            child: Text(
                              'Mark all',
                              style: TextStyle(
                                color: AppTheme.lightPrimaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : const SizedBox(width: 48),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await NotificationController.instance.getNotifications();
                },
                color: AppTheme.lightPrimaryColor,
                child: Obx(() {
                  final controller = NotificationController.instance;

                  // ⚡ Optimistic UI: Show shimmer ONLY when truly empty
                  // During refresh, keep showing existing data (Instagram pattern)
                  if (controller.notificationList.isEmpty) {
                    // Show shimmer only during initial load, not refresh
                    if (controller.isNotificationLoading.value) {
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) =>
                            const NotificationLoadingCard(),
                      );
                    }
                    return _buildEmptyState();
                  }

                  // ⚡ Optimized: Use CustomScrollView with SliverList
                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    cacheExtent: 500, // Preload 500px for smooth scrolling
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return NotificationCard(
                              notification: controller.notificationList[index],
                            );
                          },
                          childCount: controller.notificationList.length,
                          addAutomaticKeepAlives: false, // Save memory
                          addRepaintBoundaries: true,
                        ),
                      ),
                      // Loading indicator as separate sliver
                      if (controller.hasMoreData.value)
                        SliverToBoxAdapter(
                          child: Obx(
                            () => controller.isLoadingMore.value
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.lightPrimaryColor,
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 20),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see notifications here when they arrive',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
