import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'device_loading_card.dart';

class DeviceLoadingGrid extends StatelessWidget {
  const DeviceLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 2/3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10
      ),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(10),
      itemCount: 10,
      itemBuilder: (context, index) => const DeviceLoadingCard(),
    );
  }
}
