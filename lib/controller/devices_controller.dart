import 'package:get/get.dart';
import 'package:eless/model/device.dart';
import 'package:eless/service/local_service/local_device_service.dart';
import 'package:eless/service/remote_service/remote_device_service.dart';

class DevicesController extends GetxController {
  static DevicesController instance = Get.find();
  RxList<Device> deviceList = List<Device>.empty(growable: true).obs;
  RxBool isDeviceLoading = false.obs;

  final LocalDeviceService _localDeviceService = LocalDeviceService();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localDeviceService.init();
    _loadCachedDevices(); // Load from cache first for instant UI

    // Fetch fresh data in background (don't block initialization)
    getDevices().catchError((e) {
      // User still sees cached data, no error shown
    });
  }

  void _loadCachedDevices() {
    if (_localDeviceService.getDevices().isNotEmpty) {
      deviceList.assignAll(_localDeviceService.getDevices());
    }
  }

  // Fetch fresh devices from API (called on pull-to-refresh)
  Future<void> getDevices() async {
    try {
      isDeviceLoading(true);

      // Load from cache first for instant display
      if (_localDeviceService.getDevices().isNotEmpty) {
        deviceList.assignAll(_localDeviceService.getDevices());
      }

      // Call API for fresh data
      var result = await RemoteDeviceService().get();
      if (result.isNotEmpty) {
        deviceList.assignAll(result);
        _localDeviceService.assignAllDevices(devices: result);
      } else {
      }
    } finally {
      isDeviceLoading(false);
    }
  }

  void getProductByCategory({required int id}) async {
    // For now, just get all devices since we don't have category filtering yet
    // You can implement category filtering later in your Django backend
    getDevices();
  }
}
