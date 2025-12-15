import 'package:get/get.dart';
import 'package:eless/model/event.dart';
import 'package:eless/model/cancel_token.dart';
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

  // Pagination states for explore/all events
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreData = true.obs;
  RxBool isRefreshing = false.obs; // ⚡ Silent background refresh flag
  int currentPage = 1;
  final int pageSize = 10; // Load 10 events at a time

  // Pagination for individual sections (home screen)
  RxBool isLoadingMoreOngoing = false.obs;
  RxBool hasMoreOngoing = true.obs;
  int ongoingPage = 1;

  RxBool isLoadingMoreUpcoming = false.obs;
  RxBool hasMoreUpcoming = true.obs;
  int upcomingPage = 1;

  RxBool isLoadingMorePast = false.obs;
  RxBool hasMorePast = true.obs;
  int pastPage = 1;

  final LocalEventService _localEventService = LocalEventService();
  final LocalBadgeService _badgeService = LocalBadgeService();
  final RemoteAllEventsService _remoteAllEventsService =
      RemoteAllEventsService();

  // ⚡ Performance: In-memory cache to avoid repeated Hive reads
  List<Event>? _cachedOngoing;
  List<Event>? _cachedUpcoming;
  List<Event>? _cachedPast;
  DateTime? _lastFetchOngoing;
  DateTime? _lastFetchUpcoming;
  DateTime? _lastFetchPast;
  final CancelToken _cancelToken = CancelToken(); // ⚡ Cancel pending requests

  // ⚡ Cache sorted results to prevent re-sorting on every Obx rebuild
  List<Event>? _cachedSortedAll;
  int _lastSortedHash = 0; // Track if event lists changed

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _cancelToken.cancel(); // ⚡ Cancel any pending requests
    _cachedOngoing = null;
    _cachedUpcoming = null;
    _cachedPast = null;
    _lastFetchOngoing = null;
    _lastFetchUpcoming = null;
    _lastFetchPast = null;
    _cachedSortedAll = null; // Clear sorted cache
    super.onClose();
  }

  Future<void> _initialize() async {
    await _localEventService.init();
    await _badgeService.init();
    _loadCachedEvents(); // Load from cache first for instant UI

    // Fetch fresh data in background (don't block initialization)
    // Load only first page initially
    getAllEventsFirstPage().catchError((e) {
      // User still sees cached data, no error shown
    });
  }

  // Initial load - gets first page only
  Future<void> getAllEventsFirstPage() async {
    try {
      isAllEventsLoading(true);
      currentPage = 1;
      hasMoreData.value = true;

      // Load from cache first (instant UI)
      _loadCachedEvents();

      // Fetch first page from API
      await _fetchAllEventsPage(page: 1, isRefresh: true);
    } finally {
      isAllEventsLoading(false);
    }
  }

  // Load more events (pagination)
  Future<void> loadMoreAllEvents() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    try {
      isLoadingMore(true);
      currentPage++;
      await _fetchAllEventsPage(page: currentPage, isRefresh: false);
    } finally {
      isLoadingMore(false);
    }
  }

  Future<void> _fetchAllEventsPage({
    required int page,
    required bool isRefresh,
  }) async {
    try {
      var result = await _remoteAllEventsService.getAllEventsPaginated(
        page: page,
        pageSize: pageSize,
      );

      if (result['success'] == true) {
        final ongoing = result['ongoing'] as List<Event>;
        final upcoming = result['upcoming'] as List<Event>;
        final past = result['past'] as List<Event>;

        // Check if we got less data than page size (last page)
        final totalReceived = ongoing.length + upcoming.length + past.length;
        if (totalReceived < pageSize) {
          hasMoreData.value = false;
        }

        if (isRefresh) {
          // Replace all data (refresh)
          ongoingEventList.assignAll(ongoing);
          upcomingEventList.assignAll(upcoming);
          pastEventList.assignAll(past);

          // ⚡ Update memory cache immediately
          _cachedOngoing = List.from(ongoingEventList);
          _cachedUpcoming = List.from(upcomingEventList);
          _cachedPast = List.from(pastEventList);

          // ⚡ Batch write to Hive (only on refresh, not on pagination)
          _localEventService.assignAllOngoingEvents(events: ongoingEventList);
          _localEventService.assignAllUpcomingEvents(events: upcomingEventList);
          _localEventService.assignAllPastEvents(events: pastEventList);
        } else {
          // Append data (pagination)
          ongoingEventList.addAll(ongoing);
          upcomingEventList.addAll(upcoming);
          pastEventList.addAll(past);

          // ⚡ Update memory cache without disk write (save I/O)
          _cachedOngoing = List.from(ongoingEventList);
          _cachedUpcoming = List.from(upcomingEventList);
          _cachedPast = List.from(pastEventList);
        }

        // Combine all events
        _combineAllEvents();
      }
    } catch (e) {
      // Error handling
      if (page == 1) {
        // First page error - show cached data
        _loadCachedEvents();
      }
    }
  }

  // Method to fetch fresh data from API (called on pull-to-refresh)
  // ⚡ Optimized: Silent refresh without clearing existing data
  Future<void> getAllEvents() async {
    try {
      isRefreshing(true);
      currentPage = 1;
      hasMoreData.value = true;

      // Keep showing cached data while fetching (Instagram pattern)
      // Don't call _loadCachedEvents() - data already visible

      // Fetch first page silently in background
      await _fetchAllEventsPage(page: 1, isRefresh: true);
    } finally {
      isRefreshing(false);
    }
  }

  void _loadCachedEvents() {
    // ⚡ Load ongoing events with TTL
    if (_cachedOngoing != null && _lastFetchOngoing != null) {
      final cacheAge = DateTime.now().difference(_lastFetchOngoing!);
      if (cacheAge.inMinutes < 5) {
        ongoingEventList.assignAll(_cachedOngoing!);
      } else {
        final events = _localEventService.getOngoingEvents();
        if (events.isNotEmpty) {
          _cachedOngoing = events;
          _lastFetchOngoing = DateTime.now();
          ongoingEventList.assignAll(events);
        }
      }
    } else if (_localEventService.getOngoingEvents().isNotEmpty) {
      final events = _localEventService.getOngoingEvents();
      _cachedOngoing = events;
      _lastFetchOngoing = DateTime.now();
      ongoingEventList.assignAll(events);
    }

    // ⚡ Load upcoming events with TTL
    if (_cachedUpcoming != null && _lastFetchUpcoming != null) {
      final cacheAge = DateTime.now().difference(_lastFetchUpcoming!);
      if (cacheAge.inMinutes < 5) {
        upcomingEventList.assignAll(_cachedUpcoming!);
      } else {
        final events = _localEventService.getUpcomingEvents();
        if (events.isNotEmpty) {
          _cachedUpcoming = events;
          _lastFetchUpcoming = DateTime.now();
          upcomingEventList.assignAll(events);
        }
      }
    } else if (_localEventService.getUpcomingEvents().isNotEmpty) {
      final events = _localEventService.getUpcomingEvents();
      _cachedUpcoming = events;
      _lastFetchUpcoming = DateTime.now();
      upcomingEventList.assignAll(events);
    }

    // ⚡ Load past events with TTL
    if (_cachedPast != null && _lastFetchPast != null) {
      final cacheAge = DateTime.now().difference(_lastFetchPast!);
      if (cacheAge.inMinutes < 5) {
        pastEventList.assignAll(_cachedPast!);
      } else {
        final events = _localEventService.getPastEvents();
        if (events.isNotEmpty) {
          _cachedPast = events;
          _lastFetchPast = DateTime.now();
          pastEventList.assignAll(events);
        }
      }
    } else if (_localEventService.getPastEvents().isNotEmpty) {
      final events = _localEventService.getPastEvents();
      _cachedPast = events;
      _lastFetchPast = DateTime.now();
      pastEventList.assignAll(events);
    }

    _combineAllEvents();
  }

  void _combineAllEvents() {
    // ⚡ Calculate hash of event lists to detect changes
    final currentHash =
        ongoingEventList.length * 1000 +
        upcomingEventList.length * 100 +
        pastEventList.length;

    // ⚡ Return cached sorted list if events haven't changed
    if (_cachedSortedAll != null && currentHash == _lastSortedHash) {
      allEventsList.assignAll(_cachedSortedAll!);
      return;
    }

    List<Event> combined = [];
    combined.addAll(ongoingEventList);
    combined.addAll(upcomingEventList);
    combined.addAll(pastEventList);

    // Sort by date (newest first) - Latest dates at top, past dates at bottom
    // Parse date strings to DateTime for proper date comparison
    combined.sort((a, b) {
      try {
        // Try to parse dates as DateTime objects for proper comparison
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);

        // Compare: newest first (descending order)
        // Returns negative if dateB is before dateA (b should come before a)
        // Returns positive if dateB is after dateA (a should come before b)
        return dateB.compareTo(dateA);
      } catch (e) {
        // If date parsing fails, fall back to string comparison
        // This handles cases where date format might be different
        return b.date.compareTo(a.date);
      }
    });

    // ⚡ Cache the sorted result
    _cachedSortedAll = combined;
    _lastSortedHash = currentHash;

    allEventsList.assignAll(combined);
    filteredEventsList.assignAll(combined);
  }

  // Pagination for home screen - ongoing events
  Future<void> loadMoreOngoingEvents() async {
    if (isLoadingMoreOngoing.value || !hasMoreOngoing.value) return;

    try {
      isLoadingMoreOngoing(true);
      final nextPage = ongoingPage + 1; // Calculate next page

      var result = await RemoteOngoingEventService().getPaginated(
        page: nextPage,
        pageSize: pageSize,
      );

      if (result != null && result.statusCode == 200) {
        final newEvents = ongoingEventListFromJson(result.body);
        if (newEvents.length < pageSize) {
          hasMoreOngoing.value = false;
        }
        ongoingEventList.addAll(newEvents);
        ongoingPage = nextPage; // ✅ Only increment AFTER successful fetch
      } else {
        hasMoreOngoing.value = false;
      }
    } catch (e) {
      // ⚡ Error: Page stays same, user can retry
    } finally {
      isLoadingMoreOngoing(false);
    }
  }

  // Pagination for home screen - upcoming events
  Future<void> loadMoreUpcomingEvents() async {
    if (isLoadingMoreUpcoming.value || !hasMoreUpcoming.value) return;

    try {
      isLoadingMoreUpcoming(true);
      final nextPage = upcomingPage + 1; // Calculate next page

      var result = await RemoteUpcomingEventService().getPaginated(
        page: nextPage,
        pageSize: pageSize,
      );

      if (result != null && result.statusCode == 200) {
        final newEvents = upcomingEventListFromJson(result.body);
        if (newEvents.length < pageSize) {
          hasMoreUpcoming.value = false;
        }
        upcomingEventList.addAll(newEvents);
        upcomingPage = nextPage; // ✅ Only increment AFTER successful fetch
      } else {
        hasMoreUpcoming.value = false;
      }
    } catch (e) {
      // ⚡ Error: Page stays same, user can retry
    } finally {
      isLoadingMoreUpcoming(false);
    }
  }

  // Pagination for home screen - past events
  Future<void> loadMorePastEvents() async {
    if (isLoadingMorePast.value || !hasMorePast.value) return;

    try {
      isLoadingMorePast(true);
      final nextPage = pastPage + 1; // Calculate next page

      var result = await RemotePastEventService().getPaginated(
        page: nextPage,
        pageSize: pageSize,
      );

      if (result != null && result.statusCode == 200) {
        final newEvents = pastEventListFromJson(result.body);
        if (newEvents.length < pageSize) {
          hasMorePast.value = false;
        }
        pastEventList.addAll(newEvents);
        pastPage = nextPage; // ✅ Only increment AFTER successful fetch
      } else {
        hasMorePast.value = false;
      }
    } catch (e) {
      // ⚡ Error: Page stays same, user can retry
    } finally {
      isLoadingMorePast(false);
    }
  }

  // Initial load methods with pagination reset
  void getOngoingEvents() async {
    try {
      isOngoingEventLoading(true);
      ongoingPage = 1;
      hasMoreOngoing.value = true;

      //assigning local events before call api
      if (_localEventService.getOngoingEvents().isNotEmpty) {
        ongoingEventList.assignAll(_localEventService.getOngoingEvents());
      }
      //call api for first page
      var result = await RemoteOngoingEventService().getPaginated(
        page: 1,
        pageSize: pageSize,
      );
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
      upcomingPage = 1;
      hasMoreUpcoming.value = true;

      if (_localEventService.getUpcomingEvents().isNotEmpty) {
        upcomingEventList.assignAll(_localEventService.getUpcomingEvents());
      }
      var result = await RemoteUpcomingEventService().getPaginated(
        page: 1,
        pageSize: pageSize,
      );
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
      pastPage = 1;
      hasMorePast.value = true;

      if (_localEventService.getPastEvents().isNotEmpty) {
        pastEventList.assignAll(_localEventService.getPastEvents());
      }
      var result = await RemotePastEventService().getPaginated(
        page: 1,
        pageSize: pageSize,
      );
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
