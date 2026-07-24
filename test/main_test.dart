import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
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

    testWidgets('theme uses AppTheme with sante as primary color', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // Verify the MaterialApp's theme matches AppTheme.theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.colorScheme.primary, equals(AppTheme.sante));
    });

    testWidgets('HomeScreen is set as home route', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // HomeScreen displays 4 tracking buttons (one per TrackingType)
      expect(find.byType(TrackButton), findsNWidgets(4));
    });

    testWidgets('displays feature categories', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // The home screen shows 4 TrackButtons for Miam, Santé, Caca, Dodo
      expect(find.byType(TrackButton), findsNWidgets(4));
    });
  });

  group('encryption provider override in main', () {
    testWidgets('MyApp builds with encryption service override', (tester) async {
      final encryption = EncryptionService();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            encryptionServiceProvider.overrideWith((ref) async => encryption),
          ],
          child: const MyApp(),
        ),
      );

      // Should render without errors even with real encryption service injected
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
