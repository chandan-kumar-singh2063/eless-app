import 'package:flutter/material.dart';
import '../../../model/device.dart';
import './device_card.dart';

class DeviceGrid extends StatelessWidget {
  final List<Device> devices;
  const DeviceGrid({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(10),
      itemCount: devices.length,
      cacheExtent: 500,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      itemBuilder: (context, index) {
        return DeviceCard(
          key: ValueKey(devices[index].id),
          device: devices[index],
        );
      },
    );
  }
}
