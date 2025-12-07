import 'package:hive/hive.dart';
import 'package:eless/model/notification.dart';

class LocalNotificationService {
  late Box<NotificationModel> _notificationBox;
  static const String _boxName = 'notifications';

  Future<void> init() async {
    try {
      _notificationBox = await Hive.openBox<NotificationModel>(_boxName);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignAllNotifications({
    required List<NotificationModel> notifications,
  }) async {
    await _notificationBox.clear();
    await _notificationBox.addAll(notifications);
  }

  List<NotificationModel> getNotifications() => _notificationBox.values.toList()
    ..sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    ); // Sort by newest first

  Future<void> addNotification(NotificationModel notification) async {
    await _notificationBox.add(notification);
  }

  Future<void> updateNotification(NotificationModel notification) async {
    await notification.save();
  }

  Future<void> clearNotifications() async {
    await _notificationBox.clear();
  }

  int getUnreadCount() {
    return _notificationBox.values
        .where((notification) => !notification.isClicked)
        .length;
  }
}
