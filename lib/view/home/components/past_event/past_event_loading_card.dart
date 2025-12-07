import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PastEventLoadingCard extends StatelessWidget {
  const PastEventLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
      child: Material(
        elevation: 8,
        shadowColor: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.white,
          child: Container(
            width: (MediaQuery.of(context).size.width * 0.7).clamp(250, 320),
            height: (MediaQuery.of(context).size.width * 0.18).clamp(120, 160),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
