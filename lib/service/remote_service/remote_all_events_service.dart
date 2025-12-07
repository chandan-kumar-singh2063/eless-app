import 'dart:convert';
import '../../const.dart';
import '../../model/event.dart';
import 'package:eless/service/remote_service/http_client_service.dart';

class RemoteAllEventsService {
  final _httpClient = HttpClientService.instance;
  var remoteUrl = '$baseUrl/events/api/flutter/all';

  Future<Map<String, dynamic>> getAllEvents() async {
    try {
      var response = await _httpClient.get(
        Uri.parse('$remoteUrl/'),
        headers: {'Content-Type': 'application/json'},
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        List<Event> ongoingEvents = [];
        List<Event> upcomingEvents = [];
        List<Event> pastEvents = [];

        if (jsonData['ongoing'] != null) {
          ongoingEvents = (jsonData['ongoing'] as List)
              .map((event) => Event.ongoingEventFromJson(event))
              .toList();
        }

        if (jsonData['upcoming'] != null) {
          upcomingEvents = (jsonData['upcoming'] as List)
              .map((event) => Event.upcomingEventFromJson(event))
              .toList();
        }

        if (jsonData['past'] != null) {
          pastEvents = (jsonData['past'] as List)
              .map((event) => Event.pastEventFromJson(event))
              .toList();
        }

        return {
          'success': true,
          'ongoing': ongoingEvents,
          'upcoming': upcomingEvents,
          'past': pastEvents,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch events',
          'ongoing': <Event>[],
          'upcoming': <Event>[],
          'past': <Event>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'ongoing': <Event>[],
        'upcoming': <Event>[],
        'past': <Event>[],
      };
    }
  }
}
