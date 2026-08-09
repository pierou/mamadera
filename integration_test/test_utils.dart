/// Shared utilities for integration tests.
///
/// Provides provider overrides, pump helpers, and semantic key constants
/// used by both Integration Test API (widget-based) and Flutter Driver tests.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/app_preferences_service.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/main.dart';

/// Semantic keys used across the app for integration testing.
///
/// These constants are shared between widget code (for [ValueKey] assignment)
/// and test files (for [Finder.byKey()] lookups).
class TestKeys {
  TestKeys._();

  // Bottom navigation tabs
  static const String homeTab = 'home-tab';
  static const String historyTab = 'history-tab';
  static const String menuTab = 'menu-tab';

  // Track buttons on HomeScreen
  static const String trackMiam = 'track-miam';
  static const String trackSante = 'track-sante';
  static const String trackCaca = 'track-caca';
  static const String trackDodo = 'track-dodo';

  // Onboarding
  static const String termsAcceptButton = 'terms-accept-button';
}

/// Creates a [ValueKey] from any string key constant in [TestKeys].
ValueKey<String> testKey(String value) => ValueKey(value);

// ─── Provider Overrides for Testing ─────────────────────────────────────

/// Test preferences with terms already accepted, so the router skips onboarding
/// and navigates directly to /home.
const _testPrefsAccepted = AppPreferences(
  appVersion: '1.0.0',
  termsAccepted: true,
  patchNotesOptOut: false,
);

/// Test preferences simulating first launch — terms not yet accepted.
const _testPrefsNotAccepted = AppPreferences(
  appVersion: '1.0.0',
  termsAccepted: false,
  patchNotesOptOut: false,
);

/// English locale preference for consistent test output.
const _testLocaleEn = LocalePreference(languageCode: 'en', isManualOverride: false);

/// Test notifier that returns *accepted* terms immediately.
/// Sets state synchronously so the redirect callback sees data right away.
class AcceptedTermsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async {
    state = const AsyncValue.data(_testPrefsAccepted);
    return _testPrefsAccepted;
  }
}

/// Test notifier that simulates first launch (terms not accepted).
class FirstLaunchNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async {
    state = const AsyncValue.data(_testPrefsNotAccepted);
    return _testPrefsNotAccepted;
  }
}

/// Test locale notifier — returns English immediately.
class TestLocaleNotifier extends LocaleNotifier {
  @override
  Future<LocalePreference> build() async {
    state = const AsyncValue.data(_testLocaleEn);
    return _testLocaleEn;
  }
}

/// Test notifier that returns `true` for [anyBabyExistsProvider].
/// Skips the "add first baby" onboarding dialog in most tests.
class BabyExistsNotifier extends AnyBabyExistsNotifier {
  @override
  Future<bool> build() async {
    state = const AsyncValue.data(true);
    return true;
  }
}

/// Creates an in-memory SQLite database for test isolation.
/// Each call returns a fresh DB; data is discarded when the app shuts down.
Future<AppDatabase> createInMemoryDb() async {
  return AppDatabase(LazyDatabase(NativeDatabase.memory));
}

// ─── Pump Helpers ──────────────────────────────────────

/// Locale notifier override with configurable language code.
class ConfigurableLocaleNotifier extends LocaleNotifier {
  ConfigurableLocaleNotifier(this._code);

  final String _code;

  @override
  Future<LocalePreference> build() async {
    return LocalePreference(languageCode: _code, isManualOverride: false);
  }
}

/// Pumps the real [MyApp] with provider overrides suitable for most tests.
///
/// By default: terms are pre-accepted, English locale, in-memory DB,
/// and baby onboarding dialog is skipped.
/// Override any parameter to customize test environment:
/// - `termsNotAccepted`: true → use FirstLaunchNotifier (show onboarding)
/// - `localeCode`: change language code from 'en'
/// - `useInMemoryDb`: false → skip DB override (uses default file-based DB)
/// - `babyExistsOverride`: true (default) → skip "add first baby" dialog
Future<void> pumpMamadera(
  WidgetTester tester, {
  bool termsNotAccepted = false,
  String localeCode = 'en',
  bool useInMemoryDb = true,
  bool babyExistsOverride = true,
}) async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Build overrides list dynamically based on test configuration
  final overrides = [
    // Always override locale for consistent test behavior
    localeProvider.overrideWith(() => ConfigurableLocaleNotifier(localeCode)),
    // Conditionally override preferences based on test scenario
    if (!termsNotAccepted)
      appPreferencesProvider.overrideWith(AcceptedTermsNotifier.new)
    else
      appPreferencesProvider.overrideWith(FirstLaunchNotifier.new),
  ];

  // In-memory DB for isolation (when requested)
  if (useInMemoryDb) {
    overrides.add(databaseProvider.overrideWith((ref) async => createInMemoryDb()));
  }

  // Skip baby onboarding dialog by default in most tests
  if (babyExistsOverride) {
    overrides.add(anyBabyExistsProvider.overrideWith(BabyExistsNotifier.new));
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MyApp(),
    ),
  );

  // Wait for async providers to resolve and router to redirect
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

// ─── Finder Helpers ──────────────────────────────────────

/// Creates a [Finder] for a widget identified by its semantic key string.
/// Uses [ValueKey<String>] internally so it matches keys added in widget code.
Finder findByKey(String key) => find.byKey(ValueKey(key));

/// Verifies that a widget with the given key exists and is unique.
void expectUnique(WidgetTester tester, String key) {
  expect(findByKey(key), findsOneWidget, reason: 'Expected exactly one widget with key "$key"');
}

/// Verifies that a widget with the given key does not exist.
void expectAbsent(String key) {
  expect(findByKey(key), findsNothing, reason: 'Expected no widget with key "$key"');
}
