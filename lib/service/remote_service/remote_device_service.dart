import 'dart:convert';
import 'package:eless/const.dart';
import 'package:eless/service/remote_service/http_client_service.dart';
import '../../model/device.dart';

class RemoteDeviceService {
  final _httpClient = HttpClientService.instance;
  var remoteUrl = '$baseUrl/api/v1/services/devices';

  // Paginated version
  Future<Map<String, dynamic>> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      var response = await _httpClient.get(
        Uri.parse('$remoteUrl/?page=$page&page_size=$pageSize'),
        timeout: const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        // Handle both paginated and non-paginated responses
        var deviceData = jsonData['devices'] ?? jsonData['results'] ?? jsonData;
        var devices = Device.devicesFromJson(deviceData);

        return {'devices': devices, 'has_more': jsonData['next'] != null};
      } else {
        return {'devices': <Device>[], 'has_more': false};
      }
    } catch (e) {
      return {'devices': <Device>[], 'has_more': false};
    }
  }

  // Original method - kept for backward compatibility
  Future<List<Device>> get() async {
    try {
      var response = await _httpClient.get(
        Uri.parse('$remoteUrl/'),
        timeout: const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        var devices = Device.devicesFromJson(
          jsonData['devices'] ?? jsonData['results'] ?? jsonData,
        );

        // Log each device's availability and quantity
        for (var _ in devices) {}

        return devices;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
