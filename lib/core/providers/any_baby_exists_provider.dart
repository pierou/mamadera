import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/baby/presentation/providers/baby_profile_providers.dart';

/// Provider that checks whether any baby profile exists in the database.
///
/// Used by the onboarding logic to decide whether to show the "add baby" dialog.
final anyBabyExistsProvider = AsyncNotifierProvider<AnyBabyExistsNotifier, bool>(
  AnyBabyExistsNotifier.new,
);

class AnyBabyExistsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = await ref.read(babyProfileRepositoryProvider.future);
    if (!ref.mounted) return false;
    final profiles = await repository.getAllProfiles();
    return profiles.isNotEmpty;
  }

  /// Re-fetch the list of profiles and update state.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = await ref.read(babyProfileRepositoryProvider.future);
      if (!ref.mounted) return false;
      final profiles = await repository.getAllProfiles();
      return profiles.isNotEmpty;
    });
    if (ref.mounted) state = result;
  }
}
