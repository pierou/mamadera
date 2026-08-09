// ignore_for_file: lines_longer_than_80_chars // Tests for HistoryRepositoryProvider

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/data/local/app_db.dart' as db_app;

void main() {
  group('historyRepositoryProvider', () {
    late ProviderContainer container;
    late db_app.AppDatabase database;

    setUp(() async {
      database = db_app.AppDatabase(LazyDatabase(NativeDatabase.memory));
      await database.select(database.babyProfiles).get();
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWith((ref) async => database),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('returns a HistoryRepository implementation', () async {
      final repo = await container.read(historyRepositoryProvider.future);
      expect(repo, isA<HistoryRepository>());
    });

    test('repository can fetch all events ordered', () async {
      final repo = await container.read(historyRepositoryProvider.future);
      final events = await repo.getAllEventsOrdered();
      expect(events, isEmpty);
    });
  });
}
