import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetFilteredHistoryUseCase {
  final AttendanceRepository _repository;

  GetFilteredHistoryUseCase(this._repository);

  Future<List<AttendanceRecord>> execute(
    String userId, {
    AttendanceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DateTime? lastTimestamp,
  }) {
    return _repository.getFilteredHistory(
      userId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      lastTimestamp: lastTimestamp,
    );
  }
}
