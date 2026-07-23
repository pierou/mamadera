import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';

void main() {
  group('AppTheme color constants', () {
    test('darkBackground is correct dark gray', () {
      expect(AppTheme.darkBackground, equals(const Color(0xFF2D2D2D)));
    });

    test('miam is soft yellow-ish color', () {
      expect(
        AppTheme.miam,
        equals(const Color(0xFFFFE082)),
      );
    });

    test('sante is accessible green color', () {
      expect(AppTheme.sante, equals(const Color(0xFF66BB6A)));
    });

    test('caca is brown color', () {
      expect(
        AppTheme.caca,
        equals(const Color(0xFF5D4037)),
      );
    });

    test('dodo is blue color', () {
      expect(AppTheme.dodo, equals(const Color(0xFF42A5F5)));
    });

    test('darkTextPrimary is Colors.white', () {
      expect(AppTheme.darkTextPrimary, equals(Colors.white));
    });

    test('darkTextSecondary is light gray', () {
      expect(AppTheme.darkTextSecondary, equals(const Color(0xFFAAAAAA)));
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

    test('scaffoldBackgroundColor matches darkBackground constant', () {
      final theme = AppTheme.theme;

      expect(theme.scaffoldBackgroundColor, equals(AppTheme.darkBackground));
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

    test('surfaceContainerHighest matches darkDialogBackground constant', () {
      final theme = AppTheme.theme;

      expect(
        theme.colorScheme.surfaceContainerHighest,
        equals(AppTheme.darkDialogBackground),
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

      expect(theme.textTheme.bodyLarge?.fontSize, equals(18.0));
    });

    test('AppTheme can be instantiated with const constructor', () {
      // Covers the const AppTheme() constructor line.
      const instance = AppTheme();
      expect(instance, isA<AppTheme>());
    });
  });

  group('AppTheme textPrimaryForTint', () {
    test('returns black for light colors (luminance > 0.17)', () {
      expect(AppTheme.textPrimaryForTint(Colors.white), equals(Colors.black));
      expect(AppTheme.textPrimaryForTint(Colors.grey.shade200), equals(Colors.black));
    });

    test('returns white for dark colors (luminance <= 0.17)', () {
      expect(AppTheme.textPrimaryForTint(Colors.black), equals(Colors.white));
      expect(AppTheme.textPrimaryForTint(const Color(0xFF1A1A1A)), equals(Colors.white));
    });

    test('returns white when tint is null', () {
      expect(AppTheme.textPrimaryForTint(null), equals(Colors.white));
    });
  });

  group('AppTheme overlayStyle', () {
    test('returns correct overlay style for dark theme', () {
      final darkTheme = AppTheme.darkTheme;
      final overlay = AppTheme.overlayStyle(darkTheme);

      expect(overlay.statusBarColor, equals(Colors.transparent));
      expect(overlay.statusBarIconBrightness, equals(Brightness.light));
      expect(overlay.systemNavigationBarIconBrightness, equals(Brightness.light));
      expect(overlay.systemNavigationBarColor, equals(darkTheme.scaffoldBackgroundColor));
    });

    test('returns correct overlay style for light theme', () {
      final lightTheme = AppTheme.lightTheme;
      final overlay = AppTheme.overlayStyle(lightTheme);

      expect(overlay.statusBarColor, equals(Colors.transparent));
      expect(overlay.statusBarIconBrightness, equals(Brightness.dark));
      expect(overlay.systemNavigationBarIconBrightness, equals(Brightness.dark));
      expect(overlay.systemNavigationBarColor, equals(lightTheme.scaffoldBackgroundColor));
    });
  });

  group('AppTheme accentForTrackingType', () {
    test('returns miam color for miam type', () {
      expect(AppTheme.accentForTrackingType('miam'), equals(AppTheme.miam));
    });

    test('returns sante color for sante type', () {
      expect(AppTheme.accentForTrackingType('sante'), equals(AppTheme.sante));
    });

    test('returns caca color for caca type', () {
      expect(AppTheme.accentForTrackingType('caca'), equals(AppTheme.caca));
    });

    test('returns grey for unknown type including dodo', () {
      expect(AppTheme.accentForTrackingType('dodo'), equals(Colors.grey.shade700));
      expect(AppTheme.accentForTrackingType('unknown'), equals(Colors.grey.shade700));
    });

    test('handles uppercase type names', () {
      expect(AppTheme.accentForTrackingType('MIAM'), equals(AppTheme.miam));
      expect(AppTheme.accentForTrackingType('SANTE'), equals(AppTheme.sante));
    });
  });

  group('AppTheme lightTheme', () {
    test('returns ThemeData with Material3 enabled', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
    });

    test('light theme has light brightness', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, equals(Brightness.light));
    });

    test('light theme scaffoldBackgroundColor matches lightBackground', () {
      final theme = AppTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, equals(AppTheme.lightBackground));
    });

    test('light theme colorScheme is light with sante as primary', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(AppTheme.sante));
    });

    test('light theme onSurface is lightTextPrimary', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.onSurface, equals(AppTheme.lightTextPrimary));
    });

    test('light theme card has elevation 2 and white color', () {
      final theme = AppTheme.lightTheme;
      expect(theme.cardTheme.elevation, equals(2));
      expect(theme.cardTheme.color, equals(AppTheme.lightCardColor));
    });

    test('light theme inputDecoration has correct fillColor', () {
      final theme = AppTheme.lightTheme;
      expect(theme.inputDecorationTheme.fillColor, equals(AppTheme.lightInputFillColor));
      expect(theme.inputDecorationTheme.filled, isTrue);
    });
  });

  group('AppTheme button themes', () {
    test('darkTheme has outlinedButtonTheme configured', () {
      final theme = AppTheme.darkTheme;
      expect(theme.outlinedButtonTheme, isNotNull);
      expect(theme.outlinedButtonTheme.style?.foregroundColor?.resolve({}), equals(AppTheme.sante));
    });

    test('darkTheme has elevatedButtonTheme with sante background', () {
      final theme = AppTheme.darkTheme;
      expect(theme.elevatedButtonTheme, isNotNull);
      expect(
        theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
        equals(AppTheme.sante),
      );
    });

    test('darkTheme has filledButtonTheme with sante background', () {
      final theme = AppTheme.darkTheme;
      expect(theme.filledButtonTheme, isNotNull);
      expect(
        theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
        equals(AppTheme.sante),
      );
    });

    test('darkTheme has textButtonTheme with sante foreground', () {
      final theme = AppTheme.darkTheme;
      expect(theme.textButtonTheme, isNotNull);
      expect(theme.textButtonTheme.style?.foregroundColor?.resolve({}), equals(AppTheme.sante));
    });
  });

  group('AppTheme border radius constants', () {
    test('borderRadiusSmall is 8', () {
      expect(AppTheme.borderRadiusSmall, equals(8.0));
    });

    test('borderRadiusMedium is 12', () {
      expect(AppTheme.borderRadiusMedium, equals(12.0));
    });

    test('borderRadiusLarge is 16', () {
      expect(AppTheme.borderRadiusLarge, equals(16.0));
    });

    test('borderRadiusExtraLarge is 20', () {
      expect(AppTheme.borderRadiusExtraLarge, equals(20.0));
    });

    test('borderRadiusJumbo is 24', () {
      expect(AppTheme.borderRadiusJumbo, equals(24.0));
    });
  });

  group('AppTheme light theme colors', () {
    test('lightBackground is correct color', () {
      expect(AppTheme.lightBackground, equals(const Color(0xFFF5F5F5)));
    });

    test('lightTextPrimary is correct color', () {
      expect(AppTheme.lightTextPrimary, equals(const Color(0xFF212121)));
    });

    test('lightTextSecondary is correct color', () {
      expect(AppTheme.lightTextSecondary, equals(const Color(0xFF757575)));
    });

    test('lightDividerColor is correct color', () {
      expect(AppTheme.lightDividerColor, equals(const Color(0xFFE0E0E0)));
    });

    test('lightDialogBackground is white', () {
      expect(AppTheme.lightDialogBackground, equals(Colors.white));
    });

    test('lightCardColor is white', () {
      expect(AppTheme.lightCardColor, equals(Colors.white));
    });

    test('lightInputFillColor is correct color', () {
      expect(AppTheme.lightInputFillColor, equals(const Color(0xFFF9F9F9)));
    });
  });

  group('AppTheme dark theme colors', () {
    test('darkCardColor is correct color', () {
      expect(AppTheme.darkCardColor, equals(const Color(0xFF333333)));
    });

    test('darkInputFillColor is correct color', () {
      expect(AppTheme.darkInputFillColor, equals(const Color(0xFF404040)));
    });

    test('darkDialogBackground is correct color', () {
      expect(AppTheme.darkDialogBackground, equals(const Color(0xFF262626)));
    });

    test('darkDividerColor is correct color', () {
      expect(AppTheme.darkDividerColor, equals(const Color(0xFF3A3A3A)));
    });
  });

  group('AppTheme theme getter alias', () {
    test('theme getter returns darkTheme', () {
      expect(AppTheme.theme, equals(AppTheme.darkTheme));
    });
  });
}
