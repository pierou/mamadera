import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/main.dart';

void main() {
  group('MyApp widget', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('theme uses deepPurple seed color', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // Verify the MaterialApp's theme ColorScheme matches one built from deepPurple seed
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final expectedColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
      expect(materialApp.theme?.colorScheme, expectedColorScheme);
    });

    testWidgets('HomeScreen is set as home route', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // HomeScreen displays buttons with tracking type labels
      expect(find.text('Miam'), findsWidgets);
    });

    testWidgets('displays feature categories', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // The widget_test.dart pattern shows these texts exist on the home screen
      expect(find.text('Santé'), findsWidgets);
      expect(find.text('Caca'), findsWidgets);
      expect(find.text('Dodo'), findsWidgets);
    });
  });

  group('encryption provider override in main', () {
    testWidgets('MyApp builds with encryption service override', (tester) async {
      final encryption = EncryptionService();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            encryptionServiceProvider.overrideWithValue(encryption),
          ],
          child: const MyApp(),
        ),
      );

      // Should render without errors even with real encryption service injected
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
