import 'package:get/get.dart';
import 'package:eless/model/notification.dart';
import 'package:eless/service/local_service/local_notification_service.dart';
import 'package:eless/service/remote_service/remote_notification_service.dart';

class NotificationController extends GetxController {
  static NotificationController instance = Get.find();

  RxList<NotificationModel> notificationList = <NotificationModel>[].obs;
  RxBool isNotificationLoading = false.obs;
  RxInt unreadCount = 0.obs;
  RxBool isInitialized = false.obs;

  // Pagination states
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreData = true.obs;
  int currentPage = 1;
  final int pageSize = 15; // Load 15 notifications at a time

  LocalNotificationService localNotificationService =
      LocalNotificationService();
  RemoteNotificationService remoteNotificationService =
      RemoteNotificationService();

  // ⚡ Performance: In-memory cache to avoid repeated Hive reads
  List<NotificationModel>? _cachedNotifications;
  RxBool isRefreshing = false.obs; // Silent background refresh flag

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _cachedNotifications = null;
    super.onClose();
  }

  Future<void> _initialize() async {
    try {
      await localNotificationService.init();
      _loadCachedNotifications(); // Load from cache first for instant UI

      // Fetch fresh data in background (don't block initialization)
      getNotificationsFirstPage().catchError((e) {
        // User still sees cached data, no error shown
      });
    } finally {
      isInitialized.value = true;
    }
  }

  void _loadCachedNotifications() {
    // ⚡ Load from memory cache first (instant)
    if (_cachedNotifications != null && _cachedNotifications!.isNotEmpty) {
      notificationList.assignAll(_cachedNotifications!);
      _updateUnreadCount();
    } else {
      final cached = localNotificationService.getNotifications();
      if (cached.isNotEmpty) {
        _cachedNotifications = cached;
        notificationList.assignAll(cached);
        _updateUnreadCount();
      }
    }
  }

  // Initial load - first page only
  Future<void> getNotificationsFirstPage() async {
    try {
      isNotificationLoading(true);
      currentPage = 1;
      hasMoreData.value = true;

      // Load from cache first for instant display
      if (localNotificationService.getNotifications().isNotEmpty) {
        notificationList.assignAll(localNotificationService.getNotifications());
        _updateUnreadCount();
      }

      // Fetch first page from API
      var result = await remoteNotificationService.getNotificationsPaginated(
        page: 1,
        pageSize: pageSize,
      );

      if (result != null && result['notifications'] != null) {
        final notifications =
            result['notifications'] as List<NotificationModel>;
        hasMoreData.value = result['has_more'] ?? false;

        // Preserve isClicked state from local storage
        final existingNotifications = localNotificationService
            .getNotifications();
        for (var newNotification in notifications) {
          final existing = existingNotifications.firstWhereOrNull(
            (n) => n.id == newNotification.id,
          );
          if (existing != null) {
            newNotification.isClicked = existing.isClicked;
          }
        }

        localNotificationService.assignAllNotifications(
          notifications: notifications,
        );

        // ⚡ Update memory cache immediately
        _cachedNotifications = List.from(notifications);

        notificationList.assignAll(notifications);
        _updateUnreadCount();
      }
    } finally {
      isNotificationLoading(false);
    }
  }

  // Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    try {
      isLoadingMore(true);
      currentPage++;

      var result = await remoteNotificationService.getNotificationsPaginated(
        page: currentPage,
        pageSize: pageSize,
      );

      if (result != null && result['notifications'] != null) {
        final newNotifications =
            result['notifications'] as List<NotificationModel>;
        hasMoreData.value = result['has_more'] ?? false;

        // Preserve isClicked state
        final existingNotifications = localNotificationService
            .getNotifications();
        for (var newNotification in newNotifications) {
          final existing = existingNotifications.firstWhereOrNull(
            (n) => n.id == newNotification.id,
          );
          if (existing != null) {
            newNotification.isClicked = existing.isClicked;
          }
        }

        // Append new notifications
        notificationList.addAll(newNotifications);

        // ⚡ Update memory cache without disk write (save I/O)
        _cachedNotifications = List.from(notificationList);

        _updateUnreadCount();
      } else {
        hasMoreData.value = false;
      }
    } catch (e) {
      hasMoreData.value = false;
    } finally {
      isLoadingMore(false);
    }
  }

  // Refresh - optimistic silent refresh (Instagram pattern)
  Future<void> getNotifications() async {
    try {
      isRefreshing(true);
      currentPage = 1;
      hasMoreData.value = true;

      // Keep showing cached data while fetching (Instagram pattern)
      // Fetch first page silently in background
      var result = await remoteNotificationService.getNotificationsPaginated(
        page: 1,
        pageSize: pageSize,
      );

      if (result != null && result['notifications'] != null) {
        final notifications =
            result['notifications'] as List<NotificationModel>;
        hasMoreData.value = result['has_more'] ?? false;

        // Preserve isClicked state
        final existingNotifications = localNotificationService
            .getNotifications();
        for (var newNotification in notifications) {
          final existing = existingNotifications.firstWhereOrNull(
            (n) => n.id == newNotification.id,
          );
          if (existing != null) {
            newNotification.isClicked = existing.isClicked;
          }
        }

        localNotificationService.assignAllNotifications(
          notifications: notifications,
        );

        // ⚡ Update memory cache
        _cachedNotifications = List.from(notifications);

        notificationList.assignAll(notifications);
        _updateUnreadCount();
      }
    } finally {
      isRefreshing(false);
    }
  }

  void markAsClicked(NotificationModel notification) {
    // Mark as clicked (no red dot) - purely local UI state
    notification.isClicked = true;
    localNotificationService.updateNotification(notification);
    _updateUnreadCount();
    // No backend call needed - admin doesn't need to know if user clicked
  }

  void markAllAsClicked() {
    // Mark all as clicked - purely local operation
    for (var notification in notificationList) {
      notification.isClicked = true;
      localNotificationService.updateNotification(notification);
    }
    _updateUnreadCount();
    // No backend call needed
  }

  void _updateUnreadCount() {
    unreadCount.value = notificationList
        .where((notification) => !notification.isClicked)
        .length;
  }
}
