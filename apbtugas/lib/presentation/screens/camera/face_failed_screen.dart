import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
// FaceFailedScreen — shown when face capture or upload fails
// ═══════════════════════════════════════════════════════════════════════

class FaceFailedScreen extends StatefulWidget {
  final String reason;
  final VoidCallback onRetry;
  final VoidCallback? onCancel;

  const FaceFailedScreen({
    super.key,
    required this.reason,
    required this.onRetry,
    this.onCancel,
  });

  @override
  State<FaceFailedScreen> createState() => _FaceFailedScreenState();
}

class _FaceFailedScreenState extends State<FaceFailedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _contentController;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _runEntryAnimation();
  }

  Future<void> _runEntryAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _shakeController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ─── Error Icon with shake ───────────────────────────────
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: _buildErrorIcon(),
                ),

                const SizedBox(height: 28),

                // ─── Content ─────────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        children: [
                          Text(
                            'Verifikasi Gagal',
                            style: GoogleFonts.poppins(
                              color: AppColors.error,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Proses verifikasi wajah tidak berhasil diselesaikan.',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // ─── Reason Card ──────────────────────────────
                          _buildReasonCard(),

                          const SizedBox(height: 20),

                          // ─── Tips List ────────────────────────────────
                          _buildTipsList(),

                          const Spacer(),

                          // ─── Action Buttons ───────────────────────────
                          _buildActions(context),
                        ],
                      ),
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

  Widget _buildErrorIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.07),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
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
                AppColors.error.withValues(alpha: 0.25),
                AppColors.error.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: const Icon(
            Icons.face_retouching_off_rounded,
            color: AppColors.error,
            size: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alasan Kegagalan',
                  style: GoogleFonts.poppins(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reason,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    final tips = [
      _Tip(
        icon: Icons.wb_sunny_rounded,
        iconColor: AppColors.warning,
        text: 'Pastikan ruangan cukup terang, hindari backlighting.',
      ),
      _Tip(
        icon: Icons.face_rounded,
        iconColor: AppColors.info,
        text: 'Pastikan hanya 1 wajah yang terlihat di kamera.',
      ),
      _Tip(
        icon: Icons.center_focus_strong_rounded,
        iconColor: AppColors.secondary,
        text: 'Tahan posisi agar gambar tidak blur.',
      ),
      _Tip(
        icon: Icons.wifi_rounded,
        iconColor: AppColors.success,
        text: 'Periksa koneksi internet untuk upload foto.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips untuk mencoba lagi:',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(t.icon, color: t.iconColor, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.text,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Retry button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              'Kembali ke Dashboard',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tip {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _Tip({required this.icon, required this.iconColor, required this.text});
}
