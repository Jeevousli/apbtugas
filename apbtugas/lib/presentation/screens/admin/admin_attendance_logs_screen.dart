import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../providers/admin_provider.dart';

class AdminAttendanceLogsScreen extends StatefulWidget {
  final String uid;
  final String employeeName;
  const AdminAttendanceLogsScreen(
      {super.key, required this.uid, required this.employeeName});

  @override
  State<AdminAttendanceLogsScreen> createState() =>
      _AdminAttendanceLogsScreenState();
}

class _AdminAttendanceLogsScreenState
    extends State<AdminAttendanceLogsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final logs = admin.employeeAttendanceLogs;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log Absensi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(widget.employeeName,
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          if (logs.isNotEmpty)
            _isExporting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.secondary, strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded,
                        color: AppColors.secondary),
                    tooltip: 'Export CSV',
                    onPressed: _exportCsv,
                  ),
        ],
      ),
      body: Column(
        children: [
          // Date range filter bar
          _buildDateRangeBar(admin),
          // Stats row
          if (logs.isNotEmpty) _buildStatsRow(logs),
          // List
          Expanded(
            child: admin.isLoadingLogs
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.secondary))
                : logs.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildLogCard(logs[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeBar(AdminProvider admin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primaryCard,
      child: Row(
        children: [
          Expanded(
            child: _dateButton(
              label: _startDate == null
                  ? 'Dari tanggal'
                  : _fmtDate(_startDate!),
              icon: Icons.date_range_rounded,
              onTap: () async {
                final d = await _pickDate(initial: _startDate);
                if (d != null) {
                  setState(() => _startDate = d);
                  _reload(admin);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dateButton(
              label: _endDate == null
                  ? 'Hingga tanggal'
                  : _fmtDate(_endDate!),
              icon: Icons.date_range_rounded,
              onTap: () async {
                final d = await _pickDate(initial: _endDate);
                if (d != null) {
                  setState(() => _endDate = d);
                  _reload(admin);
                }
              },
            ),
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.textMuted, size: 18),
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _reload(admin);
              },
            ),
        ],
      ),
    );
  }

  Widget _dateButton(
          {required String label,
          required IconData icon,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatsRow(List<AttendanceRecord> logs) {
    final clockIns =
        logs.where((r) => r.type == AttendanceType.clockIn).toList();
    final hadir = clockIns
        .where((r) => r.attendanceStatus == AttendanceStatus.hadir)
        .length;
    final telat = clockIns
        .where((r) => r.attendanceStatus == AttendanceStatus.telat)
        .length;
    final izin = clockIns
        .where((r) => r.attendanceStatus == AttendanceStatus.izin)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primaryCard.withAlpha(80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip('Hadir', hadir, AppColors.success),
          _statChip('Telat', telat, AppColors.warning),
          _statChip('Izin', izin, AppColors.info),
          _statChip('Total', logs.length, AppColors.secondary),
        ],
      ),
    );
  }

  Widget _statChip(String label, int val, Color color) => Column(
        children: [
          Text('$val',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined,
                color: AppColors.textSecondary, size: 52),
            const SizedBox(height: 12),
            const Text('Tidak ada log absensi',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Coba ubah rentang tanggal',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );

  Widget _buildLogCard(AttendanceRecord r) {
    final isIn = r.type == AttendanceType.clockIn;
    final statusColor = _statusColor(r.attendanceStatus);
    final iconColor = isIn ? AppColors.success : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: statusColor.withAlpha(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle),
            child: Icon(
                isIn ? Icons.login_rounded : Icons.logout_rounded,
                color: iconColor,
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isIn ? 'Clock In' : 'Clock Out',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(_fmtDateTime(r.timestamp),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                if (r.latitude != null)
                  Text(
                      '${r.distanceInMeters.toStringAsFixed(0)} m dari kantor',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_statusLabel(r.attendanceStatus),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _reload(AdminProvider admin) {
    admin.loadEmployeeLogs(widget.uid,
        startDate: _startDate, endDate: _endDate);
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    await context
        .read<AdminProvider>()
        .exportAttendanceCsv(widget.employeeName);
    if (mounted) setState(() => _isExporting = false);
  }

  Future<DateTime?> _pickDate({DateTime? initial}) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.secondary,
              onPrimary: AppColors.white,
              surface: AppColors.primaryCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        ),
      );

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.hadir:
        return AppColors.success;
      case AttendanceStatus.telat:
        return AppColors.warning;
      case AttendanceStatus.izin:
        return AppColors.info;
      case AttendanceStatus.alpha:
        return AppColors.error;
    }
  }

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.telat:
        return 'Telat';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.alpha:
        return 'Alpha';
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtDateTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${_fmtDate(d)} $h:$m';
  }
}
