import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'ongoing_event_loading_card.dart';

class OngoingEventLoading extends StatelessWidget {
  const OngoingEventLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: (screenWidth * 0.18).clamp(120, 160),
      padding: const EdgeInsets.only(right: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => const OngoingEventLoadingCard(),
      ),
    );
  }
}
