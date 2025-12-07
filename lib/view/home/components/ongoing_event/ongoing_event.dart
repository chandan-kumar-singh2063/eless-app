import 'package:flutter/material.dart';
import 'package:eless/model/event.dart';
import 'ongoing_event_card.dart';

class OngoingEvent extends StatelessWidget {
  final List<Event> events;
  const OngoingEvent({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: (screenWidth * 0.18).clamp(120, 160),
      padding: const EdgeInsets.only(right: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: events.length,
        cacheExtent: 500,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) => OngoingEventCard(
          key: ValueKey(events[index].id),
          event: events[index],
        ),
      ),
    );
  }
}
