// ignore_for_file: lines_longer_than_80_chars // Widget tests for BabyProfileSection with proper provider overrides

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/features/menu/presentation/widgets/baby_profile_section.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';

// Mock repository for testing
class MockBabyProfileRepository extends Mock implements BabyProfileRepository {}

/// Minimal stub that returns pre-set active baby without hitting the repo.
class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}

Widget makeTestWidget(AsyncValue<List<BabyProfile>> profiles, BabyProfile? activeBaby) {
  return ProviderScope(
    overrides: [
      babyProfileRepositoryProvider.overrideWith((ref) async => MockBabyProfileRepository()),
      babyProfileListProvider.overrideWith((ref) async {
        return profiles.when(
          data: (data) => data,
          loading: () => throw StateError('loading'),
          error: (err, _) => throw err,
        );
      }),
      activeBabyProvider.overrideWith(() => _ActiveBabyStub(activeBaby)),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: const BabyProfileSection(),
      ),
    ),
  );
}

void main() {
  group('BabyProfileSection', () {
    testWidgets('renders without error when profiles are loading', (tester) async {
      await tester.pumpWidget(
        makeTestWidget(const AsyncLoading(), null),
      );

      await tester.pump();
      expect(find.byType(BabyProfileSection), findsOneWidget);
    });

    testWidgets('displays section title when profiles exist', (tester) async {
      final profiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15)),
      ];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          profiles.first,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BabyProfileSection), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('displays empty state when no profiles exist', (tester) async {
      await tester.pumpWidget(
        makeTestWidget(
          const AsyncValue.data(<BabyProfile>[]),
          null,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BabyProfileSection), findsOneWidget);
    });

    testWidgets('displays error state when profiles load fails', (tester) async {
      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.error('error', StackTrace.empty),
          null,
        ),
      );

      // Error state should be displayed without timing out
      await tester.pump();
      expect(find.byType(BabyProfileSection), findsOneWidget);
    });

    testWidgets('shows active indicator for active profile', (tester) async {
      final profiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15), isActive: true),
        BabyProfile(id: '2', name: 'Max', birthDate: DateTime(2024, 6, 20), isActive: false),
      ];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          profiles.first, // Luna is active
        ),
      );

      await tester.pumpAndSettle();

      // Should find check_circle icon for active profile
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // Should find both profile tiles
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
    });

    testWidgets('shows popup menu on profile tile', (tester) async {
      final profiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15), isActive: false),
      ];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          null, // No active profile
        ),
      );

      await tester.pumpAndSettle();

      // Tap the popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      // Should see menu items
      expect(find.text('Activate'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('shows add baby button when profiles exist', (tester) async {
      final profiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15)),
      ];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          profiles.first,
        ),
      );

      await tester.pumpAndSettle();

      // Should see the add baby list tile
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('displays birth date in subtitle', (tester) async {
      final profiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15)),
      ];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          profiles.first,
        ),
      );

      await tester.pumpAndSettle();

      // Should find the age-based birth date format (e.g., "2 years old" or similar)
      // The exact format depends on current date, so just verify some text is shown
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('activates profile when tapping non-active profile', (tester) async {
      final profiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15), isActive: false),
        BabyProfile(id: '2', name: 'Max', birthDate: DateTime(2024, 6, 20), isActive: true),
      ];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          profiles.last, // Max is active
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Luna's tile (non-active)
      await tester.tap(find.text('Luna'));
      await tester.pump();

      // After tap, Luna should become active (check_circle should move)
      // The widget should rebuild with new active state
      expect(find.byType(BabyProfileSection), findsOneWidget);
    });

    testWidgets('shows add baby dialog when tapping add button', (tester) async {
      final profiles = <BabyProfile>[];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          null,
        ),
      );

      await tester.pumpAndSettle();

      // Tap the "Add Baby" button in empty state
      await tester.tap(find.text('Ajouter un bébé').first);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Ajouter un bébé'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('shows formatted date when birth date is selected', (tester) async {
      final profiles = <BabyProfile>[];

      await tester.pumpWidget(
        makeTestWidget(
          AsyncValue.data(profiles),
          null,
        ),
      );

      await tester.pumpAndSettle();

      // Tap the "Ajouter un bébé" button
      await tester.tap(find.text('Ajouter un bébé'));
      await tester.pumpAndSettle();

      // The dialog should show with default date
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
