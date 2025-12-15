import 'package:get/get.dart';
import 'package:eless/model/device.dart';
import 'package:eless/service/local_service/local_device_service.dart';
import 'package:eless/service/remote_service/remote_device_service.dart';

class DevicesController extends GetxController {
  static DevicesController instance = Get.find();
  RxList<Device> deviceList = List<Device>.empty(growable: true).obs;
  RxBool isDeviceLoading = false.obs;

  // Pagination states
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreData = true.obs;
  int currentPage = 1;
  final int pageSize =
      40; // Load ALL devices at once - 40 devices is small dataset

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
    getDevicesFirstPage().catchError((e) {
      // User still sees cached data, no error shown
    });
  }

  void _loadCachedDevices() {
    if (_localDeviceService.getDevices().isNotEmpty) {
      final devices = _localDeviceService.getDevices();
      // Sort only once when loading from cache
      devices.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      deviceList.assignAll(devices);
    }
  }

  // Initial load - loads ALL devices (40 devices is small dataset)
  Future<void> getDevicesFirstPage() async {
    try {
      isDeviceLoading(true);
      currentPage = 1;

      // Call API for all devices at once (page_size=40)
      var result = await RemoteDeviceService().getPaginated(
        page: 1,
        pageSize: pageSize,
      );

      if (result['devices'] != null) {
        final devices = result['devices'] as List<Device>;

        // Sort once before saving
        devices.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        // Update UI and cache
        deviceList.assignAll(devices);
        _localDeviceService.assignAllDevices(devices: devices);

        // No pagination needed for 40 devices
        hasMoreData.value = false;
      }
    } catch (e) {
      // Keep showing cached data on error
    } finally {
      isDeviceLoading(false);
    }
  }

  // Pagination not needed - 40 devices loads instantly
  Future<void> loadMoreDevices() async {
    // No-op: All devices loaded on first page
    return;
  }

  // Fetch fresh devices from API (called on pull-to-refresh)
  Future<void> getDevices() async {
    return getDevicesFirstPage();
  }

  void getProductByCategory({required int id}) async {
    // For now, just get all devices since we don't have category filtering yet
    // You can implement category filtering later in your Django backend
    getDevices();
  }
}
