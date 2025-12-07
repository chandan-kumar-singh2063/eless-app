import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:eless/service/api_client_v2.dart';
import 'package:eless/service/local_service/secure_token_storage.dart';
import 'package:uuid/uuid.dart';

/// 🔥 FCM Token Manager - Separate from authentication
///
/// Workflow:
/// 1. Get FCM token from Firebase (with retry)
/// 2. ONLY AFTER token is obtained → Send to Django backend
/// 3. Listen for token refresh and auto-update
/// 4. No snackbars, no UI interruption - completely silent
///
/// NEW ENDPOINT: POST /api/notifications/register-fcm-token/
/// Body: {
///   "user_unique_id": "ROBO-2024-002",
///   "fcm_token": "fPida7AG...",
///   "device_id": "772dd712-...",
///   "platform": "android",
///   "device_model": "V2055",
///   "device_manufacturer": "vivo"
/// }
class FCMTokenManager {
  static final FCMTokenManager _instance = FCMTokenManager._internal();
  factory FCMTokenManager() => _instance;
  FCMTokenManager._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClientV2 _apiClient = ApiClientV2();
  final SecureTokenStorage _storage = SecureTokenStorage();
  final Uuid _uuid = const Uuid();

  StreamSubscription? _tokenRefreshSubscription;

  /// Initialize FCM token manager
  Future<void> init() async {
    await _storage.init();
  }

  /// Get or create device ID (persistent across app reinstalls if possible)
  Future<String> getOrCreateDeviceId() async {
    String? deviceId = _storage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _storage.saveDeviceId(deviceId);
    }
    return deviceId;
  }

  /// Get FCM token from Firebase (with retry logic)
  /// Returns token only when successfully obtained
  Future<String?> getFCMTokenFromFirebase() async {
    const maxAttempts = 3;

    // Check notification permissions first
    try {
      final settings = await _messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        final newSettings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (newSettings.authorizationStatus == AuthorizationStatus.denied) {
          return null;
        }
      }
    } catch (e) {}

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (attempt > 0) {
          await Future.delayed(Duration(seconds: attempt)); // 1s, 2s
        }

        final token = await _messaging.getToken();

        if (token != null && token.isNotEmpty) {
          await _storage.saveFcmToken(token);
          return token;
        } else {}
      } catch (e) {}
    }

    return null;
  }

  /// Send FCM token to Django backend
  /// ONLY call this AFTER token is successfully obtained from Firebase
  Future<bool> sendTokenToBackend(String userUniqueId) async {
    try {
      // Get stored FCM token
      final fcmToken = _storage.getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return false;
      }

      // Get device ID
      final deviceId = await getOrCreateDeviceId();

      // Check if ApiClient has access token
      if (!_apiClient.hasAccessToken) {
        return false;
      }

      // Call Django endpoint (NEW ENDPOINT)
      final response = await _apiClient.post(
        '/api/notifications/register-fcm-token/',
        body: {
          'user_unique_id': userUniqueId,
          'fcm_token': fcmToken,
          'device_id': deviceId,
          'platform': 'android', // or detect dynamically
          'device_model': 'unknown', // can add device info later
          'device_manufacturer': 'unknown',
        },
        requiresAuth: true,
        skipAutoLogout: true, // Don't logout if this fails
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Response parsed but not used
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Complete FCM token registration flow
  /// 1. Get token from Firebase (with retry)
  /// 2. Send to Django backend (only if token obtained)
  /// 3. Start refresh listener
  Future<void> registerFCMToken(String userUniqueId) async {
    try {
      // Step 1: Get token from Firebase
      final fcmToken = await getFCMTokenFromFirebase();

      if (fcmToken == null) {
        return;
      }

      // Step 2: Send to backend (with retry logic)

      // Try up to 3 times with increasing delays
      bool success = false;
      for (int attempt = 0; attempt < 3; attempt++) {
        if (attempt > 0) {
          final delaySeconds = 5 * attempt; // 5s, 10s
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          // First attempt - wait 5 seconds
          await Future.delayed(const Duration(seconds: 5));
        }

        success = await sendTokenToBackend(userUniqueId);

        if (success) {
          break;
        } else {
          if (attempt == 2) {}
        }
      }

      // Step 3: Start listening for token refresh
      startTokenRefreshListener(userUniqueId);
    } catch (e) {}
  }

  /// Start listening for FCM token refresh
  /// When Firebase refreshes the token, automatically update Django
  void startTokenRefreshListener(String userUniqueId) {
    // Cancel existing listener if any
    _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
      newToken,
    ) async {
      await _storage.saveFcmToken(newToken);

      // Update backend with new token (if authenticated)
      if (_apiClient.hasAccessToken) {
        await sendTokenToBackend(userUniqueId);
      } else {}
    });
  }

  /// Stop token refresh listener (call on logout)
  void stopTokenRefreshListener() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  /// Remove FCM token from backend (on logout)
  Future<void> removeTokenFromBackend() async {
    try {
      final fcmToken = _storage.getFcmToken();
      final deviceId = _storage.getDeviceId();

      if (fcmToken == null || deviceId == null) {
        return;
      }

      final response = await _apiClient.post(
        '/api/notifications/unregister-fcm-token/',
        body: {'fcm_token': fcmToken, 'device_id': deviceId},
        requiresAuth: true,
        skipAutoLogout: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
      } else {}
    } finally {
      // Always clear locally
      await _storage.deleteFcmToken();
    }
  }

  /// Cleanup on logout
  Future<void> cleanup() async {
    stopTokenRefreshListener();
    await removeTokenFromBackend();
  }
}
