import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:eless/controller/event_controller.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/controller/devices_controller.dart';

/// ⚡ Connectivity Service - Auto-refresh when internet comes back
///
/// Monitors network state and triggers data refresh when:
/// - User goes offline → online
/// - WiFi switches to mobile data (or vice versa)
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;

  /// Initialize connectivity monitoring
  Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _wasOffline = result.contains(ConnectivityResult.none);

    if (_wasOffline) {
      log('📡 Initial state: OFFLINE');
    } else {
      log('📡 Initial state: ONLINE (${result.join(", ")})');
    }

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    log('✅ Connectivity monitoring started');
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOffline = results.contains(ConnectivityResult.none);

    if (_wasOffline && !isOffline) {
      // Just came back online!
      log('🌐 CONNECTION RESTORED - Auto-refreshing data...');
      _refreshDataAfterReconnect();
    } else if (!_wasOffline && isOffline) {
      log('❌ CONNECTION LOST');
    } else if (!isOffline) {
      log('📡 Network changed: ${results.join(", ")}');
    }

    _wasOffline = isOffline;
  }

  /// Refresh critical data when connection is restored
  void _refreshDataAfterReconnect() {
    // Only refresh if controllers are already initialized (user is active)

    // Refresh events if controller exists
    if (Get.isRegistered<EventController>()) {
      try {
        final eventController = Get.find<EventController>();
        log('  ↻ Refreshing events...');
        eventController.getAllEventsFirstPage().catchError((e) {
          log('  ⚠️ Event refresh failed: $e');
        });
      } catch (e) {
        log('  ⚠️ EventController not ready: $e');
      }
    }

    // Refresh notifications if controller exists
    if (Get.isRegistered<NotificationController>()) {
      try {
        final notificationController = Get.find<NotificationController>();
        log('  ↻ Refreshing notifications...');
        notificationController.getNotificationsFirstPage().catchError((e) {
          log('  ⚠️ Notification refresh failed: $e');
        });
      } catch (e) {
        log('  ⚠️ NotificationController not ready: $e');
      }
    }

    // Refresh devices if controller exists
    if (Get.isRegistered<DevicesController>()) {
      try {
        final devicesController = Get.find<DevicesController>();
        log('  ↻ Refreshing devices...');
        devicesController.getDevices().catchError((e) {
          log('  ⚠️ Device refresh failed: $e');
        });
      } catch (e) {
        log('  ⚠️ DevicesController not ready: $e');
      }
    }

    log('✅ Auto-refresh complete');
  }

  /// Check if currently online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    log('🛑 Connectivity monitoring stopped');
  }
}
