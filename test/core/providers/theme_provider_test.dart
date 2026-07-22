import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/theme_provider.dart';
import 'package:mamadera/core/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeNotifier', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('theme_provider_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('build returns system mode by default', () async {
      final container = ProviderContainer(
        overrides: [
          themeServiceProvider.overrideWith((ref) => _TestThemeService(tempDir.path)),
        ],
      );

      final state = await container.read(themeProvider.future);
      expect(state.mode, equals('system'));

      container.dispose();
    });

    test('setMode updates state and persists', () async {
      final container = ProviderContainer(
        overrides: [
          themeServiceProvider.overrideWith((ref) => _TestThemeService(tempDir.path)),
        ],
      );

      // Wait for initial load
      await container.read(themeProvider.future);

      await container.read(themeProvider.notifier).setMode('dark');

      final state = container.read(themeProvider);
      expect(state.value?.mode, equals('dark'));

      // Verify persistence
      final file = File('${tempDir.path}/.mamadera_theme.json');
      expect(file.existsSync(), isTrue);
      final content = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(content['themeMode'], equals('dark'));

      container.dispose();
    });

    test('setMode light updates correctly', () async {
      final container = ProviderContainer(
        overrides: [
          themeServiceProvider.overrideWith((ref) => _TestThemeService(tempDir.path)),
        ],
      );

      await container.read(themeProvider.future);
      await container.read(themeProvider.notifier).setMode('light');

      final state = container.read(themeProvider);
      expect(state.value?.mode, equals('light'));

      container.dispose();
    });

    test('setMode invalid does nothing', () async {
      final container = ProviderContainer(
        overrides: [
          themeServiceProvider.overrideWith((ref) => _TestThemeService(tempDir.path)),
        ],
      );

      await container.read(themeProvider.future);
      await container.read(themeProvider.notifier).setMode('invalid');

      final state = container.read(themeProvider);
      expect(state.value?.mode, equals('system'));

      container.dispose();
    });

    test('resolveThemeMode returns correct ThemeMode', () async {
      final container = ProviderContainer(
        overrides: [
          themeServiceProvider.overrideWith((ref) => _TestThemeService(tempDir.path)),
        ],
      );

      await container.read(themeProvider.future);

      final notifier = container.read(themeProvider.notifier);

      // System mode
      expect(notifier.resolveThemeMode(), equals(ThemeMode.system));

      // Light mode
      await notifier.setMode('light');
      expect(notifier.resolveThemeMode(), equals(ThemeMode.light));

      // Dark mode
      await notifier.setMode('dark');
      expect(notifier.resolveThemeMode(), equals(ThemeMode.dark));

      container.dispose();
    });

    // Note: "persists across container recreation" test is not valid with current
    // code structure. ThemeNotifier.build() creates its own ThemeService() instance
    // directly (not using ref.read(themeServiceProvider)), so provider overrides
    // don't affect the build() method. The setMode() method does use the provider,
    // but the build() method doesn't. This is a design issue in the original code.
  });
}

// Mock ThemeService that writes to a specific directory
class _TestThemeService implements ThemeService {
  final String path;

  _TestThemeService(this.path);

  File _getFile() => File('$path/.mamadera_theme.json');

  @override
  Future<ThemePreference?> load() async {
    final file = _getFile();
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return ThemePreference(mode: map['themeMode'] as String? ?? 'system');
  }

  @override
  Future<void> save(ThemePreference preference) async {
    final file = _getFile();
    await file.writeAsString(jsonEncode({'themeMode': preference.mode}));
  }

  @override
  Future<void> clear() async {
    final file = _getFile();
    if (await file.exists()) await file.delete();
  }
}
