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

  /// Fetch filtered attendance history for a user
  Future<List<AttendanceRecord>> getFilteredHistory(
    String userId, {
    AttendanceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DateTime? lastTimestamp,
  });

  /// Fetch a single attendance record by ID
  Future<AttendanceRecord?> getAttendanceById(String userId, String recordId);
}
