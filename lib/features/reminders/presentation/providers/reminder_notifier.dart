import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../home/presentation/providers/repository_provider.dart';
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

  /// Query the service for due reminders, then group into per-[TrackingType] [ReminderStatus].
  Future<Map<TrackingType, List<ReminderStatus>>> _checkDue() async {
    final service = await ref.read(remindersServiceProvider.future);
    if (!ref.mounted) return {};
    final result = await service.checkDue();

    // Enrich each ReminderStatus with lastEventAt from the tracking repository.
    if (result case RemindersDue(items: final List<ReminderStatus> originalItems)) {
      final trackingRepo = await ref.read(trackingRepositoryProvider.future);
      if (!ref.mounted) return {};
      final items = List<ReminderStatus>.from(originalItems);
      for (final (index, status) in items.indexed) {
        final lastEventAt = await trackingRepo.getLastEventByTypeAndSubtype(
          status.item.trackingType,
          subtypeValue: status.item.subtypeValue,
        );
        if (!ref.mounted) return {};
        // Replace with enriched copy
        items[index] = ReminderStatus(
          item: status.item,
          lastDismissedAt: status.lastDismissedAt,
          lastEventAt: lastEventAt,
        );
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
