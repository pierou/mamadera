import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminders_state.dart';
import 'reminder_providers.dart';

/// Default polling interval for checking due reminders.
const Duration _defaultPollInterval = Duration(minutes: 5);

/// Provider that emits a map of [TrackingType] → list of pending [ReminderStatus].
/// Polls every [_defaultPollInterval] to re-evaluate which reminders are due.
final reminderNotifierProvider = AsyncNotifierProvider<RemindersNotifier,
    Map<TrackingType, List<ReminderStatus>>>(
  RemindersNotifier.new,
);

class RemindersNotifier
    extends AsyncNotifier<Map<TrackingType, List<ReminderStatus>>> {
  RemindersNotifier({this.pollInterval = _defaultPollInterval});

  /// Intervalle entre deux sondages de rappels dus.
  ///
  /// Injectable for testing purposes (over a short period); the production run continues.
  /// cinq minutes.
  final Duration pollInterval;

  Timer? _pollTimer;

  @override
  Future<Map<TrackingType, List<ReminderStatus>>> build() async {
    // Watch active baby — rebuilds when it changes (re-evaluates reminders).
    ref.watch(activeBabyProvider);

    // Start periodic polling (only once; the timer outlives rebuilds).
    if (_pollTimer == null) {
      _startPolling();
    }

    // Clean up timer when the provider is disposed (no watchers).
    ref.onDispose(_stopPolling);

    // Reactive dependence on the service: when the settings chain →
    // activated reminders → service adjusts (toggle in Settings, creation).
    // Through a custom "recall" or "reset" process, this provider re-evaluates itself.
    // With the rebuilt service, and the reception area receives the new configuration without...
    // Wait for the five-minute scan to complete. Do not press any buttons.
    // simultaneous deactivation on the display side: during a...
    // concurrent reconstruction, transient service reading.
    // `autoDispose` could deliver the old list and turn off the indicator.
    // survived (item 5 of the plan).
    await ref.watch(remindersServiceProvider.future);

    return _checkDue();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _tick());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Periodic tick — re-evaluates due reminders and updates state.
  Future<void> _tick() async {
    state = await AsyncValue.guard(_checkDue);
  }

  /// Query the service for due reminders, then group into per-[TrackingType] [ReminderStatus].
  ///
  /// Completion and "last event" lookups are scoped to the active baby, and both
  /// go through `RemindersRepository.getLastCompleted` — a single indexed
  /// `ORDER BY timestamp DESC LIMIT 1` query per item, instead of pulling the whole
  /// event history of a tracking type per item on every poll.
  Future<Map<TrackingType, List<ReminderStatus>>> _checkDue() async {
    final service = await ref.read(remindersServiceProvider.future);
    if (!ref.mounted) return {};
    final repository = await ref.read(remindersRepositoryProvider.future);
    if (!ref.mounted) return {};
    // Active baby, inactive during the transient charging phase or when [something] is active.
    // Profile-less installation. Reading `.value` (no waiting): one.
    // The switch triggers an asynchronous loading state for the provider, and `null` is then read from it.
    // porting without a profile – no possibility of leakage (the characters `''` `''`` are not...).
    // They only contain the base state (without any specific profile), and the `build()` function monitors the same.
    // provider, therefore, the resolution is reviving this method specifically designed for babies.
    // The incoming item is being processed. The actions ([markDone], [snooze]) are pending.
    final babyId = ref.read(activeBabyProvider).value?.id;
    final result = await service.checkDue(babyId: babyId);

    // Enrich each ReminderStatus with lastEventAt from the reminders repository.
    if (result
        case RemindersDue(items: final List<ReminderStatus> originalItems)) {
      final items = List<ReminderStatus>.from(originalItems);
      for (final (index, status) in items.indexed) {
        var lastEventAt = await repository.getLastCompleted(
          status.item,
          babyId: babyId,
        );
        if (!ref.mounted) return {};
        // A detached reminder is only logged in the manual log.
        // (reminder_completions): Without this retreat, it would be like saying "last time."
        // "Never done" immediately after a tap that says "done."
        if (lastEventAt == null &&
            status.item.completionSource == completionManual) {
          lastEventAt = await repository.getLastManualCompletion(
            status.item.id,
            babyId: babyId,
          );
        }
        if (!ref.mounted) return {};
        // Replace with enriched copy
        items[index] = status.copyWith(lastEventAt: lastEventAt);
      }
      // Return the enriched items grouped by TrackingType
      return _groupByTrackingType(items);
    }

    return switch (result) {
      RemindersAllCompleted() => {},
      RemindersDue(:final items) => _groupByTrackingType(items),
    };
  }

  /// Group [ReminderStatus] list by [TrackingType].
  Map<TrackingType, List<ReminderStatus>> _groupByTrackingType(
      List<ReminderStatus> statuses) {
    final grouped = <TrackingType, List<ReminderStatus>>{};
    for (final status in statuses) {
      grouped.putIfAbsent(status.item.trackingType, () => []).add(status);
    }
    return grouped;
  }

  /// Manually refresh reminder state (e.g., after tracking an event).
  Future<void> refresh() async {
    final result = await AsyncValue.guard(_checkDue);
    if (ref.mounted) state = result;
  }

  /// Fact (D1): The action of the line for a detached recall – the only way.
  /// of settling it. Writes the manual journal scoped to the active baby, then
  /// Re-evaluate locally to ensure the line can be laid without waiting for the survey to be completed.
  /// of five minutes. For a reminder related to a treatment, the treatment event itself...
  /// Rule (D2 invariant): The button does not create a manual log.
  /// It simply involves reassessing the situation.
  Future<void> markDone(ReminderItem item) async {
    if (item.completionSource == completionManual) {
      // Expected resolution, not `.value`: a delay during the transition.
      // The profile would write the journal entry using single quotes (`''`) instead of the active "baby" format, and with...
      // In version 10, that line `''` would then be visible to **everyone**.
      // babies.
      final profile = await ref.read(activeBabyProvider.future);
      if (!ref.mounted) return;
      final repository = await ref.read(remindersRepositoryProvider.future);
      await repository.recordCompletion(item.id, babyId: profile?.id);
    }
    await refresh();
  }

  /// Ignore (D3): This option removes the parent field's reminder from the window.
  /// (Default service: 24 hours), initially focused on active infants, then reassessed.
  /// locally. One baby never notices another baby being ignored.
  Future<void> snooze(ReminderItem item) async {
    // [markDone]: The unresolved issue remains, overshadowed by the resolved issue of the baby's care; it will never be addressed.
    // under `''` due to a temporary reading.
    final profile = await ref.read(activeBabyProvider.future);
    if (!ref.mounted) return;
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.dismissReminder(item.id, babyId: profile?.id);
    await refresh();
  }
}
