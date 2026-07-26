import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/app_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPreferencesService', () {
    late Directory testDir;
    late AppPreferencesService service;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp('test_prefs_');
      service = AppPreferencesService(
        directoryResolver: () async => testDir,
      );
    });

    tearDown(() async {
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('load returns null when no file exists', () async {
      final result = await service.load();
      expect(result, isNull);
    });

    test('save and load persists preferences', () async {
      final prefs = const AppPreferences(
        appVersion: '1.1.0',
        termsAccepted: true,
        patchNotesOptOut: false,
      );

      await service.save(prefs);
      final loaded = await service.load();

      expect(loaded, isNotNull);
      expect(loaded!.appVersion, '1.1.0');
      expect(loaded.termsAccepted, true);
      expect(loaded.patchNotesOptOut, false);
    });

    test('load returns default values when file is empty', () async {
      final file = File('${testDir.path}/.mamadera_prefs.json');
      await file.writeAsString('{}');

      final loaded = await service.load();
      expect(loaded, isNotNull);
      expect(loaded!.appVersion, '');
      expect(loaded.termsAccepted, false);
      expect(loaded.patchNotesOptOut, false);
    });

    test('load handles corrupted JSON gracefully', () async {
      final file = File('${testDir.path}/.mamadera_prefs.json');
      await file.writeAsString('invalid json{{{');

      final loaded = await service.load();
      expect(loaded, isNull);
    });

    test('clear removes the preferences file', () async {
      final prefs = const AppPreferences(
        appVersion: '1.0.0',
        termsAccepted: true,
        patchNotesOptOut: true,
      );

      await service.save(prefs);
      await service.clear();

      final file = File('${testDir.path}/.mamadera_prefs.json');
      expect(await file.exists(), isFalse);

      final loaded = await service.load();
      expect(loaded, isNull);
    });

    test('load partial data - only termsAccepted', () async {
      final file = File('${testDir.path}/.mamadera_prefs.json');
      await file.writeAsString(jsonEncode({'termsAccepted': true}));

      final loaded = await service.load();
      expect(loaded, isNotNull);
      expect(loaded!.termsAccepted, true);
      expect(loaded.appVersion, '');
      expect(loaded.patchNotesOptOut, false);
    });

    test('load partial data - only patchNotesOptOut', () async {
      final file = File('${testDir.path}/.mamadera_prefs.json');
      await file.writeAsString(jsonEncode({'patchNotesOptOut': true}));

      final loaded = await service.load();
      expect(loaded, isNotNull);
      expect(loaded!.patchNotesOptOut, true);
      expect(loaded.termsAccepted, false);
      expect(loaded.appVersion, '');
    });
  });
}
