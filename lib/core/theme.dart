import 'package:flutter/material.dart';
// ignore_for_file: avoid_classes_with_only_static_members
class AppTheme {
  const AppTheme();

  static const Color background = Color(0xFF2D2D2D);
  static const Color miam = Color.fromARGB(255, 247, 247, 42);
  static const Color sante = Color.fromARGB(255, 34, 252, 0);
  static const Color caca = Color.fromARGB(255, 55, 58, 14);
  static const Color dodo = Color.fromARGB(255, 39, 159, 234);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFFAAAAAA);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: sante,
          onSurface: Colors.white,
          surfaceContainerHighest: Color(0xFF3A3A3A),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
          bodyLarge: TextStyle(fontSize: 20, color: textSecondary),
        ),
      );
}

