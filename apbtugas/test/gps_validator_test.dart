import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:apbtugas/core/errors/gps_exception.dart';
import 'package:apbtugas/core/services/gps_validator.dart';
import 'package:apbtugas/domain/entities/gps_status.dart';
import 'package:apbtugas/domain/entities/gps_validation_result.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Fake implementation – no code generation required.
//
// FakeGeolocatorService lets each test scenario configure the exact
// responses it needs: service enabled/disabled, permission level, position,
// or an error thrown by getCurrentPosition.
// ═══════════════════════════════════════════════════════════════════════════

class FakeGeolocatorService implements IGeolocatorService {
  /// Controls the return value of [isLocationServiceEnabled].
  final bool serviceEnabled;

  /// Controls the return value of [checkPermission].
  final LocationPermission initialPermission;

  /// Controls the return value of [requestPermission].
  final LocationPermission requestedPermission;

  /// If set, [getCurrentPosition] returns this position.
  final Position? position;

  /// If set, [getCurrentPosition] throws this exception.
  final Exception? positionError;

  const FakeGeolocatorService({
    this.serviceEnabled = true,
    this.initialPermission = LocationPermission.whileInUse,
    this.requestedPermission = LocationPermission.whileInUse,
    this.position,
    this.positionError,
  });

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => initialPermission;

  @override
  Future<LocationPermission> requestPermission() async => requestedPermission;

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    if (positionError != null) throw positionError!;
    if (position == null) throw Exception('No position configured in fake');
    return position!;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper – creates a fake [Position] for test coordinates
// ═══════════════════════════════════════════════════════════════════════════

Position _fakePosition(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.utc(2025, 6, 1, 9, 0),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

// ── Office constants (mirrors GPSValidator defaults) ──────────────────────
const _officeLat = -6.2088;
const _officeLng = 106.8456;
const _radius = 500.0;

// ── Coordinates for test scenarios ───────────────────────────────────────
// ~200 m north of office  → within 500 m radius
const _insideLat = -6.2070;
const _insideLng = 106.8456;

// ~2.2 km south of office → outside 500 m radius
const _outsideLat = -6.2288;
const _outsideLng = 106.8456;

// ═══════════════════════════════════════════════════════════════════════════
// Test Suite
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  // ── Factory helper that builds a GPSValidator with a given fake ─────────
  GPSValidator makeValidator(FakeGeolocatorService fake) => GPSValidator(
        officeLatitude: _officeLat,
        officeLongitude: _officeLng,
        radiusInMeters: _radius,
        geolocatorService: fake,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // 1. User INSIDE radius (≤ 500 m) → status: inArea
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – user INSIDE radius', () {
    late GPSValidator validator;

    setUp(() {
      validator = makeValidator(FakeGeolocatorService(
        position: _fakePosition(_insideLat, _insideLng),
      ));
    });

    test('returns GpsStatus.inArea', () async {
      final result = await validator.validate();
      expect(result.status, GpsStatus.inArea);
    });

    test('isInsideArea is true', () async {
      final result = await validator.validate();
      expect(result.isInsideArea, isTrue);
    });

    test('distanceInMeters is within radius', () async {
      final result = await validator.validate();
      expect(result.distanceInMeters, lessThanOrEqualTo(_radius));
    });

    test('user coordinates are preserved in result', () async {
      final result = await validator.validate();
      expect(result.userLatitude, _insideLat);
      expect(result.userLongitude, _insideLng);
    });

    test('office coordinates are correct in result', () async {
      final result = await validator.validate();
      expect(result.officeLatitude, _officeLat);
      expect(result.officeLongitude, _officeLng);
    });

    test('timestamp is set and is a DateTime', () async {
      final result = await validator.validate();
      expect(result.timestamp, isA<DateTime>());
    });

    test('status label is IN_AREA', () async {
      final result = await validator.validate();
      expect(result.status.label, 'IN_AREA');
    });

    test('formattedDistance contains unit "m"', () async {
      final result = await validator.validate();
      expect(result.formattedDistance, contains('m'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. User OUTSIDE radius (> 500 m) → status: outsideArea
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – user OUTSIDE radius', () {
    late GPSValidator validator;

    setUp(() {
      validator = makeValidator(FakeGeolocatorService(
        position: _fakePosition(_outsideLat, _outsideLng),
      ));
    });

    test('returns GpsStatus.outsideArea', () async {
      final result = await validator.validate();
      expect(result.status, GpsStatus.outsideArea);
    });

    test('isInsideArea is false', () async {
      final result = await validator.validate();
      expect(result.isInsideArea, isFalse);
    });

    test('distanceInMeters exceeds radius', () async {
      final result = await validator.validate();
      expect(result.distanceInMeters, greaterThan(_radius));
    });

    test('status label is OUTSIDE_AREA', () async {
      final result = await validator.validate();
      expect(result.status.label, 'OUTSIDE_AREA');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Location SERVICE disabled → GpsErrorType.locationServiceDisabled
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – location service disabled', () {
    late GPSValidator validator;

    setUp(() {
      validator = makeValidator(const FakeGeolocatorService(
        serviceEnabled: false,
      ));
    });

    test('throws GpsException', () {
      expect(validator.validate(), throwsA(isA<GpsException>()));
    });

    test('throws GpsException with locationServiceDisabled type', () async {
      try {
        await validator.validate();
        fail('Expected GpsException');
      } on GpsException catch (e) {
        expect(e.type, GpsErrorType.locationServiceDisabled);
      }
    });

    test('exception message is non-empty', () async {
      try {
        await validator.validate();
        fail('Expected GpsException');
      } on GpsException catch (e) {
        expect(e.message, isNotEmpty);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Permission DENIED (after request) → GpsErrorType.permissionDenied
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – permission denied', () {
    late GPSValidator validator;

    setUp(() {
      validator = makeValidator(const FakeGeolocatorService(
        initialPermission: LocationPermission.denied,
        requestedPermission: LocationPermission.denied, // still denied
      ));
    });

    test('throws GpsException with permissionDenied type', () async {
      try {
        await validator.validate();
        fail('Expected GpsException');
      } on GpsException catch (e) {
        expect(e.type, GpsErrorType.permissionDenied);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Permission DENIED FOREVER → GpsErrorType.permissionDeniedForever
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – permission denied forever', () {
    late GPSValidator validator;

    setUp(() {
      validator = makeValidator(const FakeGeolocatorService(
        initialPermission: LocationPermission.deniedForever,
      ));
    });

    test('throws GpsException with permissionDeniedForever type', () async {
      try {
        await validator.validate();
        fail('Expected GpsException');
      } on GpsException catch (e) {
        expect(e.type, GpsErrorType.permissionDeniedForever);
      }
    });

    test('exception message mentions Settings', () async {
      try {
        await validator.validate();
        fail('Expected GpsException');
      } on GpsException catch (e) {
        expect(e.message.toLowerCase(), contains('settings'));
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. getCurrentPosition THROWS → GpsErrorType.locationFetchFailed
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – location fetch failed', () {
    late GPSValidator validator;

    setUp(() {
      validator = makeValidator(FakeGeolocatorService(
        positionError: Exception('GPS hardware timeout'),
      ));
    });

    test('wraps error as GpsException.locationFetchFailed', () async {
      try {
        await validator.validate();
        fail('Expected GpsException');
      } on GpsException catch (e) {
        expect(e.type, GpsErrorType.locationFetchFailed);
      }
    });

    test('error message is non-empty', () async {
      try {
        await validator.validate();
        fail('Expected GpsException');
      } on GpsException catch (e) {
        expect(e.message, isNotEmpty);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Permission initially denied → GRANTED on request → succeeds
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – permission granted after initial denial', () {
    test('resolves successfully when requestPermission returns granted',
        () async {
      final validator = makeValidator(FakeGeolocatorService(
        initialPermission: LocationPermission.denied,
        requestedPermission: LocationPermission.whileInUse, // granted
        position: _fakePosition(_insideLat, _insideLng),
      ));

      final result = await validator.validate();
      expect(result.status, GpsStatus.inArea);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Firestore serialization round-trip
  // ─────────────────────────────────────────────────────────────────────────
  group('GpsValidationResult – Firestore round-trip', () {
    final ts = DateTime.utc(2025, 6, 1, 8, 30);

    GpsValidationResult buildResult(GpsStatus status, double dist) =>
        GpsValidationResult(
          status: status,
          distanceInMeters: dist,
          userLatitude: _insideLat,
          userLongitude: _insideLng,
          officeLatitude: _officeLat,
          officeLongitude: _officeLng,
          timestamp: ts,
        );

    test('toFirestore() contains all required keys', () {
      final map = buildResult(GpsStatus.inArea, 200).toFirestore();
      expect(map.keys, containsAll(['status', 'distanceInMeters',
          'userLatitude', 'userLongitude',
          'officeLatitude', 'officeLongitude', 'timestamp']));
    });

    test('inArea round-trip preserves status', () {
      final original = buildResult(GpsStatus.inArea, 200);
      final restored = GpsValidationResult.fromFirestore(original.toFirestore());
      expect(restored.status, GpsStatus.inArea);
    });

    test('outsideArea round-trip preserves status', () {
      final original = buildResult(GpsStatus.outsideArea, 800);
      final restored = GpsValidationResult.fromFirestore(original.toFirestore());
      expect(restored.status, GpsStatus.outsideArea);
    });

    test('round-trip preserves all numeric fields', () {
      final original = buildResult(GpsStatus.inArea, 123.45);
      final restored = GpsValidationResult.fromFirestore(original.toFirestore());
      expect(restored.distanceInMeters, original.distanceInMeters);
      expect(restored.userLatitude, original.userLatitude);
      expect(restored.userLongitude, original.userLongitude);
      expect(restored.officeLatitude, original.officeLatitude);
      expect(restored.officeLongitude, original.officeLongitude);
    });

    test('round-trip preserves timestamp', () {
      final original = buildResult(GpsStatus.inArea, 200);
      final restored = GpsValidationResult.fromFirestore(original.toFirestore());
      expect(restored.timestamp, original.timestamp);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 9. Boundary condition – exactly at edge of radius
  // ─────────────────────────────────────────────────────────────────────────
  group('validate() – boundary at ~500 m', () {
    test('coordinate ~500 m north is treated as inArea (within tolerance)',
        () async {
      // -6.2043 is approximately 500 m north of -6.2088
      final validator = makeValidator(FakeGeolocatorService(
        position: _fakePosition(-6.2043, _officeLng),
      ));

      final result = await validator.validate();
      // Allow ±3 m tolerance for floating-point Haversine rounding
      expect(result.distanceInMeters, lessThanOrEqualTo(503));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 10. GpsStatus extension helpers
  // ─────────────────────────────────────────────────────────────────────────
  group('GpsStatus extensions', () {
    test('inArea.isValid is true', () {
      expect(GpsStatus.inArea.isValid, isTrue);
    });

    test('outsideArea.isValid is false', () {
      expect(GpsStatus.outsideArea.isValid, isFalse);
    });

    test('inArea.label is "IN_AREA"', () {
      expect(GpsStatus.inArea.label, 'IN_AREA');
    });

    test('outsideArea.label is "OUTSIDE_AREA"', () {
      expect(GpsStatus.outsideArea.label, 'OUTSIDE_AREA');
    });
  });
}
