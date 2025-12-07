import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:eless/model/jwt_token.dart';
import 'package:eless/service/api_client.dart';
import 'package:eless/service/local_service/secure_token_storage.dart';
import 'package:uuid/uuid.dart';

/// JWT Authentication Service
/// Handles QR-based login, token management, and logout
class JwtAuthService {
  final ApiClient _apiClient = ApiClient();
  final SecureTokenStorage _storage = SecureTokenStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  /// Initialize the service
  Future<void> init() async {
    await _apiClient.init();
    await _storage.init();
  }

  /// Login with QR code unique_id
  /// QR code contains only a plain string unique_id (NOT the JWT)
  ///
  /// Flow:
  /// 1. Scan QR → Get unique_id
  /// 2. POST to /api/auth/qr-login/ with {unique_id}
  /// 3. Backend validates and returns {access, refresh, expires_in}
  /// 4. Store tokens securely
  Future<ApiResult<JwtToken>> loginWithQR(String uniqueId) async {
    try {

      // Get or generate device ID for binding
      String deviceId = _storage.getDeviceId() ?? _uuid.v4();
      await _storage.saveDeviceId(deviceId);

      // Validate UUID format
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      if (!uuidRegex.hasMatch(deviceId)) {
        // Generate new valid UUID and save it
        deviceId = _uuid.v4();
        await _storage.saveDeviceId(deviceId);
      } else {
      }

      // Get platform and device name
      String platform = Platform.operatingSystem.toLowerCase();
      String deviceName = 'Unknown Device';

      try {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          platform = 'android';
          deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          platform = 'ios';
          deviceName = '${iosInfo.name} ${iosInfo.model}';
        }
      } catch (e) {
      }


      // Prepare request body
      final requestBody = {
        'user_id': uniqueId,
        'device_id': deviceId,
        'platform': platform,
        'device_name': deviceName,
      };


      // Send POST request to Django backend
      final response = await _apiClient.post(
        '/api/auth/qr-login/',
        body: requestBody,
        requiresAuth: false, // Login doesn't require auth
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);


        final token = JwtToken.fromJson(data);

        // Store access token in memory (ApiClient)
        _apiClient.setAccessToken(token.accessToken);

        // Store refresh token in encrypted Hive
        await _storage.saveRefreshToken(token.refreshToken);


        return ApiResult.success(token);
      } else {
        final error = _parseError(response);
        return ApiResult.error(error, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResult.error('Network error: ${e.toString()}');
    }
  }

  /// Refresh access token using refresh token
  /// This is called automatically by ApiClient when 401 is received
  Future<ApiResult<String>> refreshAccessToken() async {
    try {
      final refreshToken = _storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return ApiResult.error('No refresh token available');
      }


      final response = await _apiClient.post(
        '/api/auth/token/refresh/',
        body: {'refresh': refreshToken},
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];

        _apiClient.setAccessToken(newAccessToken);

        return ApiResult.success(newAccessToken);
      } else {

        // Clear tokens if refresh failed (likely expired/invalid)
        if (response.statusCode == 401) {
          await logout(localOnly: true);
        }

        return ApiResult.error(
          _parseError(response),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResult.error('Network error: ${e.toString()}');
    }
  }

  /// Logout user
  /// - Sends refresh token AND device_id to backend for device unregistration
  /// - Backend blacklists token and removes device registration
  /// - Clears all local tokens (even if network fails)
  /// - Idempotent: safe to call multiple times
  Future<ApiResult<void>> logout({bool localOnly = false}) async {
    try {
      if (!localOnly) {
        final refreshToken = _storage.getRefreshToken();
        final deviceId = _storage.getDeviceId();

        if (refreshToken != null && refreshToken.isNotEmpty) {

          try {
            // Send both refresh token and device_id to backend
            // This allows backend to:
            // 1. Blacklist the refresh token
            // 2. Unregister the device (stop push notifications)
            // 3. Update active device count
            //
            // NOTE: requiresAuth = false because:
            // - Access token might be expired (that's why user is logging out)
            // - Refresh token in body is sufficient for backend authentication
            final response = await _apiClient.post(
              '/api/auth/logout/',
              body: {'refresh': refreshToken, 'device_id': deviceId},
              requiresAuth:
                  false, // Don't send access token - refresh token is enough
            );

            if (response.statusCode == 200) {
            } else {
              // Continue with local logout anyway
            }
          } catch (e) {
            // Continue with local logout anyway
          }
        } else {
        }
      } else {
      }

      // Always clear local storage (even if backend request failed)
      await _storage.clearAll();
      _apiClient.clearAccessToken();

      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.error('Logout error: ${e.toString()}');
    }
  }

  /// Check if user is authenticated
  /// Has both access token (in memory) and refresh token (in storage)
  bool isAuthenticated() {
    return _apiClient.hasAccessToken && _storage.hasRefreshToken();
  }

  /// Check if refresh token exists (more reliable than isAuthenticated)
  /// This persists even if access token is lost from memory
  bool hasRefreshToken() {
    return _storage.hasRefreshToken();
  }

  /// Get current access token (from memory)
  String? get accessToken => _apiClient.accessToken;

  /// Restore session from stored refresh token
  /// Call this on app startup to restore authentication state
  Future<ApiResult<bool>> restoreSession() async {
    try {
      final refreshToken = _storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return ApiResult.success(false);
      }


      // Try to get new access token
      final result = await refreshAccessToken();

      return result.when(
        success: (_) {
          return ApiResult.success(true);
        },
        error: (error) async {
          // Clear invalid tokens
          await _storage.clearAll();
          return ApiResult.success(false);
        },
      );
    } catch (e) {
      return ApiResult.success(false);
    }
  }

  /// Parse error message from response
  String _parseError(dynamic response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('error')) {
        return body['error'];
      }
      if (body is Map && body.containsKey('detail')) {
        return body['detail'];
      }
      return 'Request failed with status ${response.statusCode}';
    } catch (e) {
      return 'Request failed with status ${response.statusCode}';
    }
  }
}
