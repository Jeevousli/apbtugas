/// Enum for categorizing GPS-related error types.
enum GpsErrorType {
  /// The device's location service is turned off.
  locationServiceDisabled,

  /// The user denied location permission.
  permissionDenied,

  /// The user permanently denied location permission (must open Settings).
  permissionDeniedForever,

  /// An unexpected error occurred while fetching the location.
  locationFetchFailed,
}

/// Custom exception thrown by [GPSValidator] on failure scenarios.
class GpsException implements Exception {
  /// Human-readable description of the error.
  final String message;

  /// The category of this GPS error.
  final GpsErrorType type;

  const GpsException({
    required this.message,
    required this.type,
  });

  // ── Factory constructors for each error scenario ──────────────────────────

  factory GpsException.locationServiceDisabled() => const GpsException(
        message:
            'Location services are disabled. Please enable GPS on your device.',
        type: GpsErrorType.locationServiceDisabled,
      );

  factory GpsException.permissionDenied() => const GpsException(
        message:
            'Location permission denied. Please allow location access to continue.',
        type: GpsErrorType.permissionDenied,
      );

  factory GpsException.permissionDeniedForever() => const GpsException(
        message:
            'Location permission permanently denied. '
            'Please open Settings and grant location access.',
        type: GpsErrorType.permissionDeniedForever,
      );

  factory GpsException.locationFetchFailed([String? detail]) => GpsException(
        message:
            'Failed to retrieve current location. ${detail ?? 'Please try again.'}',
        type: GpsErrorType.locationFetchFailed,
      );

  @override
  String toString() => 'GpsException(${type.name}): $message';
}
