import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/device.dart';
import '../../theme/app_theme.dart';
import '../../controller/device_request_controller.dart';
import 'components/device_info_card.dart';
import 'components/request_form_fields.dart';
import 'components/date_and_purpose_fields.dart';

class DeviceRequestScreen extends StatefulWidget {
  final Device device;
  const DeviceRequestScreen({super.key, required this.device});

  @override
  State<DeviceRequestScreen> createState() => _DeviceRequestScreenState();
}

class _DeviceRequestScreenState extends State<DeviceRequestScreen> {
  // ⚡ OPTIMIZATION: Cache controller reference (don't call Get.find repeatedly)
  late final DeviceRequestController controller;

  @override
  void initState() {
    super.initState();
    // Get controller from binding with error handling
    try {
      controller = Get.find<DeviceRequestController>();
    } catch (e) {
      // Fallback: use safe instance getter if binding failed
      controller = DeviceRequestController.instance;
    }
    // Set device and check availability in background (non-blocking)
    controller.currentDevice.value = widget.device;
    // Schedule availability check as microtask to not block initial render
    Future.microtask(() => controller.checkDeviceAvailability());
  }

  @override
  void dispose() {
    // Clear form when leaving screen (prevent data persistence)
    controller.clearForm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.lightPrimaryColor,
        elevation: 0,
        title: const Text(
          'Request Device',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device info card component - only this rebuilds on availability changes
            Obx(() {
              // Show unavailable message if device is not available (after check completes)
              if (!controller.isCheckingAvailability.value &&
                  controller.deviceAvailability.value?.isAvailable == false) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Device Not Available',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.deviceAvailability.value?.message ??
                              'This device is currently unavailable for requests.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lightPrimaryColor,
                          ),
                          child: const Text(
                            'Go Back',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return DeviceInfoCard(
                device: widget.device,
                availability: controller.deviceAvailability.value,
                isLoading: controller.isCheckingAvailability.value,
              );
            }),

            const SizedBox(height: 24),

            // Request form fields component - no Obx, renders immediately
            RequestFormFields(controller: controller),

            // Date and purpose fields component - no Obx, renders immediately
            DateAndPurposeFields(controller: controller),
          ],
        ),
      ),
    );
  }
}
