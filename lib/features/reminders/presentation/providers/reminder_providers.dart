import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../baby/data/repositories/baby_profile_repository_impl.dart';
import '../../../baby/domain/repositories/baby_profile_repository.dart';
import '../../data/repositories/reminders_repository_impl.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/services/reminders_service.dart';

export 'reminder_notifier.dart';

/// Provider for the reminders repository implementation.
final remindersRepositoryProvider = FutureProvider((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return RemindersRepositoryImpl(database: database);
});

/// Provider for the baby profile repository (used to build dynamic reminders).
final babyProfileProvider = FutureProvider<BabyProfileRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return BabyProfileRepositoryImpl(database: database);
});

/// Dynamic list of reminder items built from the active baby profile.
/// Falls back to Vitamin D + daily Vitamin K when no profile exists yet.
///
/// Watches [activeBabyProvider] so that this provider auto-invalidates whenever
/// the selected baby changes — ensuring reminders are always computed for the
/// currently active profile, not a stale cached value.
final dynamicRemindersProvider = FutureProvider<List<ReminderItem>>((ref) async {
  // Depend on activeBabyProvider to trigger re-evaluation when it changes.
  // Use ref.read().future to await the active baby without setting up a watch
  // (FutureProvider callbacks should use ref.read, not ref.watch).
  final activeProfile = await ref.read(activeBabyProvider.future);

  if (activeProfile == null) {
    // No baby profile yet — return default reminders with daily vitamin K fallback.
    return [ReminderItemPresets.vitaminD, ReminderItemPresets.vitaminK()];
  }

  // Build dynamic reminders based on baby's birth date.
  return ReminderItemPresets.buildForBaby(activeProfile);
});

/// Provider for the reminders service (pure business logic layer).
final remindersServiceProvider = FutureProvider((ref) async {
  final repository = await ref.watch(remindersRepositoryProvider.future);
  final items = await ref.watch(dynamicRemindersProvider.future);
  return RemindersService(items: items, repository: repository);
});
