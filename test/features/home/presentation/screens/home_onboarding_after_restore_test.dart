// Onboarding sheet vs. a backup restored from another tab.
//
// The reported flow: first launch → cancel baby creation → Menu → restore a
// backup → back to Home, and the « Bienvenue sur Mamadera » sheet is open
// again over a database that now has a baby in it.
//
// What the app is deciding on is `anyBabyExistsProvider`. A restore
// invalidates it (`import_providers._invalidateRestoredState`), which starts a
// rebuild: for the duration of that re-read the provider is *loading while
// still carrying its previous value* — `false`. A fresh `HomeScreen` (the
// shell renders `body: child`, so leaving the tab disposes it and returning
// rebuilds it from scratch, latch included) must read that as "not known yet".
// `home_screen._scheduleOnboardingSheet`'s own comment says as much: "null
// (currently being invalidated) means 'we don't know': we don't open an
// investigation into an absence that we haven't confirmed." Reading `.value`
// alone breaks that promise, because a loading state still has one — the stale
// `false`. On a phone the re-read goes through drift's isolate and outlives a
// frame, so the sheet wins; the gate below makes that window deterministic.

import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/data/local/app_db.dart' as db_app;
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/home/presentation/screens/home_screen.dart';
import 'package:mamadera/features/home/presentation/widgets/onboarding_dialog.dart';
import 'package:mamadera/features/import/domain/repositories/import_repository.dart';
import 'package:mamadera/features/import/presentation/providers/import_providers.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

import '../../../reminders/presentation/providers/no_poll_reminders_notifier.dart';
import 'home_screen_test.mocks.dart';

/// Identity encryption stub: no keychain in a widget test.
class _FakeEncryption extends EncryptionService {
  @override
  String encrypt(String plainText) => 'enc:$plainText';

  @override
  String? decrypt(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return null;
    if (!cipherText.startsWith('enc:')) return null;
    return cipherText.substring('enc:'.length);
  }
}

/// Profile repository whose reads can be held open, the way a real re-read
/// takes longer than the frame it is issued in.
class _GatedProfileRepository implements BabyProfileRepository {
  _GatedProfileRepository(this._profiles);

  List<BabyProfile> _profiles;
  Completer<void>? _gate;

  void blockReads() => _gate = Completer<void>();

  void release() {
    final gate = _gate;
    _gate = null;
    gate?.complete();
  }

  @override
  Future<List<BabyProfile>> getAllProfiles() async {
    final gate = _gate;
    if (gate != null) await gate.future;
    return _profiles;
  }

  /// Not gated: on a phone the active-baby read is not the one still in flight
  /// when Home is rebuilt, and letting it resolve keeps the provider graph from
  /// rebuilding inside Home's own build phase.
  @override
  Future<BabyProfile?> getActiveProfile() async {
    for (final profile in _profiles) {
      if (profile.isActive) return profile;
    }
    return null;
  }

  @override
  Future<String> insertProfile(BabyProfile profile) async {
    _profiles = [..._profiles, profile];
    return profile.id;
  }

  @override
  Future<BabyProfile?> updateProfile(String id,
      {String? name, DateTime? birthDate}) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteProfile(String id) async => throw UnimplementedError();

  @override
  Future<void> setActiveProfile(String id) async => throw UnimplementedError();
}

/// Restore that writes to [_GatedProfileRepository] instead of a database, so
/// no `compute()` isolate is needed to parse a document.
class _FakeImportRepository extends ImportRepository {
  _FakeImportRepository(this.profiles);

  final _GatedProfileRepository profiles;

  @override
  Future<ParsedExport> parseExport(String json) async => const ParsedExport(
        babyProfiles: [
          ImportedBabyProfile(
            id: 'baby_1',
            name: 'Leia',
            birthDateEpochMs: 1700000000000,
            isActive: true,
          ),
        ],
        trackingEvents: [],
        customReminders: [],
        reminderSettings: [],
        reminderDismissals: [],
      );

  @override
  Future<ImportCounts> restore(ParsedExport parsed) async {
    await profiles.insertProfile(BabyProfile(
      id: 'baby_1',
      name: 'Leia',
      birthDate: DateTime.utc(2023, 11, 14),
      isActive: true,
    ));
    return const ImportCounts(
      babyProfiles: 1,
      trackingEvents: 0,
      customReminders: 0,
      reminderSettings: 0,
      reminderDismissals: 0,
      measurements: 0,
      reminderCompletions: 0,
      appSettings: 0,
    );
  }
}

/// The rest of Home's provider graph is pinned to empty: this test is about the
/// onboarding decision, and an unwarmed repository resolving in the middle of
/// Home's first build would report a Riverpod scheduling complaint instead.
class _EmptyMeasurementNotifier extends MeasurementNotifier {
  @override
  Future<List<GrowthMeasurement>> build() async => const [];
}

/// `pumpAndSettle` never returns on this screen: while providers are still
/// resolving, Home renders an indeterminate progress indicator — an infinite
/// animation. Fixed-step pumps drive frames without waiting for it to stop.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late db_app.AppDatabase database;
  late ProviderContainer container;
  late _GatedProfileRepository profileRepository;
  late ImportController controller;

  setUp(() async {
    database = db_app.AppDatabase(LazyDatabase(NativeDatabase.memory));
    // Force the lazy open so the first widget frame is not the one that pays
    // for it.
    await database.select(database.reminderDismissals).get();
    profileRepository = _GatedProfileRepository(const []);

    container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) async => database),
      encryptionServiceProvider.overrideWith((ref) async => _FakeEncryption()),
      babyProfileRepositoryProvider
          .overrideWith((ref) async => profileRepository),
      importRepositoryProvider.overrideWith(
          (ref) async => _FakeImportRepository(profileRepository)),
      reminderNotifierProvider.overrideWith(NoPollRemindersNotifier.new),
      trackingRepositoryProvider
          .overrideWith((ref) async => MockTrackingRepository()),
      measurementNotifierProvider.overrideWith(_EmptyMeasurementNotifier.new),
    ]);
    controller = container.read(importControllerProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> pumpBody(WidgetTester tester, Widget body) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.theme,
          home: Scaffold(body: body),
        ),
      ),
    );
    await settle(tester);
  }

  /// Resolves the provider graph Home is about to watch, the way the Menu
  /// screen and its result dialog do on a phone before the parent taps Home.
  /// Left pending, the whole cascade would rebuild inside `_HomeContent.build`
  /// and Riverpod would report a scheduling complaint instead of the behaviour
  /// under test. `anyBabyExistsProvider` is deliberately NOT warmed: it is the
  /// read the gate holds open.
  Future<void> warmUpGraph() async {
    await container.read(activeBabyProvider.future);
    await container.read(reminderNotifierProvider.future);
    await container.read(trackingRepositoryProvider.future);
    await container.read(measurementNotifierProvider.future);
  }

  testWidgets('a restore completed off-tab keeps the sheet closed',
      (tester) async {
    // The sheet is taller than a phone-wide test viewport; give it room so a
    // layout overflow cannot stand in for the behaviour under test.
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. First launch, no profile: the sheet opens.
    await pumpBody(tester, const HomeScreen());
    expect(find.byType(OnboardingDialog), findsOneWidget);

    // 2. Baby creation is cancelled.
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.byType(OnboardingDialog), findsNothing);

    // 3. The parent goes to the Menu tab — Home is disposed with its latch —
    //    and restores a backup. The re-read of `anyBabyExistsProvider` that
    //    the restore's invalidation starts is still in flight.
    await pumpBody(tester, const SizedBox.shrink());
    profileRepository.blockReads();
    await controller.inspectFile('{}');
    expect(await controller.applyRestore(), isA<ImportSuccess>());

    // The Menu screen stays up for a few frames after the restore, which is
    // what lets the invalidation cascade settle — everything except the read
    // that is gated above.
    await pumpBody(tester, const SizedBox.shrink());
    await warmUpGraph();

    // 4. Back on Home. The database has a baby; the provider has not finished
    //    saying so, and "not yet" must not be read as "none".
    await pumpBody(tester, const HomeScreen());
    expect(container.read(anyBabyExistsProvider).value, isFalse,
        reason: 'precondition: the re-read is still carrying the stale false');
    expect(find.byType(OnboardingDialog), findsNothing,
        reason: 'an unconfirmed absence must not open the welcome sheet');

    // 5. Once the re-read lands, the answer is yes and nothing changes.
    profileRepository.release();
    await settle(tester);
    expect(container.read(anyBabyExistsProvider).value, isTrue);
    expect(find.byType(OnboardingDialog), findsNothing);
  });

  testWidgets('a confirmed absence still opens the sheet', (tester) async {
    // The guard added for the restore must not cost first-launch onboarding:
    // with an empty database and no re-read in flight, the sheet opens.
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpBody(tester, const HomeScreen());
    await settle(tester);

    expect(container.read(anyBabyExistsProvider).value, isFalse);
    expect(container.read(anyBabyExistsProvider).isLoading, isFalse);
    expect(find.byType(OnboardingDialog), findsOneWidget);
  });
}
