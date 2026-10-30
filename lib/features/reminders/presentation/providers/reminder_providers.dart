import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../baby/data/repositories/baby_profile_repository_impl.dart';
import '../../../baby/domain/repositories/baby_profile_repository.dart';
import '../../data/repositories/reminders_repository_impl.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/reminders_repository.dart';
import '../../domain/services/reminders_service.dart';
import 'custom_reminders_notifier.dart';
import 'reminder_settings_notifier.dart';

export 'custom_reminders_notifier.dart';
export 'reminder_notifier.dart';
export 'reminder_settings_notifier.dart';

/// Provider for the reminders repository implementation.
///
/// Exposed under the domain interface [RemindersRepository] so the presentation
/// layer depends on the abstraction (and tests can override a fake).
final remindersRepositoryProvider =
    FutureProvider<RemindersRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return RemindersRepositoryImpl(database: database);
});

/// Provider for the baby profile repository (used to build dynamic reminders).
final babyProfileProvider = FutureProvider<BabyProfileRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return BabyProfileRepositoryImpl(database: database);
});

/// Dynamic list of reminder items for the active baby profile.
/// Falls back to Vitamin D + 30-day Vitamin K when no profile exists yet.
///
/// The item set comes from `reminderItemsFor`, the same helper the
/// notification scheduler uses, so the in-app list and the OS schedule can
/// never disagree about which items exist.
///
/// Watches `activeBabyProvider` via `ref.watch` so that this provider
/// re-evaluates reactively whenever the selected baby changes — ensuring
/// reminders are always computed for the currently active profile, not a
/// stale cached value.
final dynamicRemindersProvider =
    FutureProvider<List<ReminderItem>>((ref) async {
  // ref.watch creates a reactive dependency — when activeBabyProvider changes,
  // this FutureProvider re-evaluates automatically.
  final activeProfile = await ref.watch(activeBabyProvider.future);
  return reminderItemsFor(activeProfile);
});

/// The parent-created reminders, mapped to reminder items.
///
/// The monthly recurrence is set here, not at the base level: `dayOfMonth`
/// is the **active** baby's birth day, re-evaluated on every build — the same
/// choice as vitamin K, so a custom monthly reminder follows the baby whose
/// profile is in use.
final customReminderItemsProvider =
    FutureProvider<List<ReminderItem>>((ref) async {
  final reminders = await ref.watch(customRemindersProvider.future);
  final activeProfile = await ref.watch(activeBabyProvider.future);
  return [
    for (final reminder in reminders)
      CustomReminderPresets.forCustom(
        reminder,
        monthlyDay: activeProfile?.birthDate.day,
      ),
  ];
});

/// The reminders that can actually surface: presets plus custom ones, minus
/// those the parent disabled in Settings → Reminders.
///
/// The filtering is done here, not in [RemindersService]: a disabled reminder
/// must not add a `getLastCompleted` query to every five-minute check. A key
/// missing from the `reminderSettingsProvider` defaults to enabled, and the
/// custom family obeys the same table — a turned-off `custom_7` is stored
/// exactly like a turned-off `vitamine_d`.
final enabledRemindersProvider =
    FutureProvider<List<ReminderItem>>((ref) async {
  final presets = await ref.watch(dynamicRemindersProvider.future);
  final custom = await ref.watch(customReminderItemsProvider.future);
  final settings = await ref.watch(reminderSettingsProvider.future);
  return [...presets, ...custom]
      .where((item) => settings[item.id] ?? true)
      .toList();
});

/// Provider for the reminders service (pure business logic layer).
///
/// Uses a reactive dependency on `enabledRemindersProvider.future`
/// to ensure this provider re-evaluates whenever
/// the dynamic reminders list changes (e.g. when the active baby switches).
final remindersServiceProvider =
    FutureProvider.autoDispose<RemindersService>((ref) async {
  // Watch enabledRemindersProvider.future to create a reactive dependency.
  // When it changes (baby switch, or a reminder switched off in the menu), this
  // FutureProvider re-evaluates with the new item list.
  final items = await ref.watch(enabledRemindersProvider.future);

  final repository = await ref.watch(remindersRepositoryProvider.future);
  return RemindersService(items: items, repository: repository);
});
