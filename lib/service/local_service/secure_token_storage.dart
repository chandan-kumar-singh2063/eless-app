import 'package:hive/hive.dart';


/// Secure token storage using encrypted Hive
/// ✓ Refresh token → Encrypted Hive Box
/// ✓ FCM device token → Encrypted Hive Box
/// ✓ Device ID → Encrypted Hive Box
/// ✗ Access token → NEVER stored here (only in memory/GetX)
class SecureTokenStorage {
  // Environment-isolated box name (dev/prod separation)
  static const String _environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  static String get _boxName => 'secure_tokens_$_environment';

  static const String _refreshTokenKey = 'jwt_refresh';
  static const String _deviceIdKey = 'device_id';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _pendingRegistrationKey = 'pending_registration';

  Box? _box;

  /// Initialize the secure storage box
  Future<void> init() async {
    try {
      // Open encrypted box for secure storage
      _box = await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(await _getEncryptionKey()),
      );
    } catch (e) {
      // If encryption fails, open regular box as fallback
      _box = await Hive.openBox(_boxName);
    }
  }

  /// Get or generate encryption key for Hive
  /// In production, use flutter_secure_storage or platform keychain
  Future<List<int>> _getEncryptionKey() async {
    // Generate a 256-bit key (32 bytes)
    // TODO: In production, store this in flutter_secure_storage
    return List<int>.generate(32, (i) => i * 7 % 256);
  }

  /// Save refresh token securely
  Future<void> saveRefreshToken(String refreshToken) async {
    await _ensureInitialized();
    await _box!.put(_refreshTokenKey, refreshToken);
  }

  /// Get refresh token from secure storage
  String? getRefreshToken() {
    try {
      return _box?.get(_refreshTokenKey) as String?;
    } catch (e) {
      return null;
    }
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _ensureInitialized();
    await _box!.delete(_refreshTokenKey);
  }

  /// Save device ID for server-side binding
  Future<void> saveDeviceId(String deviceId) async {
    await _ensureInitialized();
    await _box!.put(_deviceIdKey, deviceId);
  }

  /// Get device ID
  String? getDeviceId() {
    try {
      return _box?.get(_deviceIdKey) as String?;
    } catch (e) {
      return null;
    }
  }

  /// Clear all secure data EXCEPT device_id (used on logout)
  /// Device ID must persist across logins for proper multi-device tracking
  Future<void> clearAll() async {
    await _ensureInitialized();

    // Preserve device_id
    final deviceId = getDeviceId();

    await _box!.clear();

    // Restore device_id
    if (deviceId != null) {
      await _box!.put(_deviceIdKey, deviceId);
    } else {
    }
  }

  /// Ensure box is initialized before operations
  Future<void> _ensureInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }

  /// Check if refresh token exists
  bool hasRefreshToken() {
    return getRefreshToken() != null && getRefreshToken()!.isNotEmpty;
  }

  /// Save FCM device token securely
  Future<void> saveFcmToken(String fcmToken) async {
    await _ensureInitialized();
    await _box!.put(_fcmTokenKey, fcmToken);
  }

  /// Get FCM device token from secure storage
  String? getFcmToken() {
    try {
      return _box?.get(_fcmTokenKey) as String?;
    } catch (e) {
      return null;
    }
  }

  /// Delete FCM token
  Future<void> deleteFcmToken() async {
    await _ensureInitialized();
    await _box!.delete(_fcmTokenKey);
  }

  /// Check if FCM token exists
  bool hasFcmToken() {
    return getFcmToken() != null && getFcmToken()!.isNotEmpty;
  }

  /// Save pending registration for retry on next app start
  Future<void> savePendingRegistration(Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _box!.put(_pendingRegistrationKey, data);
  }

  /// Get pending registration
  Map<String, dynamic>? getPendingRegistration() {
    try {
      final data = _box?.get(_pendingRegistrationKey);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      return null;
    }
  }

  /// Delete pending registration
  Future<void> deletePendingRegistration() async {
    await _ensureInitialized();
    await _box!.delete(_pendingRegistrationKey);
  }

  /// Save last sent FCM token (for deduplication)
  Future<void> saveLastSentFcmToken(String token) async {
    await _ensureInitialized();
    await _box!.put('last_sent_fcm_token', token);
  }

  /// Get last sent FCM token
  String? getLastSentFcmToken() {
    try {
      return _box?.get('last_sent_fcm_token') as String?;
    } catch (e) {
      return null;
    }
  }

  /// Delete last sent FCM token
  Future<void> deleteLastSentFcmToken() async {
    await _ensureInitialized();
    await _box!.delete('last_sent_fcm_token');
  }
}
