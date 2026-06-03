import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// FaceSuccessScreen — shown after face captured & uploaded successfully
// ═══════════════════════════════════════════════════════════════════════

class FaceSuccessScreen extends StatefulWidget {
  final String selfieImagePath; // local path for display
  final String selfieUrl; // Firebase Storage URL
  final AttendanceType attendanceType;
  final String userId;
  final String userName;
  final String gpsStatus;
  final double distanceInMeters;

  const FaceSuccessScreen({
    super.key,
    required this.selfieImagePath,
    required this.selfieUrl,
    required this.attendanceType,
    required this.userId,
    required this.userName,
    required this.gpsStatus,
    required this.distanceInMeters,
  });

  @override
  State<FaceSuccessScreen> createState() => _FaceSuccessScreenState();
}

class _FaceSuccessScreenState extends State<FaceSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _contentController;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController,
          curve: const Interval(0, 0.3, curve: Curves.easeIn)),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _runEntryAnimation();
  }

  Future<void> _runEntryAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _checkController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _contentController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _confirmClockIn() async {
    if (_saved) return;
    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final attendance = context.read<AttendanceProvider>();
      final user = auth.currentUser;

      if (user != null) {
        // Determine attendanceStatus based on time (after 09:00 = telat)
        final now = DateTime.now();
        final isLate = now.hour > 9 || (now.hour == 9 && now.minute > 0);
        final attendanceStatus = widget.attendanceType == AttendanceType.clockIn
            ? (isLate ? AttendanceStatus.telat : AttendanceStatus.hadir)
            : AttendanceStatus.hadir;

        final record = AttendanceRecord(
          id: '',
          userId: widget.userId,
          userName: widget.userName,
          type: widget.attendanceType,
          timestamp: now,
          status: widget.gpsStatus,
          distanceInMeters: widget.distanceInMeters,
          selfieUrl: widget.selfieUrl,
          attendanceStatus: attendanceStatus,
        );
        await attendance.clock(user, widget.attendanceType, record);
      }

      if (!mounted) return;
      setState(() {
        _saved = true;
        _isSaving = false;
      });

      // Show brief success feedback then navigate
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go(AppRoutes.employeeDashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan absensi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClockIn = widget.attendanceType == AttendanceType.clockIn;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ─── Success Icon ───────────────────────────────────────
                AnimatedBuilder(
                  animation: _checkController,
                  builder: (_, child) => Opacity(
                    opacity: _checkOpacity.value,
                    child: Transform.scale(
                      scale: _checkScale.value,
                      child: child,
                    ),
                  ),
                  child: _buildSuccessIcon(),
                ),

                const SizedBox(height: 24),

                // ─── Content ────────────────────────────────────────────
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      children: [
                        // Title
                        Text(
                          'Verifikasi Berhasil!',
                          style: GoogleFonts.poppins(
                            color: AppColors.success,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isClockIn
                              ? 'Wajah Anda terverifikasi. Absen masuk berhasil.'
                              : 'Wajah Anda terverifikasi. Absen keluar berhasil.',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // ─── Selfie Preview ──────────────────────────────
                        _buildSelfiePreview(),

                        const SizedBox(height: 20),

                        // ─── Info Cards ──────────────────────────────────
                        _buildInfoCard(
                          icon: Icons.access_time_rounded,
                          label: 'Waktu',
                          value:
                              '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}',
                          color: AppColors.info,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.location_on_rounded,
                          label: 'Status GPS',
                          value: widget.gpsStatus == 'IN_AREA'
                              ? 'Dalam Area Kantor'
                              : 'Di Luar Area',
                          color: widget.gpsStatus == 'IN_AREA'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.social_distance_rounded,
                          label: 'Jarak dari Kantor',
                          value: '${widget.distanceInMeters.toStringAsFixed(0)} m',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.verified_user_rounded,
                          label: 'Tipe Absensi',
                          value: isClockIn ? 'Clock In' : 'Clock Out',
                          color: isClockIn ? AppColors.success : AppColors.info,
                        ),

                        const SizedBox(height: 28),

                        // ─── Confirm Button ──────────────────────────────
                        if (!_saved)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _confirmClockIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      'Simpan & Konfirmasi Absensi',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Absensi Tersimpan! Mengarahkan...',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow ring
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.success.withValues(alpha: 0.3),
                AppColors.success.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 52,
          ),
        ),
      ],
    );
  }

  Widget _buildSelfiePreview() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 130,
          height: 130,
          child: Image.file(
            File(widget.selfieImagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.primaryCard,
              child: const Icon(Icons.person_rounded,
                  color: AppColors.success, size: 60),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
