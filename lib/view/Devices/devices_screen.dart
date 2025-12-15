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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
                  // Show shimmer loading during initial load
                  if (DevicesController.instance.isDeviceLoading.value &&
                      DevicesController.instance.deviceList.isEmpty) {
                    return const DeviceLoadingGrid();
                  } else if (DevicesController.instance.deviceList.isNotEmpty) {
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 2 / 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(10),
                      itemCount: DevicesController.instance.deviceList.length,
                      cacheExtent:
                          1000, // Increased cache for smoother scrolling
                      addRepaintBoundaries: true,
                      addAutomaticKeepAlives: true,
                      itemBuilder: (context, index) {
                        return DeviceCard(
                          key: ValueKey(
                            DevicesController.instance.deviceList[index].id,
                          ),
                          device: DevicesController.instance.deviceList[index],
                        );
                      },
                    );
                  } else {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other,
                              size: 64,
                              color: Colors.grey[400],
                            ),
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
                              'Check back later for new devices',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
