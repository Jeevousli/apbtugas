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

class AttendanceRecord extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final AttendanceType type;
  final DateTime timestamp;
  final String status; // 'IN_AREA' or 'OUTSIDE_AREA'
  final double distanceInMeters;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.distanceInMeters,
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
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, userName, type, timestamp, status, distanceInMeters];
}
