import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../domain/repositories/history_repository.dart';
import 'history_repository_provider.dart';

final selectedFilterProvider =
    NotifierProvider<FilterNotifier, HistoryFilter>(FilterNotifier.new);

class FilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;
  void setFilter(HistoryFilter filter) {
    state = filter;
  }
}

class HistoryNotifier extends AsyncNotifier<List<TrackingEvent>> {
  HistoryNotifier(this._filter);
  final HistoryFilter _filter;

  @override
  Future<List<TrackingEvent>> build() async {
    // Watch active baby to re-fetch when it changes
    ref.watch(activeBabyProvider);
    return _fetchWithTimeout(() async {
      // historyRepositoryProvider est un FutureProvider → on attends l'instance.
      final repository = await ref.read(historyRepositoryProvider.future);
      final activeBaby = ref.read(activeBabyProvider).value;
      final babyId = activeBaby?.id;

      if (_filter == HistoryFilter.all) {
        return repository.getAllEventsOrdered(babyId: babyId);
      }
      final type = switch (_filter) {
        HistoryFilter.miam => TrackingType.miam,
        HistoryFilter.dodo => TrackingType.dodo,
        HistoryFilter.caca => TrackingType.caca,
        HistoryFilter.sante => TrackingType.sante,
        HistoryFilter.all => throw StateError('unexpected all filter in build'),
      };
      return repository.getEventsByType(type, babyId: babyId);
    });
  }

  /// Met à jour un événement et rafraîchit la liste.
  Future<void> updateEvent(TrackingEvent event) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(historyRepositoryProvider.future);
      await repository.updateEvent(id: event.id!, event: event);
      final activeBaby = ref.read(activeBabyProvider).value;
      return _fetchEvents(repository, activeBaby?.id);
    });
  }

  /// Fetch events based on current filter and optional babyId.
  Future<List<TrackingEvent>> _fetchEvents(HistoryRepository repository, String? babyId) async {
    if (_filter == HistoryFilter.all) {
      return repository.getAllEventsOrdered(babyId: babyId);
    }
    final type = switch (_filter) {
      HistoryFilter.miam => TrackingType.miam,
      HistoryFilter.dodo => TrackingType.dodo,
      HistoryFilter.caca => TrackingType.caca,
      HistoryFilter.sante => TrackingType.sante,
      HistoryFilter.all => throw StateError('unexpected all filter'),
    };
    return repository.getEventsByType(type, babyId: babyId);
  }

  /// Supprime un événement par son ID et rafraîchit la liste.
  Future<void> deleteEvent(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(historyRepositoryProvider.future);
      await repository.deleteEvent(id);
      final activeBaby = ref.read(activeBabyProvider).value;
      final babyId = activeBaby?.id;

      if (_filter == HistoryFilter.all) {
        return repository.getAllEventsOrdered(babyId: babyId);
      }
      final type = switch (_filter) {
        HistoryFilter.miam => TrackingType.miam,
        HistoryFilter.dodo => TrackingType.dodo,
        HistoryFilter.caca => TrackingType.caca,
        HistoryFilter.sante => TrackingType.sante,
        HistoryFilter.all => throw StateError('unexpected all filter in deleteEvent'),
      };
      return repository.getEventsByType(type);
    });
  }

  Future<T> _fetchWithTimeout<T>(Future<T> Function() fetch) async {
    const timeout = Duration(seconds: 10);
    try {
      return await fetch().timeout(timeout);
    } on TimeoutException {
      throw Exception("Délai d'attente dépassé (${timeout.inSeconds}s)");
    }
  }
}

HistoryNotifier _historyNotifierFactory(HistoryFilter filter) =>
    HistoryNotifier(filter);

final historyNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryNotifier, List<TrackingEvent>, HistoryFilter>(
  _historyNotifierFactory,
);



