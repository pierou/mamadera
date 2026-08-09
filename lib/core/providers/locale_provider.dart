import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../services/locale_service.dart';

/// Singleton instance shared across all repository implementations.
final localeServiceProvider = Provider((ref) => LocaleService());

/// Current locale preference state backed by [LocaleService].
/// Uses [AsyncNotifier] so consumers get proper loading/error states per project conventions.
final localeProvider = AsyncNotifierProvider<LocaleNotifier, LocalePreference>(
  LocaleNotifier.new,
);

Future<Directory?> _getCacheDir() async {
  try {
    return await getApplicationDocumentsDirectory();
  } catch (_) {
    // Fallback: continue without persistence.
    return null;
  }
}

class LocaleNotifier extends AsyncNotifier<LocalePreference> {
  late final _service = ref.read(localeServiceProvider);

  @override
  Future<LocalePreference> build() async {
    final cacheDir = await _getCacheDir();
    if (cacheDir != null) {
      final service = LocaleService();
      final saved = await _loadWithFallback(service);
      if (saved != null) return saved;
    }

    // No saved preference → default to device locale or French.
    final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
    return LocalePreference(
      languageCode: _isSupported(deviceLang) ? deviceLang : 'fr',
      isManualOverride: false,
    );
  }

  Future<LocalePreference?> _loadWithFallback(LocaleService service) async {
    try {
      final pref = await service.load();
      return pref;
    } catch (_) {
      return null;
    }
  }

  /// Gets the current locale preference synchronously, or a safe default.
  LocalePreference _current() => state.whenOrNull(
        data: (pref) => pref,
      ) ?? const LocalePreference(
        languageCode: 'fr',
        isManualOverride: false,
      );

  /// Sets the current locale and persists to disk as a manual override.
  Future<void> setLocale(String languageCode) async {
    if (!_isSupported(languageCode)) return;
    final updated = _current().copyWith(
      languageCode: languageCode,
      isManualOverride: true,
    );

    // Persist to disk.
    try {
      await _service.save(updated);
    } catch (_) {
      // Persistence failed — still update state in memory.
    }

    state = AsyncData(updated);
  }

  /// Resolves the effective [ui.Locale] for MaterialApp (synchronous).
  ui.Locale resolveLocale() => ui.Locale(_current().languageCode);

  static bool _isSupported(String languageCode) =>
      ['fr', 'en', 'es'].contains(languageCode.toLowerCase());
}
