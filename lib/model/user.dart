import 'dart:convert';

import 'package:hive/hive.dart';

part 'user.g.dart';

User userFromJson(String str) => User.fromJson(json.decode(str));

@HiveType(typeId: 3)
class User {
  @HiveField(0)
  String id;
  @HiveField(1)
  String fullName;
  @HiveField(2)
  String email;
  @HiveField(3)
  String? image;
  @HiveField(4)
  DateTime? birthDay;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.image,
    this.birthDay,
  });

  factory User.fromJson(Map<String, dynamic> data) {
    // Handle different possible field names from backend
    String userId =
        data['id']?.toString() ??
        data['user_id']?.toString() ??
        data['userId']?.toString() ??
        '';

    String userName =
        data['fullName']?.toString() ??
        data['full_name']?.toString() ??
        data['name']?.toString() ??
        data['username']?.toString() ??
        'Unknown User';

    String userEmail =
        data['email']?.toString() ?? data['email_address']?.toString() ?? '';

    // Handle different image field structures
    String? userImage;
    if (data['image'] != null) {
      if (data['image'] is Map) {
        userImage = data['image']['url'];
      } else if (data['image'] is String) {
        userImage = data['image'];
      }
    } else if (data['profile_image'] != null) {
      userImage = data['profile_image'].toString();
    } else if (data['avatar'] != null) {
      userImage = data['avatar'].toString();
    }

    // Handle birthday/age
    DateTime? userBirthday;
    try {
      if (data['birthDay'] != null) {
        userBirthday = DateTime.parse(data['birthDay']);
      } else if (data['birth_day'] != null) {
        userBirthday = DateTime.parse(data['birth_day']);
      } else if (data['age'] != null) {
        userBirthday = DateTime.parse(data['age']);
      }
    } catch (e) {
      // Invalid date format, skip
    }

    return User(
      id: userId,
      fullName: userName,
      email: userEmail,
      image: userImage,
      birthDay: userBirthday,
    );
  }
}
