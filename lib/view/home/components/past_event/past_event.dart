import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/view/home/components/past_event/past_event_card.dart';
import 'package:eless/controller/controllers.dart';
import '../../../../model/event.dart';

class PastEvent extends StatefulWidget {
  final List<Event> events;
  const PastEvent({super.key, required this.events});

  @override
  State<PastEvent> createState() => _PastEventState();
}

class _PastEventState extends State<PastEvent> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200px from the end
      eventController.loadMorePastEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: (screenWidth * 0.18).clamp(120, 160),
      padding: const EdgeInsets.only(right: 10),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount:
            widget.events.length + (eventController.hasMorePast.value ? 1 : 0),
        cacheExtent: 500,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index == widget.events.length) {
            return Obx(
              () => eventController.isLoadingMorePast.value
                  ? Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink(),
            );
          }

          return PastEventCard(
            key: ValueKey(widget.events[index].id),
            event: widget.events[index],
          );
        },
      ),
    );
  }
}
