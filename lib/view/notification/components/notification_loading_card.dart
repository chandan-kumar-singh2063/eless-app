import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NotificationLoadingCard extends StatelessWidget {
  const NotificationLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge placeholder
              Shimmer.fromColors(
                highlightColor: Colors.white,
                baseColor: Colors.grey.shade300,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Content placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Shimmer.fromColors(
                      highlightColor: Colors.white,
                      baseColor: Colors.grey.shade300,
                      child: Container(
                        width: 80,
                        height: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle placeholder
                    Shimmer.fromColors(
                      highlightColor: Colors.white,
                      baseColor: Colors.grey.shade300,
                      child: Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Shimmer.fromColors(
                      highlightColor: Colors.white,
                      baseColor: Colors.grey.shade300,
                      child: Container(
                        width: 120,
                        height: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Timestamp placeholder
                    Shimmer.fromColors(
                      highlightColor: Colors.white,
                      baseColor: Colors.grey.shade300,
                      child: Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Administrator placeholder
                    Shimmer.fromColors(
                      highlightColor: Colors.white,
                      baseColor: Colors.grey.shade300,
                      child: Container(
                        width: 130,
                        height: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Thumbnail placeholder
              Shimmer.fromColors(
                highlightColor: Colors.white,
                baseColor: Colors.grey.shade300,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
