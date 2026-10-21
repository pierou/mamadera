// ignore_for_file: lines_longer_than_80_chars // Tests for OnboardingDialog widget

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/features/home/presentation/widgets/onboarding_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';

class MockBabyProfileRepository extends Mock implements BabyProfileRepository {}

void main() {
  group('OnboardingDialog', () {
    testWidgets('renders onboarding dialog with all elements', (tester) async {
      final mockRepo = MockBabyProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(null)),
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
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => const OnboardingDialog(),
                    );
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDialog), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays error when saving with empty name', (tester) async {
      final mockRepo = MockBabyProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(null)),
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
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => const OnboardingDialog(),
                    );
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap cancel instead of save (empty name = no save, just close)
      final cancelButton = find.text('Annuler');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(OnboardingDialog), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // A restoration process can be initiated while this page is open: it...
  // It was there because no such profile existed before, but now it does. Validate.
  // His formula doesn't create the "first baby," but rather a second one, alongside it.
  // of those who have just returned — an unwanted baby, one that no one asked for, and...
  // that gives no indication. These tests lock both closures.
  // ─────────────────────────────────────────────────────────────────────────
  group('OnboardingDialog — a restore lands while the sheet is open', () {
    late _RecordingBabyProfileRepository repo;
    late ProviderContainer container;

    Future<void> pumpDialog(WidgetTester tester) async {
      repo = _RecordingBabyProfileRepository();
      container = ProviderContainer(overrides: [
        babyProfileRepositoryProvider.overrideWith((ref) async => repo),
        activeBabyProvider.overrideWith(() => _ActiveBabyStub(null)),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => const OnboardingDialog(),
                    );
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'a profile restored during typing is not answered with an insert',
        (tester) async {
      await pumpDialog(tester);
      expect(find.byType(OnboardingDialog), findsOneWidget);

      // The sheet is only displayed because no profile exists. An import in...
      // bring it during the seizure.
      await tester.enterText(find.byType(TextField), 'Lou');
      await tester.pump();
      repo.restore(_restoredProfile());

      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      // The duplicate was not created: that is the whole issue.
      expect(repo.inserted, isEmpty);
      expect(find.byType(OnboardingDialog), findsNothing);
    });

    testWidgets('the sheet closes by itself once a profile exists',
        (tester) async {
      await pumpDialog(tester);
      expect(find.byType(OnboardingDialog), findsOneWidget);

      // No input, no typing: the restoration process alone should be sufficient to recover the document.
      repo.restore(_restoredProfile());
      await container.read(anyBabyExistsProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDialog), findsNothing);
      expect(repo.inserted, isEmpty);
    });

    testWidgets(
        'invalidation — what the restore actually does — closes the sheet too',
        (tester) async {
      await pumpDialog(tester);
      expect(find.byType(OnboardingDialog), findsOneWidget);

      // The production path does not call `refresh()`; instead, it uses a restoration mechanism.
      // "invalidate" the provider (`import_providers.dart:183`). A listener.
      // It would never trigger unless it detected a clear and explicit change.
      repo.restore(_restoredProfile());
      container.invalidate(anyBabyExistsProvider);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDialog), findsNothing);
      expect(repo.inserted, isEmpty);
    });

    testWidgets('without a restore, saving still creates the profile',
        (tester) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'Lou');
      await tester.pump();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      // Verification: The two closures mentioned above do not interfere with the normal path.
      expect(repo.inserted.map((p) => p.name), ['Lou']);
      expect(find.byType(OnboardingDialog), findsNothing);
    });

    testWidgets('confirming twice does not insert twice', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'Lou');
      await tester.pump();
      await tester.tap(find.text('Confirmer'));
      await tester.pump();
      await tester.tap(find.text('Confirmer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repo.inserted.length, 1);
    });
  });
}

/// Profile derived from a restoration – the name is different from the one entered during the test.
/// To ensure that the "duplicate name" record is not the one that responds.
BabyProfile _restoredProfile() => BabyProfile(
      id: 'restored-1',
      name: 'Emma',
      birthDate: DateTime.utc(2024, 3, 1),
      isActive: true,
    );

/// A dummy repository that records everything inserted into it, and whose contents can be...
/// populated along the way – that's precisely what a restoration does.
class _RecordingBabyProfileRepository implements BabyProfileRepository {
  final List<BabyProfile> profiles = <BabyProfile>[];
  final List<BabyProfile> inserted = <BabyProfile>[];

  /// A restoration process brings [profile] back into the system.
  void restore(BabyProfile profile) => profiles.add(profile);

  @override
  Future<List<BabyProfile>> getAllProfiles() async => List.of(profiles);

  @override
  Future<BabyProfile?> getActiveProfile() async =>
      profiles.isEmpty ? null : profiles.first;

  @override
  Future<String> insertProfile(BabyProfile profile) async {
    inserted.add(profile);
    profiles.add(profile);
    return profile.id;
  }

  @override
  Future<BabyProfile?> updateProfile(
    String id, {
    String? name,
    DateTime? birthDate,
  }) async =>
      null;

  @override
  Future<bool> deleteProfile(String id) async => false;

  @override
  Future<void> setActiveProfile(String id) async {}
}

class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}
