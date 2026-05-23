import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color primary = Color(0xFF1D9E75);      // Agri-green
  static const Color secondary = Color(0xFFEF9F27);    // Harvest amber
  static const Color backgroundLight = Color(0xFFF8FBF9); // Clean bg
  static const Color surfaceLight = Colors.white;
  static const Color cardShadowLight = Color(0x0A000000); // Super subtle shadow (no harsh shadows)
  
  static const Color textPrimaryLight = Color(0xFF1C221E);
  static const Color textSecondaryLight = Color(0xFF536056);
  static const Color borderLight = Color(0xFFE2EBE5);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF111814); // Sleek dark green-gray
  static const Color surfaceDark = Color(0xFF1A231E);
  static const Color cardShadowDark = Color(0x1F000000);

  static const Color textPrimaryDark = Color(0xFFE3EAE5);
  static const Color textSecondaryDark = Color(0xFF90A396);
  static const Color borderDark = Color(0xFF2C3931);

  // Status/Alert Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
}
