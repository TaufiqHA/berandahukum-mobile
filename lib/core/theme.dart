import 'package:flutter/material.dart';

/// Tema "Modern Magazine": aksen merah, judul serif, latar terang.
class AppTheme {
  static const Color brand = Color(0xFFC1121F);
  static const Color brandStrong = Color(0xFF94111B);
  static const Color ink = Color(0xFF111110);
  static const Color ink600 = Color(0xFF4C4B46);
  static const Color ink500 = Color(0xFF6C6B65);
  static const Color line = Color(0xFFDCDBD6);
  static const Color tint = Color(0xFFF5F5F3);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: base.colorScheme.copyWith(
        primary: brand,
        secondary: brandStrong,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: brand,
        unselectedItemColor: ink500,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: ink)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5, fontSize: 13),
        ),
      ),
      textTheme: _textTheme(base.textTheme),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    TextStyle serif(TextStyle? s, double size) => (s ?? const TextStyle()).copyWith(
          fontFamily: 'serif',
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.12,
        );
    return base.copyWith(
      displaySmall: serif(base.displaySmall, 32),
      headlineMedium: serif(base.headlineMedium, 26),
      headlineSmall: serif(base.headlineSmall, 22),
      titleLarge: serif(base.titleLarge, 19),
      titleMedium: serif(base.titleMedium, 16),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.6, color: ink),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14.5, height: 1.6, color: ink600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .6, fontSize: 12),
    );
  }
}
