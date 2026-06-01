import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette — Deep Navy
  static const Color primary = Color(0xFF0A1931);
  static const Color primaryLight = Color(0xFF112244);
  static const Color primaryDark = Color(0xFF060E1D);
  static const Color primaryCard = Color(0xFF1A2F55);
  static const Color primarySurface = Color(0xFF0F1E3D);

  // Secondary Palette — Safety Orange
  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryLight = Color(0xFFFF8C42);
  static const Color secondaryDark = Color(0xFFE5521C);
  static const Color secondaryPale = Color(0xFFFFEDE6);

  // Text Colors
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8FA0C0);
  static const Color textMuted = Color(0xFF5A6E8A);
  static const Color textDark = Color(0xFF0A1931);

  // Functional Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFD5F5E3);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFEBF5FB);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF5F7FA);
  static const Color grey200 = Color(0xFFE4E9F0);
  static const Color grey300 = Color(0xFFCDD5E0);
  static const Color grey400 = Color(0xFF9AABBB);
  static const Color grey500 = Color(0xFF6B7A8D);
  static const Color grey600 = Color(0xFF4A5568);
  static const Color grey700 = Color(0xFF2D3748);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryDark, secondary, secondaryLight],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary, Color(0xFF0D2347)],
  );

  // Role Colors
  static const Color adminBadge = Color(0xFFFF6B35);
  static const Color employeeBadge = Color(0xFF3498DB);
}
