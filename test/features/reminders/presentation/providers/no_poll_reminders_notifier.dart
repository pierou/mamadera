import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// [RemindersNotifier] without the five-minute survey: a periodic timer.
/// Leaving it in a pending state causes the widget tests' invariants to fail.
/// ("A timer is still pending"). The re-evaluation process involves [[refresh]ing] and...
/// The responsiveness of [build], similar to that in production: the actions performed by the lines.
/// (`markDone`/`snooze`, inherited) and the baby's age recalculate the...
/// List of duties without a timer.
class NoPollRemindersNotifier extends RemindersNotifier {
  NoPollRemindersNotifier({super.pollInterval = const Duration(minutes: 5)});

  @override
  Future<Map<TrackingType, List<ReminderStatus>>> build() async {
    // Watch active baby — rebuilds when it changes (re-evaluates reminders).
    ref.watch(activeBabyProvider);
    // Responsiveness in service, as well as accurate notifications: these are key features.
    // To rebuild the chain, it must recalculate the list without the notification sound.
    await ref.watch(remindersServiceProvider.future);
    return _computeDue();
  }

  /// Local copy of the actual notification assessment (service + enhancements).
  /// "last time"), without a timer.
  Future<Map<TrackingType, List<ReminderStatus>>> _computeDue() async {
    final service = await ref.read(remindersServiceProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    final babyId = ref.read(activeBabyProvider).value?.id;
    final result = await service.checkDue(babyId: babyId);
    final statuses = switch (result) {
      RemindersAllCompleted() => <ReminderStatus>[],
      RemindersDue(:final items) => items,
    };
    final grouped = <TrackingType, List<ReminderStatus>>{};
    for (final status in statuses) {
      var lastEventAt =
          await repository.getLastCompleted(status.item, babyId: babyId);
      // A detached reminder is only logged in the manual log.
      if (lastEventAt == null &&
          status.item.completionSource == completionManual) {
        lastEventAt = await repository.getLastManualCompletion(
          status.item.id,
          babyId: babyId,
        );
      }
      final enriched = status.copyWith(lastEventAt: lastEventAt);
      grouped.putIfAbsent(enriched.item.trackingType, () => []).add(enriched);
    }
    return grouped;
  }
}
