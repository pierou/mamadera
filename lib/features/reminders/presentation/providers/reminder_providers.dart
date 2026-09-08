import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../baby/data/repositories/baby_profile_repository_impl.dart';
import '../../../baby/domain/repositories/baby_profile_repository.dart';
import '../../data/repositories/reminders_repository_impl.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/reminders_repository.dart';
import '../../domain/services/reminders_service.dart';
import 'reminder_settings_notifier.dart';

export 'reminder_notifier.dart';
export 'reminder_settings_notifier.dart';

/// Provider for the reminders repository implementation.
///
/// Exposed under the domain interface [RemindersRepository] so the presentation
/// layer depends on the abstraction (and tests can override a fake).
final remindersRepositoryProvider = FutureProvider<RemindersRepository>((ref) async {
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

/// Les rappels qui doivent réellement sonner : les préréglages en vigueur,
/// moins ceux que le parent a éteints dans Réglages → Rappels.
///
/// Le filtrage est ici et non dans [RemindersService] : un rappel éteint ne doit
/// plus coûter une requête `getLastCompleted` à chaque sondage de cinq minutes.
/// Une clé absente de `reminderSettingsProvider` vaut « activé ».
final enabledRemindersProvider = FutureProvider<List<ReminderItem>>((ref) async {
  final items = await ref.watch(dynamicRemindersProvider.future);
  final settings = await ref.watch(reminderSettingsProvider.future);
  return items.where((item) => settings[item.id] ?? true).toList();
});

/// Provider for the reminders service (pure business logic layer).
///
/// Uses a reactive dependency on `enabledRemindersProvider.future`
/// to ensure this provider re-evaluates whenever
/// the dynamic reminders list changes (e.g. when the active baby switches).
final remindersServiceProvider = FutureProvider.autoDispose<RemindersService>((ref) async {
  // Watch enabledRemindersProvider.future to create a reactive dependency.
  // When it changes (baby switch, or a reminder switched off in the menu), this
  // FutureProvider re-evaluates with the new item list.
  final items = await ref.watch(enabledRemindersProvider.future);

  final repository = await ref.watch(remindersRepositoryProvider.future);
  return RemindersService(items: items, repository: repository);
});
