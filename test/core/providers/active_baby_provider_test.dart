// ignore_for_file: lines_longer_than_80_chars // Tests for ActiveBabyNotifier

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

/// Fake repository for testing ActiveBabyNotifier.
class FakeBabyProfileRepository implements BabyProfileRepository {
  BabyProfile? _activeProfile;
  final Map<String, BabyProfile> _profiles = {};

  FakeBabyProfileRepository({BabyProfile? activeProfile})
      : _activeProfile = activeProfile;

  void setProfile(BabyProfile profile) {
    _profiles[profile.id] = profile;
    if (profile.isActive) _activeProfile = profile;
  }

  void setActiveId(String? id) {
    _activeProfile = id != null ? _profiles[id] : null;
  }

  @override
  Future<List<BabyProfile>> getAllProfiles() async => _profiles.values.toList();

  @override
  Future<BabyProfile?> getActiveProfile() async => _activeProfile;

  @override
  Future<String> insertProfile(BabyProfile profile) async {
    _profiles[profile.id] = profile;
    return profile.id;
  }

  @override
  Future<BabyProfile?> updateProfile(String id, {String? name, DateTime? birthDate}) async {
    final profile = _profiles[id];
    if (profile == null) return null;
    final updated = BabyProfile(
      id: profile.id,
      name: name ?? profile.name,
      birthDate: birthDate ?? profile.birthDate,
      isActive: profile.isActive,
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
    setActiveId(id);
  }
}

void main() {
  group('ActiveBabyNotifier', () {
    late FakeBabyProfileRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = FakeBabyProfileRepository();
      container = ProviderContainer(overrides: [
        babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('returns null when no active profile', () async {
      final result = await container.read(activeBabyProvider.future);
      expect(result, isNull);
    });

    test('returns active profile when set', () async {
      final profile = BabyProfile(id: '1', name: 'Test', birthDate: DateTime(2024, 1, 1), isActive: true);
      mockRepo.setProfile(profile);
      
      final result = await container.read(activeBabyProvider.future);
      expect(result?.name, 'Test');
    });

    test('refreshes active profile', () async {
      final profile1 = BabyProfile(id: '1', name: 'Test1', birthDate: DateTime(2024, 1, 1), isActive: true);
      final profile2 = BabyProfile(id: '2', name: 'Test2', birthDate: DateTime(2024, 2, 2), isActive: true);
      
      mockRepo.setProfile(profile1);
      var result = await container.read(activeBabyProvider.future);
      expect(result?.name, 'Test1');

      mockRepo.setProfile(profile2);
      await container.read(activeBabyProvider.notifier).refresh();
      result = await container.read(activeBabyProvider.future);
      expect(result?.name, 'Test2');
    });

    test('switchProfile updates active profile', () async {
      final profile1 = BabyProfile(id: '1', name: 'Test1', birthDate: DateTime(2024, 1, 1), isActive: true);
      final profile2 = BabyProfile(id: '2', name: 'Test2', birthDate: DateTime(2024, 2, 2), isActive: true);
      
      mockRepo.setProfile(profile1);
      mockRepo.setProfile(profile2);
      
      await container.read(activeBabyProvider.notifier).switchProfile('2');
      final result = await container.read(activeBabyProvider.future);
      expect(result?.id, '2');
    });
  });
}
