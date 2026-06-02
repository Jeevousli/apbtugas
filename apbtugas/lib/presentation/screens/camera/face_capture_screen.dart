import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/face_capture_provider.dart';
import 'face_failed_screen.dart';
import 'face_success_screen.dart';
import '../../../domain/entities/attendance_record.dart';

// ═══════════════════════════════════════════════════════════════════════
// FaceCaptureScreen
// ═══════════════════════════════════════════════════════════════════════

class FaceCaptureScreen extends StatelessWidget {
  /// Attendance type passed from GPS screen (clockIn or clockOut)
  final AttendanceType attendanceType;
  final String userId;
  final String userName;
  final String gpsStatus;
  final double distanceInMeters;

  const FaceCaptureScreen({
    super.key,
    required this.attendanceType,
    required this.userId,
    required this.userName,
    required this.gpsStatus,
    required this.distanceInMeters,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaceCaptureProvider(),
      child: _FaceCaptureView(
        attendanceType: attendanceType,
        userId: userId,
        userName: userName,
        gpsStatus: gpsStatus,
        distanceInMeters: distanceInMeters,
      ),
    );
  }
}

class _FaceCaptureView extends StatefulWidget {
  final AttendanceType attendanceType;
  final String userId;
  final String userName;
  final String gpsStatus;
  final double distanceInMeters;

  const _FaceCaptureView({
    required this.attendanceType,
    required this.userId,
    required this.userName,
    required this.gpsStatus,
    required this.distanceInMeters,
  });

  @override
  State<_FaceCaptureView> createState() => _FaceCaptureViewState();
}

class _FaceCaptureViewState extends State<_FaceCaptureView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (mounted) {
        await context.read<FaceCaptureProvider>().initCamera(cameras);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FaceCaptureProvider>();
    final size = MediaQuery.of(context).size;

    // Navigate to result screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (provider.status == FaceValidationStatus.success &&
          provider.selfieUrl != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FaceSuccessScreen(
              selfieImagePath: provider.capturedImagePath!,
              selfieUrl: provider.selfieUrl!,
              attendanceType: widget.attendanceType,
              userId: widget.userId,
              userName: widget.userName,
              gpsStatus: widget.gpsStatus,
              distanceInMeters: widget.distanceInMeters,
            ),
          ),
        );
      } else if (provider.status == FaceValidationStatus.failed &&
          provider.capturedImagePath == null) {
        // Only navigate to failed if error is unrecoverable (not during stream)
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Camera Preview ──────────────────────────────────────────
          if (provider.isCameraReady)
            _buildCameraPreview(provider, size)
          else
            _buildCameraPlaceholder(),

          // ─── Top Bar ─────────────────────────────────────────────────
          _buildTopBar(context),

          // ─── Alignment Oval Frame ────────────────────────────────────
          _buildAlignmentFrame(provider, size),

          // ─── Bottom HUD ──────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomHUD(context, provider),
          ),

          // ─── Capture button ──────────────────────────────────────────
          if (provider.status == FaceValidationStatus.capturing ||
              provider.status == FaceValidationStatus.uploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.secondary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.statusMessage,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(FaceCaptureProvider provider, Size size) {
    final ctrl = provider.cameraController!;
    final previewSize = ctrl.value.previewSize!;
    final previewRatio = previewSize.height / previewSize.width;

    return ClipRect(
      child: Transform(
        // Mirror front camera horizontally
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width * previewRatio,
            child: CameraPreview(ctrl),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      color: const Color(0xFF0A0F1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              'Mempersiapkan kamera...',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.75),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifikasi Wajah',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.attendanceType == AttendanceType.clockIn
                        ? 'Absen Masuk'
                        : 'Absen Keluar',
                    style: GoogleFonts.poppins(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignmentFrame(FaceCaptureProvider provider, Size size) {
    final passed = provider.status == FaceValidationStatus.passed;
    final frameColor = _getFrameColor(provider.status);

    return Center(
      child: ScaleTransition(
        scale: _pulseAnim,
        child: CustomPaint(
          size: Size(size.width * 0.68, size.width * 0.85),
          painter: _OvalFramePainter(
            color: frameColor,
            strokeWidth: passed ? 3.5 : 2.5,
            dashPattern: passed ? null : [12, 8],
          ),
        ),
      ),
    );
  }

  Color _getFrameColor(FaceValidationStatus status) {
    switch (status) {
      case FaceValidationStatus.passed:
        return AppColors.success;
      case FaceValidationStatus.noFace:
      case FaceValidationStatus.multipleFaces:
        return AppColors.error;
      case FaceValidationStatus.blurry:
      case FaceValidationStatus.tooDark:
        return AppColors.warning;
      default:
        return Colors.white.withValues(alpha: 0.6);
    }
  }

  Widget _buildBottomHUD(BuildContext context, FaceCaptureProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
          stops: const [0, 0.6, 1],
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 28,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Validation Indicators ─────────────────────────────
          _buildValidationBadges(provider),
          const SizedBox(height: 16),

          // ─── Status Message ────────────────────────────────────
          _buildStatusMessage(provider),
          const SizedBox(height: 20),

          // ─── Capture Button ────────────────────────────────────
          _buildCaptureButton(context, provider),
        ],
      ),
    );
  }

  Widget _buildValidationBadges(FaceCaptureProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ValidationBadge(
          icon: Icons.face_rounded,
          label: provider.faceCount == 1 ? '1 Wajah' : '${provider.faceCount} Wajah',
          isOk: provider.faceCount == 1,
          isError: provider.faceCount == 0 || provider.faceCount > 1,
        ),
        const SizedBox(width: 8),
        _ValidationBadge(
          icon: Icons.center_focus_strong_rounded,
          label: provider.sharpnessScore >= 8 ? 'Tajam' : 'Blur',
          isOk: provider.sharpnessScore >= 8,
          isError: provider.sharpnessScore > 0 && provider.sharpnessScore < 8,
        ),
        const SizedBox(width: 8),
        _ValidationBadge(
          icon: Icons.wb_sunny_rounded,
          label: provider.lightingStatus == LightingStatus.adequate
              ? 'Cukup Terang'
              : (provider.lightingStatus == LightingStatus.tooDark
                  ? 'Terlalu Gelap'
                  : 'Cahaya'),
          isOk: provider.lightingStatus == LightingStatus.adequate,
          isError: provider.lightingStatus == LightingStatus.tooDark,
        ),
      ],
    );
  }

  Widget _buildStatusMessage(FaceCaptureProvider provider) {
    final color = _getFrameColor(provider.status);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(provider.statusMessage),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStatusIcon(provider.status), color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                provider.statusMessage,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(FaceValidationStatus status) {
    switch (status) {
      case FaceValidationStatus.passed:
        return Icons.check_circle_rounded;
      case FaceValidationStatus.noFace:
        return Icons.face_retouching_off_rounded;
      case FaceValidationStatus.multipleFaces:
        return Icons.group_rounded;
      case FaceValidationStatus.blurry:
        return Icons.blur_on_rounded;
      case FaceValidationStatus.tooDark:
        return Icons.brightness_low_rounded;
      case FaceValidationStatus.capturing:
      case FaceValidationStatus.uploading:
        return Icons.hourglass_top_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildCaptureButton(
      BuildContext context, FaceCaptureProvider provider) {
    final canCapture = provider.canCapture;

    return GestureDetector(
      onTap: canCapture ? () => _onCapture(context, provider) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: canCapture
              ? const LinearGradient(
                  colors: [AppColors.secondaryDark, AppColors.secondary],
                )
              : null,
          color: canCapture ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canCapture
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              color: canCapture ? Colors.white : Colors.white38,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              canCapture ? 'Ambil Foto Sekarang' : 'Menunggu Validasi...',
              style: GoogleFonts.poppins(
                color: canCapture ? Colors.white : Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCapture(
      BuildContext context, FaceCaptureProvider provider) async {
    // Capture navigator before async gap
    final navigator = Navigator.of(context);
    final selfieUrl = await provider.captureAndUpload();
    if (!mounted) return;

    if (selfieUrl == null) {
      // Show failed screen
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => FaceFailedScreen(
            reason: provider.statusMessage,
            onRetry: () {
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (_) => FaceCaptureScreen(
                    attendanceType: widget.attendanceType,
                    userId: widget.userId,
                    userName: widget.userName,
                    gpsStatus: widget.gpsStatus,
                    distanceInMeters: widget.distanceInMeters,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    // If success, the addPostFrameCallback in build() handles navigation
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _ValidationBadge
// ═══════════════════════════════════════════════════════════════════════

class _ValidationBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOk;
  final bool isError;

  const _ValidationBadge({
    required this.icon,
    required this.label,
    required this.isOk,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOk
        ? AppColors.success
        : (isError ? AppColors.error : Colors.white38);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _OvalFramePainter — draws a dashed or solid oval alignment frame
// ═══════════════════════════════════════════════════════════════════════

class _OvalFramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double>? dashPattern;

  _OvalFramePainter({
    required this.color,
    required this.strokeWidth,
    this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    if (dashPattern == null) {
      // Solid oval
      canvas.drawOval(rect, paint);

      // Corner accent marks
      _drawCornerMarks(canvas, rect, paint);
    } else {
      // Dashed oval via path metrics
      final path = Path()..addOval(rect);
      final dashPath = Path();
      final metrics = path.computeMetrics();

      for (final metric in metrics) {
        double distance = 0;
        int dashIndex = 0;
        while (distance < metric.length) {
          final dashLen = dashPattern![dashIndex % dashPattern!.length];
          dashIndex++;
          final gapLen = dashPattern![dashIndex % dashPattern!.length];
          dashIndex++;

          final end =
              (distance + dashLen).clamp(0.0, metric.length);
          dashPath.addPath(
            metric.extractPath(distance, end),
            Offset.zero,
          );
          distance += dashLen + gapLen;
        }
      }
      canvas.drawPath(dashPath, paint);
    }
  }

  void _drawCornerMarks(Canvas canvas, Rect oval, Paint paint) {
    final markPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.5
      ..strokeCap = StrokeCap.round;

    final cx = oval.center.dx;
    final cy = oval.center.dy;
    final rx = oval.width / 2;
    final ry = oval.height / 2;
    const markLen = 22.0;

    // Top
    canvas.drawLine(
        Offset(cx - markLen / 2, cy - ry), Offset(cx + markLen / 2, cy - ry), markPaint);
    // Bottom
    canvas.drawLine(
        Offset(cx - markLen / 2, cy + ry), Offset(cx + markLen / 2, cy + ry), markPaint);
    // Left
    canvas.drawLine(
        Offset(cx - rx, cy - markLen / 2), Offset(cx - rx, cy + markLen / 2), markPaint);
    // Right
    canvas.drawLine(
        Offset(cx + rx, cy - markLen / 2), Offset(cx + rx, cy + markLen / 2), markPaint);
  }

  @override
  bool shouldRepaint(_OvalFramePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashPattern != dashPattern;
}
