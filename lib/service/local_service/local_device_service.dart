import 'package:hive/hive.dart';
import '../../model/device.dart';
import 'dart:developer';

class LocalDeviceService {
  late Box<Device> _deviceBox;
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      // ⚡ Use already-opened box from AppInitializer (don't open again)
      _deviceBox = Hive.box<Device>('Devices');
      _isInitialized = true;
      log('✅ LocalDeviceService initialized (using pre-opened box)');
    } catch (e) {
      log('❌ Error init LocalDeviceService: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> assignAllDevices({required List<Device> devices}) async {
    if (!_isInitialized) {
      log('⚠️ Skipping device save to Hive (not initialized)');
      return;
    }
    try {
      await _deviceBox.clear();
      // ⚡ Cache limit: Keep only latest 100 devices to prevent Hive bloat
      final limitedDevices = devices.take(100).toList();
      await _deviceBox.addAll(limitedDevices);
    } catch (e) {
      log('❌ Error saving devices: $e');
    }
  }

  Future<void> appendDevices({required List<Device> devices}) async {
    if (!_isInitialized) {
      log('⚠️ Skipping device append to Hive (not initialized)');
      return;
    }
    try {
      // Append new devices without clearing existing ones
      await _deviceBox.addAll(devices);
    } catch (e) {
      log('❌ Error appending devices: $e');
    }
  }

  List<Device> getDevices() {
    if (!_isInitialized) return [];
    try {
      return _deviceBox.values.toList();
    } catch (e) {
      log('❌ Error getting devices: $e');
      return [];
    }
  }

  Future<void> clearDevices() async {
    if (!_isInitialized) return;
    try {
      await _deviceBox.clear();
    } catch (e) {
      log('❌ Error clearing devices: $e');
    }
  }
}
