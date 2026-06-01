import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../core/errors/gps_exception.dart';
import '../../domain/entities/gps_status.dart';
import '../../domain/entities/gps_validation_result.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Abstraction – makes GPSValidator fully unit-testable by allowing
// IGeolocatorService to be swapped with a mock in tests.
// ═══════════════════════════════════════════════════════════════════════════

/// Abstract interface for device-location operations.
///
/// The real implementation wraps the [geolocator] plugin.
/// Tests inject a mock that never touches the hardware.
abstract class IGeolocatorService {
  /// Returns [true] when the device's location service is active.
  Future<bool> isLocationServiceEnabled();

  /// Returns the current [LocationPermission] status without prompting.
  Future<LocationPermission> checkPermission();

  /// Prompts the user for location permission and returns the result.
  Future<LocationPermission> requestPermission();

  /// Fetches the device's current [Position].
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Production implementation – thin wrapper around the geolocator plugin.
// ─────────────────────────────────────────────────────────────────────────────

/// Default [IGeolocatorService] that delegates to the [geolocator] plugin.
class GeolocatorServiceImpl implements IGeolocatorService {
  const GeolocatorServiceImpl();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) =>
      Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: desiredAccuracy),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// GPSValidator – main class
// ═══════════════════════════════════════════════════════════════════════════

/// Validates whether the user is within the office radius.
///
/// Usage:
/// ```dart
/// final validator = GPSValidator();
/// final result = await validator.validate();
/// if (result.isInsideArea) { /* allow clock-in */ }
/// ```
///
/// Office coordinates and radius can be overridden when constructing:
/// ```dart
/// final validator = GPSValidator(
///   officeLatitude: -6.2088,
///   officeLongitude: 106.8456,
///   radiusInMeters: 500,
/// );
/// ```
class GPSValidator {
  /// Latitude of the office. Default: -6.2088 (Jakarta)
  final double officeLatitude;

  /// Longitude of the office. Default: 106.8456 (Jakarta)
  final double officeLongitude;

  /// Maximum allowed distance from office in meters. Default: 500 m.
  final double radiusInMeters;

  final IGeolocatorService _geolocatorService;

  GPSValidator({
    this.officeLatitude = -6.2088,
    this.officeLongitude = 106.8456,
    this.radiusInMeters = 500,
    IGeolocatorService? geolocatorService,
  }) : _geolocatorService =
            geolocatorService ?? const GeolocatorServiceImpl();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Validates the user's current GPS location against the office radius.
  ///
  /// Returns a [GpsValidationResult] on success.
  /// Throws a [GpsException] on any location-related failure.
  Future<GpsValidationResult> validate() async {
    await _ensureServiceEnabled();
    await _ensurePermission();

    final position = await _fetchPosition();

    final distance = _haversineDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: officeLatitude,
      lon2: officeLongitude,
    );

    final status =
        distance <= radiusInMeters ? GpsStatus.inArea : GpsStatus.outsideArea;

    return GpsValidationResult(
      status: status,
      distanceInMeters: distance,
      userLatitude: position.latitude,
      userLongitude: position.longitude,
      officeLatitude: officeLatitude,
      officeLongitude: officeLongitude,
      timestamp: DateTime.now().toUtc(),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Throws [GpsException.locationServiceDisabled] if GPS is off.
  Future<void> _ensureServiceEnabled() async {
    final enabled = await _geolocatorService.isLocationServiceEnabled();
    if (!enabled) throw GpsException.locationServiceDisabled();
  }

  /// Checks and, if needed, requests location permission.
  ///
  /// Throws the appropriate [GpsException] when permission is absent.
  Future<void> _ensurePermission() async {
    LocationPermission permission =
        await _geolocatorService.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _geolocatorService.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw GpsException.permissionDenied();
    }
    if (permission == LocationPermission.deniedForever) {
      throw GpsException.permissionDeniedForever();
    }
  }

  /// Wraps [IGeolocatorService.getCurrentPosition] with error handling.
  Future<Position> _fetchPosition() async {
    try {
      return await _geolocatorService.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw GpsException.locationFetchFailed(e.toString());
    }
  }

  /// Calculates the distance (in metres) between two coordinates using the
  /// **Haversine Formula** — accurate for short–to–medium distances.
  ///
  /// Parameters follow the WGS-84 standard (decimal degrees).
  double _haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusMeters = 6371000; // mean radius of Earth in metres

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.pow(math.sin(dLon / 2), 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
