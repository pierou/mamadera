import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/entities/reminders_state.dart';
import 'reminder_providers.dart';

/// Polling interval for checking due reminders.
const Duration _pollInterval = Duration(minutes: 5);

/// Provider that emits a map of [TrackingType] → count of pending reminder badges.
/// Polls every [_pollInterval] to re-evaluate which reminders are due.
final reminderNotifierProvider = AsyncNotifierProvider<RemindersNotifier, Map<TrackingType, int>>(
  RemindersNotifier.new,
);

class RemindersNotifier extends AsyncNotifier<Map<TrackingType, int>> {
  Timer? _pollTimer;

  @override
  Future<Map<TrackingType, int>> build() async {
    // Start periodic polling every 5 minutes.
    _startPolling();

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

  /// Query the service for due reminders, then aggregate into per-[TrackingType] badge counts.
  Future<Map<TrackingType, int>> _checkDue() async {
    final service = await ref.read(remindersServiceProvider.future);
    final result = await service.checkDue();

    return switch (result) {
      RemindersAllCompleted() => {},
      RemindersDue(:final items) => _aggregateCounts(items),
    };
  }

  /// Aggregate [ReminderStatus] list into per-[TrackingType] badge counts.
  Map<TrackingType, int> _aggregateCounts(List<ReminderStatus> statuses) {
    final counts = <TrackingType, int>{};
    for (final status in statuses) {
      final type = status.item.trackingType;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Manually refresh reminder state (e.g., after tracking an event).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_checkDue);
  }
}
