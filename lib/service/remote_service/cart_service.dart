import 'dart:convert';

import 'package:eless/const.dart';
import 'package:eless/service/remote_service/http_client_service.dart';
import '../../model/cart_item.dart';

class CartService {
  final _httpClient = HttpClientService.instance;

  Future<List<CartItem>> getUserDeviceRequests({
    required String userUniqueId,
    int retryCount = 0,
  }) async {
    const maxRetries = 2;

    try {
      final endpoint = '$baseUrl/services/api/user/device-requests/';

      // Simple POST with user_unique_id - No JWT needed!
      var response = await _httpClient.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_unique_id': userUniqueId}),
        timeout: const Duration(seconds: 10),
      );


      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        // Handle response format
        List<dynamic> cartData;
        if (jsonData is Map && jsonData.containsKey('results')) {
          cartData = jsonData['results'];
        } else if (jsonData is List) {
          cartData = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          cartData = jsonData['data'];
        } else {
          return [];
        }

        return cartData.map((item) => CartItem.fromJson(item)).toList();
      } else {

        // Retry on server errors
        if (retryCount < maxRetries && response.statusCode >= 500) {
          await Future.delayed(Duration(seconds: retryCount + 1));
          return getUserDeviceRequests(
            userUniqueId: userUniqueId,
            retryCount: retryCount + 1,
          );
        }

        return [];
      }
    } catch (e) {

      // Retry on network errors
      if (retryCount < maxRetries && e.toString().contains('Timeout')) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return getUserDeviceRequests(
          userUniqueId: userUniqueId,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCartSummary({
    required String userUniqueId,
    int retryCount = 0,
  }) async {
    const maxRetries = 2;
    const defaultSummary = {
      'total_requests': 0,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
    };

    try {
      final endpoint = '$baseUrl/services/api/user/device-requests/summary/';

      var response = await _httpClient.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_unique_id': userUniqueId}),
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        return jsonData;
      } else {

        // Retry on server errors
        if (retryCount < maxRetries && response.statusCode >= 500) {
          await Future.delayed(Duration(seconds: retryCount + 1));
          return getCartSummary(
            userUniqueId: userUniqueId,
            retryCount: retryCount + 1,
          );
        }

        return defaultSummary;
      }
    } catch (e) {

      // Retry on network errors
      if (retryCount < maxRetries && e.toString().contains('Timeout')) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return getCartSummary(
          userUniqueId: userUniqueId,
          retryCount: retryCount + 1,
        );
      }

      return defaultSummary;
    }
  }
}
