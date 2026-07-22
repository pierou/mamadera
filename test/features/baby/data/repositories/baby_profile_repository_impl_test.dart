import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart' as db_app;
import 'package:mamadera/features/baby/data/repositories/baby_profile_repository_impl.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

void main() {
  group('BabyProfileRepositoryImpl', () {
    late db_app.AppDatabase database;
    late BabyProfileRepositoryImpl repository;

    setUp(() async {
      final connection = LazyDatabase(NativeDatabase.memory);
      database = db_app.AppDatabase(connection);
      // Trigger migration to create tables before any test runs.
      await database.select(database.babyProfiles).get();
      repository = BabyProfileRepositoryImpl(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    final baby1 = BabyProfile(
      id: 'baby-001',
      name: 'Léo',
      birthDate: DateTime(2026, 3, 15),
      isActive: true,
    );
    final baby2 = BabyProfile(
      id: 'baby-002',
      name: 'Emma',
      birthDate: DateTime(2026, 7, 1),
      isActive: false,
    );

    group('getAllProfiles', () {
      test('returns empty list when no profiles exist', () async {
        final result = await repository.getAllProfiles();
        expect(result, isEmpty);
      });

      test('returns all profiles', () async {
        await repository.insertProfile(baby1);
        await repository.insertProfile(baby2);

        final result = await repository.getAllProfiles();
        expect(result, hasLength(2));
        // Verify both are present (order not guaranteed without explicit ORDER BY).
        expect(result.map((p) => p.id), contains('baby-001'));
        expect(result.map((p) => p.id), contains('baby-002'));
      });

      test('profiles have correct domain entity fields', () async {
        await repository.insertProfile(baby1);

        final result = await repository.getAllProfiles();
        final profile = result.first;
        expect(profile.name, equals('Léo'));
        expect(profile.birthDate.year, equals(2026));
        expect(profile.birthDate.month, equals(3));
        expect(profile.birthDate.day, equals(15));
        expect(profile.isActive, isTrue);
      });

      test('birthDayOfMonth getter works on returned profiles', () async {
        await repository.insertProfile(baby1);

        final result = await repository.getAllProfiles();
        expect(babyProfileBirthDayOfMonth(result.first.birthDate), equals(15));
      });
    });

    group('getActiveProfile', () {
      test('returns null when no profiles exist', () async {
        final result = await repository.getActiveProfile();
        expect(result, isNull);
      });

      test('returns active profile', () async {
        await repository.insertProfile(baby1);

        final result = await repository.getActiveProfile();
        expect(result, isNotNull);
        expect(result!.id, equals(baby1.id));
        expect(result.name, equals('Léo'));
      });

      test('returns null when active profile has been deactivated', () async {
        await repository.insertProfile(babyProfileUpdated(baby2, isActive: false));

        final result = await repository.getActiveProfile();
        expect(result, isNull);
      });

      test('returns correct one when multiple profiles exist', () async {
        await repository.insertProfile(babyProfileUpdated(baby1, name: 'Léo (inactive)', isActive: false));
        await repository.insertProfile(babyProfileUpdated(baby2, isActive: true));

        final result = await repository.getActiveProfile();
        expect(result, isNotNull);
        expect(result!.name, equals('Emma'));
      });
    });

    group('insertProfile', () {
      test('returns the profile id on success', () async {
        final id = await repository.insertProfile(baby1);
        expect(id, equals('baby-001'));
      });

      test('profile is immediately queryable after insert', () async {
        await repository.insertProfile(baby1);

        final profile = await repository.getActiveProfile();
        expect(profile, isNotNull);
        expect(profile!.name, equals('Léo'));
      });

      test('can insert multiple profiles with different IDs', () async {
        await repository.insertProfile(baby1);
        await repository.insertProfile(baby2);

        final all = await repository.getAllProfiles();
        expect(all, hasLength(2));
      });
    });

    group('updateProfile', () {
      test('updates the name field', () async {
        await repository.insertProfile(baby1);

        final updated = await repository.updateProfile('baby-001', name: 'Léonard');
        expect(updated, isNotNull);
        expect(updated!.name, equals('Léonard'));
      });

      test('updates the birthDate field', () async {
        await repository.insertProfile(baby1);

        final newBirth = DateTime(2026, 5, 20);
        final updated = await repository.updateProfile('baby-001', birthDate: newBirth);
        expect(updated, isNotNull);
        expect(updated!.birthDate.day, equals(20));
        expect(updated.birthDate.month, equals(5));
      });

      test('updates both name and birthDate together', () async {
        await repository.insertProfile(baby1);

        final updated = await repository.updateProfile(
          'baby-001',
          name: 'Léonard',
          birthDate: DateTime(2026, 5, 20),
        );
        expect(updated!.name, equals('Léonard'));
        expect(babyProfileBirthDayOfMonth(updated.birthDate), equals(20));
      });

      test('leaves unchanged fields intact when updating only one', () async {
        await repository.insertProfile(baby1);

        final updated = await repository.updateProfile('baby-001', name: 'Léonard');
        expect(updated!.name, equals('Léonard'));
        expect(updated.birthDate.day, equals(15)); // unchanged
      });

      test('throws exception when updating non-existent profile ID', () async {
        // updateProfile calls getAllProfiles().firstWhere(... orElse: throw Exception)
        expect(
          () => repository.updateProfile('nonexistent-id', name: 'Nobody'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteProfile', () {
      test('deletes an existing profile and returns true', () async {
        await repository.insertProfile(baby1);

        final deleted = await repository.deleteProfile('baby-001');
        expect(deleted, isTrue);

        final all = await repository.getAllProfiles();
        expect(all, isEmpty);
      });

      test('returns false when deleting non-existent profile', () async {
        final deleted = await repository.deleteProfile('nonexistent-id');
        expect(deleted, isFalse);
      });

      test('can delete one of multiple profiles', () async {
        await repository.insertProfile(baby1);
        await repository.insertProfile(baby2);

        final deleted = await repository.deleteProfile('baby-001');
        expect(deleted, isTrue);

        final all = await repository.getAllProfiles();
        expect(all, hasLength(1));
        expect(all.first.id, equals('baby-002'));
      });
    });

    group('setActiveProfile', () {
      test('activates a profile and deactivates others', () async {
        await repository.insertProfile(babyProfileUpdated(baby1, isActive: false));
        await repository.insertProfile(babyProfileUpdated(baby2, isActive: true));

        // Emma is active, switch to Léo.
        await repository.setActiveProfile('baby-001');

        final leo = await repository.getActiveProfile();
        expect(leo!.id, equals('baby-001'));
        expect(leo.name, equals('Léo'));
      });

      test('activates profile when no active one exists', () async {
        await repository.insertProfile(babyProfileUpdated(baby1, isActive: false));
        await repository.insertProfile(babyProfileUpdated(baby2, isActive: false));

        await repository.setActiveProfile('baby-002');

        final all = await repository.getAllProfiles();
        final emma = all.firstWhere((p) => p.id == 'baby-002');
        expect(emma.isActive, isTrue);
      });

      test('switching active to same profile is idempotent', () async {
        await repository.insertProfile(babyProfileUpdated(baby1, isActive: true));

        // Call setActive twice on the same ID.
        await repository.setActiveProfile('baby-001');
        await repository.setActiveProfile('baby-001');

        final active = await repository.getActiveProfile();
        expect(active!.id, equals('baby-001'));
      });

      test('activating non-existent profile is silent no-op', () async {
        // drift update on a missing row silently succeeds, so the implementation
        // does not throw — it just leaves nothing active.
        await repository.setActiveProfile('ghost-id');

        final all = await repository.getAllProfiles();
        expect(all, isEmpty);
      });
    });
  });
}
