import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/theme_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// Mock platform for testing
class _TestPathProvider extends Fake implements PathProviderPlatform {
  final String rootPath;

  _TestPathProvider(this.rootPath);

  Future<String> getApplicationDocumentsDirectory() async {
    return rootPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService', () {
    late Directory tempDir;
    late ThemeService service;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('theme_service_test_');
      _TestPathProvider(tempDir.path);
      service = ThemeService(directoryResolver: () async => tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('load returns null when no file exists', () async {
      final result = await service.load();
      expect(result, isNull);
    });

    test('save and load theme preference', () async {
      final preference = const ThemePreference(mode: 'dark');
      await service.save(preference);

      final loaded = await service.load();
      expect(loaded, isNotNull);
      expect(loaded!.mode, equals('dark'));
    });

    test('load returns default mode when file has no themeMode key', () async {
      final file = File('${tempDir.path}/.mamadera_theme.json');
      await file.writeAsString(jsonEncode({'otherKey': 'value'}));

      final loaded = await service.load();
      expect(loaded, isNotNull);
      expect(loaded!.mode, equals('system'));
    });

    test('load returns null when file is corrupted', () async {
      final file = File('${tempDir.path}/.mamadera_theme.json');
      await file.writeAsString('not valid json{{{');

      final loaded = await service.load();
      expect(loaded, isNull);
    });

    test('clear removes the theme file', () async {
      final preference = const ThemePreference(mode: 'light');
      await service.save(preference);

      // Verify file exists
      expect(File('${tempDir.path}/.mamadera_theme.json').existsSync(), isTrue);

      await service.clear();

      // Verify file is removed
      expect(File('${tempDir.path}/.mamadera_theme.json').existsSync(), isFalse);
    });

    test('clear does nothing when file does not exist', () async {
      // Should not throw
      await expectLater(service.clear(), completes);
    });

    test('ThemePreference copyWith creates new instance', () async {
      const original = ThemePreference(mode: 'system');
      final updated = original.copyWith(mode: 'dark');

      expect(original.mode, equals('system'));
      expect(updated.mode, equals('dark'));
    });

    test('ThemePreference toMap returns correct map', () async {
      const preference = ThemePreference(mode: 'light');
      final map = preference.toMap();

      expect(map, equals({'themeMode': 'light'}));
    });

    test('ThemePreference toString contains mode', () async {
      const preference = ThemePreference(mode: 'dark');
      final str = preference.toString();

      expect(str, contains('ThemePreference'));
      expect(str, contains('dark'));
    });
  });
}
