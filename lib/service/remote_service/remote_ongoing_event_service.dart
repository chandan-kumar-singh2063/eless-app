import 'package:eless/const.dart';
import 'package:eless/service/remote_service/http_client_service.dart';

class RemoteOngoingEventService {
  final _httpClient = HttpClientService.instance;
  var remoteUrl = '$baseUrl/events/api/flutter/ongoing';

  Future<dynamic> get() async {
    try {
      var response = await _httpClient.get(
        Uri.parse(remoteUrl),
        timeout: const Duration(seconds: 12),
      );
      return response;
    } catch (e) {
      return null;
    }
  }
}
