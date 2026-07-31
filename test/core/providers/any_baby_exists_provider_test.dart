import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

/// Mutable fake repository for testing state changes.
class FakeBabyProfileRepository implements BabyProfileRepository {
  List<BabyProfile> profiles = [];

  @override
  Future<List<BabyProfile>> getAllProfiles() async => profiles;

  @override
  Future<BabyProfile?> getActiveProfile() async => null;

  @override
  Future<String> insertProfile(BabyProfile profile) async {
    return profile.id;
  }

  @override
  Future<BabyProfile?> updateProfile(
    String id, {
    String? name,
    DateTime? birthDate,
  }) async => null;

  @override
  Future<bool> deleteProfile(String id) async => false;

  @override
  Future<void> setActiveProfile(String id) async {}
}

void main() {
  group('AnyBabyExistsNotifier', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('returns false when no profiles exist', () async {
      final fakeRepo = FakeBabyProfileRepository();
      container = ProviderContainer(overrides: [
        babyProfileRepositoryProvider.overrideWith((ref) async => fakeRepo),
      ]);

      final result = await container.read(anyBabyExistsProvider.future);
      expect(result, isFalse);
    });

    test('returns true when at least one profile exists', () async {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 1, 1),
        isActive: true,
      );
      final fakeRepo = FakeBabyProfileRepository();
      fakeRepo.profiles.add(profile);
      container = ProviderContainer(overrides: [
        babyProfileRepositoryProvider.overrideWith((ref) async => fakeRepo),
      ]);

      final result = await container.read(anyBabyExistsProvider.future);
      expect(result, isTrue);
    });

    test('returns true regardless of active status', () async {
      final profileOne = BabyProfile(
        id: '1',
        name: 'Baby One',
        birthDate: DateTime(2024, 1, 1),
        isActive: false,
      );
      final profileTwo = BabyProfile(
        id: '2',
        name: 'Baby Two',
        birthDate: DateTime(2024, 6, 15),
        isActive: false,
      );
      final fakeRepo = FakeBabyProfileRepository();
      fakeRepo.profiles.addAll([profileOne, profileTwo]);
      container = ProviderContainer(overrides: [
        babyProfileRepositoryProvider.overrideWith((ref) async => fakeRepo),
      ]);

      final result = await container.read(anyBabyExistsProvider.future);
      // The provider checks profiles.isNotEmpty, not active status
      expect(result, isTrue);
    });

    test('refresh updates state based on current profiles', () async {
      final dynamicRepo = FakeBabyProfileRepository();
      container = ProviderContainer(overrides: [
        babyProfileRepositoryProvider.overrideWith(
          (ref) async => dynamicRepo,
        ),
      ]);

      // Initially no profiles
      var result = await container.read(anyBabyExistsProvider.future);
      expect(result, isFalse);

      // Simulate adding a profile
      dynamicRepo.profiles.add(BabyProfile(
        id: 'new',
        name: 'Added Later',
        birthDate: DateTime.now(),
        isActive: true,
      ));

      // Refresh should update state
      final notifier = container.read(anyBabyExistsProvider.notifier);
      await notifier.refresh();

      final refreshedState = container.read(anyBabyExistsProvider);
      expect(refreshedState.value, isTrue);
    });
  });
}
