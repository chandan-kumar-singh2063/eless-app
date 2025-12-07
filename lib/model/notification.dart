import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 7)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String image;

  @HiveField(4)
  final String type; // 'explore_redirect' or 'open_details'

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool isClicked; // Local UI state only - tracks if user clicked on this notification

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.type,
    required this.createdAt,
    this.isClicked = false, // Default: not clicked (unread UI state)
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      type: json['type'] ?? 'open_details',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isClicked: false, // Always start as unclicked when fetched from backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      // Note: isClicked is not sent to backend - purely local UI state
    };
  }
}
