import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF6B4A2B);
  static const Color paper = Color(0xFFF7F2E9);
  static const Color ink = Color(0xFF2B2118);
  static const Color mutedInk = Color(0xFF5E5448);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
