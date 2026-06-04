import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/errors/gps_exception.dart';
import '../../core/services/gps_validator.dart';
import '../../domain/entities/gps_status.dart';
import '../../domain/entities/gps_validation_result.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/notification_entity.dart';
import '../screens/camera/face_capture_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ClockInButton – example widget demonstrating GPSValidator usage
// ═══════════════════════════════════════════════════════════════════════════

/// A self-contained button widget that:
///  1. Validates GPS before allowing clock-in.
///  2. Shows loading state during validation.
///  3. Displays the validation result (distance, status).
///  4. On success, passes the [GpsValidationResult] upstream for Firestore write.
///
/// Usage in a screen:
/// ```dart
/// ClockInButton(
///   onClockInSuccess: (result) async {
///     // Save attendance to Firestore
///     await FirebaseFirestore.instance
///         .collection('attendance')
///         .doc(uid)
///         .collection('records')
///         .add({
///           ...result.toFirestore(),
///           'type': 'clock_in',
///           'userId': uid,
///         });
///   },
/// )
/// ```
class ClockInButton extends StatefulWidget {
  /// Called after GPS validation passes AND face capture succeeds.
  /// Receives the full [GpsValidationResult] for Firestore persistence.
  /// Note: After face integration, this is called from FaceSuccessScreen.
  final Future<void> Function(GpsValidationResult result, AttendanceType type)? onClockSuccess;

  /// Optional custom [GPSValidator] — useful for injecting a test double.
  final GPSValidator? validator;

  /// Whether this is for clock in or clock out. Default is clock_in.
  final AttendanceType attendanceType;

  const ClockInButton({
    super.key,
    this.onClockSuccess,
    this.validator,
    this.attendanceType = AttendanceType.clockIn,
  });

  @override
  State<ClockInButton> createState() => _ClockInButtonState();
}

class _ClockInButtonState extends State<ClockInButton>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  GpsValidationResult? _lastResult;
  String? _errorMessage;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── GPS validation flow ────────────────────────────────────────────────────

  Future<void> _handleClockIn() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
      _errorMessage = null;
    });

    try {
      final validator = widget.validator ?? GPSValidator();
      final result = await validator.validate();

      if (!mounted) return;
      setState(() => _lastResult = result);

      if (result.isInsideArea) {
        // ✅ GPS valid — navigate to Face Capture screen
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;
        if (user == null) {
          _showSnackBar('⚠️ Sesi tidak ditemukan. Silakan login ulang.', isError: true);
          return;
        }
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FaceCaptureScreen(
              attendanceType: widget.attendanceType,
              userId: user.uid,
              userName: user.name,
              gpsStatus: result.status.label,
              distanceInMeters: result.distanceInMeters,
            ),
          ),
        );
      } else {
        // ❌ User is too far from office
        if (mounted) {
          _showSnackBar(
            '❌ Anda berada ${result.formattedDistance} dari kantor. '
            'Anda harus berada dalam radius 500 m.',
            isError: true,
          );
          final title = '❌ Gagal Absen: Lokasi Kejauhan';
          final body = 'Anda berada ${result.formattedDistance} dari kantor. Mendekatlah ke radius 500m.';
          
          final provider = context.read<AttendanceProvider>();
          provider.fcmService.showLocalNotification(
            title: title,
            body: body,
            id: 30,
          );
          
          final user = context.read<AuthProvider>().currentUser;
          if (user != null) {
            provider.notificationRepository.saveNotification(
              user.uid,
              NotificationEntity(
                id: '',
                title: title,
                body: body,
                timestamp: DateTime.now(),
                type: NotificationType.gpsFailed,
                isRead: false,
              ),
            );
          }
        }
      }
    } on GpsException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      _showSnackBar('⚠️ ${e.message}', isError: true);
      final title = '⚠️ Gagal Absen: GPS Error';
      final body = e.message;
      
      final provider = context.read<AttendanceProvider>();
      provider.fcmService.showLocalNotification(
        title: title,
        body: body,
        id: 31,
      );
      
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        provider.notificationRepository.saveNotification(
          user.uid,
          NotificationEntity(
            id: '',
            title: title,
            body: body,
            timestamp: DateTime.now(),
            type: NotificationType.gpsFailed,
            isRead: false,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
      _showSnackBar('⚠️ Terjadi kesalahan tak terduga.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Clock-In Button ────────────────────────────────────────────────
        ScaleTransition(
          scale: _pulseAnimation,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleClockIn,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.location_on_rounded, size: 22),
              label: Text(
                _isLoading 
                    ? 'Memvalidasi lokasi...' 
                    : (widget.attendanceType == AttendanceType.clockIn ? 'Clock In' : 'Clock Out'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.attendanceType == AttendanceType.clockIn 
                    ? AppColors.primary 
                    : AppColors.info,
                foregroundColor: Colors.white,
                disabledBackgroundColor: (widget.attendanceType == AttendanceType.clockIn 
                    ? AppColors.primary 
                    : AppColors.info).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),

        // ── Last validation result card ────────────────────────────────────
        if (_lastResult != null) ...[
          const SizedBox(height: 16),
          _ValidationResultCard(result: _lastResult!),
        ],

        // ── Error display ──────────────────────────────────────────────────
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _ErrorCard(message: _errorMessage!),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the GPS validation result in a compact info card.
class _ValidationResultCard extends StatelessWidget {
  final GpsValidationResult result;

  const _ValidationResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isInArea = result.status == GpsStatus.inArea;
    final statusColor = isInArea ? Colors.green.shade400 : Colors.red.shade400;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isInArea ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                result.formattedDistance,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lat: ${result.userLatitude.toStringAsFixed(6)} | '
            'Lng: ${result.userLongitude.toStringAsFixed(6)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          Text(
            'Timestamp: ${result.timestamp.toLocal()}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a GPS error message.
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
