import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  late String _userId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _userId = authProvider.currentUser?.uid ?? '';
      context.read<AttendanceProvider>().fetchFilteredHistory(_userId);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<AttendanceProvider>().fetchFilteredHistory(_userId, isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final history = attendance.filteredHistory;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<AttendanceProvider>().fetchFilteredHistory(_userId);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header & Title ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Kehadiran',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cari dan filter riwayat kehadiran Anda',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ── Date Picker Search Bar ──
                      _buildDatePickerBar(context, attendance),
                      const SizedBox(height: 16),
                      
                      // ── Filter Status Chips ──
                      _buildFilterChips(attendance),
                    ],
                  ),
                ),
              ),

              // ── Content List ──
              if (attendance.isLoading && history.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  ),
                )
              else if (history.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryCard.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.textSecondary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada riwayat absensi',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba ubah filter atau tanggal pencarian',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == history.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          );
                        }
                        final record = history[index];
                        return _buildHistoryCard(context, record);
                      },
                      childCount: history.length + (attendance.hasMoreHistory ? 1 : 0),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerBar(BuildContext context, AttendanceProvider provider) {
    final searchDate = provider.searchDate;
    final dateText = searchDate == null
        ? 'Cari berdasarkan tanggal...'
        : '${searchDate.day} ${_getMonthName(searchDate.month)} ${searchDate.year}';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: searchDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.secondary,
                  onPrimary: AppColors.white,
                  surface: AppColors.primaryCard,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          provider.setSearchDate(_userId, picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withAlpha(20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateText,
                style: TextStyle(
                  color: searchDate == null ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            if (searchDate != null)
              GestureDetector(
                onTap: () => provider.setSearchDate(_userId, null),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(AttendanceProvider provider) {
    final statusList = [
      null, // Semua
      AttendanceStatus.hadir,
      AttendanceStatus.telat,
      AttendanceStatus.izin,
      AttendanceStatus.alpha,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusList.map((status) {
          final isSelected = provider.selectedFilter == status;
          final label = status == null ? 'Semua' : _getStatusName(status);
          final color = status == null ? AppColors.secondary : _getStatusColor(status);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => provider.setFilter(_userId, status),
              selectedColor: color,
              backgroundColor: AppColors.primaryCard,
              checkmarkColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? color : AppColors.primaryCard,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AttendanceRecord record) {
    final isClockIn = record.type == AttendanceType.clockIn;
    final statusColor = _getStatusColor(record.attendanceStatus);
    final statusName = _getStatusName(record.attendanceStatus);
    final iconColor = isClockIn ? AppColors.success : AppColors.info;

    return InkWell(
      onTap: () {
        context.push('${AppRoutes.attendanceDetail}?id=${record.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withAlpha(20)),
        ),
        child: Row(
          children: [
            // Icon representing clocking state
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isClockIn ? Icons.login_rounded : Icons.logout_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Middle info: Clock Type & Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isClockIn ? 'Clock In' : 'Clock Out',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(record.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            // Right info: Attendance Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      record.status == 'IN_AREA' ? 'WFO' : 'WFA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_getMonthName(dt.month)} ${dt.year} - $h:$m';
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month];
  }

  String _getStatusName(AttendanceStatus status) {
    switch (status) {
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

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
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
}
