import 'package:hive/hive.dart';
import '../../model/device.dart';
import 'dart:developer';

class LocalDeviceService {
  late Box<Device> _deviceBox;
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      _deviceBox = await Hive.openBox<Device>('Devices');
      _isInitialized = true;
      log('✅ LocalDeviceService initialized');
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
      await _deviceBox.addAll(devices);
    } catch (e) {
      log('❌ Error saving devices: $e');
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
