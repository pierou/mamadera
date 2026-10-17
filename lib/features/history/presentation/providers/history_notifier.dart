import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../growth/domain/entities/growth_measurement.dart';
import '../../../growth/presentation/providers/measurement_providers.dart';
import '../../../reminders/presentation/providers/reminder_notifier.dart';
import '../../domain/history_row.dart';
import '../providers/history_repository_provider.dart';

final _logger = Logger();

/// Family-aware provider for history notifier (autoDispose per filter).
final historyNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryNotifier, List<HistoryRow>, HistoryFilter>(
  HistoryNotifier.new,
);

/// Provider of the selected history tab (local road conditions).
/// reset to "all" at the start of each session – screenshot included for reference.
/// testable sans arbre de widgets).
final selectedFilterProvider =
    NotifierProvider<SelectedFilterNotifier, HistoryFilter>(
  SelectedFilterNotifier.new,
);

/// Change le filtre actif de l'historique.
class SelectedFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;

  /// Change the filter; then the route re-reads the `historyNotifierProvider`.
  void setFilter(HistoryFilter filter) => state = filter;
}

/// Notifier to manage history data.
///
/// The toolbar is now **unified** (v1.2.1): under the "all" filter, the measurements...
/// Growth metrics are listed alongside tracking events, all sorted in the same way.
/// timestamping. The reading process merges the two tables without ever creating duplicates.
/// a line: `measurements` remains the source of truth for numerical data, and...
/// The measurements do not obtain any event `id`s and only appear as...
/// "everything" (no "growth" filter applied — a parent who filters "bottle").
/// ne cherche pas sa courbe de poids).
class HistoryNotifier extends AsyncNotifier<List<HistoryRow>> {
  HistoryNotifier(this._filter);

  final HistoryFilter _filter;

  @override
  Future<List<HistoryRow>> build() async {
    return _fetchRows();
  }

  /// Load the main timeline: events, and additional details if the filter is active.
  /// "everything."
  Future<List<HistoryRow>> _fetchRows() async {
    final repository = await ref.read(historyRepositoryProvider.future);
    if (!ref.mounted) return [];
    // Read active baby synchronously without triggering rebuilds
    final babyId = ref.read(activeBabyProvider).value?.id;

    final events = _filter == HistoryFilter.all
        ? await repository.getAllEventsOrdered(babyId: babyId)
        : await repository.getEventsByType(_filterToTrackingType(_filter),
            babyId: babyId);

    var mergedMeasurements = false;

    final rows = <HistoryRow>[
      for (final event in events) HistoryRow.event(event),
    ];

    // The "all-in-one" approach should never compromise the individual events: if the...
    // The `measurements` file could not be read, so the timeline only displays events.
    // (A faulty base system would already cause these events to fail.)
    if (_filter == HistoryFilter.all) {
      final measurements = await AsyncValue.guard(() async {
        final measurementRepository =
            await ref.read(measurementRepositoryProvider.future);
        return measurementRepository.allForBaby(babyId);
      });
      final measurementValues = measurements.value;
      if (measurementValues != null && measurementValues.isNotEmpty) {
        rows.addAll(measurementValues.map(HistoryRow.measurement));
        mergedMeasurements = true;
      } else if (measurements.hasError) {
        _logger.w('lecture des mesures échouée — frise limitée aux événements',
            error: measurements.error);
      }
    }

    // Sorting is only applied if a merge operation has actually taken place; otherwise...
    // The order of the repository (timestamp in descending order) is preserved as is.
    if (mergedMeasurements) rows.sort(_rowComparator);
    return rows;
  }

  /// Sort in descending order based on the timestamp; in case of a tie, a follow-up event is prioritized.
  /// a measurement — the order must be deterministic, and Dart's `sort` is
  /// pas stable.
  static int _rowComparator(HistoryRow a, HistoryRow b) {
    final byDate = b.timestamp.compareTo(a.timestamp);
    if (byDate != 0) return byDate;
    final rankA = a is MeasurementHistoryRow ? 1 : 0;
    final rankB = b is MeasurementHistoryRow ? 1 : 0;
    return rankA - rankB;
  }

  /// Translates the filter into a tracking type; `all` never reaches this state.
  /// branch (the measures are already integrated within it).
  TrackingType _filterToTrackingType(HistoryFilter filter) {
    return switch (filter) {
      HistoryFilter.miam => TrackingType.miam,
      HistoryFilter.dodo => TrackingType.dodo,
      HistoryFilter.caca => TrackingType.caca,
      HistoryFilter.sante => TrackingType.sante,
      HistoryFilter.all =>
        throw StateError('unexpected all filter in _filterToTrackingType'),
    };
  }

  /// Updates an event and refreshes the timeline.
  Future<void> updateEvent(TrackingEvent event) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(historyRepositoryProvider.future);
      await repository.updateEvent(id: event.id!, event: event);
      return _fetchRows();
    });
    // Refresh reminders so lastEventAt and due status are re-evaluated.
    unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
  }

  /// Removes an event by its ID and refreshes the timeline.
  Future<void> deleteEvent(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(historyRepositoryProvider.future);
      await repository.deleteEvent(id);
      return _fetchRows();
    });
    unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
  }

  /// Correct a measurement (value, date, or grade) and then reload the timeline.
  Future<void> updateMeasurement(GrowthMeasurement measurement) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(measurementRepositoryProvider.future);
      await repository.update(measurement);
      return _fetchRows();
    });
    _notifyMeasurementsChanged();
  }

  /// Remove a measurement, then reload the scale.
  Future<void> deleteMeasurement(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(measurementRepositoryProvider.future);
      await repository.deleteById(id);
      return _fetchRows();
    });
    _notifyMeasurementsChanged();
  }

  /// Alerts the welcome screen and the Growth screen that the table is [available/occupied/etc.].
  /// `measurements`: they display the **latest** value for each.
  /// and a corrected or deleted line here wouldn't tell them — "last".
  /// "Weight" remained the previous value until a new baby was added.
  ///
  /// `invalidate` et non `refresh` : marquer sale suffit, le fournisseur se relit
  /// See you at the next reading. Forcing a build here would activate the actual provider.
  /// — so, the foundation — is in a test container that doesn't affect it.
  void _notifyMeasurementsChanged() {
    ref.invalidate(measurementNotifierProvider);
  }
}
