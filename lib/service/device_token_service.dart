
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:eless/service/api_client.dart';
import 'package:eless/service/local_service/secure_token_storage.dart';
import 'package:uuid/uuid.dart';

/// Device Token Service - Handles FCM token registration with Django
///
/// Workflow:
/// 1. Get FCM token from Firebase
/// 2. Register with Django: POST /api/device/register/
/// 3. Store token in encrypted Hive
/// 4. Listen for token refresh and update Django
/// 5. On logout: POST /api/device/remove/ + clear Hive
///
/// Multi-device support:
/// - Each device has unique device_id (UUID)
/// - Django stores multiple tokens per user
/// - Logout removes only THIS device's token
class DeviceTokenService {
  static final DeviceTokenService _instance = DeviceTokenService._internal();
  factory DeviceTokenService() => _instance;
  DeviceTokenService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  final SecureTokenStorage _storage = SecureTokenStorage();
  final Uuid _uuid = const Uuid();

  String? _currentFcmToken;
  bool _isRegistered = false;

  /// Initialize device token service
  Future<void> init() async {
    await _storage.init();
    await _apiClient.init();
  }

  /// Get or generate device ID
  /// Device ID is persistent and unique per device installation
  Future<String> getDeviceId() async {
    String? deviceId = _storage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _storage.saveDeviceId(deviceId);
    }
    return deviceId;
  }

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

  /// Register device token with Django backend with retry + exponential backoff
  ///
  /// Endpoint: POST /api/device/register/
  /// Body: {
  ///   "user_unique_id": "abc123...",  // From QR code
  ///   "fcm_token": "fGHj...",
  ///   "device_id": "550e8400-..."
  /// }
  ///
  /// IMPORTANT: This ADDS the device token, never replaces existing ones
  /// Retry logic: 5 attempts with exponential backoff (1s, 2s, 4s, 8s, 16s)
  Future<bool> registerDeviceToken(String userUniqueId) async {
    // Get FCM token
    final fcmToken = await getFcmToken();
    if (fcmToken == null) {
      return false;
    }

    // Get or generate device ID
    final deviceId = await getDeviceId();


    // Retry with exponential backoff
    const maxAttempts = 5;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (attempt > 0) {
          final delaySeconds = 1 << (attempt - 1); // 1, 2, 4, 8, 16
          await Future.delayed(Duration(seconds: delaySeconds));
        }

        // Call Django endpoint
        final response = await _apiClient.post(
          '/api/device/register/',
          body: {
            'user_unique_id': userUniqueId,
            'fcm_token': fcmToken,
            'device_id': deviceId,
          },
          requiresAuth: true,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Success - save token locally and clear any pending
          await _storage.saveFcmToken(fcmToken);
          await _storage.deletePendingRegistration();
          _isRegistered = true;

          // Response parsed but not used
          return true;
        } else {
        }
      } catch (e) {
      }
    }

    // All attempts failed - persist for later retry
    await _storage.savePendingRegistration({
      'user_unique_id': userUniqueId,
      'fcm_token': fcmToken,
      'device_id': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return false;
  }

  /// Start listening for FCM token refresh
  /// When Firebase refreshes the token, automatically update Django
  void startTokenRefreshListener(String userUniqueId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      _currentFcmToken = newToken;

      // Update Django with new token (if user is logged in)
      if (_apiClient.hasAccessToken) {
        await registerDeviceToken(userUniqueId);
      } else {
      }
    });

  }

  /// Remove device token from Django backend
  ///
  /// Endpoint: POST /api/device/remove/
  /// Body: {
  ///   "fcm_token": "fGHj...",
  ///   "device_id": "550e8400-..."
  /// }
  ///
  /// Only removes THIS device's token, other devices remain active
  Future<bool> removeDeviceToken() async {
    try {
      final fcmToken = _storage.getFcmToken();
      final deviceId = _storage.getDeviceId();

      if (fcmToken == null || deviceId == null) {
        return true;
      }


      // Call Django endpoint
      final response = await _apiClient.post(
        '/api/device/remove/',
        body: {'fcm_token': fcmToken, 'device_id': deviceId},
        requiresAuth: true, // Requires JWT access token
      );

      if (response.statusCode == 200 || response.statusCode == 204) {

        // Clear local storage
        await _storage.deleteFcmToken();
        _currentFcmToken = null;
        _isRegistered = false;

        return true;
      } else {

        // Still clear locally even if backend fails
        await _storage.deleteFcmToken();
        _currentFcmToken = null;
        _isRegistered = false;

        return false;
      }
    } catch (e) {

      // Always clear locally
      await _storage.deleteFcmToken();
      _currentFcmToken = null;
      _isRegistered = false;

      return false;
    }
  }

  /// Flush pending registrations (call on app start)
  Future<void> flushPendingRegistrations() async {
    final pending = _storage.getPendingRegistration();
    if (pending == null || pending.isEmpty) {
      return;
    }

    final userUniqueId = pending['user_unique_id'] as String?;
    if (userUniqueId != null && _apiClient.hasAccessToken) {
      final success = await registerDeviceToken(userUniqueId);
      if (success) {
      }
    } else {
    }
  }

  /// Check if device token is registered
  bool get isRegistered => _isRegistered;

  /// Get current FCM token (from memory)
  String? get currentToken => _currentFcmToken;

  /// Clean up (called on logout)
  Future<void> cleanup() async {
    await removeDeviceToken();
    await _storage.deletePendingRegistration();
  }
}
