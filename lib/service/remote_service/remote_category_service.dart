import 'package:http/http.dart' as http;
import 'package:eless/const.dart';
import 'dart:developer';

class RemoteCategoryService {
  var client = http.Client();
  var remoteUrl = '$baseUrl/api/categories';

  Future<dynamic> get() async {
    try {
      log('🌐 Fetching categories from: $remoteUrl?populate=image');
      var response = await client.get(Uri.parse('$remoteUrl?populate=image'));
      log('📦 Category response status: ${response.statusCode}');
      log(
        '📦 Category response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        return response;
      } else {
        log('❌ Category API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('❌ Category fetch error: $e');
      return null;
    }
  }
}
