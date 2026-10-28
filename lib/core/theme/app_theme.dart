import 'package:flutter/material.dart';

class AppTheme {
  static const _orange = Color(0xFFF67300);
  static const _olive = Color(0xFF687600);

  static ThemeData get light {
    final colors = ColorScheme.fromSeed(
      seedColor: _orange,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFFB94F00),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFE2CC),
      onPrimaryContainer: const Color(0xFF4B1D00),
      secondary: _olive,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFEAF0C6),
      onSecondaryContainer: const Color(0xFF252D00),
      surface: const Color(0xFFFFFCF6),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }
}
