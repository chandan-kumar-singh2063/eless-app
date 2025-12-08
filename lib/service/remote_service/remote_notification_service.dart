import 'dart:convert';
import 'package:eless/config/api_config.dart';
import 'package:eless/model/notification.dart';
import 'package:eless/service/remote_service/http_client_service.dart';

class RemoteNotificationService {
  final _httpClient = HttpClientService.instance;

  // Paginated version
  Future<Map<String, dynamic>?> getNotificationsPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      var response = await _httpClient.get(
        Uri.parse(
          '${ApiConfig.getFullApiUrl(ApiConfig.notificationsEndpoint)}?page=$page&page_size=$pageSize',
        ),
        headers: {"Content-Type": "application/json"},
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        var jsonString = response.body;
        var jsonMap = json.decode(jsonString);

        var notificationList = <NotificationModel>[];

        // Handle both paginated and non-paginated responses
        final data = jsonMap['results'] ?? jsonMap;

        if (data is List) {
          for (var item in data) {
            notificationList.add(NotificationModel.fromJson(item));
          }
        } else if (data is Map && data['results'] != null) {
          for (var item in data['results']) {
            notificationList.add(NotificationModel.fromJson(item));
          }
        }

        return {
          'notifications': notificationList,
          'has_more': jsonMap['next'] != null,
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Original method - kept for backward compatibility
  Future<dynamic> getNotifications() async {
    var response = await _httpClient.get(
      Uri.parse(ApiConfig.getFullApiUrl(ApiConfig.notificationsEndpoint)),
      headers: {"Content-Type": "application/json"},
      timeout: const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      var jsonString = response.body;
      var jsonMap = json.decode(jsonString);

      var notificationList = <NotificationModel>[];
      for (var data in jsonMap['results'] ?? jsonMap) {
        notificationList.add(NotificationModel.fromJson(data));
      }

      return notificationList;
    } else {
      return null;
    }
  }

  // Note: No mark-as-read endpoints needed
  // isClicked is purely local UI state, not tracked on backend
}
