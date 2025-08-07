// caro_ui/lib/game_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color parchment = Color(0xFFF5EEDC);
  static const Color ink = Color(0xFF42291A);
  static const Color gridLines = Color(0x9942291A);
  static const Color woodFrame = Color(0xFF6D4C41);
  
  // Mảng màu cho 4 người chơi
  static const List<Color> playerColors = [
    Color(0xFF9E2B25), // Player 1
    Color(0xFF1E3A8A), // Player 2
    Color(0xFF14532D), // Player 3
    Color(0xFFB45309), // Player 4
  ];
  
  static const Color primaryText = ink;
  static const Color secondaryText = Color(0xCC42291A);
  static const Color background = parchment;
  static const Color highlight = Color(0xFFFFC107);
}

final ThemeData gameTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.playerColors[1],
  scaffoldBackgroundColor: AppColors.background,
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 20),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.primaryText, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(fontSize: 15, color: AppColors.secondaryText),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.ink,
    ),
  ),
);