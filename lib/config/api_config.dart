class ApiConfig {
  // Base URL for your Django API (Production)
  static const String baseUrl = "https://ckseless.me";

  // Base URL for Cloudinary images (consistent with your Django setup)
  static const String imageBaseUrl = "https://res.cloudinary.com";

  // API Endpoints (based on your Django URLs)
  static const String notificationsEndpoint =
      "/notifications/api/notifications/";
  static const String servicesEndpoint = "/services/api/flutter/all/";
  static const String eventsEndpoint = "/events/api/events/";
  static const String aboutEndpoint = "/about/api/members/";

  // Helper method to construct full image URLs
  // Django returns relative paths like "/v1_1/your-cloud/image/upload/sample.jpg"
  static String getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) {
      return relativePath; // Already full URL
    }
    return '$imageBaseUrl$relativePath';
  }

  // Helper method to construct full API URLs
  static String getFullApiUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
