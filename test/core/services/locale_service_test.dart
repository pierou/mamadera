import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/locale_service.dart';

void main() {
  late LocaleService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mamadera_locale_test_');
    service = LocaleService(directoryResolver: () => tempDir);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('LocalePreference', () {
    test('should create with required fields', () {
      const pref = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );

      expect(pref.languageCode, 'en');
      expect(pref.isManualOverride, true);
    });

    test('copyWith should replace specified fields', () {
      const original = LocalePreference(
        languageCode: 'fr',
        isManualOverride: false,
      );

      final updated = original.copyWith(languageCode: 'en');

      expect(updated.languageCode, 'en');
      expect(updated.isManualOverride, false); // unchanged
    });

    test('copyWith should replace both fields when provided', () {
      const original = LocalePreference(
        languageCode: 'fr',
        isManualOverride: false,
      );

      final updated = original.copyWith(
        languageCode: 'en',
        isManualOverride: true,
      );

      expect(updated.languageCode, 'en');
      expect(updated.isManualOverride, true);
    });

    test('copyWith should keep all fields when none provided', () {
      const original = LocalePreference(
        languageCode: 'fr',
        isManualOverride: false,
      );

      final copied = original.copyWith();

      expect(copied.languageCode, original.languageCode);
      expect(copied.isManualOverride, original.isManualOverride);
    });

    test('toMap should serialize all fields', () {
      const pref = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );

      final map = pref.toMap();

      expect(map['languageCode'], 'en');
      expect(map['isManualOverride'], true);
    });

    test('toString should include language code and override flag', () {
      const pref = LocalePreference(
        languageCode: 'fr',
        isManualOverride: true,
      );

      final string = pref.toString();

      expect(string, contains('LocalePreference'));
      expect(string, contains('fr'));
      expect(string, contains('override: true'));
    });
  });

  group('load()', () {
    test('should return null when no data is saved', () async {
      final result = await service.load();

      expect(result, isNull);
    });

    test('should load previously saved preference', () async {
      const pref = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );

      await service.save(pref);
      final loaded = await service.load();

      expect(loaded, isNotNull);
      expect(loaded!.languageCode, 'en');
      expect(loaded.isManualOverride, true);
    });

    test('should load with default values when JSON has missing fields', () async {
      // path_provider gives us a real temp directory in tests
      final file = File('${tempDir.path}/.mamadera_locale.json');
      await file.writeAsString(jsonEncode({'languageCode': 'de'}));

      final loaded = await service.load();

      expect(loaded, isNotNull);
      expect(loaded!.languageCode, 'de');
      // Missing isManualOverride should default to false
      expect(loaded.isManualOverride, false);
    });

    test('should return null when JSON file contains invalid data', () async {
      final file = File('${tempDir.path}/.mamadera_locale.json');
      await file.writeAsString('not valid json{{{');

      final loaded = await service.load();

      expect(loaded, isNull);
    });

    test('should load preference with manual override false', () async {
      const pref = LocalePreference(
        languageCode: 'fr',
        isManualOverride: false,
      );

      await service.save(pref);
      final loaded = await service.load();

      expect(loaded!.languageCode, 'fr');
      expect(loaded.isManualOverride, false);
    });
  });

  group('save()', () {
    test('should write preference to disk', () async {
      const pref = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );

      await service.save(pref);

      final file = File('${tempDir.path}/.mamadera_locale.json');
      expect(await file.exists(), isTrue);

      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['languageCode'], 'en');
      expect(map['isManualOverride'], true);
    });

    test('should overwrite existing preference', () async {
      const pref1 = LocalePreference(
        languageCode: 'fr',
        isManualOverride: false,
      );
      await service.save(pref1);

      final file = File('${tempDir.path}/.mamadera_locale.json');
      expect(await file.exists(), isTrue);

      const pref2 = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );
      await service.save(pref2);

      // Verify the overwrite
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['languageCode'], 'en');
    });
  });

  group('clear()', () {
    test('should remove persisted data', () async {
      const pref = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );
      await service.save(pref);

      final file = File('${tempDir.path}/.mamadera_locale.json');
      expect(await file.exists(), isTrue);

      await service.clear();

      expect(await file.exists(), isFalse);
    });

    test('should not throw when no data exists', () async {
      // No prior save, clear should be safe on empty state
      await service.clear();

      // Verify the file does not exist (no error was thrown)
      final file = File('${tempDir.path}/.mamadera_locale.json');
      expect(await file.exists(), isFalse);
    });

    test('load after clear should return null', () async {
      const pref = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );
      await service.save(pref);

      final beforeClear = await service.load();
      expect(beforeClear, isNotNull);

      await service.clear();

      final afterClear = await service.load();
      expect(afterClear, isNull);
    });
  });

  group('round-trip', () {
    test('should preserve all fields through save and load cycle', () async {
      const original = LocalePreference(
        languageCode: 'en',
        isManualOverride: true,
      );

      await service.save(original);
      final loaded = await service.load();

      expect(loaded!.languageCode, original.languageCode);
      expect(loaded.isManualOverride, original.isManualOverride);
    });

    test('should handle multiple save-load cycles', () async {
      const pref1 = LocalePreference(languageCode: 'fr', isManualOverride: false);
      await service.save(pref1);
      var loaded = await service.load();
      expect(loaded!.languageCode, 'fr');

      const pref2 = LocalePreference(languageCode: 'en', isManualOverride: true);
      await service.save(pref2);
      loaded = await service.load();
      expect(loaded!.languageCode, 'en');
    });
  });
}
