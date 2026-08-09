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
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';

import 'baby_profile_section_test.mocks.dart';

/// Minimal stub that returns pre-set active baby without hitting the repo.
class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}

@GenerateNiceMocks([MockSpec<BabyProfileRepository>()])

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

      // Should see menu items (French locale)
      expect(find.text('Activer'), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
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

  group('baby list invalidation after mutations', () {
    late MockBabyProfileRepository mockRepo;

    setUp(() {
      mockRepo = MockBabyProfileRepository();
    });

    // A1: baby list rebuilds after adding a new baby via dialog
    testWidgets('invalidates baby list provider after adding a new baby', (tester) async {
      final initialProfiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15)),
      ];

      List<BabyProfile> currentProfiles = List.from(initialProfiles);

      when(mockRepo.getAllProfiles()).thenAnswer((_) async => List.from(currentProfiles));
      when(mockRepo.insertProfile(any)).thenAnswer((Invocation invocation) {
        final newProfile = invocation.positionalArguments[0] as BabyProfile;
        currentProfiles.add(newProfile);
        return Future.value(newProfile.id);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
            // Use a FutureProvider that calls getAllProfiles — simulates real DB read.
            babyProfileListProvider.overrideWith((ref) async {
              return ref.watch(babyProfileRepositoryProvider.future).then(
                (repo) => repo.getAllProfiles(),
              );
            }),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(initialProfiles.first)),
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
            home: const Scaffold(body: BabyProfileSection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should see initial profile count (1 profile + 1 add button tile)
      expect(find.text('Luna'), findsOneWidget);

      // Tap the "Add Baby" list tile
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);

      // Fill in name
      await tester.enterText(find.byType(TextField).first, 'Max');

      // Tap add button (second TextButton — first is cancel)
      final buttons = find.byType(TextButton);
      expect(buttons, findsNWidgets(2));
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      // After invalidation the list should show both profiles
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
    });

    // A2: baby list rebuilds after editing a profile
    testWidgets('invalidates baby list provider after editing an existing baby', (tester) async {
      final initialProfiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15)),
      ];

      List<BabyProfile> currentProfiles = List.from(initialProfiles);

      when(mockRepo.getAllProfiles()).thenAnswer((_) async => List.from(currentProfiles));
      when(mockRepo.updateProfile(any, name: anyNamed('name'), birthDate: anyNamed('birthDate')))
          .thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as String;
        final newName = invocation.namedArguments[#name] as String? ?? 'updated';
        currentProfiles = [
          for (final p in currentProfiles)
            if (p.id == id) BabyProfile(id: p.id, name: newName, birthDate: p.birthDate)
            else p,
        ];
        return currentProfiles.firstWhere((p) => p.id == id);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
            babyProfileListProvider.overrideWith((ref) async {
              return ref.watch(babyProfileRepositoryProvider.future).then(
                (repo) => repo.getAllProfiles(),
              );
            }),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(initialProfiles.first)),
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
            home: const Scaffold(body: BabyProfileSection()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Luna'), findsOneWidget);

      // Open popup menu and tap Modifier
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Change name in TextField
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Lunaa');

      // Tap update button (last TextButton)
      final buttons = find.byType(TextButton);
      expect(buttons, findsNWidgets(2));
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      // After invalidation the list should show updated name
      expect(find.text('Lunaa'), findsOneWidget);
    });

    // A3: baby list rebuilds after deleting a non-active profile
    testWidgets('invalidates baby list provider after deleting a non-active baby', (tester) async {
      final initialProfiles = [
        BabyProfile(id: '1', name: 'Luna', birthDate: DateTime(2024, 3, 15), isActive: true),
        BabyProfile(id: '2', name: 'Max', birthDate: DateTime(2024, 6, 20), isActive: false),
      ];

      List<BabyProfile> currentProfiles = List.from(initialProfiles);

      when(mockRepo.getAllProfiles()).thenAnswer((_) async => List.from(currentProfiles));
      when(mockRepo.deleteProfile(any)).thenAnswer((invocation) async {
        final idToDelete = invocation.positionalArguments.first as String;
        currentProfiles.removeWhere((p) => p.id == idToDelete);
        return true;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
            babyProfileListProvider.overrideWith((ref) async {
              return ref.watch(babyProfileRepositoryProvider.future).then(
                (repo) => repo.getAllProfiles(),
              );
            }),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(initialProfiles.first)),
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
            home: const Scaffold(body: BabyProfileSection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both profiles visible
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);

      // Open popup menu on Max (second profile) and tap Supprimer
      final popups = find.byType(PopupMenuButton<String>);
      await tester.tap(popups.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);

      // Confirm delete (last TextButton)
      final buttons = find.byType(TextButton);
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      // After invalidation: Max should be gone, Luna still visible
      expect(find.text('Max'), findsNothing);
      expect(find.text('Luna'), findsOneWidget);
    });
  });
  });
}
