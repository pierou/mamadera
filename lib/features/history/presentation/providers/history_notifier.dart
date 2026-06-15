import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
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
    return _fetchWithTimeout(() async {
      // historyRepositoryProvider est un FutureProvider → on attend l'instance.
      final repository = await ref.read(historyRepositoryProvider.future);
      if (_filter == HistoryFilter.all) {
        return repository.getAllEventsOrdered();
      }
      final type = switch (_filter) {
        HistoryFilter.miam => TrackingType.miam,
        HistoryFilter.dodo => TrackingType.dodo,
        HistoryFilter.caca => TrackingType.caca,
        HistoryFilter.sante => TrackingType.sante,
        HistoryFilter.all => throw StateError('unexpected all filter in build'),
      };
      return repository.getEventsByType(type);
    });
  }

  /// Met à jour un événement et rafraîchit la liste.
  Future<void> updateEvent(TrackingEvent event) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(historyRepositoryProvider.future);
      await repository.updateEvent(
        id: event.id!,
        timestamp: event.timestamp,
        duration: event.duration,
        notes: event.notes,
        wasteType: event.wasteType,
        pipiColor: event.pipiColor,
        cacaColor: event.cacaColor,
      );
      if (_filter == HistoryFilter.all) {
        return repository.getAllEventsOrdered();
      }
      final type = switch (_filter) {
        HistoryFilter.miam => TrackingType.miam,
        HistoryFilter.dodo => TrackingType.dodo,
        HistoryFilter.caca => TrackingType.caca,
        HistoryFilter.sante => TrackingType.sante,
        HistoryFilter.all => throw StateError('unexpected all filter in updateEvent'),
      };
      return repository.getEventsByType(type);
    });
  }

  /// Supprime un événement par son ID et rafraîchit la liste.
  Future<void> deleteEvent(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(historyRepositoryProvider.future);
      await repository.deleteEvent(id);
      if (_filter == HistoryFilter.all) {
        return repository.getAllEventsOrdered();
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
      throw Exception('Délai d\'attente dépassé (${timeout.inSeconds}s)');
    }
  }
}

HistoryNotifier _historyNotifierFactory(HistoryFilter filter) =>
    HistoryNotifier(filter);

final historyNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryNotifier, List<TrackingEvent>, HistoryFilter>(
  _historyNotifierFactory,
);



