import 'package:flutter/material.dart';

class AppTheme {
  static const _orange = Color(0xFFE96800);
  static const _orangeLight = Color(0xFFFFE6D1);
  static const _white = Color(0xFFFFFFFF);
  static const _warmWhite = Color(0xFFFFFBF7);

  static ThemeData get light {
    final colors = ColorScheme.fromSeed(
      seedColor: _orange,
      brightness: Brightness.light,
    ).copyWith(
      primary: _orange,
      onPrimary: _white,
      primaryContainer: _orangeLight,
      onPrimaryContainer: const Color(0xFF492000),
      secondary: const Color(0xFF98500C),
      onSecondary: _white,
      secondaryContainer: const Color(0xFFFFEBD6),
      onSecondaryContainer: const Color(0xFF321900),
      surface: _white,
      surfaceContainerLowest: _white,
      surfaceContainerLow: _warmWhite,
      surfaceContainer: const Color(0xFFFFF3E9),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: _warmWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: _white,
        foregroundColor: colors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: _white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFEBDD)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _white,
        indicatorColor: _orangeLight,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }
}
