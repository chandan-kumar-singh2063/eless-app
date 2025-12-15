import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/component/main_header.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/view/Explore/components/explore_event_card.dart';
import 'package:eless/view/Explore/components/explore_event_loading_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

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
    // Guard 1: Prevent duplicate calls while loading
    if (_isLoadingMore) return;

    // Guard 2: Check if more data available before calculating position
    if (!eventController.hasMoreData.value) return;

    // Guard 3: Only trigger when close to bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _isLoadingMore = true;
      eventController.loadMoreAllEvents().then((_) {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

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
                  final controller = eventController;

                  // ⚡ Optimistic UI: Show shimmer ONLY when truly empty
                  // During refresh, keep showing existing data (Instagram pattern)
                  if (controller.filteredEventsList.isEmpty) {
                    // Show shimmer only during initial load, not refresh
                    if (controller.isAllEventsLoading.value) {
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: 6,
                        itemBuilder: (context, index) =>
                            const ExploreEventLoadingCard(),
                      );
                    }
                    return _buildEmptyState(context);
                  }

                  // ⚡ Optimized: Use CustomScrollView with SliverList
                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 500, // Preload 500px for smooth scrolling
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ExploreEventCard(
                              event: controller.filteredEventsList[index],
                            );
                          },
                          childCount: controller.filteredEventsList.length,
                          addAutomaticKeepAlives: false, // Save memory
                          addRepaintBoundaries: true,
                        ),
                      ),
                      // Loading indicator as separate sliver
                      if (controller.hasMoreData.value)
                        SliverToBoxAdapter(
                          child: Obx(
                            () => controller.isLoadingMore.value
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.lightPrimaryColor,
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 20),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
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
        ),
      ),
    );
  }
}
