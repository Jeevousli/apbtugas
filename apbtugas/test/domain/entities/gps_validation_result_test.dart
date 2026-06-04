import 'package:flutter_test/flutter_test.dart';
import 'package:apbtugas/domain/entities/gps_validation_result.dart';
import 'package:apbtugas/domain/entities/gps_status.dart';

void main() {
  group('GpsValidationResult', () {
    final tDate = DateTime.utc(2024, 1, 1, 10, 0, 0);

    final tResult = GpsValidationResult(
      status: GpsStatus.inArea,
      distanceInMeters: 125.5,
      userLatitude: -6.200,
      userLongitude: 106.816,
      officeLatitude: -6.201,
      officeLongitude: 106.817,
      timestamp: tDate,
    );

    test('isInsideArea should return true if status is inArea', () {
      expect(tResult.isInsideArea, isTrue);
    });

    test('formattedDistance should return correctly rounded string', () {
      expect(tResult.formattedDistance, '125.50 m');
    });

    test('toFirestore should convert to valid Map', () {
      final map = tResult.toFirestore();

      expect(map['status'], 'IN_AREA');
      expect(map['distanceInMeters'], 125.5);
      expect(map['userLatitude'], -6.200);
      expect(map['userLongitude'], 106.816);
      expect(map['officeLatitude'], -6.201);
      expect(map['officeLongitude'], 106.817);
      expect(map['timestamp'], tDate.toIso8601String());
    });

    test('fromFirestore should recreate GpsValidationResult correctly', () {
      final map = {
        'status': 'OUTSIDE_AREA',
        'distanceInMeters': 600.0,
        'userLatitude': -6.300,
        'userLongitude': 106.900,
        'officeLatitude': -6.201,
        'officeLongitude': 106.817,
        'timestamp': tDate.toIso8601String(),
      };

      final result = GpsValidationResult.fromFirestore(map);

      expect(result.status, GpsStatus.outsideArea);
      expect(result.distanceInMeters, 600.0);
      expect(result.isInsideArea, isFalse);
      expect(result.timestamp, tDate);
    });
  });
}
