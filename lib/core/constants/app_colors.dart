import 'package:flutter/material.dart';

class AppColors {
  // Theme Primary Colors
  static const Color primary = Color(0xFF420093); // Purple from Figma
  static const Color primaryLight = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF4E45D5); // Indigo from Figma
  static const Color accent = Color(0xFF7C3AED); // Bright Purple

  // Neutral colors (Light Theme)
  static const Color bgLight = Color(0xFFFCF9F8); // Scaffold bg
  static const Color surfaceLight = Color(0xFFFFFFFF); // Card bg
  static const Color textDark = Color(0xFF1C1B1B); // Main heading text
  static const Color textMedium = Color(0xFF4A4453); // Subtitles/body text
  static const Color textLight = Color(0xFF7B7485); // Secondary body text
  static const Color textMuted = Color(0xFFCCC3D6); // Placeholders

  // Neutral colors (Dark Theme)
  static const Color bgDark = Color(0xFF121016);
  static const Color surfaceDark = Color(0xFF1D1B22);
  static const Color textLightDark = Color(0xFFE6E1E5);
  static const Color textMediumDark = Color(0xFFCAC4D0);

  // Status colors
  static const Color present = Color(0xFF16A34A); // Success Text
  static const Color presentDark = Color(0xFF15803D); // Success Badge Text
  static const Color presentBg = Color(0xFFDCFCE7); // Success Badge Bg

  static const Color absent = Color(0xFFBA1A1A); // Error Text
  static const Color absentDark = Color(0xFF93000A); // Error Badge Text
  static const Color absentBg = Color(0xFFFFDAD6); // Error Badge Bg

  static const Color late = Color(0xFFD97706); // Warning Text
  static const Color lateDark = Color(0xFFB45309); // Warning Badge Text
  static const Color lateBg = Color(0xFFFEF3C7); // Warning Badge Bg

  static const Color wfh = Color(0xFF4E45D5); // Info Text
  static const Color wfhDark = Color(0xFF372ABF); // Info Badge Text
  static const Color wfhBg = Color(0xFFE3DFFF); // Info Badge Bg

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryLight, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
