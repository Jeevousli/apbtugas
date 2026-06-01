import 'package:flutter/foundation.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/entities/user_entity.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;

  AttendanceProvider({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AttendanceRecord> _todayRecords = [];
  List<AttendanceRecord> _history = [];
  Map<String, int> _weeklyStats = {
    'present': 0,
    'late': 0,
    'absent': 0,
    'leave': 0,
  };

  List<AttendanceRecord> get todayRecords => _todayRecords;
  List<AttendanceRecord> get history => _history;
  Map<String, int> get weeklyStats => _weeklyStats;

  bool get hasClockedInToday => _todayRecords.any((r) => r.type == AttendanceType.clockIn);
  bool get hasClockedOutToday => _todayRecords.any((r) => r.type == AttendanceType.clockOut);

  Future<void> fetchData(UserEntity? user) async {
    if (user == null) return;
    _setLoading(true);
    try {
      final results = await Future.wait([
        repository.getTodayRecords(user.uid),
        repository.getAttendanceHistory(user.uid),
        repository.getWeeklyStats(user.uid),
      ]);
      _todayRecords = results[0] as List<AttendanceRecord>;
      _history = results[1] as List<AttendanceRecord>;
      _weeklyStats = results[2] as Map<String, int>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clock(UserEntity user, AttendanceType type, AttendanceRecord partialRecord) async {
    _setLoading(true);
    try {
      final newRecord = AttendanceRecord(
        id: '', // Firestore will generate this
        userId: user.uid,
        userName: user.name,
        type: type,
        timestamp: partialRecord.timestamp,
        status: partialRecord.status,
        distanceInMeters: partialRecord.distanceInMeters,
      );

      await repository.saveAttendanceRecord(newRecord);
      await fetchData(user); // Refresh data
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
