import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../extention/image_url_helper.dart';
import '../../model/event.dart';

class UpcomingEventDetailsScreen extends StatelessWidget {
  final Event event;
  const UpcomingEventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: (MediaQuery.of(context).size.height * 0.3).clamp(
                    200.0,
                    350.0,
                  ),
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: getFullImageUrl(event.image),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      highlightColor: Colors.white,
                      baseColor: Colors.grey.shade300,
                      child: Container(color: Colors.grey.shade300),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Text(
                        'UPCOMING',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(Icons.calendar_today, 'Date', event.date),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.access_time, 'Time', event.time),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Venue', event.location),
                    const SizedBox(height: 12),
                    if (event.registrationStatus.isNotEmpty)
                      _buildRegistrationStatusRow(),
                    const SizedBox(height: 20),
                    Text(
                      'About this event:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 24),
                    // Register button inside scroll view
                    if (event.registrationStatus.toLowerCase() == 'open')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final String rawUrl = event.registrationUrl.trim();
                            if (rawUrl.isNotEmpty) {
                              try {
                                final String normalizedUrl =
                                    rawUrl.startsWith('http://') ||
                                        rawUrl.startsWith('https://')
                                    ? rawUrl
                                    : 'https://$rawUrl';

                                final bool launched = await launchUrlString(
                                  normalizedUrl,
                                  mode: LaunchMode.externalApplication,
                                );

                                if (!launched) {
                                  Get.snackbar(
                                    'Error',
                                    'Cannot open registration URL',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              } on FormatException {
                                Get.snackbar(
                                  'Error',
                                  'Invalid registration URL format',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  'Something went wrong opening the link',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            } else {
                              Get.snackbar(
                                'Registration',
                                'Registration URL not available',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                            }
                          },
                          child: const Text(
                            'Register for Event',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationStatusRow() {
    bool isOpen = event.registrationStatus.toLowerCase() == 'open';
    return Row(
      children: [
        Icon(Icons.how_to_reg, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        const Text(
          'Registration: ',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOpen ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event.registrationStatus.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
