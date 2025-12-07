import 'package:eless/const.dart';
import 'package:eless/service/remote_service/http_client_service.dart';
import 'dart:developer';

class RemoteBannerService {
  final _httpClient = HttpClientService.instance;
  var remoteUrl = '$baseUrl/api/banners';

  Future<dynamic> get() async {
    try {
      log('🌐 Fetching banners from: $remoteUrl/?populate=image');
      var response = await _httpClient.get(
        Uri.parse('$remoteUrl/?populate=image'),
        timeout: const Duration(seconds: 10),
      );
      log('✅ Banner response: ${response.statusCode}');
      return response;
    } catch (e) {
      log('❌ Banner fetch error: $e');
      rethrow;
    }
  }
}
