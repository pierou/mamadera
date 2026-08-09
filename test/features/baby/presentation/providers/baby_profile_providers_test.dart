// ignore_for_file: lines_longer_than_80_chars // Tests for BabyProfileRepositoryProvider

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';
import 'package:mamadera/data/local/app_db.dart' as db_app;

void main() {
  group('babyProfileRepositoryProvider', () {
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

    test('returns a BabyProfileRepository implementation', () async {
      final repo = await container.read(babyProfileRepositoryProvider.future);
      expect(repo, isA<BabyProfileRepository>());
    });

    test('repository can fetch all profiles', () async {
      final repo = await container.read(babyProfileRepositoryProvider.future);
      final profiles = await repo.getAllProfiles();
      expect(profiles, isEmpty);
    });
  });
}
