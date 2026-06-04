import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/attendance_record.dart';
import '../../data/models/user_model.dart';

class AdminStats {
  final int totalEmployees;
  final int presentToday;
  final int lateToday;
  final int absentToday;
  final int leaveToday;
  final double attendanceRate;

  const AdminStats({
    required this.totalEmployees,
    required this.presentToday,
    required this.lateToday,
    required this.absentToday,
    required this.leaveToday,
    required this.attendanceRate,
  });
}

class WeeklyKpiData {
  final List<double> attendanceRates; // 7 days
  final List<double> lateTrend; // 7 days count
  final Map<int, int> hourlyDistribution; // hour -> count

  const WeeklyKpiData({
    required this.attendanceRates,
    required this.lateTrend,
    required this.hourlyDistribution,
  });
}

class EmployeeClockInLocation {
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final AttendanceStatus status;

  const EmployeeClockInLocation({
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
  });
}

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  AdminProvider({required FirebaseFirestore firestore}) : _firestore = firestore;

  // ─── State ─────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AdminStats? _stats;
  AdminStats? get stats => _stats;

  List<UserEntity> _employees = [];
  List<UserEntity> get employees => _employees;

  List<UserEntity> _filteredEmployees = [];
  List<UserEntity> get filteredEmployees => _filteredEmployees;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Selected employee for detail view
  UserEntity? _selectedEmployee;
  UserEntity? get selectedEmployee => _selectedEmployee;

  // Attendance logs for selected employee
  List<AttendanceRecord> _employeeAttendanceLogs = [];
  List<AttendanceRecord> get employeeAttendanceLogs => _employeeAttendanceLogs;

  bool _isLoadingLogs = false;
  bool get isLoadingLogs => _isLoadingLogs;

  // Date range filter for logs
  DateTime? _logStartDate;
  DateTime? get logStartDate => _logStartDate;

  DateTime? _logEndDate;
  DateTime? get logEndDate => _logEndDate;

  // KPI Data
  WeeklyKpiData? _weeklyKpi;
  WeeklyKpiData? get weeklyKpi => _weeklyKpi;

  bool _isLoadingKpi = false;
  bool get isLoadingKpi => _isLoadingKpi;

  // Map overview data
  List<EmployeeClockInLocation> _clockInLocations = [];
  List<EmployeeClockInLocation> get clockInLocations => _clockInLocations;

  // ─── Load Dashboard Stats ────────────────────────────────────────
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all employees
      final usersSnap = await _firestore.collection('users').get();
      final allUsers = usersSnap.docs
          .map((d) => UserModel.fromFirestore(d))
          .where((u) => u.role == UserRole.employee)
          .toList();

      _employees = allUsers;
      _filteredEmployees = allUsers;

      // Today's attendance range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Fetch today's records by querying each employee's subcollection 
      // This avoids the need for a composite index required by collectionGroup
      final futures = allUsers.map((emp) => _firestore
          .collection('attendance')
          .doc(emp.uid)
          .collection('records')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('timestamp', isLessThan: endOfDay.toIso8601String())
          .get());
          
      final snaps = await Future.wait(futures);
      
      final todayRecords = snaps.expand((snap) => 
          snap.docs.map((d) => AttendanceRecord.fromFirestore(d.id, d.data()))
      ).toList();

      // Unique clock-in records per user (first clock-in of the day)
      final Map<String, AttendanceRecord> firstClockIns = {};
      for (var r in todayRecords) {
        if (r.type == AttendanceType.clockIn) {
          if (!firstClockIns.containsKey(r.userId) ||
              r.timestamp.isBefore(firstClockIns[r.userId]!.timestamp)) {
            firstClockIns[r.userId] = r;
          }
        }
      }

      int presentCount = 0;
      int lateCount = 0;
      int leaveCount = 0;

      for (var record in firstClockIns.values) {
        switch (record.attendanceStatus) {
          case AttendanceStatus.hadir:
            presentCount++;
            break;
          case AttendanceStatus.telat:
            presentCount++;
            lateCount++;
            break;
          case AttendanceStatus.izin:
            leaveCount++;
            break;
          default:
            break;
        }
      }

      final totalEmp = allUsers.length;
      final absent = totalEmp - firstClockIns.length;
      final rate =
          totalEmp > 0 ? (firstClockIns.length / totalEmp * 100) : 0.0;

      _stats = AdminStats(
        totalEmployees: totalEmp,
        presentToday: presentCount,
        lateToday: lateCount,
        absentToday: absent < 0 ? 0 : absent,
        leaveToday: leaveCount,
        attendanceRate: rate,
      );

      // Build map locations
      _clockInLocations = firstClockIns.values
          .where((r) => r.latitude != null && r.longitude != null)
          .map((r) => EmployeeClockInLocation(
                userId: r.userId,
                userName: r.userName,
                latitude: r.latitude!,
                longitude: r.longitude!,
                timestamp: r.timestamp,
                status: r.attendanceStatus,
              ))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        _error = 'Tidak ada koneksi internet. Cek jaringan Anda.';
      } else {
        _error = 'Error database: ${e.message}';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan tidak terduga.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Load KPI Charts ────────────────────────────────────────────
  Future<void> loadWeeklyKpi() async {
    _isLoadingKpi = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Last 7 days
      final startDate =
          DateTime(now.year, now.month, now.day - 6).toUtc();

      final totalEmp = _employees.isNotEmpty ? _employees.length : 1;

      final futures = _employees.map((emp) => _firestore
          .collection('attendance')
          .doc(emp.uid)
          .collection('records')
          .where('timestamp',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .get());

      final snaps = await Future.wait(futures);
      final records = snaps.expand((snap) => 
          snap.docs.map((d) => AttendanceRecord.fromFirestore(d.id, d.data()))
      ).where((r) => r.type == AttendanceType.clockIn).toList();

      // Group by day
      final List<double> attendanceRates = List.filled(7, 0.0);
      final List<double> lateTrend = List.filled(7, 0.0);
      final Map<int, int> hourlyDist = {};

      // Count unique users per day
      final Map<int, Set<String>> presentPerDay = {};
      final Map<int, Set<String>> latePerDay = {};

      for (var r in records) {
        final dayIndex = r.timestamp.difference(startDate.toLocal()).inDays;
        if (dayIndex < 0 || dayIndex >= 7) continue;

        presentPerDay.putIfAbsent(dayIndex, () => {}).add(r.userId);
        if (r.attendanceStatus == AttendanceStatus.telat) {
          latePerDay.putIfAbsent(dayIndex, () => {}).add(r.userId);
        }

        // Hourly distribution
        final hour = r.timestamp.hour;
        hourlyDist[hour] = (hourlyDist[hour] ?? 0) + 1;
      }

      for (int i = 0; i < 7; i++) {
        final presentCount = presentPerDay[i]?.length ?? 0;
        attendanceRates[i] = (presentCount / totalEmp * 100).clamp(0, 100);
        lateTrend[i] = (latePerDay[i]?.length ?? 0).toDouble();
      }

      _weeklyKpi = WeeklyKpiData(
        attendanceRates: attendanceRates,
        lateTrend: lateTrend,
        hourlyDistribution: hourlyDist,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        _error = 'Tidak ada koneksi internet. Cek jaringan Anda.';
      } else {
        _error = 'Error database: ${e.message}';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan saat memuat grafik.';
    } finally {
      _isLoadingKpi = false;
      notifyListeners();
    }
  }

  // ─── Employee Search ────────────────────────────────────────────
  void searchEmployees(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredEmployees = _employees;
    } else {
      final q = query.toLowerCase();
      _filteredEmployees = _employees
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.nik.toLowerCase().contains(q) ||
              (e.department?.toLowerCase().contains(q) ?? false) ||
              e.email.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  // ─── Load Employee Detail ───────────────────────────────────────
  Future<void> loadEmployeeDetail(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _selectedEmployee = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Load Employee Attendance Logs ──────────────────────────────
  Future<void> loadEmployeeLogs(String uid,
      {DateTime? startDate, DateTime? endDate}) async {
    _isLoadingLogs = true;
    _logStartDate = startDate;
    _logEndDate = endDate;
    notifyListeners();

    try {
      var query = _firestore
          .collection('attendance')
          .doc(uid)
          .collection('records')
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo:
                DateTime(startDate.year, startDate.month, startDate.day)
                    .toUtc()
                    .toIso8601String());
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo:
                DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
                    .toUtc()
                    .toIso8601String());
      }

      final snap = await query.limit(100).get();
      _employeeAttendanceLogs = snap.docs
          .map((d) => AttendanceRecord.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  // ─── Update Employee Role ───────────────────────────────────────
  Future<bool> updateEmployeeRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole == UserRole.admin ? 'admin' : 'employee',
      });
      // Refresh employees list
      await loadDashboardStats();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Export Attendance to CSV ───────────────────────────────────
  Future<void> exportAttendanceCsv(String employeeName) async {
    if (_employeeAttendanceLogs.isEmpty) return;

    final rows = <List<dynamic>>[
      [
        'Nama',
        'Tanggal',
        'Waktu',
        'Tipe',
        'Status Kehadiran',
        'Lokasi GPS',
        'Jarak (m)',
        'Catatan'
      ],
    ];

    for (var r in _employeeAttendanceLogs) {
      final dt = r.timestamp;
      rows.add([
        r.userName,
        '${dt.day}/${dt.month}/${dt.year}',
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        r.type == AttendanceType.clockIn ? 'Masuk' : 'Keluar',
        r.attendanceStatus.value,
        r.latitude != null ? '${r.latitude}, ${r.longitude}' : '-',
        r.distanceInMeters.toStringAsFixed(0),
        r.notes ?? '-',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);

    try {
      final directory = await getTemporaryDirectory();
      final safeFileName =
          employeeName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${directory.path}/absensi_$safeFileName.csv');
      await file.writeAsString(csvData);

      final xFile = XFile(file.path, mimeType: 'text/csv');
      await Share.shareXFiles(
        [xFile],
        subject: 'Laporan Absensi - $employeeName',
      );
    } catch (e) {
      _error = 'Gagal export CSV: $e';
      notifyListeners();
    }
  }

  // ─── Stream today's stats in real-time ─────────────────────────


  void clearError() {
    _error = null;
    notifyListeners();
  }
}
 
