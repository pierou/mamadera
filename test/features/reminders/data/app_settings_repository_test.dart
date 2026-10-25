import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/data/repositories/app_settings_repository_impl.dart';

void main() {
  group('AppSettingsRepositoryImpl', () {
    late AppDatabase database;
    late AppSettingsRepositoryImpl repository;

    setUp(() async {
      final connection = LazyDatabase(NativeDatabase.memory);
      database = AppDatabase(connection);
      // Trigger onCreate (schema v13) before any test runs.
      await database.select(database.appSettings).get();
      repository = AppSettingsRepositoryImpl(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    test('get() returns null for a key that was never set', () async {
      expect(await repository.get(settingsKeyNotificationsOptIn), isNull);
      expect(await repository.get(settingsKeyNotificationTime), isNull);
    });

    test('set() then get() round-trips a value', () async {
      await repository.set(settingsKeyNotificationsOptIn, '1');
      expect(await repository.get(settingsKeyNotificationsOptIn), '1');

      await repository.set(settingsKeyNotificationTime, '08:30');
      expect(await repository.get(settingsKeyNotificationTime), '08:30');
    });

    test('set() on an existing key overwrites the value (upsert, one row)',
        () async {
      await repository.set(settingsKeyNotificationTime, '09:00');
      await repository.set(settingsKeyNotificationTime, '07:15');
      expect(await repository.get(settingsKeyNotificationTime), '07:15');

      final all = await repository.getAll();
      expect(all.length, 1, reason: 'one row per key, not one per set()');
      expect(all[settingsKeyNotificationTime], '07:15');
    });

    test('getAll() returns an empty map on a fresh database', () async {
      expect(await repository.getAll(), isEmpty);
    });

    test('getAll() returns every stored key/value pair', () async {
      await repository.set(settingsKeyNotificationsOptIn, '0');
      await repository.set(settingsKeyNotificationTime, '09:00');
      final all = await repository.getAll();
      expect(all, {
        settingsKeyNotificationsOptIn: '0',
        settingsKeyNotificationTime: '09:00',
      });
    });

    test('deleteAll() empties the table', () async {
      await repository.set(settingsKeyNotificationsOptIn, '1');
      await repository.set(settingsKeyNotificationTime, '09:00');
      expect((await repository.getAll()).length, 2);

      await repository.deleteAll();
      expect(await repository.getAll(), isEmpty);
      expect(await repository.get(settingsKeyNotificationsOptIn), isNull);
    });
  });
}
