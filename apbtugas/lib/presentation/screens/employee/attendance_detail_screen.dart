import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final String recordId;

  const AttendanceDetailScreen({super.key, required this.recordId});

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<AttendanceProvider>().fetchAttendanceDetail(user.uid, widget.recordId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final record = attendanceProvider.selectedRecord;
    final isLoading = attendanceProvider.isLoadingDetail;
    final errorMessage = attendanceProvider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kehadiran'),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: _buildBody(context, isLoading, errorMessage, record),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isLoading, String? errorMessage, AttendanceRecord? record) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat detail kehadiran',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (record == null) {
      return const Center(
        child: Text(
          'Data absensi tidak ditemukan',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final isClockIn = record.type == AttendanceType.clockIn;
    final statusColor = _getStatusColor(record.attendanceStatus);
    final statusName = _getStatusName(record.attendanceStatus);
    final locationValid = record.status == 'IN_AREA';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CARD 1: Status & Waktu ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isClockIn ? AppColors.success : AppColors.info).withAlpha(25),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isClockIn ? Icons.login_rounded : Icons.logout_rounded,
                            color: isClockIn ? AppColors.success : AppColors.info,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isClockIn ? 'CLOCK IN' : 'CLOCK OUT',
                            style: TextStyle(
                              color: isClockIn ? AppColors.success : AppColors.info,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        statusName.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _formatTime(record.timestamp),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDateFull(record.timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CARD 2: Foto Selfie ──
          if (record.selfieUrl != null && record.selfieUrl!.isNotEmpty) ...[
            Text(
              'Foto Selfie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondary.withAlpha(15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildSelfieImage(record.selfieUrl!),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── CARD 3: Lokasi & Map ──
          Text(
            'Lokasi & Koordinat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          locationValid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          color: locationValid ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          locationValid ? 'Lokasi Valid (Dalam Area)' : 'Di Luar Radius Kantor',
                          style: TextStyle(
                            color: locationValid ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '±${record.distanceInMeters.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (record.latitude != null && record.longitude != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed_rounded, color: AppColors.secondary, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          '${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (record.address != null && record.address!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    record.address!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                if (record.latitude != null && record.longitude != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        "https://static-maps.yandex.ru/1.x/?ll=${record.longitude},${record.latitude}&z=16&l=map&size=450,200",
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.secondary),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primaryDark,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_rounded, color: AppColors.textSecondary, size: 36),
                                  SizedBox(height: 8),
                                  Text(
                                    'Peta tidak tersedia offline',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CARD 4: Catatan / Notes ──
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            Text(
              'Catatan / Keterangan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withAlpha(10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      record.notes!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelfieImage(String selfieUrl) {
    if (selfieUrl.startsWith('data:image')) {
      try {
        final base64Data = selfieUrl.substring(selfieUrl.indexOf(',') + 1);
        final decodedBytes = base64Decode(base64Data);
        return Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.error),
        );
      }
    }

    return Image.network(
      selfieUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary, size: 40),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateFull(DateTime dt) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month]} ${dt.year}';
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
