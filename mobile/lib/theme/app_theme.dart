import 'package:flutter/material.dart';

/// Krāsas un tipogrāfija no K2 dizaina pamatelementiem.
class AppColors {
  static const ink = Color(0xFF1E2A33);
  static const muted = Color(0xFF56626B);
  static const line = Color(0xFFD5DDDB);
  static const surface2 = Color(0xFFEEF3F1);
  static const primary = Color(0xFF1F5C4A);
  static const primaryWeak = Color(0xFFE3EFEA);
  static const danger = Color(0xFFB3261E);
  static const dangerBg = Color(0xFFFBE9E7);
}

ThemeData buildTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line, width: 1.5),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
      titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
