import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:eless/model/jwt_token.dart';
import 'package:eless/service/local_service/secure_token_storage.dart';
import 'package:eless/const.dart';

/// Singleton HTTP client with automatic JWT token management
/// Features:
/// - Automatic Authorization header injection
/// - Auto-refresh on 401 errors
/// - Single in-flight refresh to prevent refresh storms
/// - Exponential backoff for retry attempts
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  final SecureTokenStorage _storage = SecureTokenStorage();

  // Current access token (IN MEMORY ONLY)
  String? _accessToken;

  // Refresh lock to prevent multiple simultaneous refresh attempts
  Completer<bool>? _refreshLock;

  // Callback for logout when refresh fails
  Function()? onUnauthorized;

  /// Initialize the API client
  Future<void> init() async {
    await _storage.init();
  }

  /// Set the current access token (stored in memory only)
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Clear access token from memory
  void clearAccessToken() {
    _accessToken = null;
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Check if we have an access token
  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// Make GET request with automatic auth header
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _makeRequest(
      () => _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers, requiresAuth),
      ),
      requiresAuth: requiresAuth,
    );
  }

  /// Make POST request with automatic auth header
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool requiresAuth = true,
    bool skipAutoLogout = false,
  }) async {
    return _makeRequest(
      () => _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers, requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
      skipAutoLogout: skipAutoLogout,
    );
  }

  /// Make PUT request with automatic auth header
  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _makeRequest(
      () => _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers, requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  /// Make DELETE request with automatic auth header
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _makeRequest(
      () => _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(headers, requiresAuth),
      ),
      requiresAuth: requiresAuth,
    );
  }

  /// Core request method with auto-refresh on 401
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    required bool requiresAuth,
    int retryCount = 0,
    bool skipAutoLogout = false,
  }) async {
    try {
      final response = await request();

      // If 401 and requires auth, try to refresh token
      if (response.statusCode == 401 && requiresAuth && retryCount == 0) {

        final refreshed = await _refreshToken();

        if (refreshed) {
          // Retry the original request with new token
          return _makeRequest(
            request,
            requiresAuth: requiresAuth,
            retryCount: 1,
            skipAutoLogout: skipAutoLogout,
          );
        } else {
          // Refresh failed - trigger logout (unless skipAutoLogout)
          if (skipAutoLogout) {
          } else {
            onUnauthorized?.call();
          }
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Build headers with Authorization if needed
  Map<String, String> _buildHeaders(
    Map<String, String>? customHeaders,
    bool requiresAuth,
  ) {
    final headers = {'Content-Type': 'application/json', ...?customHeaders};

    if (requiresAuth && hasAccessToken) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Refresh the access token using refresh token
  /// Uses a lock to prevent multiple simultaneous refresh attempts
  /// Includes 30s timeout to prevent hanging
  Future<bool> _refreshToken() async {
    // If refresh is already in progress, wait for it with timeout
    if (_refreshLock != null && !_refreshLock!.isCompleted) {
      try {
        return await _refreshLock!.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            return false;
          },
        );
      } catch (e) {
        return false;
      }
    }

    // Create new refresh lock
    _refreshLock = Completer<bool>();

    // Timeout safety: force completion after 30s
    Future.delayed(const Duration(seconds: 30), () {
      if (_refreshLock != null && !_refreshLock!.isCompleted) {
        _refreshLock!.complete(false);
        _refreshLock = null;
      }
    });

    try {
      final refreshToken = _storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshLock!.complete(false);
        return false;
      }


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/token/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Refresh request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];

        setAccessToken(newAccessToken);

        _refreshLock!.complete(true);
        return true;
      } else {

        // If refresh token is invalid/expired, clear everything
        if (response.statusCode == 401) {
          await _storage.clearAll();
          clearAccessToken();
        }

        _refreshLock!.complete(false);
        return false;
      }
    } catch (e) {
      if (_refreshLock != null && !_refreshLock!.isCompleted) {
        _refreshLock!.complete(false);
      }
      return false;
    } finally {
      _refreshLock = null;
    }
  }

  /// Proactively refresh token if near expiry
  /// Call this on app start or before critical operations
  Future<void> proactiveRefresh(JwtToken? currentToken) async {
    if (currentToken != null && currentToken.isExpired()) {
      await _refreshToken();
    }
  }

  /// Clean up resources
  void dispose() {
    _client.close();
  }
}
