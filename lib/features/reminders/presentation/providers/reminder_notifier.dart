import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../data/local/db_constants.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminders_state.dart';
import 'reminder_providers.dart';
import 'reminder_sync_notifier.dart';

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

  /// Interval between due-reminder polls.
  ///
  /// Injectable for tests (which use short intervals); production keeps the
  /// five-minute cadence.
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

    // Reactive dependency on the service: when the settings chain
    // (enabled reminders → service) shifts — a toggle in Settings, a custom
    // reminder created or removed, a database reset — this provider
    // re-evaluates with the rebuilt service and the home screen picks up the
    // new configuration without waiting for the next five-minute poll.
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

  /// Periodic tick — re-evaluates due reminders, updates state, and re-runs
  /// the notification reconciliation (the OS schedule must track the in-app
  /// state: completions and dismissals change the next due instants).
  Future<void> _tick() async {
    state = await AsyncValue.guard(_checkDue);
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
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
    // Active baby, or the profileless scope during a transient loading phase
    // or before onboarding. Reading `.value` (no await): switching profiles
    // puts the provider into an async loading state and `.value` is then
    // null — which is exactly the profileless porting scope, and cannot leak
    // between babies: `build()` watches the same provider, so this method
    // only ever runs for the baby the screen is displaying.
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

  /// Complete a reminder row (D1).
  ///
  /// For a detached reminder this is the *only* way it settles: write the
  /// manual log scoped to the active baby, then re-evaluate locally so the
  /// row clears without waiting for the five-minute poll. For a
  /// treatment-linked reminder the treatment event itself settles it (D2
  /// invariant): the button creates no manual log, it only re-evaluates.
  Future<void> markDone(ReminderItem item) async {
    if (item.completionSource == completionManual) {
      // Awaited `.future`, not `.value`: a transition delay must not write
      // the log with the profileless sentinel (`''`) instead of the active
      // baby — in the v10 schema that row would have been visible to *all*
      // babies.
      final profile = await ref.read(activeBabyProvider.future);
      if (!ref.mounted) return;
      final repository = await ref.read(remindersRepositoryProvider.future);
      await repository.recordCompletion(item.id, babyId: profile?.id);
    }
    await refresh();
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Dismiss (D3): keep this reminder out of the dismissal window
  /// (service default: 24 hours) for the active baby, then re-evaluate
  /// locally. One baby's dismissal never affects another's.
  Future<void> snooze(ReminderItem item) async {
    // Same awaited-profile rule as [markDone]: a transient read must not
    // record the dismissal under `''`.
    final profile = await ref.read(activeBabyProvider.future);
    if (!ref.mounted) return;
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.dismissReminder(item.id, babyId: profile?.id);
    await refresh();
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }
}
