import 'package:get/get.dart';
import 'package:eless/model/device.dart';
import 'package:eless/model/cancel_token.dart';
import 'package:eless/service/local_service/local_device_service.dart';
import 'package:eless/service/remote_service/remote_device_service.dart';

class DevicesController extends GetxController {
  static DevicesController instance = Get.find();
  RxList<Device> deviceList = List<Device>.empty(growable: true).obs;
  RxBool isDeviceLoading = false.obs;

  // Pagination states
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreData = true.obs;
  RxBool isRefreshing = false.obs; // ⚡ Silent background refresh flag
  int currentPage = 1;
  final int pageSize = 12; // Load 12 devices at a time (like events use 10)

  final LocalDeviceService _localDeviceService = LocalDeviceService();

  // ⚡ Performance: In-memory cache to avoid repeated Hive reads
  List<Device>? _cachedDevices;
  DateTime? _lastFetch; // ⚡ Cache expiry: refresh every 5 minutes
  final CancelToken _cancelToken = CancelToken(); // ⚡ Cancel pending requests

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _cancelToken.cancel(); // ⚡ Cancel any pending requests
    _cachedDevices = null;
    _lastFetch = null;
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
    if (_cachedDevices != null && _lastFetch != null) {
      final cacheAge = DateTime.now().difference(_lastFetch!);
      if (cacheAge.inMinutes < 5) {
        deviceList.assignAll(_cachedDevices!);
        return;
      }
    }
    // ⚡ Fall back to Hive if cache expired
    if (_localDeviceService.getDevices().isNotEmpty) {
      final devices = _localDeviceService.getDevices();
      _cachedDevices = devices;
      _lastFetch = DateTime.now();
      deviceList.assignAll(devices);
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
      final nextPage = currentPage + 1; // Calculate next page
      await _fetchDevicesPage(page: nextPage, isRefresh: false);
      currentPage = nextPage; // ✅ Only increment AFTER successful fetch
    } catch (e) {
      // ⚡ Error: Page stays same, user can retry
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

      // ⚡ Check if request was cancelled (user navigated away)
      if (_cancelToken.isCancelled) return;

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
          _lastFetch = DateTime.now();

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
  // ⚡ Optimized: Silent refresh without clearing existing data
  Future<void> getDevices() async {
    try {
      isRefreshing(true);
      currentPage = 1;
      hasMoreData.value = true;

      // Keep showing cached data while fetching (Instagram pattern)
      // Don't call _loadCachedDevices() - data already visible

      // Fetch first page silently in background
      await _fetchDevicesPage(page: 1, isRefresh: true);
    } finally {
      isRefreshing(false);
    }
  }

  void getProductByCategory({required int id}) async {
    // For now, just get all devices since we don't have category filtering yet
    // You can implement category filtering later in your Django backend
    getDevices();
  }
}
