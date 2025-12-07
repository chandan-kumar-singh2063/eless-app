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

  LocalNotificationService localNotificationService =
      LocalNotificationService();
  RemoteNotificationService remoteNotificationService =
      RemoteNotificationService();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await localNotificationService.init();
      _loadCachedNotifications(); // Load from cache first for instant UI

      // Fetch fresh data in background (don't block initialization)
      getNotifications().catchError((e) {
        // User still sees cached data, no error shown
      });
    } finally {
      isInitialized.value = true;
    }
  }

  void _loadCachedNotifications() {
    if (localNotificationService.getNotifications().isNotEmpty) {
      notificationList.assignAll(localNotificationService.getNotifications());
      _updateUnreadCount();
    }
  }

  Future<void> getNotifications() async {
    try {
      isNotificationLoading(true);

      // Load from cache first for instant display
      if (localNotificationService.getNotifications().isNotEmpty) {
        notificationList.assignAll(localNotificationService.getNotifications());
        _updateUnreadCount();
      }

      // Then fetch fresh data from API
      var result = await remoteNotificationService.getNotifications();
      if (result != null) {
        // Preserve isClicked state from local storage
        final existingNotifications = localNotificationService
            .getNotifications();
        for (var newNotification in result) {
          final existing = existingNotifications.firstWhereOrNull(
            (n) => n.id == newNotification.id,
          );
          if (existing != null) {
            // Preserve the clicked state from local storage
            newNotification.isClicked = existing.isClicked;
          }
        }
        localNotificationService.assignAllNotifications(notifications: result);
        notificationList.assignAll(result);
        _updateUnreadCount();
      } else {
      }
    } finally {
      isNotificationLoading(false);
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
