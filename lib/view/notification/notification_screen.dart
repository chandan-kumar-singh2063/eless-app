import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/notification/components/notification_card.dart';
import 'package:eless/view/notification/components/notification_loading_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Mark all notifications as clicked when user opens notification screen
    // This is standard badge behavior - badge disappears when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationController.instance.markAllAsClicked();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      // Load more when user is 300px from the bottom
      NotificationController.instance.loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header matching device details style
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Obx(
                    () => NotificationController.instance.unreadCount.value > 0
                        ? TextButton(
                            onPressed: () => NotificationController.instance
                                .markAllAsClicked(),
                            child: Text(
                              'Mark all',
                              style: TextStyle(
                                color: AppTheme.lightPrimaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : const SizedBox(width: 48),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await NotificationController.instance.getNotifications();
                },
                color: AppTheme.lightPrimaryColor,
                child: Obx(() {
                  if (NotificationController
                          .instance
                          .isNotificationLoading
                          .value &&
                      NotificationController
                          .instance
                          .notificationList
                          .isEmpty) {
                    // Show loading state
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) =>
                          const NotificationLoadingCard(),
                    );
                  } else if (NotificationController
                      .instance
                      .notificationList
                      .isNotEmpty) {
                    // Show notifications with pagination
                    return ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount:
                          NotificationController
                              .instance
                              .notificationList
                              .length +
                          (NotificationController.instance.hasMoreData.value
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at the bottom
                        if (index ==
                            NotificationController
                                .instance
                                .notificationList
                                .length) {
                          return Obx(
                            () =>
                                NotificationController
                                    .instance
                                    .isLoadingMore
                                    .value
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        }

                        return NotificationCard(
                          notification: NotificationController
                              .instance
                              .notificationList[index],
                        );
                      },
                    );
                  } else {
                    // Show empty state - wrap in scrollable to enable pull-to-refresh
                    return _buildEmptyState();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icon(
                  Icons.notifications_none_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see notifications here when they arrive',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
