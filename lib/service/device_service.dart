import 'dart:async';

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:eless/service/api_client_v2.dart';
import 'package:eless/service/local_service/secure_token_storage.dart';
import 'package:uuid/uuid.dart';

/// 🔥 PRODUCTION-READY Device Service
///
/// Features:
/// ✅ Rock-solid device_id lifecycle (generate once, never regenerate)
/// ✅ Device fingerprinting (model, OS version, platform)
/// ✅ FCM token registration with retry + exponential backoff
/// ✅ Offline queue for pending updates
/// ✅ Deduplication (last_sent_token tracking)
/// ✅ Handles app restart, token refresh, reinstall scenarios
class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClientV2 _apiClient = ApiClientV2();
  final SecureTokenStorage _storage = SecureTokenStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  String? _currentFcmToken;
  String? _lastSentToken;
  bool _isRegistered = false;
  DateTime? _lastRegistrationTime;
  StreamSubscription? _tokenRefreshSubscription;

  // Prevent duplicate registrations within 5 minutes
  static const Duration _registrationCooldown = Duration(minutes: 5);

  /// Initialize device service
  Future<void> init() async {
    await _storage.init();
    _lastSentToken = _storage.getLastSentFcmToken();
  }

  /// 1️⃣ DEVICE ID LIFECYCLE - Rock-solid implementation

  /// Get or generate device ID (generated once, never regenerated)
  /// Stored in encrypted Hive/SecureStorage
  /// Only regenerated on app reinstall (when Hive is cleared)
  Future<String> getOrCreateDeviceId() async {
    String? deviceId = _storage.getDeviceId();

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _storage.saveDeviceId(deviceId);
    } else {
    }

    return deviceId;
  }

  /// Get device fingerprint (model, OS version, platform)
  Future<Map<String, String>> getDeviceFingerprint() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'os_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt.toString(),
          'brand': androidInfo.brand,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'os_version': iosInfo.systemVersion,
          'is_physical': iosInfo.isPhysicalDevice.toString(),
        };
      }
    } catch (e) {
    }

    return {
      'platform': Platform.operatingSystem,
      'model': 'unknown',
      'os_version': 'unknown',
    };
  }

  /// 2️⃣ FCM TOKEN REGISTRATION FLOW - Production-ready

  /// Get FCM token from Firebase
  Future<String?> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentFcmToken = token;
      } else {
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Register device token with Django (with retry + exponential backoff)
  ///
  /// Called on:
  /// - Login
  /// - App start (if user logged in)
  /// - Token refresh
  ///
  /// Features:
  /// - Fast retries: 0.5s, 1s (max 1.5s total for 3 attempts)
  /// - Offline queue (persists to Hive if all retries fail)
  /// - Deduplication (skips if token unchanged within 5min cooldown)
  Future<bool> registerDeviceToken(String userUniqueId) async {
    try {
      // Get FCM token
      final fcmToken = await getFcmToken();
      if (fcmToken == null) {
        return false;
      }

      // Check if token already sent (deduplication)
      if (_lastSentToken == fcmToken && _isRegistered) {
        // Additional time-based check to prevent spam
        if (_lastRegistrationTime != null) {
          final timeSinceLastReg = DateTime.now().difference(
            _lastRegistrationTime!,
          );
          if (timeSinceLastReg < _registrationCooldown) {
            return true;
          }
        }
      }

      // Get or create device ID (persistent)
      final deviceId = await getOrCreateDeviceId();

      // Get device fingerprint
      final fingerprint = await getDeviceFingerprint();


      // Retry with exponential backoff (reduced from 5 to 3 attempts)
      const maxAttempts = 3;
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        if (attempt > 0) {
          final delayMs = [500, 1000][attempt - 1]; // 0.5s, 1s (max 1.5s total)
          await Future.delayed(Duration(milliseconds: delayMs));
        }

        try {
          final response = await _apiClient.post(
            '/api/auth/register-device/',
            body: {
              'unique_id': userUniqueId,
              'fcm_token': fcmToken,
              'device_id': deviceId,
              'platform': fingerprint['platform'],
              'device_model': fingerprint['model'],
              'device_manufacturer':
                  fingerprint['manufacturer'] ?? fingerprint['brand'],
              'os_version': fingerprint['os_version'],
            },
            requiresAuth: true,
            skipAutoLogout: true, // Don't logout on 401 - this is non-critical
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Success - update state
            await _storage.saveFcmToken(fcmToken);
            await _storage.saveLastSentFcmToken(fcmToken);
            await _storage.deletePendingRegistration();

            _lastSentToken = fcmToken;
            _isRegistered = true;
            _lastRegistrationTime = DateTime.now();

            // Response parsed but not used
            return true;
          } else if (response.statusCode == 401) {
            // 401 Unauthorized - token not ready yet or expired
            // This is NON-CRITICAL, don't trigger logout
            // Continue to next retry
          } else {
          }
        } catch (e) {
          // Catch and ignore "Unauthorized" exceptions from token refresh
          if (e.toString().contains('Unauthorized')) {
            // Continue to next retry
          } else {
          }
        }
      }

      // All attempts failed - add to offline queue
      await _addToOfflineQueue(userUniqueId, fcmToken, deviceId, fingerprint);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Add failed registration to offline queue (persists to Hive)
  Future<void> _addToOfflineQueue(
    String userUniqueId,
    String fcmToken,
    String deviceId,
    Map<String, String> fingerprint,
  ) async {
    await _storage.savePendingRegistration({
      'user_unique_id': userUniqueId,
      'fcm_token': fcmToken,
      'device_id': deviceId,
      'device_info': fingerprint,
      'timestamp': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  /// Flush offline queue (process pending registrations)
  /// Called on:
  /// - App start (if network available)
  /// - Network connectivity restored
  /// - After successful login
  Future<void> flushOfflineQueue() async {
    final pending = _storage.getPendingRegistration();
    if (pending == null || pending.isEmpty) {
      return;
    }

    final retryCount = pending['retry_count'] as int? ?? 0;
    if (retryCount >= 10) {
      await _storage.deletePendingRegistration();
      return;
    }


    final userUniqueId = pending['user_unique_id'] as String?;
    if (userUniqueId != null && _apiClient.accessToken != null) {
      // Update retry count
      pending['retry_count'] = retryCount + 1;
      await _storage.savePendingRegistration(pending);

      final success = await registerDeviceToken(userUniqueId);
      if (success) {
      } else {
      }
    } else {
    }
  }

  /// Start FCM token refresh listener
  /// Automatically updates Django when Firebase rotates the token
  void startTokenRefreshListener(String userUniqueId) {
    _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
      newToken,
    ) async {
      _currentFcmToken = newToken;

      if (_apiClient.accessToken != null) {
        await registerDeviceToken(userUniqueId);
      } else {
      }
    });

  }

  /// Stop token refresh listener
  void stopTokenRefreshListener() {
    if (_tokenRefreshSubscription != null) {
      _tokenRefreshSubscription!.cancel();
      _tokenRefreshSubscription = null;
    } else {
    }
  }

  /// Remove device token from Django
  /// Only removes THIS device (uses device_id as key)
  Future<bool> removeDeviceToken() async {
    try {
      final fcmToken = _storage.getFcmToken();
      final deviceId = _storage.getDeviceId();

      if (fcmToken == null || deviceId == null) {
        return true;
      }


      final response = await _apiClient.post(
        '/api/auth/unregister-device/',
        body: {'fcm_token': fcmToken, 'device_id': deviceId},
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _clearLocalTokenData();
        return true;
      } else {
        await _clearLocalTokenData(); // Clear locally anyway
        return false;
      }
    } catch (e) {
      await _clearLocalTokenData(); // Always clear locally
      return false;
    }
  }

  /// Clear local token data
  Future<void> _clearLocalTokenData() async {
    await _storage.deleteFcmToken();
    await _storage.deleteLastSentFcmToken();
    _currentFcmToken = null;
    _lastSentToken = null;
    _isRegistered = false;
    _lastRegistrationTime = null;
  }

  /// Clean up (called on logout)
  Future<void> cleanup() async {
    stopTokenRefreshListener();
    await removeDeviceToken();
    await _storage.deletePendingRegistration();
  }

  /// Check if device is registered
  bool get isRegistered => _isRegistered;

  /// Get current FCM token
  String? get currentToken => _currentFcmToken;
}
