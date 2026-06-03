import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceDetailUseCase {
  final AttendanceRepository _repository;

  GetAttendanceDetailUseCase(this._repository);

  Future<AttendanceRecord?> execute(String userId, String recordId) {
    return _repository.getAttendanceById(userId, recordId);
  }
}
