import 'package:http/http.dart' as http;
import 'package:eless/const.dart';

class RemoteBannerService {
  var client = http.Client();
  var remoteUrl = '$baseUrl/api/banners';
  
  Future<Map<String, dynamic>> getBanners() async {
    try {
      var response = await client.get(
        Uri.parse('$remoteUrl?populate=image'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.body,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch banners: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  // Legacy method for backward compatibility with existing code
  Future<dynamic> get() async {
    var result = await getBanners();
    if (result['success']) {
      var response = http.Response(result['data'], 200);
      return response;
    }
    return null;
  }
}
