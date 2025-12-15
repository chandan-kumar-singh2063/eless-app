/// JWT Token Model
/// Represents access and refresh tokens with expiry information
class JwtToken {
  final String accessToken;
  final String refreshToken;
  final int expiresIn; // seconds until access token expires
  final DateTime issuedAt;
  final Map<String, dynamic>? userData; // User data from login response

  JwtToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    DateTime? issuedAt,
    this.userData,
  }) : issuedAt = issuedAt ?? DateTime.now();

  /// Calculate when the access token expires
  DateTime get expiresAt => issuedAt.add(Duration(seconds: expiresIn));

  /// Check if access token is expired or about to expire (within threshold)
  bool isExpired({Duration threshold = const Duration(minutes: 2)}) {
    return DateTime.now().add(threshold).isAfter(expiresAt);
  }

  /// Check if token is valid (not expired with threshold)
  bool get isValid => !isExpired();

  /// Time remaining until expiry
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Factory constructor from JSON response
  factory JwtToken.fromJson(Map<String, dynamic> json) {
    return JwtToken(
      accessToken: json['access'] ?? '',
      refreshToken: json['refresh'] ?? '',
      expiresIn: json['expires_in'] ?? 3600, // default 1 hour
      userData: json['user'], // Extract user data if present
    );
  }

  /// Convert to JSON for storage (only refresh token should be stored)
  Map<String, dynamic> toJson() {
    return {
      'refresh': refreshToken,
      'expires_in': expiresIn,
      'issued_at': issuedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated access token (after refresh)
  JwtToken copyWithNewAccess({
    required String newAccessToken,
    required int newExpiresIn,
  }) {
    return JwtToken(
      accessToken: newAccessToken,
      refreshToken: refreshToken, // Keep same refresh token
      expiresIn: newExpiresIn,
      issuedAt: DateTime.now(),
      userData: userData, // Preserve user data
    );
  }

  @override
  String toString() {
    return 'JwtToken(expiresAt: $expiresAt, isValid: $isValid, timeLeft: ${timeUntilExpiry.inMinutes}m)';
  }
}

/// API Response wrapper for type-safe error handling
class ApiResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResult.success(this.data) : error = null, statusCode = 200;
  ApiResult.error(this.error, {this.statusCode}) : data = null;

  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;

  /// Execute different callbacks based on success/error
  R when<R>({
    required R Function(T data) success,
    required R Function(String error, {int? statusCode}) error,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return error(this.error ?? 'Unknown error', statusCode: statusCode);
    }
  }
}
