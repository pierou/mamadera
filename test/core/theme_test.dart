import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';

void main() {
  group('AppTheme color constants', () {
    test('background is correct dark gray', () {
      expect(AppTheme.background, equals(const Color(0xFF2D2D2D)));
    });

    test('miam is yellow-ish color', () {
      expect(
        AppTheme.miam,
        equals(const Color.fromARGB(255, 247, 247, 42)),
      );
    });

    test('sante is green color', () {
      expect(AppTheme.sante, equals(const Color.fromARGB(255, 34, 252, 0)));
    });

    test('caca is dark brown/green color', () {
      expect(
        AppTheme.caca,
        equals(const Color.fromARGB(255, 55, 58, 14)),
      );
    });

    test('dodo is blue color', () {
      expect(AppTheme.dodo, equals(const Color.fromARGB(255, 39, 159, 234)));
    });

    test('textPrimary is Colors.black', () {
      expect(AppTheme.textPrimary, equals(Colors.black));
    });

    test('textSecondary is light gray', () {
      expect(AppTheme.textSecondary, equals(const Color(0xFFAAAAAA)));
    });
  });

  group('AppTheme.theme getter', () {
    test('returns ThemeData with Material3 enabled', () {
      final theme = AppTheme.theme;

      expect(theme.useMaterial3, isTrue);
    });

    test('theme has dark brightness', () {
      final theme = AppTheme.theme;

      expect(theme.brightness, equals(Brightness.dark));
    });

    test('scaffoldBackgroundColor matches background constant', () {
      final theme = AppTheme.theme;

      expect(theme.scaffoldBackgroundColor, equals(AppTheme.background));
    });

    test('colorScheme is dark with sante as primary', () {
      final theme = AppTheme.theme;

      expect(theme.colorScheme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(AppTheme.sante));
    });

    test('onSurface in colorScheme is white', () {
      final theme = AppTheme.theme;

      expect(theme.colorScheme.onSurface, equals(Colors.white));
    });

    test('surfaceContainerHighest is dark gray', () {
      final theme = AppTheme.theme;

      expect(
        theme.colorScheme.surfaceContainerHighest,
        equals(const Color(0xFF3A3A3A)),
      );
    });

    test('headlineLarge text style has correct fontSize and fontWeight', () {
      final theme = AppTheme.theme;

      expect(theme.textTheme.headlineLarge?.fontSize, equals(32.0));
      expect(
        theme.textTheme.headlineLarge?.fontWeight,
        equals(FontWeight.bold),
      );
    });

    test('bodyLarge text style has correct fontSize', () {
      final theme = AppTheme.theme;

      expect(theme.textTheme.bodyLarge?.fontSize, equals(20.0));
    });

    test('AppTheme can be instantiated with const constructor', () {
      // Covers the const AppTheme() constructor line.
      const instance = AppTheme();
      expect(instance, isA<AppTheme>());
    });
  });
}
