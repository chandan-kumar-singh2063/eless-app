import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/component/main_header.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/home/components/ongoing_event/ongoing_event.dart';
import 'package:eless/view/home/components/upcoming_event/upcoming_event.dart';
import 'package:eless/view/home/components/past_event/past_event.dart';
import 'package:eless/view/home/components/ongoing_event/ongoing_event_loading.dart';
import 'package:eless/view/home/components/upcoming_event/upcoming_event_loading.dart';
import 'package:eless/view/home/components/past_event/past_event_loading.dart';
import 'package:eless/view/home/components/section_title.dart';

import 'components/carousel_slider/carousel_slider_view.dart';
import 'components/carousel_slider/carousel_loading.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const MainHeader(pageType: 'home'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    homeController.getAdBanners(),
                    eventController.getAllEvents(),
                  ]);
                },
                color: AppTheme.lightPrimaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Obx(() {
                        if (homeController.bannerList.isNotEmpty) {
                          return CarouselSliderView(
                            bannerList: homeController.bannerList,
                          );
                        } else {
                          return const CarouselLoading();
                        }
                      }),
                      const RepaintBoundary(
                        child: SectionTitle(title: "Ongoing Events"),
                      ),
                      Obx(() {
                        // Show shimmer only on initial load (when list is empty)
                        if (eventController.isAllEventsLoading.value &&
                            eventController.ongoingEventList.isEmpty) {
                          return const OngoingEventLoading();
                        } else if (eventController
                            .ongoingEventList
                            .isNotEmpty) {
                          return OngoingEvent(
                            events: eventController.ongoingEventList,
                          );
                        } else {
                          return _buildEmptyEventSection(
                            context,
                            'No ongoing events',
                          );
                        }
                      }),
                      const RepaintBoundary(
                        child: SectionTitle(title: "Upcoming Events"),
                      ),
                      Obx(() {
                        // Show shimmer only on initial load (when list is empty)
                        if (eventController.isAllEventsLoading.value &&
                            eventController.upcomingEventList.isEmpty) {
                          return const UpcomingEventLoading();
                        } else if (eventController
                            .upcomingEventList
                            .isNotEmpty) {
                          return UpcomingEvent(
                            events: eventController.upcomingEventList,
                          );
                        } else {
                          return _buildEmptyEventSection(
                            context,
                            'No upcoming events',
                          );
                        }
                      }),
                      const RepaintBoundary(
                        child: SectionTitle(title: "Past Events"),
                      ),
                      Obx(() {
                        // Show shimmer only on initial load (when list is empty)
                        if (eventController.isAllEventsLoading.value &&
                            eventController.pastEventList.isEmpty) {
                          return const PastEventLoading();
                        } else if (eventController.pastEventList.isNotEmpty) {
                          return PastEvent(
                            events: eventController.pastEventList,
                          );
                        } else {
                          return _buildEmptyEventSection(
                            context,
                            'No past events',
                          );
                        }
                      }),
                      const SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEventSection(BuildContext context, String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: (screenWidth * 0.18).clamp(120, 160),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
