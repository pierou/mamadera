import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../services/theme_service.dart';

/// Singleton instance shared across all consumers.
final themeServiceProvider = Provider((ref) => ThemeService());

/// Current theme preference state backed by [ThemeService].
final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemePreference>(
  ThemeNotifier.new,
);

class ThemeNotifier extends AsyncNotifier<ThemePreference> {
  late final _service = ref.read(themeServiceProvider);

  @override
  Future<ThemePreference> build() async {
    // Try loading saved preference first.
    Directory? cacheDir;
    try {
      cacheDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      // Fallback: continue without persistence.
    }

    if (cacheDir != null) {
      final service = ThemeService();
      final saved = await _loadWithFallback(service);
      if (saved != null) return saved;
    }

    // No saved preference → default to system mode.
    return const ThemePreference(mode: 'system');
  }

  Future<ThemePreference?> _loadWithFallback(ThemeService service) async {
    try {
      final pref = await service.load();
      return pref;
    } catch (_) {
      return null;
    }
  }

  /// Gets the current theme preference synchronously, or a safe default.
  ThemePreference _current() => state.whenOrNull(
        data: (pref) => pref,
      ) ?? const ThemePreference(mode: 'system');

  /// Sets the theme mode and persists to disk.
  Future<void> setMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) return;

    final updated = _current().copyWith(mode: mode);

    // Persist to disk.
    try {
      await _service.save(updated);
    } catch (_) {
      // Persistence failed — still update state in memory.
    }

    state = AsyncData(updated);
  }

  /// Resolves the effective [ThemeMode] for MaterialApp (synchronous).
  ThemeMode resolveThemeMode() {
    switch (_current().mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
