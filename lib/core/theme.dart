import 'package:flutter/material.dart';

// ignore_for_file: avoid_classes_with_only_static_members
class AppTheme {
  const AppTheme();

  // ── Design tokens (border radius) ───────────────────────────
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusExtraLarge = 20;
  static const double borderRadiusJumbo = 24;

  // ── Color palette (tracking-type accents, mode-agnostic) ─────
  static const Color miam = Color.fromARGB(255, 247, 247, 42);
  static const Color sante = Color.fromARGB(255, 34, 252, 0);
  static const Color caca = Color.fromARGB(255, 55, 58, 14);
  static const Color dodo = Color.fromARGB(255, 39, 159, 234);

  // ── Shared button/input configs (reused by both themes) ─────
  static OutlinedButtonThemeData _outlinedButtonTheme() => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: sante,
          side: const BorderSide(color: sante, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusExtraLarge)),
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme() => ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(sante),
          foregroundColor: WidgetStateProperty.all(Colors.black),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusExtraLarge))),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(sante),
          foregroundColor: WidgetStateProperty.all(Colors.black),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: ButtonStyle(foregroundColor: WidgetStateProperty.all(sante)),
      );

  // ── Dark Theme colors ────────────────────────────────────────
  static const Color darkBackground = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkDividerColor = Color(0xFF3A3A3A);
  static const Color darkDialogBackground = Color(0xFF262626);
  static const Color darkCardColor = Color(0xFF333333);
  static const Color darkInputFillColor = Color(0xFF404040);

  // Legacy aliases (backward compat with hardcoded widget usages)
  static const Color background = darkBackground;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color dividerColor = darkDividerColor;
  static const Color dialogBackground = darkDialogBackground;
  static const Color cardColor = darkCardColor;
  static const Color inputFillColor = darkInputFillColor;

  // ── Dark ThemeData ───────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: sante,
          onPrimary: Colors.black,
          secondary: dodo,
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          surface: darkBackground,
          onSurface: darkTextPrimary,
          onSurfaceVariant: darkTextSecondary,
          outline: darkDividerColor,
          primaryContainer: Color(0xFF1B5E20),
          secondaryContainer: Color(0xFF1A3A4D),
          surfaceContainerHighest: darkDialogBackground,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: darkTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondary),
          labelSmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
        ),
        outlinedButtonTheme: _outlinedButtonTheme(),
        elevatedButtonTheme: _elevatedButtonTheme(),
        filledButtonTheme: _filledButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkCardColor,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusLarge)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              borderSide: const BorderSide(color: darkDividerColor)),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: sante),
              borderRadius: BorderRadius.circular(borderRadiusMedium)),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: darkDividerColor),
              borderRadius: BorderRadius.circular(borderRadiusMedium)),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          filled: true,
          fillColor: darkInputFillColor,
        ),
      );

  // ── Light Theme colors ───────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightDividerColor = Color(0xFFE0E0E0);
  static const Color lightDialogBackground = Colors.white;
  static const Color lightCardColor = Colors.white;
  static const Color lightInputFillColor = Color(0xFFF9F9F9);

  // ── Light ThemeData ──────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: const ColorScheme.light(
          primary: sante,
          onPrimary: Colors.black,
          secondary: dodo,
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          surface: lightDialogBackground,
          onSurface: lightTextPrimary,
          onSurfaceVariant: lightTextSecondary,
          outline: lightDividerColor,
          primaryContainer: Color(0xFFA5D6A7),
          secondaryContainer: Color(0xFFB3E5FC),
          surfaceContainerHighest: lightDialogBackground,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
          bodyLarge: TextStyle(fontSize: 18, color: lightTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: lightTextSecondary),
          labelSmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF616161)),
        ),
        outlinedButtonTheme: _outlinedButtonTheme(),
        elevatedButtonTheme: _elevatedButtonTheme(),
        filledButtonTheme: _filledButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        cardTheme: CardThemeData(
          elevation: 2,
          color: lightCardColor,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusLarge)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              borderSide: const BorderSide(color: lightDividerColor)),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: sante),
              borderRadius: BorderRadius.circular(borderRadiusMedium)),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: lightDividerColor),
              borderRadius: BorderRadius.circular(borderRadiusMedium)),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          filled: true,
          fillColor: lightInputFillColor,
        ),
      );

  // ── Legacy alias (backward compat) ───────────────────────────
  static ThemeData get theme => darkTheme;

  // ── Helper: tracking type → accent color ─────────────────────
  static Color accentForTrackingType(String type) {
    switch (type.toLowerCase()) {
      case 'miam':
        return miam;
      case 'sante':
        return sante;
      case 'caca':
        return caca;
      default:
        return Colors.grey.shade700;
    }
  }
}
