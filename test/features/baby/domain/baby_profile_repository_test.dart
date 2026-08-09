// ignore_for_file: lines_longer_than_80_chars // Tests de l'interface BabyProfileRepository (contrat pur, sans DB)

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

/// Mock de [BabyProfileRepository] pour tester le contrat d'interface.
class MockBabyProfileRepository implements BabyProfileRepository {
  final Map<String, BabyProfile> _profiles = {};
  String? _activeId;

  @override
  Future<List<BabyProfile>> getAllProfiles() async {
    return _profiles.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  @override
  Future<BabyProfile?> getActiveProfile() async {
    if (_activeId == null) return null;
    return _profiles[_activeId];
  }

  @override
  Future<String> insertProfile(BabyProfile profile) async {
    _profiles[profile.id] = profile;
    return profile.id;
  }

  @override
  Future<BabyProfile?> updateProfile(String id, {String? name, DateTime? birthDate}) async {
    final existing = _profiles[id];
    if (existing == null) return null;
    final updated = BabyProfile(
      id: existing.id,
      name: name ?? existing.name,
      birthDate: birthDate ?? existing.birthDate,
      isActive: existing.isActive,
    );
    _profiles[id] = updated;
    return updated;
  }

  @override
  Future<bool> deleteProfile(String id) async {
    return _profiles.remove(id) != null;
  }

  @override
  Future<void> setActiveProfile(String id) async {
    if (_profiles.containsKey(id)) _activeId = id;
  }
}

void main() {
  late MockBabyProfileRepository repository;

  setUp(() {
    repository = MockBabyProfileRepository();
  });

  group('BabyProfileRepository interface contract', () {
    group('getAllProfiles', () {
      test('retourne une liste vide quand aucun profil n\'existe', () async {
        final result = await repository.getAllProfiles();
        expect(result, isEmpty);
      });

      test('retourne tous les profils insérés', () async {
        final profile1 = BabyProfile(id: 'p1', name: 'Léo', birthDate: DateTime(2024, 1, 15));
        final profile2 = BabyProfile(id: 'p2', name: 'Emma', birthDate: DateTime(2024, 6, 20));
        await repository.insertProfile(profile1);
        await repository.insertProfile(profile2);

        final result = await repository.getAllProfiles();
        expect(result, hasLength(2));
        expect(result.map((p) => p.id), unorderedEquals(['p1', 'p2']));
      });

      test('retourne les profils triés par ID (plus récent en premier)', () async {
        await repository.insertProfile(BabyProfile(id: 'a1', name: 'A', birthDate: DateTime(2024, 1, 1)));
        await repository.insertProfile(BabyProfile(id: 'a2', name: 'B', birthDate: DateTime(2024, 1, 2)));

        final result = await repository.getAllProfiles();
        expect(result.first.id, 'a2');
        expect(result.last.id, 'a1');
      });
    });

    group('getActiveProfile', () {
      test('retourne null quand aucun profil actif', () async {
        await repository.insertProfile(BabyProfile(id: 'p1', name: 'Léo', birthDate: DateTime(2024, 1, 1)));
        final result = await repository.getActiveProfile();
        expect(result, isNull);
      });

      test('retourne le profil actif après setActiveProfile', () async {
        final profile = BabyProfile(id: 'p1', name: 'Léo', birthDate: DateTime(2024, 1, 1), isActive: true);
        await repository.insertProfile(profile);
        await repository.setActiveProfile('p1');

        final result = await repository.getActiveProfile();
        expect(result, isNotNull);
        expect(result!.id, 'p1');
        expect(result.name, 'Léo');
      });

      test('retourne null pour un ID inconnu', () async {
        await repository.setActiveProfile('non_existent');
        final result = await repository.getActiveProfile();
        expect(result, isNull);
      });
    });

    group('insertProfile', () {
      test('insère un profil et retourne son ID', () async {
        final profile = BabyProfile(id: 'new-id', name: 'Nouveau', birthDate: DateTime(2024, 3, 10));
        final id = await repository.insertProfile(profile);

        expect(id, 'new-id');
        final all = await repository.getAllProfiles();
        expect(all, hasLength(1));
        expect(all.first.name, 'Nouveau');
      });

      test('écrase un profil avec le même ID', () async {
        final p1 = BabyProfile(id: 'p1', name: 'Original', birthDate: DateTime(2024, 1, 1));
        final p2 = BabyProfile(id: 'p1', name: 'Mis à jour', birthDate: DateTime(2024, 1, 1));
        await repository.insertProfile(p1);
        await repository.insertProfile(p2);

        final all = await repository.getAllProfiles();
        expect(all, hasLength(1));
        expect(all.first.name, 'Mis à jour');
      });
    });

    group('updateProfile', () {
      test('met à jour le nom et retourne le profil mis à jour', () async {
        await repository.insertProfile(BabyProfile(id: 'p1', name: 'Original', birthDate: DateTime(2024, 1, 1)));
        final updated = await repository.updateProfile('p1', name: 'Updated');

        expect(updated, isNotNull);
        expect(updated!.name, 'Updated');
        expect(updated.id, 'p1');
      });

      test('met à jour la date de naissance', () async {
        await repository.insertProfile(BabyProfile(id: 'p1', name: 'Test', birthDate: DateTime(2024, 1, 1)));
        final updated = await repository.updateProfile('p1', birthDate: DateTime(2025, 6, 15));

        expect(updated!.birthDate, DateTime(2025, 6, 15));
        expect(updated.name, 'Test');
      });

      test('retourne null pour un ID inexistant', () async {
        final updated = await repository.updateProfile('non_existent', name: 'Ghost');
        expect(updated, isNull);
      });

      test('ne modifie pas les champs non spécifiés', () async {
        await repository.insertProfile(BabyProfile(id: 'p1', name: 'Original', birthDate: DateTime(2024, 1, 1)));
        final updated = await repository.updateProfile('p1', name: 'NewName');

        expect(updated!.name, 'NewName');
        expect(updated.birthDate, DateTime(2024, 1, 1));
      });
    });

    group('deleteProfile', () {
      test('supprime un profil existant et retourne true', () async {
        await repository.insertProfile(BabyProfile(id: 'p1', name: 'À supprimer', birthDate: DateTime(2024, 1, 1)));
        final result = await repository.deleteProfile('p1');

        expect(result, isTrue);
        final all = await repository.getAllProfiles();
        expect(all, isEmpty);
      });

      test('retourne false pour un ID inexistant', () async {
        final result = await repository.deleteProfile('non_existent');
        expect(result, isFalse);
      });
    });

    group('setActiveProfile', () {
      test('active un profil et le retourne via getActiveProfile', () async {
        await repository.insertProfile(BabyProfile(id: 'p1', name: 'A', birthDate: DateTime(2024, 1, 1)));
        await repository.insertProfile(BabyProfile(id: 'p2', name: 'B', birthDate: DateTime(2024, 1, 2)));
        await repository.setActiveProfile('p2');

        final active = await repository.getActiveProfile();
        expect(active!.id, 'p2');
        expect(active.name, 'B');
      });

      test('met à jour le profil actif quand appelé plusieurs fois', () async {
        await repository.insertProfile(BabyProfile(id: 'p1', name: 'A', birthDate: DateTime(2024, 1, 1)));
        await repository.insertProfile(BabyProfile(id: 'p2', name: 'B', birthDate: DateTime(2024, 1, 2)));
        await repository.setActiveProfile('p1');
        await repository.setActiveProfile('p2');

        final active = await repository.getActiveProfile();
        expect(active!.id, 'p2');
      });
    });

    group('contrat complet', () {
      test('cycle complet: insert → update → setActive → read → delete', () async {
        // Insert
        final profile = BabyProfile(id: 'cycle-1', name: 'Cycle', birthDate: DateTime(2024, 5, 10));
        await repository.insertProfile(profile);
        expect((await repository.getAllProfiles()), hasLength(1));

        // Update
        final updated = await repository.updateProfile('cycle-1', name: 'Cycle Updated');
        expect(updated!.name, 'Cycle Updated');

        // Activate
        await repository.setActiveProfile('cycle-1');
        final active = await repository.getActiveProfile();
        expect(active!.name, 'Cycle Updated');

        // Delete
        final deleted = await repository.deleteProfile('cycle-1');
        expect(deleted, isTrue);
        expect(await repository.getAllProfiles(), isEmpty);
      });
    });
  });
}
