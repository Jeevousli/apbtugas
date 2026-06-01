import 'package:equatable/equatable.dart';
import 'gps_status.dart';

/// Immutable result returned by [GPSValidator.validate].
///
/// Contains all location data needed for an attendance record in Firestore.
class GpsValidationResult extends Equatable {
  /// Whether the user is inside (inArea) or outside (outsideArea) the office.
  final GpsStatus status;

  /// Calculated distance between the user and the office in meters.
  final double distanceInMeters;

  /// The user's current latitude.
  final double userLatitude;

  /// The user's current longitude.
  final double userLongitude;

  /// The office's reference latitude.
  final double officeLatitude;

  /// The office's reference longitude.
  final double officeLongitude;

  /// Exact moment the validation was performed (UTC).
  final DateTime timestamp;

  const GpsValidationResult({
    required this.status,
    required this.distanceInMeters,
    required this.userLatitude,
    required this.userLongitude,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.timestamp,
  });

  // ── Convenience getters ───────────────────────────────────────────────────

  /// Returns [true] if the user is within the permitted office radius.
  bool get isInsideArea => status.isValid;

  /// Distance rounded to 2 decimal places for display.
  String get formattedDistance => '${distanceInMeters.toStringAsFixed(2)} m';

  // ── Serialization for Firestore ───────────────────────────────────────────

  /// Converts this result to a Map suitable for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'status': status.label,
      'distanceInMeters': distanceInMeters,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'officeLatitude': officeLatitude,
      'officeLongitude': officeLongitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a [GpsValidationResult] from a Firestore document map.
  factory GpsValidationResult.fromFirestore(Map<String, dynamic> map) {
    return GpsValidationResult(
      status: (map['status'] as String) == GpsStatus.inArea.label
          ? GpsStatus.inArea
          : GpsStatus.outsideArea,
      distanceInMeters: (map['distanceInMeters'] as num).toDouble(),
      userLatitude: (map['userLatitude'] as num).toDouble(),
      userLongitude: (map['userLongitude'] as num).toDouble(),
      officeLatitude: (map['officeLatitude'] as num).toDouble(),
      officeLongitude: (map['officeLongitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [
        status,
        distanceInMeters,
        userLatitude,
        userLongitude,
        officeLatitude,
        officeLongitude,
        timestamp,
      ];

  @override
  String toString() =>
      'GpsValidationResult(status: ${status.label}, '
      'distance: $formattedDistance, '
      'user: ($userLatitude, $userLongitude), '
      'timestamp: $timestamp)';
}
