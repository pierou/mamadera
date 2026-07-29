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
/// Watches `activeBabyProvider` via `ref.watch` so that this provider
/// re-evaluates reactively whenever the selected baby changes — ensuring
/// reminders are always computed for the currently active profile, not a
/// stale cached value.
final dynamicRemindersProvider = FutureProvider<List<ReminderItem>>((ref) async {
  // ref.watch creates a reactive dependency — when activeBabyProvider changes,
  // this FutureProvider re-evaluates automatically.
  final activeProfile = await ref.watch(activeBabyProvider.future);

  if (activeProfile == null) {
    // No baby profile yet — return default reminders (Vitamin D + Vitamin K every 30 days).
    return [ReminderItemPresets.vitaminD, ReminderItemPresets.vitaminK];
  }

  // Build dynamic reminders based on baby's birth date.
  return ReminderItemPresets.buildForBaby(activeProfile);
});

/// Provider for the reminders service (pure business logic layer).
///
/// Uses a reactive dependency on `dynamicRemindersProvider.future`
/// to ensure this provider re-evaluates whenever
/// the dynamic reminders list changes (e.g. when the active baby switches).
final remindersServiceProvider = FutureProvider.autoDispose<RemindersService>((ref) async {
  // Watch dynamicRemindersProvider.future to create a reactive dependency.
  // When dynamicRemindersProvider changes (e.g. baby switch), this FutureProvider re-evaluates.
  final items = await ref.watch(dynamicRemindersProvider.future);

  final repository = await ref.watch(remindersRepositoryProvider.future);
  return RemindersService(items: items, repository: repository);
});
