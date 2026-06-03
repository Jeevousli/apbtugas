import 'package:equatable/equatable.dart';

enum AttendanceType { clockIn, clockOut }

extension AttendanceTypeX on AttendanceType {
  String get value {
    switch (this) {
      case AttendanceType.clockIn:
        return 'clock_in';
      case AttendanceType.clockOut:
        return 'clock_out';
    }
  }

  static AttendanceType fromString(String val) {
    if (val == 'clock_out') return AttendanceType.clockOut;
    return AttendanceType.clockIn;
  }
}

enum AttendanceStatus { hadir, telat, izin, alpha }

extension AttendanceStatusX on AttendanceStatus {
  String get value {
    switch (this) {
      case AttendanceStatus.hadir:
        return 'hadir';
      case AttendanceStatus.telat:
        return 'telat';
      case AttendanceStatus.izin:
        return 'izin';
      case AttendanceStatus.alpha:
        return 'alpha';
    }
  }

  static AttendanceStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'telat':
        return AttendanceStatus.telat;
      case 'izin':
        return AttendanceStatus.izin;
      case 'alpha':
        return AttendanceStatus.alpha;
      default:
        return AttendanceStatus.hadir;
    }
  }
}

class AttendanceRecord extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final AttendanceType type;
  final DateTime timestamp;
  final String status; // 'IN_AREA' or 'OUTSIDE_AREA'
  final double distanceInMeters;
  final String? selfieUrl; // Firebase Storage URL after face capture
  final AttendanceStatus attendanceStatus;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.distanceInMeters,
    required this.attendanceStatus,
    this.selfieUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.notes,
  });

  factory AttendanceRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return AttendanceRecord(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: AttendanceTypeX.fromString(data['type'] ?? 'clock_in'),
      timestamp: DateTime.parse(data['timestamp'] as String).toLocal(),
      status: data['status'] ?? 'UNKNOWN',
      distanceInMeters: (data['distanceInMeters'] as num?)?.toDouble() ?? 0.0,
      selfieUrl: data['selfieUrl'] as String?,
      attendanceStatus: AttendanceStatusX.fromString(data['attendanceStatus'] ?? 'hadir'),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      address: data['address'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.value,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'status': status,
      'distanceInMeters': distanceInMeters,
      'attendanceStatus': attendanceStatus.value,
      if (selfieUrl != null) 'selfieUrl': selfieUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        type,
        timestamp,
        status,
        distanceInMeters,
        selfieUrl,
        attendanceStatus,
        latitude,
        longitude,
        address,
        notes,
      ];
}
