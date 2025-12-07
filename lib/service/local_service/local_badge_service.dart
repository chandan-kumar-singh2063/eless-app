import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Service to track which events and devices user has viewed
/// Used to hide "new" badges after first view
class LocalBadgeService extends GetxService {
  static const String _viewedEventsKey = 'viewed_events';
  static const String _viewedDevicesKey = 'viewed_devices';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox('badge_storage');
  }

  // ============ EVENTS ============

  /// Mark event as viewed by user
  void markEventAsViewed(int eventId) {
    if (_box == null) return;

    List<int> viewedEvents = getViewedEvents();
    if (!viewedEvents.contains(eventId)) {
      viewedEvents.add(eventId);
      _box!.put(_viewedEventsKey, viewedEvents);
    }
  }

  /// Check if user has viewed this event
  bool isEventViewed(int eventId) {
    return getViewedEvents().contains(eventId);
  }

  /// Get list of all viewed event IDs
  List<int> getViewedEvents() {
    if (_box == null) return [];

    var stored = _box!.get(_viewedEventsKey);
    if (stored == null) return [];

    // Convert to List<int>
    return (stored as List).cast<int>();
  }

  /// Clear all viewed events (for testing/reset)
  void clearViewedEvents() {
    _box?.delete(_viewedEventsKey);
  }

  // ============ DEVICES ============

  /// Mark device as viewed by user
  void markDeviceAsViewed(String deviceId) {
    if (_box == null) return;

    List<String> viewedDevices = getViewedDevices();
    if (!viewedDevices.contains(deviceId)) {
      viewedDevices.add(deviceId);
      _box!.put(_viewedDevicesKey, viewedDevices);
    }
  }

  /// Check if user has viewed this device
  bool isDeviceViewed(String deviceId) {
    return getViewedDevices().contains(deviceId);
  }

  /// Get list of all viewed device IDs
  List<String> getViewedDevices() {
    if (_box == null) return [];

    var stored = _box!.get(_viewedDevicesKey);
    if (stored == null) return [];

    // Convert to List<String>
    return (stored as List).cast<String>();
  }

  /// Clear all viewed devices (for testing/reset)
  void clearViewedDevices() {
    _box?.delete(_viewedDevicesKey);
  }

  /// Clear all badge data
  void clearAll() {
    clearViewedEvents();
    clearViewedDevices();
  }
}
