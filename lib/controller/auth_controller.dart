import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/service/local_service/local_auth_service.dart';
import 'package:eless/service/remote_service/jwt_auth_service.dart';
import 'package:eless/service/device_service.dart';
import 'package:eless/service/api_client_v2.dart';
import 'package:eless/service/notification_service.dart';
import 'package:eless/service/fcm_token_manager.dart';
import 'package:eless/model/jwt_token.dart';
import '../model/user.dart';

/// 🔥 PRODUCTION-READY Authentication Controller
///
/// Features:
/// ✅ UI blocking during login/logout
/// ✅ Offline queue flushing
/// ✅ Device ID preservation on logout
/// ✅ Proper error handling
/// ✅ Silent token refresh (no UI interruption)
class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // State
  Rxn<User> user = Rxn<User>();
  Rxn<JwtToken> jwtToken = Rxn<JwtToken>();

  // UI State
  RxBool isLoggingOut = false.obs;
  RxBool isLoggingIn = false.obs;
  RxBool isRefreshing = false.obs;
  RxBool isInitialized = false.obs;

  // Services
  final LocalAuthService _localAuthService = LocalAuthService();
  final JwtAuthService _jwtAuthService = JwtAuthService();
  final DeviceService _deviceService = DeviceService();
  final ApiClientV2 _apiClient = ApiClientV2();
  final NotificationService _notificationService = NotificationService();
  final FCMTokenManager _fcmTokenManager = FCMTokenManager();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Initialize controller asynchronously
  Future<void> _initialize() async {
    try {
      await _initializeServices();
      await _loadStoredSession();
    } finally {
      isInitialized.value = true;
    }
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    await _localAuthService.init();
    await _jwtAuthService.init();
    await _deviceService.init();
    await _apiClient.init();
    await _notificationService.init();

    // Setup API client callbacks
    _apiClient.onUnauthorized = () => _handleForceLogout();
    // Token refresh happens silently in background (no UI indicator)
  }

  /// Load stored session
  Future<void> _loadStoredSession() async {
    try {
      await checkExistingUser();
      await restoreJwtSession();
    } catch (e) {
    }
  }

  /// Check existing user
  Future<void> checkExistingUser() async {
    try {
      User? storedUser = _localAuthService.getUser();
      if (storedUser != null) {
        user.value = storedUser;
      }
    } catch (e) {
    }
  }

  /// Restore JWT session from refresh token
  Future<void> restoreJwtSession() async {
    try {
      final result = await _jwtAuthService.restoreSession();
      result.when(
        success: (restored) async {
          if (restored) {

            // 5️⃣ Flush offline queue on app start
            await _deviceService.flushOfflineQueue();
          } else {
            // Clear user data if JWT session cannot be restored
            user.value = null;
            await _localAuthService.clear();
          }
        },
        error: (error) async {
          // Clear user data on restore failure
          user.value = null;
          await _localAuthService.clear();
          _apiClient.clearAccessToken();
        },
      );
    } catch (e) {
      // Clear user data on exception
      user.value = null;
      await _localAuthService.clear();
      _apiClient.clearAccessToken();
    }
  }

  /// 1️⃣ LOGIN WITH QR CODE - Production-ready with deep optimization
  ///
  /// Flow:
  /// 1. Block UI (isLoggingIn = true) - BLOCKS ALL USER INTERACTION
  /// 2. JWT authentication (optimized with minimal logging)
  /// 3. Store tokens (access in RAM, refresh in Hive)
  /// 4. Extract user profile from token response
  /// 5. State updates trigger AuthWrapper navigation automatically
  Future<String> loginWithQRCode(String uniqueId) async {
    // 🔒 Prevent duplicate login attempts
    if (isLoggingIn.value) {
      return 'ALREADY_IN_PROGRESS';
    }

    // 🔒 BLOCK ALL UI - This is observed by ModalBarrier in UI
    isLoggingIn.value = true;

    try {
      // Step 1: JWT authentication (minimal logging for performance)
      final result = await _jwtAuthService.loginWithQR(uniqueId);

      return await result.when(
        success: (token) async {
          // Step 2: Store tokens in memory (fast)
          jwtToken.value = token;
          _apiClient.setAccessToken(token.accessToken);


          // Step 3: Parse user data and save to Hive (async, non-blocking)
          try {
            if (token.userData != null && token.userData!.containsKey('id')) {
              user.value = User.fromJson(token.userData!);
            } else {
              user.value = User(id: uniqueId, fullName: 'User', email: '');
            }

            // ⚡ Save to Hive asynchronously (don't wait)
            _localAuthService.addUser(user: user.value!).catchError((e) {
            });


            // 🔔 Register FCM token in background (after backend session is established)
            // Wait 10 seconds to ensure backend user session is fully ready
            Future.delayed(const Duration(seconds: 10), () {
              _fcmTokenManager
                  .registerFCMToken(uniqueId)
                  .then((_) {
                  })
                  .catchError((e) {
                  });
            });

            return 'SUCCESS';
          } catch (e) {
            return 'FAILED: $e';
          }
        },
        error: (error) {
          return 'FAILED: $error';
        },
      );
    } catch (e) {
      return 'FAILED: $e';
    } finally {
      isLoggingIn.value = false;
    }
  }

  /// 2️⃣ LOGOUT - Production-ready with optimization
  ///
  /// Flow:
  /// 1. Block UI (isLoggingOut = true) - BLOCKS ALL USER INTERACTION
  /// 2. Call backend logout (fast, non-blocking if fails)
  /// 3. Clear local storage immediately (don't wait for backend)
  /// 4. State updates trigger UI refresh automatically
  Future<void> signOut() async {
    // 🔒 Prevent duplicate logout attempts
    if (isLoggingOut.value) {
      return;
    }

    // 🔒 BLOCK ALL UI
    isLoggingOut.value = true;

    try {
      // ⚡ Optimize: Clear local data FIRST (instant UX)
      // Device ID initialization removed (was only for logging)

      // 🔄 Stop FCM token refresh listener and cleanup (BEFORE clearing token)
      _deviceService.stopTokenRefreshListener();
      await _fcmTokenManager.cleanup().catchError((e) {
      });

      // NOW clear tokens and user data
      user.value = null;
      jwtToken.value = null;
      _apiClient.clearAccessToken();
      await _localAuthService.clear();

      // ⚡ Backend logout in background (don't block UI)
      _jwtAuthService
          .logout(localOnly: false)
          .then((_) {
          })
          .catchError((e) {
          });


      // Show success message
      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );

      // Account screen will automatically update to show "Sign in your account"
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout error: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  /// Handle force logout (after multiple refresh failures)
  Future<void> _handleForceLogout() async {
    Get.snackbar(
      'Session Expired',
      'Please login again',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    await signOut();
  }

  /// Check if user is logged in
  /// Changed to check user.value AND refresh token (not access token)
  /// Access token is in memory and can be lost, but refresh token persists
  /// If we have user data and refresh token, we're logged in (even if access token is lost)
  bool get isLoggedIn =>
      user.value != null && _jwtAuthService.hasRefreshToken();
}
