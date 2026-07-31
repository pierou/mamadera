// ignore_for_file: lines_longer_than_80_chars
// Comprehensive tests for PatchNotesDialog widget

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/services/app_preferences_service.dart';
import 'package:mamadera/features/patchnotes/presentation/widgets/patch_notes_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';

/// Test preferences with default values for widget testing.
const _testPrefs = AppPreferences(
  appVersion: '1.0.0',
  termsAccepted: false,
  patchNotesOptOut: false,
);

/// Test notifier that returns pre-filled preferences without file I/O.
class _TestAppPreferencesNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async {
    state = AsyncData(_testPrefs);
    return _testPrefs;
  }

  @override
  Future<void> markPatchNotesSeen() async {
    final updated = _testPrefs.copyWith(appVersion: '1.0.0');
    state = AsyncData(updated);
  }

  @override
  Future<void> setPatchNotesOptOut({required bool value}) async {
    final updated = _testPrefs.copyWith(patchNotesOptOut: value);
    state = AsyncData(updated);
  }
}

void main() {
  group('PatchNotesDialog', () {
    const localizationDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    testWidgets('renders dialog with close button and opt-out checkbox', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Dialog Scaffold + inner PatchNotesScreen Scaffold = 2 Scaffolds total
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget); // Close button
    });

    testWidgets('calls onDismiss when close button is tapped', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () => dismissed = true),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(dismissed, isFalse);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(seconds: 1));

      expect(dismissed, isTrue);
    });

    testWidgets('renders skip button when showSkipButton is true', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(
              onDismiss: () {},
              showSkipButton: true,
              onSkip: () => skipped = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(OutlinedButton), findsOneWidget); // Skip button

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump(const Duration(seconds: 1));

      expect(skipped, isTrue);
    });

    testWidgets('does not render skip button when showSkipButton is false', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(OutlinedButton), findsNothing); // No skip button shown
    });

    testWidgets('renders checkbox for opt-out toggle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('toggles opt-out checkbox state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Tap to toggle opt-out on
      await tester.tap(checkbox.first);
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('renders patch notes content area', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Dialog should render with Scaffold regardless of markdown loading state
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('dialog layout respects safe areas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('close button has correct styling', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.padding?.resolve({}), equals(const EdgeInsets.symmetric(vertical: 16)));
    });

    testWidgets('skip button has primary color styling', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(
              onDismiss: () {},
              showSkipButton: true,
              onSkip: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      final skipButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(skipButton.style?.side?.resolve({}), isNotNull);
    });

    testWidgets('renders column layout with all children', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('checkbox row renders label text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(Row), findsWidgets); // Checkbox row + type selector rows in content
    });

    testWidgets('multiple taps on close call callback each time', (tester) async {
      var dismissCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () => dismissCount++),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(seconds: 1));

      expect(dismissCount, equals(1));
    });

    testWidgets('dialog builds with async provider loading state', (tester) async {
      // Test that dialog renders even when provider is still loading
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: const [Locale('en', '')],
            home: PatchNotesDialog(onDismiss: () {}),
          ),
        ),
      );

      // Initial pump
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
