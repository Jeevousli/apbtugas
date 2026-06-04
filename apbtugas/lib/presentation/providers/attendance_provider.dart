import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/user_entity.dart';

import '../../core/services/fcm_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;
  final FcmService fcmService;
  final NotificationRepository notificationRepository;

  AttendanceProvider({
    required this.repository,
    required this.fcmService,
    required this.notificationRepository,
  });

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

  // History Filter State
  List<AttendanceRecord> _filteredHistory = [];
  List<AttendanceRecord> get filteredHistory => _filteredHistory;

  AttendanceStatus? _selectedFilter;
  AttendanceStatus? get selectedFilter => _selectedFilter;

  DateTime? _searchDate;
  DateTime? get searchDate => _searchDate;

  bool _hasMoreHistory = true;
  bool get hasMoreHistory => _hasMoreHistory;

  // Detail State
  AttendanceRecord? _selectedRecord;
  AttendanceRecord? get selectedRecord => _selectedRecord;

  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

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

  Future<void> fetchFilteredHistory(String userId, {bool isLoadMore = false}) async {
    if (isLoadMore && !_hasMoreHistory) return;

    if (!isLoadMore) {
      _filteredHistory = [];
      _hasMoreHistory = true;
      _isLoading = true;
      notifyListeners();
    }

    try {
      final lastTimestamp = isLoadMore && _filteredHistory.isNotEmpty
          ? _filteredHistory.last.timestamp
          : null;

      final results = await repository.getFilteredHistory(
        userId,
        status: _selectedFilter,
        startDate: _searchDate != null
            ? DateTime(_searchDate!.year, _searchDate!.month, _searchDate!.day)
            : null,
        endDate: _searchDate != null
            ? DateTime(_searchDate!.year, _searchDate!.month, _searchDate!.day)
            : null,
        limit: 15,
        lastTimestamp: lastTimestamp,
      );

      if (isLoadMore) {
        _filteredHistory.addAll(results);
      } else {
        _filteredHistory = results;
      }
      _hasMoreHistory = results.length == 15;
      _errorMessage = null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        _errorMessage = 'Tidak ada koneksi internet. Mode offline aktif.';
      } else {
        _errorMessage = 'Error absensi: ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat histori absensi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String userId, AttendanceStatus? status) {
    _selectedFilter = status;
    fetchFilteredHistory(userId);
  }

  void setSearchDate(String userId, DateTime? date) {
    _searchDate = date;
    fetchFilteredHistory(userId);
  }

  Future<void> fetchAttendanceDetail(String userId, String recordId) async {
    _isLoadingDetail = true;
    notifyListeners();
    try {
      _selectedRecord = await repository.getAttendanceById(userId, recordId);
      _errorMessage = null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        _errorMessage = 'Tidak ada koneksi internet.';
      } else {
        _errorMessage = 'Error absensi: ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat detail absensi.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
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
        selfieUrl: partialRecord.selfieUrl,
        attendanceStatus: partialRecord.attendanceStatus,
        latitude: partialRecord.latitude,
        longitude: partialRecord.longitude,
        address: partialRecord.address,
        notes: partialRecord.notes,
      );

      await repository.saveAttendanceRecord(newRecord);
      await fetchData(user); // Refresh data
      
      // Tampilkan Notifikasi
      final isClockIn = type == AttendanceType.clockIn;
      final title = isClockIn ? '✅ Berhasil Absen Masuk' : '🌙 Berhasil Absen Pulang';
      final body = isClockIn 
            ? 'Selamat bekerja, ${user.name}!'
            : 'Terima kasih atas kerja keras Anda hari ini.';
            
      fcmService.showLocalNotification(
        title: title,
        body: body,
        id: isClockIn ? 10 : 20,
      );
      
      // Simpan ke Halaman Notifikasi (Firestore)
      final notif = NotificationEntity(
        id: '',
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: NotificationType.clockSuccess,
        isRead: false,
      );
      await notificationRepository.saveNotification(user.uid, notif);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        _errorMessage = 'Tidak ada koneksi internet. Absen gagal disimpan.';
      } else {
        _errorMessage = 'Error absensi: ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Gagal melakukan absensi.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
