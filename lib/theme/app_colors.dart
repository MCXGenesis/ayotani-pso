import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF0B6138);
  static const teal = Color(0xFF0B5F61);
  static const lightGreenBg = Color(0xFFE8F5E9);
  static const darkGreenCard = Color(0xFF1E5E3F);
  static const borderGreen = Color(0xFFC8E6C9);
}

extension ThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get primaryColor => isDarkMode ? const Color(0xFF81C784) : AppColors.green;
  Color get secondaryColor => isDarkMode ? const Color(0xFF4DB6AC) : AppColors.teal;
  Color get scaffoldBg => isDarkMode ? const Color(0xFF0E1410) : Colors.white;
  Color get cardBg => isDarkMode ? const Color(0xFF18221B) : Colors.white;
  Color get lightGreenBg => isDarkMode ? const Color(0xFF1B2C21) : AppColors.lightGreenBg;
  Color get darkGreenCard => isDarkMode ? const Color(0xFF18221B) : AppColors.darkGreenCard;
  Color get borderGreen => isDarkMode ? const Color(0xFF2A382E) : AppColors.borderGreen;
  Color get textPrimary => isDarkMode ? const Color(0xFFE0E8E3) : Colors.black;
  Color get textSecondary => isDarkMode ? const Color(0xFFB0BEC5) : Colors.black54;
  Color get textMuted => isDarkMode ? Colors.white54 : Colors.grey;
  Color get bgGrey => isDarkMode ? const Color(0xFF18221B) : const Color(0xFFF5F5F5);
  Color get surfaceBg => isDarkMode ? const Color(0xFF18221B) : Colors.white;
  Color get dividerColor => isDarkMode ? const Color(0xFF2A382E) : const Color(0xFFE0E0E0);
}
