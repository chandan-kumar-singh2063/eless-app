import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/component/main_header.dart';
import 'package:eless/controller/devices_controller.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/Devices/components/device_grid.dart';
import 'package:eless/view/Devices/components/device_loading_grid.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

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
                  // Show shimmer loading during refresh OR initial load
                  if (DevicesController.instance.isDeviceLoading.value) {
                    return const DeviceLoadingGrid();
                  } else if (DevicesController.instance.deviceList.isNotEmpty) {
                    return DeviceGrid(
                      devices: DevicesController.instance.deviceList,
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
