import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../extention/image_url_helper.dart';
import '../../../../model/event.dart';

class UpcomingEventCard extends StatelessWidget {
  final Event event;
  const UpcomingEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 10, 5, 10),
      child: InkWell(
        onTap: () {
          Get.toNamed('/upcoming-event-details', arguments: event);
        },
        child: CachedNetworkImage(
          imageUrl: getFullImageUrl(event.image),
          imageBuilder: (context, imageProvider) => Material(
            elevation: 8,
            shadowColor: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.hardEdge,
            child: Container(
              width: (MediaQuery.of(context).size.width * 0.7).clamp(250, 320),
              height: (MediaQuery.of(context).size.width * 0.18).clamp(
                120,
                160,
              ),
              color: Colors.grey.shade300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: imageProvider, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Registration status badge
                  if (event.registrationStatus.isNotEmpty &&
                      event.registrationStatus.toLowerCase() !=
                          'no_registration')
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              event.registrationStatus.toLowerCase() == 'open'
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
                  // Event title and date at bottom
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          placeholder: (context, url) => Material(
            elevation: 8,
            shadowColor: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.white,
              child: Container(
                width: (MediaQuery.of(context).size.width * 0.7).clamp(
                  250,
                  320,
                ),
                height: (MediaQuery.of(context).size.width * 0.18).clamp(
                  120,
                  160,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Material(
            elevation: 8,
            shadowColor: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: (MediaQuery.of(context).size.width * 0.7).clamp(250, 320),
              height: (MediaQuery.of(context).size.width * 0.18).clamp(
                120,
                160,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
