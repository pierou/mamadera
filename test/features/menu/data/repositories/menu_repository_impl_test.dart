import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/providers/theme_provider.dart';
import 'package:mamadera/features/menu/domain/repositories/menu_repository.dart';
import 'package:mamadera/features/menu/presentation/providers/menu_repository_provider.dart';

void main() {
  group('MenuRepositoryImpl', () {
    late ProviderContainer container;
    late MenuRepository repository;

    setUp(() {
      container = ProviderContainer();
      repository = container.read(menuRepositoryProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('getCurrentLanguage', () {
      test('returns fr when locale is loading', () {
        final result = repository.getCurrentLanguage();
        expect(result, equals('fr'));
      });

      test('returns correct language when locale is data', () async {
        await container.read(localeProvider.future);
        final result = repository.getCurrentLanguage();
        expect(result, anyOf(equals('fr'), equals('en')));
      });
    });

    group('setLanguage', () {
      test('does nothing for unsupported language', () async {
        await expectLater(repository.setLanguage('de'), completes);
      });

      test('sets supported language', () async {
        await container.read(localeProvider.future);
        await repository.setLanguage('en');
        final state = container.read(localeProvider);
        expect(state.value?.languageCode, equals('en'));
      });
    });

    group('getCurrentThemeMode', () {
      test('returns system when theme is loading', () {
        final result = repository.getCurrentThemeMode();
        expect(result, equals('system'));
      });

      test('returns correct theme mode when data', () async {
        await container.read(themeProvider.future);
        final result = repository.getCurrentThemeMode();
        expect(result, anyOf(equals('system'), equals('light'), equals('dark')));
      });
    });

    group('setThemeMode', () {
      test('does nothing for invalid mode', () async {
        await expectLater(repository.setThemeMode('invalid'), completes);
      });

      test('sets light mode', () async {
        await container.read(themeProvider.future);
        await repository.setThemeMode('light');
        final state = container.read(themeProvider);
        expect(state.value?.mode, equals('light'));
      });

      test('sets dark mode', () async {
        await container.read(themeProvider.future);
        await repository.setThemeMode('dark');
        final state = container.read(themeProvider);
        expect(state.value?.mode, equals('dark'));
      });

      test('sets system mode', () async {
        await container.read(themeProvider.future);
        await repository.setThemeMode('system');
        final state = container.read(themeProvider);
        expect(state.value?.mode, equals('system'));
      });
    });

    group('getSupportedLanguages', () {
      test('returns fr, en and es', () {
        final languages = repository.getSupportedLanguages();
        expect(languages, equals(['fr', 'en', 'es']));
      });

      test('returns immutable list', () {
        final languages = repository.getSupportedLanguages();
        expect(() => languages.add('de'), throwsUnsupportedError);
      });
    });

    group('resetDatabase', () {
      // Skipped: requires platform channels for database access not available in tests
      // test('closes and invalidates database provider', () async { ... });
    });
  });
}
