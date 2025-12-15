import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:eless/auth_wrapper.dart';
import 'package:eless/controller/auth_controller.dart';
import 'package:eless/controller/dashboard_controller.dart';
import 'package:eless/controller/home_controller.dart';
import 'package:eless/controller/devices_controller.dart';
import 'package:eless/controller/explore_controller.dart';
import 'package:eless/controller/event_controller.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/controller/cart_controller.dart';
import 'package:eless/service/fcm_token_manager.dart';
import 'package:eless/model/ad_banner.dart';
import 'package:eless/model/category.dart';
import 'package:eless/model/user.dart';
import 'package:eless/model/device.dart';
import 'package:eless/model/event.dart';
import 'package:eless/model/notification.dart';
import 'package:eless/route/app_page.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Background message handler - MUST be top-level function
/// Called when app receives FCM message while in background/terminated state
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('📬 Background FCM message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    final String title = notification?.title ?? data['title'] ?? 'Notification';
    final String body = notification?.body ?? data['body'] ?? '';
    final String? imageUrl = notification?.android?.imageUrl ?? data['image'];

    log('  Title: $title');
    log('  Body: $body');
    log('  Image: ${imageUrl ?? "none"}');
    log('  Data: ${message.data}');

    // Show local notification with image (when app is closed)
    await _showBackgroundNotification(title, body, imageUrl, data);
  } catch (e) {
    log('❌ Background FCM handler error: $e');
    // Don't crash - just log the error
  }
}

/// Show notification when app is in background/terminated
Future<void> _showBackgroundNotification(
  String title,
  String body,
  String? imageUrl,
  Map<String, dynamic> data,
) async {
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );
  await localNotifications.initialize(initSettings);

  AndroidNotificationDetails androidDetails;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    log('🖼️ Downloading image for background notification...');
    try {
      final String? imagePath = await _downloadImageBackground(imageUrl);

      if (imagePath != null) {
        log('✅ Using BigPicture style in background');
        final bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(imagePath),
          largeIcon: FilePathAndroidBitmap(imagePath),
          contentTitle: title,
          summaryText: body,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );

        androidDetails = AndroidNotificationDetails(
          'eless_channel',
          'Eless Notifications',
          channelDescription: 'General notifications for Eless app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          styleInformation: bigPictureStyle,
        );
      } else {
        log('⚠️ Image download failed in background');
        androidDetails = _getDefaultAndroidDetailsBackground();
      }
    } catch (e) {
      log('❌ Error loading image in background: $e');
      androidDetails = _getDefaultAndroidDetailsBackground();
    }
  } else {
    androidDetails = _getDefaultAndroidDetailsBackground();
  }

  final platformDetails = NotificationDetails(android: androidDetails);

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    platformDetails,
    payload: data.isNotEmpty ? data.toString() : null,
  );

  log('✅ Background notification displayed');
}

AndroidNotificationDetails _getDefaultAndroidDetailsBackground() {
  return const AndroidNotificationDetails(
    'eless_channel',
    'Eless Notifications',
    channelDescription: 'General notifications for Eless app',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );
}

Future<String?> _downloadImageBackground(String url) async {
  try {
    log('📥 Background download: $url');
    final response = await http
        .get(Uri.parse(url), headers: {'Accept': 'image/*'})
        .timeout(const Duration(seconds: 10));

    log(
      '   Status: ${response.statusCode}, Size: ${response.bodyBytes.length} bytes',
    );

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/bg_notif_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (await file.exists()) {
        log('✅ Background image saved: $filePath');

        // ⚡ Cleanup old notification images (prevent memory leak)
        _cleanupOldNotificationImages(directory).catchError((e) {
          log('⚠️ Cleanup failed: $e');
        });

        return filePath;
      }
    }
  } catch (e) {
    log('❌ Background download failed: $e');
  }
  return null;
}

/// Clean up old notification images to prevent temp directory bloat
Future<void> _cleanupOldNotificationImages(Directory directory) async {
  try {
    final files = directory.listSync();
    final now = DateTime.now();

    for (final file in files) {
      if (file is File && file.path.contains('bg_notif_')) {
        final stat = await file.stat();
        final age = now.difference(stat.modified);

        // Delete images older than 24 hours
        if (age.inHours > 24) {
          await file.delete();
          log('🗑️ Deleted old notification image: ${file.path}');
        }
      }
    }
  } catch (e) {
    log('⚠️ Cleanup error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Hive (local database)
  await Hive.initFlutter();

  // Register Hive adapters for models (safe registration)
  try {
    Hive.registerAdapter(AdBannerAdapter()); // typeId: 1
    Hive.registerAdapter(CategoryAdapter()); // typeId: 2
    Hive.registerAdapter(UserAdapter()); // typeId: 3
    // ⚠️ typeId: 4 is reserved/skipped - DO NOT USE
    Hive.registerAdapter(EventAdapter()); // typeId: 5
    Hive.registerAdapter(DeviceAdapter()); // typeId: 6
    Hive.registerAdapter(NotificationModelAdapter()); // typeId: 7
  } catch (e) {
    // Adapters already registered (e.g., during hot reload)
    log('Adapters already registered: $e');
  }

  // Configure EasyLoading
  configLoading();

  // Initialize all controllers BEFORE running the app (during splash screen)
  log('🚀 Initializing controllers...');

  // Initialize AuthController and WAIT for it to complete
  final authController = Get.put(AuthController(), permanent: true);

  // ⚡ FIX: Wait for auth initialization without blocking
  if (!authController.isInitialized.value) {
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return !authController.isInitialized.value;
    });
  }
  log('✅ AuthController initialized');

  // ⚡ FIX: Initialize only essential controllers (lazy load others)
  Get.put(DashboardController());
  log('✅ DashboardController initialized');

  // ⚡ FIX: Register controllers with lazy loading - they initialize on first use
  Get.lazyPut(() => HomeController(), fenix: true);
  Get.lazyPut(() => DevicesController(), fenix: true);
  Get.lazyPut(() => ExploreController(), fenix: true);
  Get.lazyPut(() => EventController(), fenix: true);
  Get.lazyPut(() => NotificationController(), fenix: true);
  Get.lazyPut(() => CartController(), fenix: true);
  log('✅ Controllers registered (lazy load)');

  // Initialize FCM Token Manager and start background registration
  // This happens AFTER all controllers are ready
  final fcmTokenManager = FCMTokenManager();
  await fcmTokenManager.init();
  log('✅ FCM Token Manager initialized');

  // If user is logged in, register FCM token in background
  if (authController.isLoggedIn &&
      authController.userUniqueId.value.isNotEmpty) {
    // IMPORTANT: Use userUniqueId (ROBO-2024-003 format) not user.id (database ID)
    final userUniqueId = authController.userUniqueId.value;
    // Run in background with reduced delay (3s is enough for app to be ready)
    Future.delayed(const Duration(seconds: 3), () {
      fcmTokenManager.registerFCMToken(userUniqueId).catchError((e) {
        log('⚠️ FCM registration failed: $e');
      });
    });
    log('🔔 FCM token registration scheduled (3s delay)');
  }

  log('✅ All initialization complete - launching app');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      getPages: AppPage.list,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      builder: EasyLoading.init(),
    );
  }
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..userInteractions = false
    ..maskType = EasyLoadingMaskType.black
    ..dismissOnTap = true;
}
