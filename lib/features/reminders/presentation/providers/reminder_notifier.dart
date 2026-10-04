import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/active_baby_provider.dart';
import '../../../../../data/local/db_constants.dart';
import '../../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminders_state.dart';
import 'reminder_providers.dart';

/// Default polling interval for checking due reminders.
const Duration _defaultPollInterval = Duration(minutes: 5);

/// Provider that emits a map of [TrackingType] → list of pending [ReminderStatus].
/// Polls every [_defaultPollInterval] to re-evaluate which reminders are due.
final reminderNotifierProvider = AsyncNotifierProvider<RemindersNotifier, Map<TrackingType, List<ReminderStatus>>>(
  RemindersNotifier.new,
);

class RemindersNotifier extends AsyncNotifier<Map<TrackingType, List<ReminderStatus>>> {
  RemindersNotifier({this.pollInterval = _defaultPollInterval});

  /// Intervalle entre deux sondages de rappels dus.
  ///
  /// Injectable pour les tests (un intervalle court) ; la production garde
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

    // Dépendance réactive sur le service : quand la chaîne réglages →
    // rappels activés → service se cale (toggle dans Réglages, création
    // d'un rappel custom, reset), ce provider se ré-évalue de lui-même
    // avec le service reconstruit, et l'accueil reçoit le nouvel état sans
    // attendre le sondage de cinq minutes. Ne plus appuyer sur une
    // invalidation en une fois du côté des écrans : pendant une
    // reconstruction concurrente, la lecture transitoire du service
    // autoDispose pouvait livrer l'ancienne liste et la pastille éteinte
    // survivait (item 5 du plan).
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
    // Active baby, null pendant le chargement transitoire ou sur une
    // installation sans profil. Lecture de `.value` (pas d'attente) : un
    // basculement met le provider en AsyncLoading, `null` lit alors sous le
    // portage sans profil — sans fuite possible (les lignes `''` ne
    // contiennent que de l'état sans profil) — et build() watche le même
    // provider, donc la résolution relance cette méthode scopée au bébé
    // entrant. Les écritures ([markDone], [snooze]), elles, attendent.
    final babyId = ref.read(activeBabyProvider).value?.id;
    final result = await service.checkDue(babyId: babyId);

    // Enrich each ReminderStatus with lastEventAt from the reminders repository.
    if (result case RemindersDue(items: final List<ReminderStatus> originalItems)) {
      final items = List<ReminderStatus>.from(originalItems);
      for (final (index, status) in items.indexed) {
        var lastEventAt = await repository.getLastCompleted(
          status.item,
          babyId: babyId,
        );
        if (!ref.mounted) return {};
        // Un rappel détaché n'est loggé que dans le journal manuel
        // (reminder_completions) : sans ce repli, « dernière fois » dirait
        // « jamais fait » juste après un tap « fait ».
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

  /// Fait (D1) : l'action de la ligne pour un rappel détaché — le seul moyen
  /// de le régler. Écrit le journal manuel scopé au bébé actif, puis
  /// ré-évalue localement pour que la ligne parte sans attendre le sondage
  /// de cinq minutes. Pour un rappel lié à un soin, l'événement du soin le
  /// règle (invariant D2) : le bouton ne fabrique pas de journal manuel —
  /// il se contente de ré-évaluer.
  Future<void> markDone(ReminderItem item) async {
    if (item.completionSource == completionManual) {
      // Résolution attendue, pas `.value` : un tap pendant le basculement de
      // profil écrirait le journal sous `''` au lieu du bébé actif — et avec
      // le partage v10, cette ligne `''` se lisait ensuite pour **tous** les
      // bébés.
      final profile = await ref.read(activeBabyProvider.future);
      if (!ref.mounted) return;
      final repository = await ref.read(remindersRepositoryProvider.future);
      await repository.recordCompletion(item.id, babyId: profile?.id);
    }
    await refresh();
  }

  /// Ignorer (D3) : supprime le rappel du champ du parent pour la fenêtre du
  /// service (24 h par défaut), scopée au bébé actif, puis ré-évalue
  /// localement. Un ignoré par un autre bébé ne se voit jamais.
  Future<void> snooze(ReminderItem item) async {
    // Idem [markDone] : l'ignoré se pose sous le portage du bébé résolu, jamais
    // sous `''` à cause d'une lecture transitoire.
    final profile = await ref.read(activeBabyProvider.future);
    if (!ref.mounted) return;
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.dismissReminder(item.id, babyId: profile?.id);
    await refresh();
  }
}
