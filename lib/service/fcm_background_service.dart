import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:eless/firebase_options.dart';

/// ⚡ FCM Background Service - Handles notifications when app is closed
///
/// MUST be a top-level function (not a class method)
/// Called by Firebase when notification arrives while app is terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
    await FCMBackgroundService.showNotification(title, body, imageUrl, data);
  } catch (e) {
    log('❌ Background FCM handler error: $e');
    // Don't crash - just log the error
  }
}

/// FCM Background Service - Static methods for notification handling
class FCMBackgroundService {
  /// Show notification when app is in background/terminated
  static Future<void> showNotification(
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
        final String? imagePath = await _downloadImage(imageUrl);

        if (imagePath != null) {
          log('✅ Using BigPicture style');
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
          log('⚠️ Image download failed');
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

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: data.isNotEmpty ? data.toString() : null,
    );

    log('✅ Background notification displayed');
  }

  static AndroidNotificationDetails _getDefaultAndroidDetails() {
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

  static Future<String?> _downloadImage(String url) async {
    try {
      log('📥 Downloading: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      log(
        '📊 Response: ${response.statusCode}, Size: ${response.bodyBytes.length} bytes',
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'notification_$timestamp.jpg';
        final filePath = '${directory.path}/$filename';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        log('✅ Image saved: $filePath (${response.bodyBytes.length} bytes)');

        // Clean up old images (older than 24 hours)
        _cleanupOldImages(directory);

        return filePath;
      }
    } catch (e) {
      log('❌ Download failed: $e');
    }
    return null;
  }

  /// Clean up old notification images to prevent temp directory bloat
  static Future<void> _cleanupOldImages(Directory directory) async {
    try {
      final files = directory.listSync();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File && file.path.contains('notification_')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

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
}
