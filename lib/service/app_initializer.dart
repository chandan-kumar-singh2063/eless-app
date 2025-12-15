import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:eless/controller/auth_controller.dart';
import 'package:eless/controller/dashboard_controller.dart';
import 'package:eless/controller/home_controller.dart';
import 'package:eless/controller/devices_controller.dart';
import 'package:eless/controller/explore_controller.dart';
import 'package:eless/controller/event_controller.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/controller/cart_controller.dart';
import 'package:eless/service/fcm_token_manager.dart';
import 'package:eless/service/connectivity_service.dart';
import 'package:eless/service/fcm_background_service.dart';
import 'package:eless/model/ad_banner.dart';
import 'package:eless/model/category.dart';
import 'package:eless/model/user.dart';
import 'package:eless/model/device.dart';
import 'package:eless/model/event.dart';
import 'package:eless/model/notification.dart';
import 'package:eless/firebase_options.dart';

/// ⚡ App Initializer - Handles all startup initialization in proper order
///
/// Responsibilities:
/// 1. Firebase initialization
/// 2. Hive database setup
/// 3. Controller initialization (lazy loading)
/// 4. FCM setup
/// 5. Connectivity monitoring
class AppInitializer {
  static Future<void> initialize() async {
    log('🚀 App initialization started...');

    // 1. Initialize Firebase
    await _initializeFirebase();

    // 2. Initialize Hive database
    await _initializeHive();

    // 3. Initialize Controllers
    await _initializeControllers();

    // 4. Initialize FCM
    await _initializeFCM();

    // 5. Initialize Connectivity Monitoring
    await _initializeConnectivity();

    log('✅ App initialization complete');
  }

  /// Initialize Firebase
  static Future<void> _initializeFirebase() async {
    log('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    log('✅ Firebase initialized');
  }

  /// Initialize Hive database and register adapters
  static Future<void> _initializeHive() async {
    log('📦 Initializing Hive...');
    await Hive.initFlutter();

    // Register Hive adapters for models
    try {
      Hive.registerAdapter(AdBannerAdapter()); // typeId: 1
      Hive.registerAdapter(CategoryAdapter()); // typeId: 2
      Hive.registerAdapter(UserAdapter()); // typeId: 3
      // ⚠️ typeId: 4 is reserved/skipped - DO NOT USE
      Hive.registerAdapter(EventAdapter()); // typeId: 5
      Hive.registerAdapter(DeviceAdapter()); // typeId: 6
      Hive.registerAdapter(NotificationModelAdapter()); // typeId: 7
    } catch (e) {
      log('Adapters already registered: $e');
    }

    // ⚡ Pre-open all Hive boxes ONCE at startup (parallel)
    log('📦 Pre-opening Hive boxes...');
    await Future.wait([
      Hive.openBox<Device>('Devices'),
      Hive.openBox<Event>('OngoingEvents'),
      Hive.openBox<Event>('UpcomingEvents'),
      Hive.openBox<Event>('PastEvents'),
      Hive.openBox<NotificationModel>('notifications'),
      Hive.openBox<Category>('categories'),
      Hive.openBox<AdBanner>('AdBanners'),
      Hive.openBox('banner_metadata'),
      Hive.openBox('badge_storage'),
      Hive.openBox<String>('token'),
      Hive.openBox<User>('user'),
    ]);
    log('✅ All Hive boxes opened');
  }

  /// Initialize GetX controllers with lazy loading
  static Future<void> _initializeControllers() async {
    log('🎮 Initializing controllers...');

    // Initialize AuthController and WAIT for it to complete
    final authController = Get.put(AuthController(), permanent: true);

    // ⚡ Wait for auth initialization without blocking
    if (!authController.isInitialized.value) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return !authController.isInitialized.value;
      });
    }
    log('✅ AuthController initialized');

    // ⚡ Initialize only essential controllers (lazy load others)
    Get.put(DashboardController());
    log('✅ DashboardController initialized');

    // ⚡ Register controllers with lazy loading - they initialize on first use
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => DevicesController(), fenix: true);
    Get.lazyPut(() => ExploreController(), fenix: true);
    Get.lazyPut(() => EventController(), fenix: true);
    Get.lazyPut(() => NotificationController(), fenix: true);
    Get.lazyPut(() => CartController(), fenix: true);
    log('✅ Controllers registered (lazy load)');
  }

  /// Initialize Firebase Cloud Messaging
  static Future<void> _initializeFCM() async {
    log('🔔 Initializing FCM...');

    // Initialize FCM Token Manager
    final fcmTokenManager = FCMTokenManager();
    await fcmTokenManager.init();
    log('✅ FCM Token Manager initialized');

    // Register FCM token if user is logged in
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn &&
        authController.userUniqueId.value.isNotEmpty) {
      final userUniqueId = authController.userUniqueId.value;
      Future.delayed(const Duration(seconds: 3), () {
        fcmTokenManager.registerFCMToken(userUniqueId).catchError((e) {
          log('⚠️ FCM registration failed: $e');
        });
      });
      log('🔔 FCM token registration scheduled (3s delay)');
    }

    // ⚡ Setup FCM Foreground Handler (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📬 Foreground FCM message: ${message.messageId}');

      final notification = message.notification;
      final data = message.data;

      final String title =
          notification?.title ?? data['title'] ?? 'Notification';
      final String body = notification?.body ?? data['body'] ?? '';
      final String? imageUrl = notification?.android?.imageUrl ?? data['image'];

      log('  Title: $title');
      log('  Body: $body');
      log('  Data: ${message.data}');

      // Show local notification even when app is open
      FCMBackgroundService.showNotification(title, body, imageUrl, data);

      // Update notification controller badge count if available
      try {
        if (Get.isRegistered<NotificationController>()) {
          final notifController = Get.find<NotificationController>();
          notifController.getNotificationsFirstPage();
        }
      } catch (e) {
        log('⚠️ Could not update notification badge: $e');
      }
    });
    log('✅ FCM foreground handler registered');
  }

  /// Initialize connectivity monitoring
  static Future<void> _initializeConnectivity() async {
    log('📡 Initializing connectivity monitoring...');
    final connectivityService = ConnectivityService();
    await connectivityService.init();
    log('✅ Connectivity monitoring started');
  }
}
