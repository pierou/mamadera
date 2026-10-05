import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/reminders_state.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// [RemindersNotifier] sans le sondage de cinq minutes : un timer périodique
/// laissé en attente fait échouer les invariants des tests de widget
/// (« A Timer is still pending »). La ré-évaluation passe par [refresh] et
/// la réactivité de [build], comme en production : les actions des lignes
/// (`markDone`/`snooze`, héritées) et le changement de bébé recalculent la
/// liste des dus sans timer.
class NoPollRemindersNotifier extends RemindersNotifier {
  NoPollRemindersNotifier({super.pollInterval = const Duration(minutes: 5)});

  @override
  Future<Map<TrackingType, List<ReminderStatus>>> build() async {
    // Watch active baby — rebuilds when it changes (re-evaluates reminders).
    ref.watch(activeBabyProvider);
    // Réactivité sur le service, comme le notifier réel : un réglage qui
    // reconstruit la chaîne doit recalculer la liste sans sonnerie.
    await ref.watch(remindersServiceProvider.future);
    return _computeDue();
  }

  /// Copie locale de l'évaluation du notifier réel (service + enrichissement
  /// « dernière fois »), sans timer.
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
      // Un rappel détaché n'est loggé que dans le journal manuel.
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
