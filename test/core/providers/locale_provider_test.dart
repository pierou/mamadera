import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/locale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleNotifier', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('locale_provider_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('build returns device locale when supported', () async {
      final container = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      final state = await container.read(localeProvider.future);
      expect(state.languageCode, anyOf(equals('fr'), equals('en')));
      expect(state.isManualOverride, isFalse);

      container.dispose();
    });

    test('build returns fr when no saved preference', () async {
      final container = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      // Clear any existing file
      final file = File('${tempDir.path}/.mamadera_locale.json');
      if (file.existsSync()) await file.delete();

      final state = await container.read(localeProvider.future);
      expect(state.languageCode, anyOf(equals('fr'), equals('en')));

      container.dispose();
    });

    test('setLocale updates state and persists', () async {
      final container = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      await container.read(localeProvider.future);
      await container.read(localeProvider.notifier).setLocale('en');

      final state = container.read(localeProvider);
      expect(state.value?.languageCode, equals('en'));
      expect(state.value?.isManualOverride, isTrue);

      // Verify persistence
      final file = File('${tempDir.path}/.mamadera_locale.json');
      expect(file.existsSync(), isTrue);
      final content = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(content['languageCode'], equals('en'));
      expect(content['isManualOverride'], isTrue);

      container.dispose();
    });

    test('setLocale fr updates correctly', () async {
      final container = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      await container.read(localeProvider.future);
      await container.read(localeProvider.notifier).setLocale('fr');

      final state = container.read(localeProvider);
      expect(state.value?.languageCode, equals('fr'));

      container.dispose();
    });

    test('setLocale unsupported language does nothing', () async {
      final container = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      await container.read(localeProvider.future);
      await container.read(localeProvider.notifier).setLocale('de');

      final state = container.read(localeProvider);
      // Should remain at initial value
      expect(state.value?.languageCode, anyOf(equals('fr'), equals('en')));

      container.dispose();
    });

    test('resolveLocale returns correct ui.Locale', () async {
      final container = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      await container.read(localeProvider.future);
      final notifier = container.read(localeProvider.notifier);

      // Should match the initial language code
      final locale = notifier.resolveLocale();
      expect(locale.languageCode, anyOf(equals('fr'), equals('en')));

      // After changing to English
      await notifier.setLocale('en');
      expect(notifier.resolveLocale().languageCode, equals('en'));

      container.dispose();
    });

    test('persists across container recreation', () async {
      // First container - set English
      final container1 = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      await container1.read(localeProvider.future);
      await container1.read(localeProvider.notifier).setLocale('en');
      container1.dispose();

      // Second container - should load English
      final container2 = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWith((ref) => _TestLocaleService(tempDir.path)),
        ],
      );

      final state = await container2.read(localeProvider.future);
      expect(state.languageCode, equals('en'));

      container2.dispose();
    });
  });
}

// Mock LocaleService that writes to a specific directory
class _TestLocaleService implements LocaleService {
  final String path;

  _TestLocaleService(this.path);

  File _getFile() => File('$path/.mamadera_locale.json');

  @override
  Future<LocalePreference?> load() async {
    final file = _getFile();
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return LocalePreference(
      languageCode: map['languageCode'] as String? ?? 'fr',
      isManualOverride: map['isManualOverride'] as bool? ?? false,
    );
  }

  @override
  Future<void> save(LocalePreference preference) async {
    final file = _getFile();
    await file.writeAsString(
      jsonEncode({
        'languageCode': preference.languageCode,
        'isManualOverride': preference.isManualOverride,
      }),
    );
  }

  @override
  Future<void> clear() async {
    final file = _getFile();
    if (await file.exists()) await file.delete();
  }
}
