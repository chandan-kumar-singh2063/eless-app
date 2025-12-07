import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;
import '../../../extention/image_url_helper.dart';
import '../../../model/event.dart';
import '../../../theme/app_theme.dart';
import '../../../controller/event_controller.dart';

class ExploreEventCard extends StatelessWidget {
  final Event event;

  const ExploreEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GetBuilder<EventController>(
        builder: (controller) => badges.Badge(
          showBadge: controller.shouldShowNewBadge(event),
          position: badges.BadgePosition.topStart(top: 8, start: 8),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red,
            padding: EdgeInsets.all(6),
          ),
          child: InkWell(
            onTap: () {
              _navigateToEventDetails();
            },
            child: CachedNetworkImage(
              imageUrl: getFullImageUrl(event.image),
              imageBuilder: (context, imageProvider) => Material(
                elevation: 6,
                shadowColor: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.hardEdge,
                child: Container(
                  width: double.infinity,
                  height: (MediaQuery.of(context).size.height * 0.22).clamp(
                    180,
                    220,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(
                                event.status == 'past' ? 0.8 : 0.7,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Fade overlay for past events
                      if (event.status == 'past')
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),

                      // Registration badge for upcoming events only (matches home page logic)
                      if (event.status == 'upcoming' &&
                          event.registrationStatus.isNotEmpty &&
                          event.registrationStatus != 'no_registration')
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  event.registrationStatus.toLowerCase() ==
                                      'open'
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.registrationStatus.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Event details at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              placeholder: (context, url) => Material(
                elevation: 6,
                shadowColor: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.white,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Material(
                elevation: 6,
                shadowColor: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEventDetails() {
    // Mark event as viewed when user opens it
    EventController.instance.markEventAsViewed(event.id);
    switch (event.status) {
      case 'ongoing':
        Get.toNamed('/ongoing-event-details', arguments: event);
        break;
      case 'upcoming':
        Get.toNamed('/upcoming-event-details', arguments: event);
        break;
      case 'past':
        Get.toNamed('/past-event-details', arguments: event);
        break;
      default:
        Get.toNamed('/ongoing-event-details', arguments: event);
    }
  }
}
