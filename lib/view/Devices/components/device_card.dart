import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import '../../../model/device.dart';
import '../../../extention/image_url_helper.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
        Get.toNamed('/device-details', arguments: device);
      },
      child: Material(
        elevation: 8,
        shadowColor: Colors.grey.shade300,
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability badge at top
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: device.isAvailable
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    device.isAvailable ? 'Available' : 'Not Available',
                    style: TextStyle(
                      color: device.isAvailable
                          ? Colors.green[800]
                          : Colors.red[800],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Image area
              Flexible(
                flex: 4,
                child: Center(
                  child: Hero(
                    tag: device.image,
                    child: CachedNetworkImage(
                      imageUrl: getFullImageUrl(device.image),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        highlightColor: Colors.white,
                        baseColor: Colors.grey.shade300,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.grey.shade300,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error_outline, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Quantity: ${device.totalQuantity}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
