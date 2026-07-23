import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/domain/entities/tracking_type.dart';

// ignore_for_file: avoid_classes_with_only_static_members
class AppTheme {
  const AppTheme();

  // ── Spacing scale (4pt-based) ──────────────────────────────
  static const double spacingXs = 2;
  static const double spacingSm = 4;
  static const double spacingMd = 8;
  static const double spacingLg = 12;
  static const double spacingXl = 16;
  static const double spacingXxl = 24;
  static const double spacingXXXl = 32;
  static const double spacingJumbo = 48;

  // ── Shape tokens ───────────────────────────────────────────
  static const double shapeBottomSheetRadius = 16;
  static const double shapeCardRadius = 16;
  static const double shapeChipRadius = 20;
  static const double shapeButtonRadius = 20;

  // ── Design tokens (border radius) ──────────────────────────
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusExtraLarge = 20;
  static const double borderRadiusJumbo = 24;

  // ── Color palette (tracking-type accents, mode-agnostic) ─────
  // WCAG AA compliant variants — adjusted from neon for readability on both themes
  static const Color miam = Color(0xFFFFE082);  // soft yellow, was #F7F72A
  static const Color sante = Color(0xFF66BB6A); // accessible green, was #22FC00
  static const Color caca = Color(0xFF5D4037);  // brown, was #373A0E
  static const Color dodo = Color(0xFF42A5F5);  // blue, was #279FEA

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

  // ── Safe color utility for title text on any card background ──
  static Color textPrimaryForTint([Color? tint]) {
    return (tint?.computeLuminance() ?? 0) > 0.17 ? Colors.black : Colors.white;
  }

  // ── System chrome overlay style helpers ──
  /// Returns [SystemUiOverlayStyle] for the current [ThemeData].
  static SystemUiOverlayStyle overlayStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }

  // ── Dark Theme colors ────────────────────────────────────────
  static const Color darkBackground = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkDividerColor = Color(0xFF3A3A3A);
  static const Color darkDialogBackground = Color(0xFF262626);
  static const Color darkCardColor = Color(0xFF333333);
  static const Color darkInputFillColor = Color(0xFF404040);

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
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFF999999)),
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
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: darkBackground,
          foregroundColor: darkTextPrimary,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          backgroundColor: darkCardColor,
          contentTextStyle: TextStyle(color: darkTextPrimary),
          actionTextColor: sante,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: sante,
          unselectedItemColor: darkTextSecondary,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          elevation: 8,
          backgroundColor: darkBackground,
          selectedIconTheme: IconThemeData(size: 24),
          unselectedIconTheme: IconThemeData(size: 24),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: darkDialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(shapeBottomSheetRadius)),
          ),
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
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
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
          shadowColor: Colors.black12,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: lightBackground,
          foregroundColor: lightTextPrimary,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          backgroundColor: lightCardColor,
          contentTextStyle: TextStyle(color: lightTextPrimary),
          actionTextColor: sante,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: sante,
          unselectedItemColor: lightTextSecondary,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          elevation: 8,
          backgroundColor: lightBackground,
          selectedIconTheme: IconThemeData(size: 24),
          unselectedIconTheme: IconThemeData(size: 24),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: lightDialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(shapeBottomSheetRadius)),
          ),
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

  // ── ColorScheme extensions for tracking-type accents ─────────
  /// Returns the tracking accent color for the given type, respecting theme brightness.
  /// Use `colorScheme.trackingAccent(TrackingType.miam)` instead of `AppTheme.miam`.
  static Color trackingAccent(ColorScheme scheme, TrackingType type) {
    return switch (type) {
      TrackingType.miam => miam,
      TrackingType.sante => sante,
      TrackingType.caca => caca,
      TrackingType.dodo => dodo,
    };
  }

  /// Returns the appropriate text color to place on top of a tracking accent.
  /// Dark text on light accents, white text on dark accents.
  static Color trackingOnAccent(ColorScheme scheme, TrackingType type) {
    final accent = trackingAccent(scheme, type);
    return accent.computeLuminance() > 0.17 ? Colors.black87 : Colors.white;
  }

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
