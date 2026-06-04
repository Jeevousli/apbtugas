import 'package:flutter_test/flutter_test.dart';
import 'package:apbtugas/domain/entities/attendance_record.dart';

void main() {
  group('AttendanceRecord', () {
    final tDate = DateTime(2024, 1, 1, 8, 0, 0).toUtc();
    
    final tRecord = AttendanceRecord(
      id: '123',
      userId: 'user1',
      userName: 'John Doe',
      type: AttendanceType.clockIn,
      timestamp: tDate,
      status: 'IN_AREA',
      distanceInMeters: 50.0,
      attendanceStatus: AttendanceStatus.hadir,
      latitude: -6.200000,
      longitude: 106.816666,
      address: 'Jakarta',
      selfieUrl: 'https://example.com/photo.jpg',
      notes: 'Hadir tepat waktu',
    );

    test('should correctly convert AttendanceType to string and vice versa', () {
      expect(AttendanceType.clockIn.value, 'clock_in');
      expect(AttendanceType.clockOut.value, 'clock_out');
      
      expect(AttendanceTypeX.fromString('clock_in'), AttendanceType.clockIn);
      expect(AttendanceTypeX.fromString('clock_out'), AttendanceType.clockOut);
      // default fallback
      expect(AttendanceTypeX.fromString('invalid'), AttendanceType.clockIn);
    });

    test('should correctly convert AttendanceStatus to string and vice versa', () {
      expect(AttendanceStatus.hadir.value, 'hadir');
      expect(AttendanceStatus.telat.value, 'telat');
      expect(AttendanceStatus.izin.value, 'izin');
      expect(AttendanceStatus.alpha.value, 'alpha');

      expect(AttendanceStatusX.fromString('telat'), AttendanceStatus.telat);
      expect(AttendanceStatusX.fromString('invalid'), AttendanceStatus.hadir);
    });

    test('should return valid map from toFirestore()', () {
      final map = tRecord.toFirestore();
      
      expect(map['userId'], 'user1');
      expect(map['userName'], 'John Doe');
      expect(map['type'], 'clock_in');
      expect(map['status'], 'IN_AREA');
      expect(map['distanceInMeters'], 50.0);
      expect(map['attendanceStatus'], 'hadir');
      expect(map['latitude'], -6.200000);
      expect(map['address'], 'Jakarta');
      expect(map['notes'], 'Hadir tepat waktu');
      expect(map['selfieUrl'], 'https://example.com/photo.jpg');
    });

    test('should create valid AttendanceRecord from fromFirestore()', () {
      final map = {
        'userId': 'user1',
        'userName': 'John Doe',
        'type': 'clock_in',
        'timestamp': tDate.toIso8601String(),
        'status': 'IN_AREA',
        'distanceInMeters': 50.0,
        'attendanceStatus': 'hadir',
        'latitude': -6.200000,
        'longitude': 106.816666,
      };

      final result = AttendanceRecord.fromFirestore('123', map);

      expect(result.id, '123');
      expect(result.userId, 'user1');
      expect(result.type, AttendanceType.clockIn);
      expect(result.attendanceStatus, AttendanceStatus.hadir);
      expect(result.distanceInMeters, 50.0);
      expect(result.latitude, -6.200000);
      // Ensure local time conversion doesn't break equality check logic depending on timezone
      expect(result.timestamp.toUtc(), tDate);
    });
  });
}
