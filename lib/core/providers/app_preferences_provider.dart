import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

import '../config/app_config.dart';
import '../services/app_preferences_service.dart';

/// Singleton instance shared across all consumers.
final appPreferencesServiceProvider = Provider((ref) => AppPreferencesService());

/// Current app preferences state backed by [AppPreferencesService].
final appPreferencesProvider = AsyncNotifierProvider<AppPreferencesNotifier, AppPreferences>(
  AppPreferencesNotifier.new,
);

class AppPreferencesNotifier extends AsyncNotifier<AppPreferences> {
  late final _service = ref.read(appPreferencesServiceProvider);

  @override
  Future<AppPreferences> build() async {
    // Try loading saved preference first.
    Directory? cacheDir;
    try {
      cacheDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      // Fallback: continue without persistence.
    }

    if (cacheDir != null) {
      final service = AppPreferencesService();
      final saved = await _loadWithFallback(service);
      if (saved != null) return saved;
    }

    // No saved preference → default state.
    return const AppPreferences(
      appVersion: AppConfig.version,
      termsAccepted: false,
      patchNotesOptOut: false,
    );
  }

  Future<AppPreferences?> _loadWithFallback(AppPreferencesService service) async {
    try {
      return await service.load();
    } catch (_) {
      return null;
    }
  }

  AppPreferences _current() => state.asData?.value ?? const AppPreferences(
        appVersion: AppConfig.version,
        termsAccepted: false,
        patchNotesOptOut: false,
      );

  /// Marks the Terms & Conditions as accepted.
  Future<void> acceptTerms() async {
    final updated = _current().copyWith(termsAccepted: true);
    await _save(updated);
    state = AsyncData(updated);
  }

  /// Sets the patch notes opt-out flag.
  Future<void> setPatchNotesOptOut({required bool value}) async {
    final updated = _current().copyWith(patchNotesOptOut: value);
    await _save(updated);
    state = AsyncData(updated);
  }

  /// Marks the current version's patch notes as seen.
  Future<void> markPatchNotesSeen() async {
    final updated = _current().copyWith(appVersion: AppConfig.version);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> _save(AppPreferences prefs) async {
    try {
      await _service.save(prefs);
    } catch (_) {
      // Persistence failed — still update state in memory.
    }
  }
}
