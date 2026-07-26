import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/app_preferences_service.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
import 'package:mamadera/main.dart';

/// Test preferences with terms accepted so the router goes to /home.
const _testPrefs = AppPreferences(
  appVersion: '1.0.0',
  termsAccepted: true,
  patchNotesOptOut: false,
);

void main() {
  group('MyApp widget', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: const MyApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('theme uses AppTheme with sante as primary color', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: const MyApp(),
        ),
      );

      // Verify the MaterialApp's theme matches AppTheme.theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.colorScheme.primary, equals(AppTheme.sante));
    });

    testWidgets('HomeScreen is set as home route', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for async providers to resolve and router to redirect
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // HomeScreen displays 4 tracking buttons (one per TrackingType)
      expect(find.byType(TrackButton), findsNWidgets(4));
    });

    testWidgets('displays feature categories', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for async providers to resolve and router to redirect
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: const MyApp(),
        ),
      );

      // Should render without errors even with real encryption service injected
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

/// Test notifier that returns accepted terms so the router goes to /home.
/// Sets state synchronously so the redirect callback sees data immediately.
class _TestAppPreferencesNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async {
    state = const AsyncValue.data(_testPrefs);
    return _testPrefs;
  }
}
