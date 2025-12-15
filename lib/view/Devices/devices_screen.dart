import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/component/main_header.dart';
import 'package:eless/controller/devices_controller.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/Devices/components/device_card.dart';
import 'package:eless/view/Devices/components/device_loading_grid.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Guard 1: Prevent duplicate calls while loading
    if (_isLoadingMore) return;

    final controller = DevicesController.instance;

    // Guard 2: Check if more data available before calculating position
    if (!controller.hasMoreData.value) return;

    // Guard 3: Only trigger when close to bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _isLoadingMore = true;
      controller.loadMoreDevices().then((_) {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const MainHeader(pageType: 'devices'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await DevicesController.instance.getDevices();
                },
                color: AppTheme.lightPrimaryColor,
                child: Obx(() {
                  final controller = DevicesController.instance;

                  // ⚡ Optimistic UI: Show shimmer ONLY when truly empty
                  // During refresh, keep showing existing data (Instagram pattern)
                  if (controller.deviceList.isEmpty) {
                    // Show shimmer only during initial load, not refresh
                    if (controller.isDeviceLoading.value) {
                      return const DeviceLoadingGrid();
                    }
                    return _buildEmptyState(context);
                  }

                  // ⚡ Optimized: Use CustomScrollView with SliverGrid
                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 500, // Preload 500px for smooth scrolling
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(10),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                childAspectRatio: 2 / 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return DeviceCard(
                                device: controller.deviceList[index],
                              );
                            },
                            childCount: controller.deviceList.length,
                            addAutomaticKeepAlives: false, // Save memory
                            addRepaintBoundaries: true,
                          ),
                        ),
                      ),
                      // Loading indicator as separate sliver
                      if (controller.hasMoreData.value)
                        SliverToBoxAdapter(
                          child: Obx(
                            () => controller.isLoadingMore.value
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.lightPrimaryColor,
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 20),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No devices available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and pull down to refresh',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
