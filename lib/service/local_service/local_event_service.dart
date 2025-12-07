import 'package:hive/hive.dart';
import '../../model/event.dart';

class LocalEventService {
  late Box<Event> _ongoingEventBox;
  late Box<Event> _upcomingEventBox;
  late Box<Event> _pastEventBox;

  Future<void> init() async {
    try {
      _ongoingEventBox = await Hive.openBox<Event>('OngoingEvents');
      _upcomingEventBox = await Hive.openBox<Event>('UpcomingEvents');
      _pastEventBox = await Hive.openBox<Event>('PastEvents');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignAllOngoingEvents({required List<Event> events}) async {
    await _ongoingEventBox.clear();
    await _ongoingEventBox.addAll(events);
  }

  Future<void> assignAllUpcomingEvents({required List<Event> events}) async {
    await _upcomingEventBox.clear();
    await _upcomingEventBox.addAll(events);
  }

  Future<void> assignAllPastEvents({required List<Event> events}) async {
    await _pastEventBox.clear();
    await _pastEventBox.addAll(events);
  }

  List<Event> getOngoingEvents() => _ongoingEventBox.values.toList();
  List<Event> getUpcomingEvents() => _upcomingEventBox.values.toList();
  List<Event> getPastEvents() => _pastEventBox.values.toList();
}
