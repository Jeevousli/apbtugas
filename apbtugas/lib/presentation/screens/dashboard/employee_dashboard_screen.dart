import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/clock_in_button.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/gps_status.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<AttendanceProvider>().fetchData(user);
      }
    });
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.fingerprint_rounded, label: 'Absensi'),
    _NavItem(icon: Icons.campaign_rounded, label: 'Pengumuman'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const AppLogo(size: 32, showTagline: false, horizontal: true),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, user, attendance),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody(BuildContext context, user, AttendanceProvider attendance) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await attendance.fetchData(user);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              _buildGreetingCard(context, user),
              const SizedBox(height: 20),

              // Quick Actions
              Text(
                'Aksi Cepat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // Absensi Hari Ini (GPS Validation)
              Text(
                'Absensi GPS',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildDynamicClockButton(context, user, attendance),
              const SizedBox(height: 20),

              // Attendance Summary
              Text(
                'Kehadiran Minggu Ini',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildAttendanceSummary(context, attendance),
              const SizedBox(height: 20),

              // Riwayat Absensi Terakhir
              Text(
                'Riwayat Absensi Terakhir',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildAttendanceHistory(context, attendance),
              const SizedBox(height: 20),

              // Announcements
              Text(
                'Pengumuman Terbaru',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildAnnouncementPlaceholders(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicClockButton(BuildContext context, user, AttendanceProvider attendance) {
    if (attendance.isLoading && attendance.todayRecords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (attendance.hasClockedOutToday) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
            const SizedBox(height: 8),
            Text(
              'Anda sudah menyelesaikan absensi hari ini.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    final type = attendance.hasClockedInToday ? AttendanceType.clockOut : AttendanceType.clockIn;

    return ClockInButton(
      attendanceType: type,
      onClockSuccess: (result, type) async {
        if (user != null) {
          final partial = AttendanceRecord(
            id: '',
            userId: user.uid,
            userName: user.name,
            type: type,
            timestamp: result.timestamp,
            status: result.status.label,
            distanceInMeters: result.distanceInMeters,
          );
          await attendance.clock(user, type, partial);
        }
      },
    );
  }

  Widget _buildGreetingCard(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.welcomeBack,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withAlpha(200),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Karyawan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined,
                          color: AppColors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.employeeRole,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.white.withAlpha(38),
            child: Text(
              user?.name.isNotEmpty == true
                  ? user!.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
          icon: Icons.fingerprint_rounded,
          label: 'Absen\nMasuk',
          color: AppColors.success),
      _QuickAction(
          icon: Icons.login_rounded,
          label: 'Absen\nKeluar',
          color: AppColors.info),
      _QuickAction(
          icon: Icons.assignment_outlined,
          label: 'Izin\n& Cuti',
          color: AppColors.warning),
      _QuickAction(
          icon: Icons.history_rounded,
          label: 'Riwayat\nAbsensi',
          color: AppColors.secondary),
    ];

    return Row(
      children: actions
          .map((action) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildQuickActionCard(context, action),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, _QuickAction action) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary(BuildContext context, AttendanceProvider attendance) {
    final stats = attendance.weeklyStats;
    final statList = [
      _AttendanceStat(label: 'Hadir', value: '${stats['present'] ?? 0}', color: AppColors.success),
      _AttendanceStat(label: 'Telat', value: '${stats['late'] ?? 0}', color: AppColors.warning),
      _AttendanceStat(label: 'Alpha', value: '${stats['absent'] ?? 0}', color: AppColors.error),
      _AttendanceStat(label: 'Izin', value: '${stats['leave'] ?? 0}', color: AppColors.secondary),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: statList
            .map((s) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        s.value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: s.color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAttendanceHistory(BuildContext context, AttendanceProvider attendance) {
    if (attendance.isLoading && attendance.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (attendance.history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Belum ada riwayat absensi.', textAlign: TextAlign.center),
      );
    }

    return Column(
      children: attendance.history.map((record) {
        final isClockIn = record.type == AttendanceType.clockIn;
        final iconColor = isClockIn ? AppColors.success : AppColors.info;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryCard),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isClockIn ? Icons.login_rounded : Icons.logout_rounded,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClockIn ? 'Clock In' : 'Clock Out',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year} ${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                record.status == 'IN_AREA' ? 'Valid' : 'Invalid',
                style: TextStyle(
                  color: record.status == 'IN_AREA' ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnnouncementPlaceholders(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryCard),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i == 0 ? 'Perubahan Jam Operasional' : 'Safety Briefing',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i == 0
                          ? 'Efektif mulai 1 Juni 2025'
                          : 'Wajib hadir - Senin, 2 Juni 2025',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(top: BorderSide(color: AppColors.primaryCard)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 3) {
            _showLogoutDialog();
            return;
          }
          setState(() => _selectedIndex = i);
        },
        items: _navItems
            .asMap()
            .entries
            .map((e) => BottomNavigationBarItem(
                  icon: Icon(e.value.icon),
                  label: e.value.label,
                ))
            .toList(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logoutButton),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction(
      {required this.icon, required this.label, required this.color});
}

class _AttendanceStat {
  final String label;
  final String value;
  final Color color;
  const _AttendanceStat(
      {required this.label, required this.value, required this.color});
}
