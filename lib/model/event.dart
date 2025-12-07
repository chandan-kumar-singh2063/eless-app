import 'dart:convert';
import 'package:hive/hive.dart';

part 'event.g.dart';

List<Event> ongoingEventListFromJson(String val) => List<Event>.from(
  json.decode(val).map((val) => Event.ongoingEventFromJson(val)),
);

List<Event> upcomingEventListFromJson(String val) => List<Event>.from(
  json.decode(val).map((val) => Event.upcomingEventFromJson(val)),
);

List<Event> pastEventListFromJson(String val) => List<Event>.from(
  json.decode(val).map((val) => Event.pastEventFromJson(val)),
);

@HiveType(typeId: 5)
class Event {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String image;
  @HiveField(4)
  final String date;
  @HiveField(5)
  final String time;
  @HiveField(6)
  final String location;
  @HiveField(7)
  final String status;
  @HiveField(8)
  final String registrationStatus;
  @HiveField(9)
  final String registrationUrl;
  @HiveField(10)
  final bool isNew; // Backend sends this to indicate new event

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.registrationStatus,
    required this.registrationUrl,
    this.isNew = false, // Default to false if backend doesn't send it
  });

  factory Event.ongoingEventFromJson(Map<String, dynamic> data) => Event(
    id: data['id'],
    title: data['title'],
    description: data['description'],
    image: data['image'] ?? '',
    date: data['date'],
    time: data['time'] ?? '',
    location: data['location'],
    status: 'ongoing',
    registrationStatus: data['registration_status'] ?? 'no_registration',
    registrationUrl: data['registration_url'] ?? '',
    isNew: data['is_new'] ?? false,
  );

  factory Event.upcomingEventFromJson(Map<String, dynamic> data) => Event(
    id: data['id'],
    title: data['title'],
    description: data['description'],
    image: data['image'] ?? '',
    date: data['date'],
    time: data['time'] ?? '',
    location: data['location'],
    status: 'upcoming',
    registrationStatus: data['registration_status'] ?? 'no_registration',
    registrationUrl: data['registration_url'] ?? '',
    isNew: data['is_new'] ?? false,
  );

  factory Event.pastEventFromJson(Map<String, dynamic> data) => Event(
    id: data['id'],
    title: data['title'],
    description: data['description'],
    image: data['image'] ?? '',
    date: data['date'],
    time: data['time'] ?? '',
    location: data['location'],
    status: 'past',
    registrationStatus: data['registration_status'] ?? 'no_registration',
    registrationUrl: data['registration_url'] ?? '',
    isNew: data['is_new'] ?? false,
  );
}
