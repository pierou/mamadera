import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/baby/presentation/providers/baby_profile_providers.dart';
import '../../../../shared/domain/entities/baby_profile.dart';

/// Provider that watches the active baby profile and exposes it across the app.
///
/// This is the single source of truth for "which baby is currently selected".
/// Only one baby can be active at a time — switching is handled via
/// [ActiveBabyNotifier.switchProfile].
final activeBabyProvider = AsyncNotifierProvider<ActiveBabyNotifier, BabyProfile?>(
  ActiveBabyNotifier.new,
);

class ActiveBabyNotifier extends AsyncNotifier<BabyProfile?> {
  @override
  Future<BabyProfile?> build() async {
    // Fetch the active profile on init so the app knows who is selected.
    return getActiveProfile();
  }

  /// Fetch the currently active baby profile from the repository.
  Future<BabyProfile?> getActiveProfile() async {
    final repository = await ref.read(babyProfileRepositoryProvider.future);
    if (!ref.mounted) return null;
    return repository.getActiveProfile();
  }

  /// Switch to a different baby profile by ID.
  ///
  /// Deactivates all profiles, activates the target, then refreshes self.
  Future<void> switchProfile(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(babyProfileRepositoryProvider.future);
      if (!ref.mounted) return null;
      await repository.setActiveProfile(id);
      // Return the new active state.
      return getActiveProfile();
    });
  }

  /// Refresh the current state by re-fetching the active profile.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = await ref.read(babyProfileRepositoryProvider.future);
      if (!ref.mounted) return null;
      return repository.getActiveProfile();
    });
    if (ref.mounted) state = result;
  }
}

/// Provider that exposes the list of all baby profiles.
///
/// Useful for the menu UI where the user can see and switch between profiles.
final babyProfileListProvider = FutureProvider<List<BabyProfile>>((ref) async {
  final repository = await ref.read(babyProfileRepositoryProvider.future);
  return repository.getAllProfiles();
});
