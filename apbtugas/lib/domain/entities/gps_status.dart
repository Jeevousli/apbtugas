/// Represents the validation status of a user's GPS location
/// relative to the office radius.
enum GpsStatus {
  /// User is within the allowed radius from the office.
  inArea,

  /// User is outside the allowed radius from the office.
  outsideArea,
}

/// Extension to provide human-readable labels and helper utilities.
extension GpsStatusX on GpsStatus {
  /// Display label for UI purposes.
  String get label {
    switch (this) {
      case GpsStatus.inArea:
        return 'IN_AREA';
      case GpsStatus.outsideArea:
        return 'OUTSIDE_AREA';
    }
  }

  /// Returns true if the user is within the office area.
  bool get isValid => this == GpsStatus.inArea;
}
