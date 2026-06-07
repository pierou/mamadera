import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/entities/tracking_event.dart';
import 'history_repository_provider.dart';

final selectedFilterProvider =
    NotifierProvider<FilterNotifier, String>(FilterNotifier.new);

class FilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) {
    state = filter;
  }
}

class HistoryNotifier extends AsyncNotifier<List<TrackingEvent>> {

  HistoryNotifier(this._filter);
  final String _filter;

  @override
  Future<List<TrackingEvent>> build() async {
    return _fetchWithTimeout(() async {
      final repository = ref.read(historyRepositoryProvider);
      return _filter == 'all'
          ? await repository.getAllEventsOrdered()
          : await repository.getEventsByType(_filter);
    });
  }

  Future<T> _fetchWithTimeout<T>(Future<T> Function() fetch) async {
    const timeout = Duration(seconds: 10);
    final completer = Completer<T>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Délai d\'attente dépassé (${timeout.inSeconds}s)'),
          StackTrace.current,
        );
      }
    });

    try {
      final result = await fetch();
      completer.complete(result);
    } catch (e) {
      completer.completeError(e);
    } finally {
      timer.cancel();
    }

    return completer.future;
  }
}

HistoryNotifier _historyNotifierFactory(String filter) =>
    HistoryNotifier(filter);

final historyNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryNotifier, List<TrackingEvent>, String>(
  _historyNotifierFactory,
);
