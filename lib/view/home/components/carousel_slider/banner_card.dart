import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../extention/image_url_helper.dart';

class BannerCard extends StatelessWidget {
  final String imageUrl;
  const BannerCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: CachedNetworkImage(
            imageUrl: getFullImageUrl(imageUrl),
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Shimmer.fromColors(
                  highlightColor: Colors.white,
                  baseColor: Colors.grey.shade300,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
            fit: BoxFit.cover,
            width: double.infinity,
            memCacheWidth: 800,
            memCacheHeight: 450,
            maxWidthDiskCache: 1200,
            maxHeightDiskCache: 675,
          ),
        ),
      ),
    );
  }
}
