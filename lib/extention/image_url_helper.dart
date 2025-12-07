/// Helper function to construct proper image URLs from Django API responses
///
/// Django returns Cloudinary paths in format: /cloudname/image/upload/v123/path.jpg
/// This function converts them to: https://res.cloudinary.com/cloudname/image/upload/v123/path.jpg
library;

String getFullImageUrl(String? imagePath) {
  // Handle null or empty paths
  if (imagePath == null || imagePath.isEmpty) {
    return '';
  }

  // If already a full URL, return as-is
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }

  // If it's a Cloudinary path (contains /image/upload/)
  // Format: /cloudname/image/upload/v123/path.jpg
  // Should become: https://res.cloudinary.com/cloudname/image/upload/v123/path.jpg
  if (imagePath.contains('/image/upload/')) {
    return 'https://res.cloudinary.com$imagePath';
  }

  // For relative paths that aren't Cloudinary, use the base URL
  // (though this shouldn't happen with your Django setup)
  return imagePath;
}

/// Example usage:
/// ```dart
/// // In your widget:
/// CachedNetworkImage(
///   imageUrl: getFullImageUrl(device.image),
///   ...
/// )
/// ```
