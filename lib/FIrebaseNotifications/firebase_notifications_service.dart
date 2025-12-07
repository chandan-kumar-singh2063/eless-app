import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FirebaseNotificationsService {
  FirebaseMessaging messages = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> setupInterachMessage(BuildContext context) async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      FirebaseMessaging.onMessageOpenedApp.listen((event) {});
    }
  }

  Future<String> getDeviceToken() async {
    String? token = await messages.getToken();
    messages.onTokenRefresh.listen((event) {
      token = event;
    });
    return token!;
  }

  Future<void> initLocalNotification() async {
    var androidIntialize = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
      android: androidIntialize,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await messages.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      sound: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('User granted provisional permission');
    } else {
      log('User declined permission');
    }
  }

  Future<void> forgroundMessage() async {
    await messages.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📬 Foreground message: ${message.messageId}');

      // Check if it's a notification message or data-only message
      if (message.notification != null) {
        log('  Has notification object');
        _showLocalNotification(message);
      } else if (message.data.isNotEmpty) {
        log('  Data-only message, checking for notification fields in data');
        // Backend sent data-only message with notification fields in data
        _showDataOnlyNotification(message);
      }
    });
  }

  Future<void> _showDataOnlyNotification(RemoteMessage message) async {
    final data = message.data;

    // Extract notification fields from data payload
    final String title = data['title'] ?? 'Notification';
    final String body = data['body'] ?? '';
    final String? imageUrl = data['image'];

    log('📱 Showing notification:');
    log('   Title: $title');
    log('   Body: $body');
    log('   Image URL: ${imageUrl ?? "none"}');

    AndroidNotificationDetails androidDetails;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      log('🖼️ Attempting to download image...');
      try {
        final String? imagePath = await _downloadAndSaveImage(imageUrl);

        if (imagePath != null) {
          log('✅ Image downloaded to: $imagePath');

          final BigPictureStyleInformation bigPictureStyle =
              BigPictureStyleInformation(
                FilePathAndroidBitmap(imagePath),
                largeIcon: FilePathAndroidBitmap(imagePath),
                contentTitle: title,
                summaryText: body,
                htmlFormatContentTitle: true,
                htmlFormatSummaryText: true,
              );

          androidDetails = AndroidNotificationDetails(
            'channel_id',
            'channel_name',
            channelDescription: 'Push notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: bigPictureStyle,
          );

          log('✅ Using BigPicture style for notification');
        } else {
          log('⚠️ Image download failed, using default style');
          androidDetails = _getDefaultAndroidDetails();
        }
      } catch (e) {
        log('❌ Error loading image: $e');
        androidDetails = _getDefaultAndroidDetails();
      }
    } else {
      log('ℹ️ No image URL provided, using default style');
      androidDetails = _getDefaultAndroidDetails();
    }

    var platformDetails = NotificationDetails(android: androidDetails);

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    log('🔔 Displaying notification with ID: $notificationId');

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
    );

    log('✅ Notification displayed');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification!;
    final data = message.data;

    // Check if there's an image URL in the notification or data payload
    String? imageUrl = notification.android?.imageUrl ?? data['image'];

    AndroidNotificationDetails androidDetails;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Download and display image with BigPicture style
      try {
        final String? imagePath = await _downloadAndSaveImage(imageUrl);

        if (imagePath != null) {
          final BigPictureStyleInformation bigPictureStyle =
              BigPictureStyleInformation(
                FilePathAndroidBitmap(imagePath),
                largeIcon: FilePathAndroidBitmap(imagePath),
                contentTitle: notification.title,
                summaryText: notification.body,
                htmlFormatContentTitle: true,
                htmlFormatSummaryText: true,
              );

          androidDetails = AndroidNotificationDetails(
            'channel_id',
            'channel_name',
            channelDescription: 'description',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: bigPictureStyle,
          );
        } else {
          // Fallback to normal notification if image download fails
          androidDetails = _getDefaultAndroidDetails();
        }
      } catch (e) {
        log('Error loading notification image: $e');
        androidDetails = _getDefaultAndroidDetails();
      }
    } else {
      // No image - use default notification style
      androidDetails = _getDefaultAndroidDetails();
    }

    var platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      notification.title,
      notification.body,
      platformDetails,
    );
  }

  AndroidNotificationDetails _getDefaultAndroidDetails() {
    return const AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'description',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
  }

  Future<String?> _downloadAndSaveImage(String url) async {
    try {
      log('📥 Downloading image from: $url');

      final http.Response response = await http
          .get(Uri.parse(url), headers: {'Accept': 'image/*'})
          .timeout(const Duration(seconds: 10));

      log('   Response status: ${response.statusCode}');
      log('   Content length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final Directory directory = await getTemporaryDirectory();
        final String filePath =
            '${directory.path}/notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        log('✅ Image saved to: $filePath');

        // Verify file exists and has size
        if (await file.exists()) {
          final fileSize = await file.length();
          log('   File size: $fileSize bytes');
          return filePath;
        } else {
          log('❌ File not found after saving');
          return null;
        }
      } else {
        log('❌ Invalid response: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('❌ Failed to download notification image: $e');
      return null;
    }
  }
}
