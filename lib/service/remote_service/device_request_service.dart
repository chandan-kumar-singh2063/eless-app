import 'dart:convert';
import 'package:eless/const.dart';
import 'package:eless/service/remote_service/http_client_service.dart';
import '../../model/device_request.dart';

class DeviceRequestService {
  final _httpClient = HttpClientService.instance;
  var remoteUrl = '$baseUrl/api/v1/services/devices';

  Future<DeviceAvailability> checkAvailability({
    required String deviceId,
  }) async {
    try {
      var response = await _httpClient.get(
        Uri.parse('$remoteUrl/$deviceId/availability/'),
        headers: {'Content-Type': 'application/json'},
        timeout: const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return DeviceAvailability.fromJson(jsonData);
      } else {
        return DeviceAvailability(
          isAvailable: false,
          availableQuantity: 0,
          totalQuantity: 0,
          message: 'Unable to check availability',
        );
      }
    } catch (e) {
      return DeviceAvailability(
        isAvailable: false,
        availableQuantity: 0,
        totalQuantity: 0,
        message: 'Connection error',
      );
    }
  }

  Future<Map<String, dynamic>> submitRequest({
    required String deviceId,
    required DeviceRequest request,
  }) async {
    try {
      final endpoint = '$remoteUrl/$deviceId/request/';
      final payload = request.toJson();

      var response = await _httpClient.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 15),
      );

      var jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Request submitted successfully',
          'data': jsonData,
        };
      } else {
        String errorMessage = 'Request failed';
        if (jsonData.containsKey('error')) {
          errorMessage = jsonData['error'];
        } else if (jsonData.containsKey('message')) {
          errorMessage = jsonData['message'];
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'error': 'network_error',
      };
    }
  }
}
