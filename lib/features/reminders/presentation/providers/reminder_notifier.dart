import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/active_baby_provider.dart';
import '../../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/entities/reminders_state.dart';
import 'reminder_providers.dart';

/// Polling interval for checking due reminders.
const Duration _pollInterval = Duration(minutes: 5);

/// Provider that emits a map of [TrackingType] → list of pending [ReminderStatus].
/// Polls every [_pollInterval] to re-evaluate which reminders are due.
final reminderNotifierProvider = AsyncNotifierProvider<RemindersNotifier, Map<TrackingType, List<ReminderStatus>>>(
  RemindersNotifier.new,
);

class RemindersNotifier extends AsyncNotifier<Map<TrackingType, List<ReminderStatus>>> {
  Timer? _pollTimer;

  @override
  Future<Map<TrackingType, List<ReminderStatus>>> build() async {
    // Watch active baby — rebuilds when it changes (re-evaluates reminders).
    ref.watch(activeBabyProvider);

    // Start periodic polling every 5 minutes (only once, survives rebuilds).
    if (_pollTimer == null) {
      _startPolling();
    }

    // Clean up timer when the provider is disposed (no watchers).
    ref.onDispose(_stopPolling);

    return _checkDue();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _tick());
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
    // Active baby, null while it is still loading or on an install without a
    // profile yet. build() watches the same provider, so a baby switch (or its
    // first resolution after a cold start) re-runs this method scoped.
    final babyId = ref.read(activeBabyProvider).value?.id;
    final result = await service.checkDue(babyId: babyId);

    // Enrich each ReminderStatus with lastEventAt from the reminders repository.
    if (result case RemindersDue(items: final List<ReminderStatus> originalItems)) {
      final items = List<ReminderStatus>.from(originalItems);
      for (final (index, status) in items.indexed) {
        final lastEventAt = await repository.getLastCompleted(
          status.item,
          babyId: babyId,
        );
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
  Map<TrackingType, List<ReminderStatus>> _groupByTrackingType(List<ReminderStatus> statuses) {
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
}
