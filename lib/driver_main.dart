// This file is used for automated screenshot capture using Flutter Driver / DTD.
// To run screenshots: flutter run --target=lib/driver_main.dart -d <device_id>

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/any_baby_exists_provider.dart';
import 'core/providers/app_preferences_provider.dart';
import 'core/services/app_preferences_service.dart';

import 'main.dart' as app;

/// Test notifier that returns *accepted* terms immediately.
class _AcceptedTermsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async {
    const prefs = AppPreferences(
      appVersion: '1.0.0',
      termsAccepted: true,
      patchNotesOptOut: false,
    );
    state = const AsyncValue.data(prefs);
    return prefs;
  }
}

/// Test notifier that pretends a baby profile already exists.
/// This skips the "add first baby" onboarding dialog completely.
class _BabyExistsNotifier extends AnyBabyExistsNotifier {
  @override
  Future<bool> build() async {
    state = const AsyncValue.data(true);
    return true;
  }
}

void main() {
  // Enable the driver extension for automated UI interactions
  enableFlutterDriverExtension();

  // Initialize Flutter bindings (same as app.main())
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with test overrides to skip ALL onboarding:
  // - Terms acceptance dialog
  // - "Add first baby" profile creation dialog
  runApp(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWith(_AcceptedTermsNotifier.new),
        anyBabyExistsProvider.overrideWith(_BabyExistsNotifier.new),
      ],
      child: const app.MyApp(),
    ),
  );
}
