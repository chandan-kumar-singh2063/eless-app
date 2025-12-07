import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/component/main_header.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/Explore/components/explore_event_card.dart';
import 'package:eless/view/Explore/components/explore_event_loading_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const MainHeader(pageType: 'explore'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await eventController.getAllEvents();
                },
                color: AppTheme.lightPrimaryColor,
                child: Obx(() {
                  // Show shimmer loading during refresh OR initial load
                  if (eventController.isAllEventsLoading.value) {
                    // Show loading state when loading or refreshing
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: 6, // Show 6 loading cards
                      itemBuilder: (context, index) =>
                          const ExploreEventLoadingCard(),
                    );
                  } else if (eventController.filteredEventsList.isNotEmpty) {
                    // Show filtered events
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: eventController.filteredEventsList.length,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) => ExploreEventCard(
                        key: ValueKey(
                          eventController.filteredEventsList[index].id,
                        ),
                        event: eventController.filteredEventsList[index],
                      ),
                    );
                  } else {
                    // Show empty state
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: _buildEmptyState(),
                      ),
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No events available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new events',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
