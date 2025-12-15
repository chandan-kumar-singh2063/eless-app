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
  final int pageSize = 12; // Load 12 devices at a time (fits 2x6 grid)

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
      _sortDevicesAlphabetically(devices);
      deviceList.assignAll(devices);
    }
  }

  // Initial load - first page only
  Future<void> getDevicesFirstPage() async {
    try {
      isDeviceLoading(true);
      currentPage = 1;
      hasMoreData.value = true;

      // Load from cache first for instant display
      if (_localDeviceService.getDevices().isNotEmpty) {
        deviceList.assignAll(_localDeviceService.getDevices());
      }

      // Call API for first page
      var result = await RemoteDeviceService().getPaginated(
        page: 1,
        pageSize: pageSize,
      );

      if (result['devices'] != null) {
        final devices = result['devices'] as List<Device>;
        // Sort devices alphabetically before displaying
        _sortDevicesAlphabetically(devices);

        hasMoreData.value = result['has_more'] ?? false;

        deviceList.assignAll(devices);
        _localDeviceService.assignAllDevices(devices: devices);
      }
    } finally {
      isDeviceLoading(false);
    }
  }

  // Load more devices (pagination)
  Future<void> loadMoreDevices() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    try {
      isLoadingMore(true);
      currentPage++;

      var result = await RemoteDeviceService().getPaginated(
        page: currentPage,
        pageSize: pageSize,
      );

      if (result['devices'] != null) {
        final newDevices = result['devices'] as List<Device>;
        hasMoreData.value = result['has_more'] ?? false;

        // Append new devices and re-sort entire list alphabetically
        deviceList.addAll(newDevices);
        _sortDevicesAlphabetically(deviceList);
      } else {
        hasMoreData.value = false;
      }
    } catch (e) {
      hasMoreData.value = false;
    } finally {
      isLoadingMore(false);
    }
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

  /// Sort devices alphabetically by name (A-Z)
  /// Provides better UX by organizing devices in predictable order
  void _sortDevicesAlphabetically(List<Device> devices) {
    devices.sort((a, b) {
      // Case-insensitive alphabetical comparison
      // Converts to lowercase for consistent sorting regardless of case
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
}
