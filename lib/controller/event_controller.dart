import 'package:get/get.dart';
import 'package:eless/model/event.dart';
import 'package:eless/service/local_service/local_event_service.dart';
import 'package:eless/service/local_service/local_badge_service.dart';
import 'package:eless/service/remote_service/remote_ongoing_event_service.dart';
import 'package:eless/service/remote_service/remote_upcoming_event_service.dart';
import 'package:eless/service/remote_service/remote_past_event_service.dart';
import 'package:eless/service/remote_service/remote_all_events_service.dart';

class EventController extends GetxController {
  static EventController instance = Get.find();

  // Individual event lists
  RxList<Event> ongoingEventList = List<Event>.empty(growable: true).obs;
  RxList<Event> upcomingEventList = List<Event>.empty(growable: true).obs;
  RxList<Event> pastEventList = List<Event>.empty(growable: true).obs;

  // Combined lists for explore screen
  RxList<Event> allEventsList = List<Event>.empty(growable: true).obs;
  RxList<Event> filteredEventsList = List<Event>.empty(growable: true).obs;

  // Loading states
  RxBool isOngoingEventLoading = false.obs;
  RxBool isUpcomingEventLoading = false.obs;
  RxBool isPastEventLoading = false.obs;
  RxBool isAllEventsLoading = false.obs;

  final LocalEventService _localEventService = LocalEventService();
  final LocalBadgeService _badgeService = LocalBadgeService();
  final RemoteAllEventsService _remoteAllEventsService =
      RemoteAllEventsService();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localEventService.init();
    await _badgeService.init();
    _loadCachedEvents(); // Load from cache first for instant UI

    // Fetch fresh data in background (don't block initialization)
    getAllEvents().catchError((e) {
      // User still sees cached data, no error shown
    });
  }

  // Method to fetch fresh data from API (called on pull-to-refresh)
  Future<void> getAllEvents() async {
    try {
      isAllEventsLoading(true);

      // Load from cache first (instant UI)
      _loadCachedEvents();

      // Try to get all events from a single API call
      var result = await _remoteAllEventsService.getAllEvents();

      if (result['success'] == true) {
        // Update individual lists
        ongoingEventList.assignAll(result['ongoing']);
        upcomingEventList.assignAll(result['upcoming']);
        pastEventList.assignAll(result['past']);

        // Save to local storage
        _localEventService.assignAllOngoingEvents(events: result['ongoing']);
        _localEventService.assignAllUpcomingEvents(events: result['upcoming']);
        _localEventService.assignAllPastEvents(events: result['past']);

        // Combine all events
        _combineAllEvents();
      } else {
        // Fallback to individual API calls if the combined API fails
        await Future.wait([
          _fetchOngoingEvents(),
          _fetchUpcomingEvents(),
          _fetchPastEvents(),
        ]);
        _combineAllEvents();
      }
    } finally {
      isAllEventsLoading(false);
    }
  }

  void _loadCachedEvents() {
    if (_localEventService.getOngoingEvents().isNotEmpty) {
      ongoingEventList.assignAll(_localEventService.getOngoingEvents());
    }
    if (_localEventService.getUpcomingEvents().isNotEmpty) {
      upcomingEventList.assignAll(_localEventService.getUpcomingEvents());
    }
    if (_localEventService.getPastEvents().isNotEmpty) {
      pastEventList.assignAll(_localEventService.getPastEvents());
    }
    _combineAllEvents();
  }

  void _combineAllEvents() {
    List<Event> combined = [];
    combined.addAll(ongoingEventList);
    combined.addAll(upcomingEventList);
    combined.addAll(pastEventList);

    // Sort by date (newest first)
    combined.sort((a, b) => b.date.compareTo(a.date));

    allEventsList.assignAll(combined);
    filteredEventsList.assignAll(combined);
  }

  Future<void> _fetchOngoingEvents() async {
    try {
      var result = await RemoteOngoingEventService().get();
      if (result != null && result.statusCode == 200) {
        ongoingEventList.assignAll(ongoingEventListFromJson(result.body));
        _localEventService.assignAllOngoingEvents(
          events: ongoingEventListFromJson(result.body),
        );
      }
    } catch (e) {
    }
  }

  Future<void> _fetchUpcomingEvents() async {
    try {
      var result = await RemoteUpcomingEventService().get();
      if (result != null && result.statusCode == 200) {
        upcomingEventList.assignAll(upcomingEventListFromJson(result.body));
        _localEventService.assignAllUpcomingEvents(
          events: upcomingEventListFromJson(result.body),
        );
      }
    } catch (e) {
    }
  }

  Future<void> _fetchPastEvents() async {
    try {
      var result = await RemotePastEventService().get();
      if (result != null && result.statusCode == 200) {
        pastEventList.assignAll(pastEventListFromJson(result.body));
        _localEventService.assignAllPastEvents(
          events: pastEventListFromJson(result.body),
        );
      }
    } catch (e) {
    }
  }

  void getOngoingEvents() async {
    try {
      isOngoingEventLoading(true);
      //assigning local events before call api
      if (_localEventService.getOngoingEvents().isNotEmpty) {
        ongoingEventList.assignAll(_localEventService.getOngoingEvents());
      }
      //call api
      var result = await RemoteOngoingEventService().get();
      if (result != null && result.statusCode == 200) {
        //assign api result
        ongoingEventList.assignAll(ongoingEventListFromJson(result.body));
        //save api result to local db
        _localEventService.assignAllOngoingEvents(
          events: ongoingEventListFromJson(result.body),
        );
      }
    } catch (e) {
      // If API fails, we still have cached data loaded above
    } finally {
      isOngoingEventLoading(false);
    }
  }

  void getUpcomingEvents() async {
    try {
      isUpcomingEventLoading(true);
      if (_localEventService.getUpcomingEvents().isNotEmpty) {
        upcomingEventList.assignAll(_localEventService.getUpcomingEvents());
      }
      var result = await RemoteUpcomingEventService().get();
      if (result != null && result.statusCode == 200) {
        upcomingEventList.assignAll(upcomingEventListFromJson(result.body));
        _localEventService.assignAllUpcomingEvents(
          events: upcomingEventListFromJson(result.body),
        );
      }
    } finally {
      isUpcomingEventLoading(false);
    }
  }

  void getPastEvents() async {
    try {
      isPastEventLoading(true);
      if (_localEventService.getPastEvents().isNotEmpty) {
        pastEventList.assignAll(_localEventService.getPastEvents());
      }
      var result = await RemotePastEventService().get();
      if (result != null && result.statusCode == 200) {
        pastEventList.assignAll(pastEventListFromJson(result.body));
        _localEventService.assignAllPastEvents(
          events: pastEventListFromJson(result.body),
        );
      }
    } finally {
      isPastEventLoading(false);
    }
  }

  /// Mark event as viewed (called when user opens event details)
  void markEventAsViewed(int eventId) {
    _badgeService.markEventAsViewed(eventId);
    // Trigger UI update by reassigning filtered list
    filteredEventsList.refresh();
  }

  /// Check if event should show "new" badge
  bool shouldShowNewBadge(Event event) {
    // Show badge if backend marked as new AND user hasn't viewed it yet
    return event.isNew && !_badgeService.isEventViewed(event.id);
  }
}
