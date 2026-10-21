import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0E14);
  static const surface = Color(0xFF141B26);
  static const surfaceAlt = Color(0xFF1C2635);
  static const border = Color(0xFF2A3547);
  static const accent = Color(0xFF0EA5E9);
  static const text = Color(0xFFE5EAF2);
  static const muted = Color(0xFF8A97AB);
  static const lost = Color(0xFFEF4444);
  static const found = Color(0xFF10B981);
}

ThemeData buildTheme() {
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.border),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.lost,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.accent)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.2),
    ),
  );
}
