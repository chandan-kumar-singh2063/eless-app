import 'package:hive/hive.dart';
import '../../model/device.dart';

class LocalDeviceService {
  late Box<Device> _deviceBox;

  Future<void> init() async {
    try {
      _deviceBox = await Hive.openBox<Device>('Devices');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignAllDevices({required List<Device> devices}) async {
    await _deviceBox.clear();
    // ⚡ Cache limit: Keep only latest 100 devices to prevent Hive bloat
    final limitedDevices = devices.take(100).toList();
    await _deviceBox.addAll(limitedDevices);
  }

  List<Device> getDevices() => _deviceBox.values.toList();

  Future<void> clearDevices() async {
    await _deviceBox.clear();
  }
}
