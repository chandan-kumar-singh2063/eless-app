import 'package:flutter/material.dart';
import 'package:eless/view/home/components/past_event/past_event_card.dart';
import '../../../../model/event.dart';

class PastEvent extends StatelessWidget {
  final List<Event> events;
  const PastEvent({super.key, required this.events});

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
        itemBuilder: (context, index) => PastEventCard(
          key: ValueKey(events[index].id),
          event: events[index],
        ),
      ),
    );
  }
}
