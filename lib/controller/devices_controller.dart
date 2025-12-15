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
  final int pageSize = 12; // Load 12 devices at a time (like events use 10)

  final LocalDeviceService _localDeviceService = LocalDeviceService();

  // ⚡ Performance: In-memory cache to avoid repeated Hive reads
  List<Device>? _cachedDevices;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _cachedDevices = null;
    super.onClose();
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
    // ⚡ Load from memory cache first (instant)
    if (_cachedDevices != null && _cachedDevices!.isNotEmpty) {
      deviceList.assignAll(_cachedDevices!);
    } else {
      final cached = _localDeviceService.getDevices();
      if (cached.isNotEmpty) {
        _cachedDevices = cached;
        deviceList.assignAll(cached);
      }
    }
  }

  // Initial load - gets first page only
  Future<void> getDevicesFirstPage() async {
    try {
      isDeviceLoading(true);
      currentPage = 1;
      hasMoreData.value = true;

      // Load from cache first (instant UI)
      _loadCachedDevices();

      // Fetch first page from API
      await _fetchDevicesPage(page: 1, isRefresh: true);
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
      await _fetchDevicesPage(page: currentPage, isRefresh: false);
    } finally {
      isLoadingMore(false);
    }
  }

  Future<void> _fetchDevicesPage({
    required int page,
    required bool isRefresh,
  }) async {
    try {
      var result = await RemoteDeviceService().getPaginated(
        page: page,
        pageSize: pageSize,
      );

      if (result['devices'] != null) {
        final devices = result['devices'] as List<Device>;

        // Check if we got less data than page size (last page)
        if (devices.length < pageSize) {
          hasMoreData.value = false;
        }

        // Sort alphabetically (A-Z)
        devices.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        if (isRefresh) {
          // Replace all data (refresh)
          deviceList.assignAll(devices);

          // ⚡ Update memory cache immediately
          _cachedDevices = List.from(deviceList);

          // ⚡ Batch write to Hive (only on refresh)
          _localDeviceService.assignAllDevices(devices: devices);
        } else {
          // Append data (pagination)
          deviceList.addAll(devices);

          // ⚡ Update memory cache without disk write (save I/O)
          _cachedDevices = List.from(deviceList);
        }
      }
    } catch (e) {
      // Error handling
      if (page == 1) {
        // First page error - show cached data
        _loadCachedDevices();
      }
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
}
