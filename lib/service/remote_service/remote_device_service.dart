import 'dart:convert';
import 'package:eless/const.dart';
import 'package:eless/service/remote_service/http_client_service.dart';
import '../../model/device.dart';

class RemoteDeviceService {
  final _httpClient = HttpClientService.instance;
  var remoteUrl = '$baseUrl/services/api/devices';

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
        for (var _ in devices) {
        }

        return devices;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
