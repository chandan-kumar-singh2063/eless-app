import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/controllers.dart';
import '../../model/device.dart';
import '../../theme/app_theme.dart';
import '../../route/app_route.dart';
import '../../extention/image_url_helper.dart';
import '../account/auth/sign_in_bottom_sheet.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailsScreen({super.key, required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with overlay back button (matching event screen)
              Stack(
                children: [
                  SizedBox(
                    height: (MediaQuery.of(context).size.height * 0.3).clamp(
                      200.0,
                      350.0,
                    ),
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: getFullImageUrl(widget.device.image),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        highlightColor: Colors.white,
                        baseColor: Colors.grey.shade300,
                        child: Container(color: Colors.grey.shade300),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: InkWell(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Availability Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.device.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.device.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.device.isAvailable
                                  ? 'Available'
                                  : 'Not Available',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Total Quantity
                      Text(
                        'Total Quantity: ${widget.device.totalQuantity}',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.lightTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Currently Available (only show if backend provides this data)
                      if (widget.device.availableQuantity != null)
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: widget.device.availableQuantity! > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Currently Available: ${widget.device.availableQuantity}',
                              style: TextStyle(
                                fontSize: 16,
                                color: widget.device.availableQuantity! > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTextColor,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        widget.device.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightTextColor,
                          height: 1.5,
                        ),
                        softWrap: true,
                      ),

                      const SizedBox(height: 24),

                      // Logged in user info (if logged in)
                      if (authController.isLoggedIn &&
                          authController.user.value != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Logged in as ${authController.user.value!.fullName}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (authController.isLoggedIn) const SizedBox(height: 16),

                      // Get Device Button
                      if (widget.device.isAvailable)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: authController.isLoggingIn.value
                                ? null
                                : () {
                                    if (authController.isLoggedIn) {
                                      // User is logged in, proceed with device request
                                      Get.toNamed(
                                        AppRoute.deviceRequest,
                                        arguments: widget.device,
                                      );
                                    } else {
                                      // User is not logged in, show sign-in bottom sheet
                                      SignInBottomSheet.show(
                                        context,
                                        canDismiss: true,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              authController.isLoggedIn
                                  ? Icons.arrow_forward
                                  : Icons.login,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              authController.isLoggedIn
                                  ? 'Request Device'
                                  : 'Sign In to Get Device',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
