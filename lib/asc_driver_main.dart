// ignore_for_file: avoid_print
/// Driver entry point for App Store screenshot capture.
///
/// Runs the real app (French, dark-friendly theme) on top of a seeded
/// in-memory database so every screen renders realistic content without
/// touching the device's real data. A small data-handler lets the driver
/// (`test_driver/asc_screenshots.dart`) rotate the simulator.
///
/// Run with:
/// ```bash
/// flutter drive \
///   --target=lib/asc_driver_main.dart \
///   --driver=test_driver/asc_screenshots.dart \
///   -d "iPhone 17"
/// ```
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/providers/any_baby_exists_provider.dart';
import 'core/providers/app_preferences_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/app_preferences_service.dart';
import 'core/services/locale_service.dart';
import 'data/local/app_db.dart';
import 'main.dart' as app;

const _babyId = 'baby-asc';

/// Locale pinned to French regardless of the host device language.
class _FrLocaleNotifier extends LocaleNotifier {
  @override
  Future<LocalePreference> build() async {
    const pref = LocalePreference(
      languageCode: 'fr',
      isManualOverride: true,
    );
    state = const AsyncData(pref);
    return pref;
  }
}

/// Terms already accepted (skips the legal dialog).
class _AcceptedTermsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async {
    const prefs = AppPreferences(
      appVersion: AppConfig.version,
      termsAccepted: true,
      patchNotesOptOut: false,
    );
    state = const AsyncData(prefs);
    return prefs;
  }
}

/// Pretends a baby profile exists (skips onboarding).
class _BabyExistsNotifier extends AnyBabyExistsNotifier {
  @override
  Future<bool> build() async {
    state = const AsyncData(true);
    return true;
  }
}

/// Seed data: a 3-month-old with a full day of tracking events so Home,
/// History and the dialogs render realistic content.
Future<AppDatabase> _seededDb() async {
  final db = AppDatabase(NativeDatabase.memory());

  final now = DateTime.now();
  final birth = now.subtract(const Duration(days: 87));

  await db.insertBabyProfile(
    BabyProfilesCompanion.insert(
      id: _babyId,
      name: 'Léa',
      birthDate: birth.millisecondsSinceEpoch,
      isActive: const Value(true),
    ),
  );

  Future<void> dodo(DateTime start, double minutes) =>
      db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'dodo',
          timestamp: start,
          duration: Value(minutes),
          quantity: Value(minutes),
          babyId: const Value(_babyId),
        ),
      );

  Future<void> miam(DateTime at, {bool artificial = false, double? ml}) =>
      db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'miam',
          timestamp: at,
          subtype: Value(artificial ? 'artificial' : 'natural'),
          quantity: Value(ml),
          babyId: const Value(_babyId),
        ),
      );

  Future<void> caca(
    DateTime at, {
    required String wasteType,
    String? color,
    String? texture,
  }) =>
      db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'caca',
          timestamp: at,
          wasteType: Value(wasteType),
          color: Value(color),
          texture: Value(texture),
          babyId: const Value(_babyId),
        ),
      );

  Future<void> sante(DateTime at, String subtype) =>
      db.insertEvent(
        TrackingEventsCompanion.insert(
          type: 'sante',
          timestamp: at,
          subtype: Value(subtype),
          babyId: const Value(_babyId),
        ),
      );

  // Night + naps
  await dodo(now.subtract(const Duration(hours: 16)), 460); // last night
  await dodo(now.subtract(const Duration(hours: 25)), 90); // yesterday nap
  await dodo(now.subtract(const Duration(hours: 2, minutes: 30)), 80); // today nap
  // Feedings
  await miam(now.subtract(const Duration(hours: 11)));
  await miam(now.subtract(const Duration(hours: 8)), artificial: true, ml: 110);
  await miam(now.subtract(const Duration(hours: 6)));
  await miam(now.subtract(const Duration(hours: 3)), artificial: true, ml: 120);
  await miam(now.subtract(const Duration(hours: 4)));
  // Diapers
  await caca(now.subtract(const Duration(hours: 14)),
      wasteType: 'caca', color: 'jaune_moutarde', texture: 'pateuse');
  await caca(now.subtract(const Duration(hours: 5)),
      wasteType: 'pipi', color: 'jaune_clair');
  await caca(now.subtract(const Duration(hours: 1)),
      wasteType: 'les_deux', color: 'incolore|jaune_moutarde', texture: 'grumeleuse');
  // Health
  await sante(now.subtract(const Duration(hours: 4, minutes: 30)), 'nettoyage_nez');
  await sante(now.subtract(const Duration(hours: 26)), 'vitamine_d');

  return db;
}

void main() async {
  // NOTE: do not call WidgetsFlutterBinding.ensureInitialized() here —
  // enableFlutterDriverExtension must install its own binding first.
  final db = await _seededDb();

  enableFlutterDriverExtension(
    handler: (message) async {
      switch (message) {
        case 'ascRotate:landscape':
          await SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          return 'ok';
        case 'ascRotate:portrait':
          await SystemChrome.setPreferredOrientations(
              const [DeviceOrientation.portraitUp]);
          return 'ok';
        default:
          return 'unknown: $message';
      }
    },
  );

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(_FrLocaleNotifier.new),
        appPreferencesProvider.overrideWith(_AcceptedTermsNotifier.new),
        anyBabyExistsProvider.overrideWith(_BabyExistsNotifier.new),
        databaseProvider.overrideWith((ref) async => db),
      ],
      child: const app.MyApp(),
    ),
  );
}
