import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/model/event.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/theme/app_theme.dart';
import 'ongoing_event_card.dart';

class OngoingEvent extends StatefulWidget {
  final List<Event> events;
  const OngoingEvent({super.key, required this.events});

  @override
  State<OngoingEvent> createState() => _OngoingEventState();
}

class _OngoingEventState extends State<OngoingEvent> {
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
      eventController.loadMoreOngoingEvents();
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
            widget.events.length +
            (eventController.hasMoreOngoing.value ? 1 : 0),
        cacheExtent: 500,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index == widget.events.length) {
            return Obx(
              () => eventController.isLoadingMoreOngoing.value
                  ? Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.lightPrimaryColor,
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          }

          return OngoingEventCard(
            key: ValueKey(widget.events[index].id),
            event: widget.events[index],
          );
        },
      ),
    );
  }
}
