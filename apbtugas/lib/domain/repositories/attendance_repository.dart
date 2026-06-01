import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  /// Save an attendance record to Firestore
  Future<void> saveAttendanceRecord(AttendanceRecord record);

  /// Fetch today's records for a specific user to determine state
  Future<List<AttendanceRecord>> getTodayRecords(String userId);

  /// Fetch the latest N records for history
  Future<List<AttendanceRecord>> getAttendanceHistory(String userId, {int limit = 5});

  /// Get attendance stats for the current week
  Future<Map<String, int>> getWeeklyStats(String userId);
}
