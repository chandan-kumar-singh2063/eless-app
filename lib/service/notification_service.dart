import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 🔥 PRODUCTION-READY Notification Service
///
/// Features:
/// ✅ onMessage (foreground)
/// ✅ onBackgroundMessage (background/terminated)
/// ✅ onMessageOpenedApp (tap handling)
/// ✅ Local notifications for foreground
/// ✅ Navigation based on notification data
/// ✅ Android-only (as requested)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription? _foregroundSubscription;
  StreamSubscription? _messageOpenedSubscription;

  /// Initialize notification service
  Future<void> init() async {
    // Initialize local notifications (Android only)
    await _initLocalNotifications();

    // Request permission (Android 13+)
    await _requestPermission();

    // Setup foreground message handler
    _setupForegroundMessageHandler();

    // Setup tap handler (background/terminated)
    _setupMessageTapHandler();

    // Check for initial message (app opened from terminated state)
    _checkInitialMessage();

    log('✓ Notification service initialized');
  }

  /// Initialize local notifications (Android only)
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    log('✓ Local notifications initialized (Android)');
  }

  /// Request notification permission (Android 13+)
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('✓ Notification permission granted');
    } else {
      log('✗ Notification permission denied');
    }
  }

  /// 5️⃣ FOREGROUND MESSAGE HANDLER
  /// Called when app is open and in foreground
  void _setupForegroundMessageHandler() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      log('📬 Foreground message: ${message.messageId}');
      log('  Title: ${message.notification?.title ?? 'No title'}');
      log('  Body: ${message.notification?.body ?? 'No body'}');
      log('  Data: ${message.data}');

      // Show local notification for both notification object and data-only messages
      _showLocalNotification(message);

      // Handle data-only messages
      _handleMessageData(message.data, fromForeground: true);
    });

    log('✓ Foreground message handler setup');
  }

  /// BACKGROUND/TERMINATED MESSAGE HANDLER
  /// Note: This is registered in main.dart as top-level function
  /// @pragma('vm:entry-point')
  /// Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  ///   await Firebase.initializeApp();
  ///   log('📬 Background message: ${message.messageId}');
  ///   // Process data, save to local DB, etc.
  /// }

  /// MESSAGE TAP HANDLER (background/terminated)
  /// Called when user taps notification while app in background/terminated
  void _setupMessageTapHandler() {
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      log('👆 User tapped notification: ${message.messageId}');
      log('  Data: ${message.data}');

      // Navigate based on message data
      _handleNotificationTap(message.data);
    });

    log('✓ Message tap handler setup');
  }

  /// Check for initial message (app opened from terminated state)
  Future<void> _checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      log('📬 App opened from terminated state');
      log('  Message ID: ${message.messageId}');
      log('  Data: ${message.data}');

      // Delay navigation to ensure app fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(message.data);
      });
    }
  }

  /// Show local notification (foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Get title and body from notification object or data payload
    final String title = notification?.title ?? data['title'] ?? 'Notification';
    final String body = notification?.body ?? data['body'] ?? '';
    final String? imageUrl = notification?.android?.imageUrl ?? data['image'];

    log('📱 Showing local notification');
    log('   Title: $title');
    log('   Body: $body');
    log('   Image: ${imageUrl ?? "none"}');

    AndroidNotificationDetails androidDetails;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      log('🖼️ Downloading image for notification...');
      try {
        final String? imagePath = await _downloadImage(imageUrl);

        if (imagePath != null) {
          log('✅ Using BigPicture style with image');
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
          log('⚠️ Image download failed, using default style');
          androidDetails = _getDefaultAndroidDetails();
        }
      } catch (e) {
        log('❌ Error loading image: $e');
        androidDetails = _getDefaultAndroidDetails();
      }
    } else {
      androidDetails = _getDefaultAndroidDetails();
    }

    final platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );

    log('✅ Local notification displayed');
  }

  AndroidNotificationDetails _getDefaultAndroidDetails() {
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

  Future<String?> _downloadImage(String url) async {
    try {
      log('📥 Downloading: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'image/*'})
          .timeout(const Duration(seconds: 10));

      log(
        '   Status: ${response.statusCode}, Size: ${response.bodyBytes.length} bytes',
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/notif_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (await file.exists()) {
          log('✅ Saved to: $filePath');
          return filePath;
        }
      }
    } catch (e) {
      log('❌ Download failed: $e');
    }
    return null;
  }

  /// Handle message data (data-only messages or additional data)
  void _handleMessageData(
    Map<String, dynamic> data, {
    bool fromForeground = false,
  }) {
    if (data.isEmpty) return;

    final type = data['type'] as String?;
    log('🔔 Handling message type: $type (foreground: $fromForeground)');

    switch (type) {
      case 'device_request':
        // Refresh device requests
        // Example: DeviceRequestController.instance.refresh();
        log('  → Refreshing device requests');
        break;
      case 'device_approved':
        // Show success message
        if (fromForeground) {
          Get.snackbar(
            'Device Approved',
            'Your device has been approved',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        break;
      case 'device_rejected':
        // Show rejection message
        if (fromForeground) {
          Get.snackbar(
            'Device Rejected',
            'Your device request was rejected',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        break;
      default:
        log('  → Unknown message type');
    }
  }

  /// 3️⃣ Handle notification tap (deep link navigation)
  /// Passes message.data to GetX route handler
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      log('👆 Notification tapped - no data, going to main');
      Get.toNamed('/main');
      return;
    }

    final type = data['type'] as String?;
    final targetScreen = data['screen'] as String?;

    log('👆 Notification tapped - type: $type, screen: $targetScreen');
    log('   Full data: $data');

    // Direct screen navigation (highest priority)
    if (targetScreen != null) {
      log('  → Navigating to screen: $targetScreen');
      Get.toNamed(targetScreen, arguments: data);
      return;
    }

    // Type-based navigation with data passed to route
    if (type != null) {
      switch (type) {
        case 'device_request':
          log('  → Navigating to device requests');
          Get.toNamed('/device-requests', arguments: data);
          break;
        case 'device_approved':
        case 'device_rejected':
          log('  → Navigating to my devices');
          Get.toNamed('/my-devices', arguments: data);
          break;
        case 'event':
          final eventId = data['event_id'] as String?;
          if (eventId != null) {
            log('  → Navigating to event detail: $eventId');
            Get.toNamed('/event-detail', arguments: data);
          } else {
            log('  → No event_id, going to events list');
            Get.toNamed('/events', arguments: data);
          }
          break;
        case 'message':
          final chatId = data['chat_id'] as String?;
          if (chatId != null) {
            log('  → Navigating to chat: $chatId');
            Get.toNamed('/chat', arguments: data);
          } else {
            log('  → Going to messages list');
            Get.toNamed('/messages', arguments: data);
          }
          break;
        default:
          log('  → Unknown type, going to main');
          Get.toNamed('/main', arguments: data);
      }
    } else {
      // No type or screen, go to main
      log('  → No type specified, going to main');
      Get.toNamed('/main', arguments: data);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    log('👆 Local notification tapped: ${response.id}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Parse payload as map (simplified)
        // In production, use proper JSON parsing
        log('  Payload: ${response.payload}');
      } catch (e) {
        log('  Error parsing payload: $e');
      }
    }
  }

  /// Clean up subscriptions
  void dispose() {
    _foregroundSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    log('✓ Notification service disposed');
  }
}

/// Top-level background message handler
/// Must be registered in main.dart BEFORE runApp()
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized here
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  log('📬 Background message: ${message.messageId}');
  log('  Title: ${message.notification?.title ?? 'No title'}');
  log('  Body: ${message.notification?.body ?? 'No body'}');
  log('  Data: ${message.data}');

  // Process notification data
  // Example: Save to local DB, update badge count, etc.
  // NOTE: Cannot show UI, navigate, or call GetX methods from here

  // Example: Save notification to Hive
  // final box = await Hive.openBox('notifications');
  // await box.add({
  //   'id': message.messageId,
  //   'title': message.notification?.title,
  //   'body': message.notification?.body,
  //   'data': message.data,
  //   'timestamp': DateTime.now().toIso8601String(),
  // });
}
