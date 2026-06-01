import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final bool horizontal;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showTagline = true,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoIcon = _buildLogoIcon();
    final textSection = _buildTextSection(context);

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoIcon,
          const SizedBox(width: 14),
          textSection,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        const SizedBox(height: 16),
        textSection,
      ],
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(76),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shield shape
          Icon(
            Icons.shield_rounded,
            color: AppColors.white.withAlpha(30),
            size: size * 0.7,
          ),
          // APB text
          Text(
            'APB',
            style: TextStyle(
              color: AppColors.white,
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'APB Connect',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: horizontal ? size * 0.25 : size * 0.22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Connecting People, Building Safety',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: horizontal ? size * 0.14 : size * 0.12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
