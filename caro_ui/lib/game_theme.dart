import 'package:flutter/material.dart';

class AppColors {
  static const Color boardBackground = Color(0xFFF5F5DC);
  static const Color gridLines = Color(0xFFBDBDBD);
  static const Color player1 = Color(0xFFE53935);
  static const Color player2 = Color(0xFF1E88E5);
  static const Color player3 = Color(0xFF43A047);
  static const Color player4 = Color(0xFFFFB300);
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);
  static const Color background = Color(0xFFECEFF1);
}

final ThemeData gameTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.player2,
  scaffoldBackgroundColor: AppColors.background,
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: AppColors.primaryText,
      fontSize: 20,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.primaryText),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.secondaryText),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);
