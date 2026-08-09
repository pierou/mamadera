import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/core/services/theme_service.dart';
import 'package:mamadera/data/local/app_db.dart' as drift;
import 'package:mamadera/data/local/database.dart';
import 'package:mamadera/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'menu_repository_impl_test.mocks.dart';

// Shared DB event type constants (mirror lib/data/local/db_constants.dart)
const String _typeMiam = 'miam';

// ignore_for_file: type=lint
@GenerateMocks([drift.AppDatabase])
void main() {
  late Directory tempDir;
  late LocaleService localeService;
  late ThemeService themeService;
  late MockAppDatabase mockDb;
  late MenuRepositoryImpl repository;

  Future<Directory> _resolveTempDir() async => tempDir;

  setUp(() async {
    final uniqueName = 'menu_repo_test_${DateTime.now().millisecondsSinceEpoch}';
    tempDir = await Directory('${Directory.systemTemp.path}/$uniqueName').create(
          recursive: true,
        );

    localeService = LocaleService(directoryResolver: _resolveTempDir);
    themeService = ThemeService(directoryResolver: _resolveTempDir);
    mockDb = MockAppDatabase();
    when(mockDb.close()).thenAnswer((_) async => {});

    repository = MenuRepositoryImpl(
      localeService: localeService,
      themeService: themeService,
      databaseFuture: Future.value(mockDb),
      directoryPath: tempDir.path,
    );
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Ignore cleanup errors.
    }
  });

  group('getCurrentLanguage', () {
    test('returns fr when no preference saved', () async {
      final result = await repository.getCurrentLanguage();
      expect(result, equals('fr'));
    });

    test('returns correct language after saving', () async {
      await localeService.save(
        const LocalePreference(languageCode: 'en', isManualOverride: true),
      );

      final result = await repository.getCurrentLanguage();
      expect(result, equals('en'));
    });

    test('returns fr on corrupted file', () async {
      // Write invalid JSON to the locale file
      final localeFile = File('${tempDir.path}/.mamadera_locale.json');
      await localeFile.writeAsString('not valid json{{{');

      final result = await repository.getCurrentLanguage();
      expect(result, equals('fr'));
    });
  });

  group('setLanguage', () {
    test('does nothing for unsupported language', () async {
      await expectLater(repository.setLanguage('de'), completes);
      // Verify no file was written (or original state unchanged)
      final pref = await localeService.load();
      expect(pref, isNull);
    });

    test('sets supported language fr', () async {
      await repository.setLanguage('fr');
      final saved = await localeService.load();
      expect(saved?.languageCode, equals('fr'));
      expect(saved?.isManualOverride, isTrue);
    });

    test('sets supported language en', () async {
      await repository.setLanguage('en');
      final saved = await localeService.load();
      expect(saved?.languageCode, equals('en'));
      expect(saved?.isManualOverride, isTrue);
    });

    test('sets supported language es', () async {
      await repository.setLanguage('es');
      final saved = await localeService.load();
      expect(saved?.languageCode, equals('es'));
    });

    test(
      'persists preference and subsequent getCurrentLanguage reflects change',
      () async {
        await repository.setLanguage('en');
        final current = await repository.getCurrentLanguage();
        expect(current, equals('en'));
      },
    );
  });

  group('getCurrentThemeMode', () {
    test('returns system when no preference saved', () async {
      final result = await repository.getCurrentThemeMode();
      expect(result, equals('system'));
    });

    test('returns correct theme mode after saving', () async {
      await themeService.save(const ThemePreference(mode: 'dark'));

      final result = await repository.getCurrentThemeMode();
      expect(result, equals('dark'));
    });

    test('returns system on corrupted file', () async {
      final themeFile = File('${tempDir.path}/.mamadera_theme.json');
      await themeFile.writeAsString('{invalid json content');

      final result = await repository.getCurrentThemeMode();
      expect(result, equals('system'));
    });
  });

  group('setThemeMode', () {
    test('does nothing for invalid mode', () async {
      await expectLater(repository.setThemeMode('invalid'), completes);
      // Verify no file was written
      final pref = await themeService.load();
      expect(pref, isNull);
    });

    test('sets light mode', () async {
      await repository.setThemeMode('light');
      final saved = await themeService.load();
      expect(saved?.mode, equals('light'));
    });

    test('sets dark mode', () async {
      await repository.setThemeMode('dark');
      final saved = await themeService.load();
      expect(saved?.mode, equals('dark'));
    });

    test('sets system mode', () async {
      await repository.setThemeMode('system');
      final saved = await themeService.load();
      expect(saved?.mode, equals('system'));
    });

    test(
      'persists preference and subsequent getCurrentThemeMode reflects change',
      () async {
        await repository.setThemeMode('dark');
        final current = await repository.getCurrentThemeMode();
        expect(current, equals('dark'));
      },
    );
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
    test(
      'closes database and deletes SQLite file when it exists',
      () async {
        // Create a real database in temp dir for this test
        final db = await createAppDatabase(directoryPath: tempDir.path);

        // Insert an event to ensure DB file is created on disk
        await db.insertEvent(
          drift.TrackingEventsCompanion(
            type: const Value(_typeMiam),
            timestamp: Value(DateTime.now()),
          ),
        );

        final initialDb = MenuRepositoryImpl(
          localeService: localeService,
          themeService: themeService,
          databaseFuture: Future.value(db),
          directoryPath: tempDir.path,
        );

        // Verify file exists before reset
        final dbFile = File('${tempDir.path}/mamadera.db');
        expect(await dbFile.exists(), isTrue);

        // Reset should close DB and delete file
        await initialDb.resetDatabase();

        expect(await dbFile.exists(), isFalse);
      },
    );

    test('does nothing when database file does not exist', () async {
      // No DB file created in temp dir — should not throw
      await expectLater(repository.resetDatabase(), completes);

      verify(mockDb.close()).called(1);
    });

    test('succeeds even if database is already closed', () async {
      // Create and close a real database first
      final db = await createAppDatabase(directoryPath: tempDir.path);
      await db.insertEvent(
        drift.TrackingEventsCompanion(
          type: const Value(_typeMiam),
          timestamp: Value(DateTime.now()),
        ),
      );
      await db.close();

      final closedDbRepo = MenuRepositoryImpl(
        localeService: localeService,
        themeService: themeService,
        databaseFuture: Future.value(db),
        directoryPath: tempDir.path,
      );

      final dbFile = File('${tempDir.path}/mamadera.db');
      expect(await dbFile.exists(), isTrue);

      // Should not throw even though DB is already closed
      await expectLater(closedDbRepo.resetDatabase(), completes);
      expect(await dbFile.exists(), isFalse);
    });
  });
}
