import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Clock In', 'Clock Out'];

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final history = _applyFilter(attendance.history);

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
          final user = context.read<AuthProvider>().currentUser;
          if (user != null) {
            await context.read<AttendanceProvider>().fetchData(user);
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Absensi',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan kehadiran Anda',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // ── Filter Chips ──
                    _buildFilterChips(),
                  ],
                ),
              ),
            ),

            // ── Content ──
            if (attendance.isLoading && history.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (history.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat absensi',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
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
                      final record = history[index];
                      return _buildHistoryCard(context, record);
                    },
                    childCount: history.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  List<AttendanceRecord> _applyFilter(List<AttendanceRecord> records) {
    if (_selectedFilter == 'Clock In') {
      return records.where((r) => r.type == AttendanceType.clockIn).toList();
    } else if (_selectedFilter == 'Clock Out') {
      return records.where((r) => r.type == AttendanceType.clockOut).toList();
    }
    return records;
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            selectedColor: AppColors.secondary,
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
                color: isSelected ? AppColors.secondary : AppColors.primaryCard,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AttendanceRecord record) {
    final isClockIn = record.type == AttendanceType.clockIn;
    final iconColor = isClockIn ? AppColors.success : AppColors.info;
    final statusColor =
        record.status == 'IN_AREA' ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withAlpha(30)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isClockIn ? Icons.login_rounded : Icons.logout_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClockIn ? 'Clock In' : 'Clock Out',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
          // Status & Distance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.status == 'IN_AREA' ? 'Valid' : 'Di Luar',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${record.distanceInMeters.toStringAsFixed(0)} m',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year} • $h:$m';
  }
}
