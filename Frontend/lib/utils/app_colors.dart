import 'package:flutter/material.dart';

/// Faruk Fashion - Classic Elegant Black & Gold Theme
class AppColors {
  // Primary Brand Colors (from banner)
  static const Color black = Color(0xFF0A0A0A);
  static const Color deepBlack = Color(0xFF050505);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color darkGrey = Color(0xFF2A2A2A);

  // Gold Accents
  static const Color gold = Color(0xFFD4AF37);
  static const Color richGold = Color(0xFFC9A227);
  static const Color lightGold = Color(0xFFE8D48B);
  static const Color softGold = Color(0xFFF5E6C8);

  // Text
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F5F0);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF888888);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF9A825);

  // Cards & Surfaces
  static const Color cardBg = Color(0xFF141414);
  static const Color surface = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF333333);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFC9A227), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blackGoldGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF1F1A0F), Color(0xFF0A0A0A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
