import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:eless/extention/image_url_helper.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/controller/dashboard_controller.dart';
import 'package:eless/model/notification.dart';
import 'package:eless/theme/app_theme.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread indicator (red dot for unclicked notifications)
                if (!notification.isClicked)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: badges.Badge(
                      badgeContent: const SizedBox(),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: Colors.red,
                        padding: const EdgeInsets.all(4),
                      ),
                      child: const SizedBox(width: 8, height: 8),
                    ),
                  )
                else
                  const SizedBox(width: 16),

                const SizedBox(width: 8),

                // Content - aligned to left
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice label
                      Text(
                        'Notice',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightPrimaryColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTextColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Description
                      if (notification.description.isNotEmpty)
                        Text(
                          notification.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 8),

                      // Timestamp
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'MMM dd, hh:mm a',
                            ).format(notification.createdAt).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Thumbnail - Only show for 'open_details' type, NOT for 'explore_redirect'
                if (notification.type == 'open_details') ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildThumbnail(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap() {
    // Mark as clicked (removes red dot, decreases badge count)
    NotificationController.instance.markAsClicked(notification);

    // Navigate based on type
    if (notification.type == 'explore_redirect') {
      // Close notification screen first, then switch to Explore tab
      Get.back(); // Close notification screen
      // Wait a frame for navigation to complete, then switch tabs
      Future.delayed(const Duration(milliseconds: 100), () {
        final dashboardController = Get.find<DashboardController>();
        dashboardController.updateIndex(1); // Switch to Explore tab
      });
    } else if (notification.type == 'open_details') {
      Get.toNamed('/notification-details', arguments: notification);
    }
  }

  Widget _buildThumbnail() {
    // Only for 'open_details' type notifications - show image or notification icon
    if (notification.image.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: getFullImageUrl(notification.image),
        fit: BoxFit.cover,
        memCacheWidth: 150,
        memCacheHeight: 150,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.lightPrimaryColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[500],
            size: 24,
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.article_outlined, color: Colors.grey[600], size: 24),
      );
    }
  }
}
