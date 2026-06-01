import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    await _firestore
        .collection('attendance')
        .doc(record.userId)
        .collection('records')
        .add(record.toFirestore());
  }

  @override
  Future<List<AttendanceRecord>> getTodayRecords(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('attendance')
        .doc(userId)
        .collection('records')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('timestamp', isLessThan: endOfDay.toIso8601String())
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceRecord.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(String userId,
      {int limit = 5}) async {
    final snapshot = await _firestore
        .collection('attendance')
        .doc(userId)
        .collection('records')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceRecord.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<Map<String, int>> getWeeklyStats(String userId) async {
    final now = DateTime.now();
    // Start of current week (Monday)
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1))
        .toUtc();

    final snapshot = await _firestore
        .collection('attendance')
        .doc(userId)
        .collection('records')
        .where('timestamp', isGreaterThanOrEqualTo: startOfWeek.toIso8601String())
        .get();

    final records = snapshot.docs
        .map((doc) => AttendanceRecord.fromFirestore(doc.id, doc.data()))
        .toList();

    int presentCount = 0; // Days with at least one clock_in
    int lateCount = 0;    // Clock in after 09:00

    // Group by day to prevent double counting
    final Set<int> presentDays = {};
    for (var r in records) {
      if (r.type == AttendanceType.clockIn && r.status == 'IN_AREA') {
        final day = r.timestamp.day;
        if (!presentDays.contains(day)) {
          presentDays.add(day);
          presentCount++;
          // Basic late logic (after 9 AM)
          if (r.timestamp.hour >= 9) {
            lateCount++;
          }
        }
      }
    }

    // Assuming we don't have alpha/izin automated yet
    return {
      'present': presentCount,
      'late': lateCount,
      'absent': 0, // Placeholder
      'leave': 0,  // Placeholder
    };
  }
}
