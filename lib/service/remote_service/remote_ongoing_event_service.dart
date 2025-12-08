import 'package:eless/const.dart';
import 'package:eless/service/remote_service/http_client_service.dart';

class RemoteOngoingEventService {
  final _httpClient = HttpClientService.instance;
  var remoteUrl = '$baseUrl/events/api/flutter/ongoing';

  // Paginated version
  Future<dynamic> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      var response = await _httpClient.get(
        Uri.parse('$remoteUrl?page=$page&page_size=$pageSize'),
        timeout: const Duration(seconds: 12),
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Original method - kept for backward compatibility
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
