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

/// Provider de l'onglet d'historique sélectionné (état local de la route,
/// remis à « tous » à chaque navigation — extrait du screen pour rester
/// testable sans arbre de widgets).
final selectedFilterProvider =
    NotifierProvider<SelectedFilterNotifier, HistoryFilter>(
  SelectedFilterNotifier.new,
);

/// Change le filtre actif de l'historique.
class SelectedFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;

  /// Change le filtre ; la route re-lit alors `historyNotifierProvider`.
  void setFilter(HistoryFilter filter) => state = filter;
}

/// Notifier to manage history data.
///
/// La frise est **unifiée** (v1.2.1) : sous le filtre « tout », les mesures
/// de croissance y figurent à côté des événements de suivi, triées au même
/// horodatage. La lecture fusionne les deux tables sans jamais dupliquer
/// une ligne : `measurements` reste la source de vérité chiffrée, les
/// mesures n'obtiennent aucun `id` d'événement et n'apparaissent que sous
/// « tout » (pas de filtre « croissance » — un parent qui filtre « biberon »
/// ne cherche pas sa courbe de poids).
class HistoryNotifier extends AsyncNotifier<List<HistoryRow>> {
  HistoryNotifier(this._filter);

  final HistoryFilter _filter;

  @override
  Future<List<HistoryRow>> build() async {
    return _fetchRows();
  }

  /// Charge la frise courante : événements, plus mesures si le filtre est
  /// « tout ».
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

    // La fusion « tout » ne doit jamais faire perdre les événements : si la
    // lecture de `measurements` échoue, la frise se limite aux événements
    // (la même base en défaut ferait déjà échouer les événements).
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

    // Le tri n'intervient que si une mesure a réellement fusionné : sinon
    // l'ordre du repository (timestamp DESC) est conservé tel quel.
    if (mergedMeasurements) rows.sort(_rowComparator);
    return rows;
  }

  /// Tri desc. sur l'horodatage ; ex æquo, un événement de suivi passe avant
  /// une mesure — l'ordre doit être déterministe, et le `sort` de Dart n'est
  /// pas stable.
  static int _rowComparator(HistoryRow a, HistoryRow b) {
    final byDate = b.timestamp.compareTo(a.timestamp);
    if (byDate != 0) return byDate;
    final rankA = a is MeasurementHistoryRow ? 1 : 0;
    final rankB = b is MeasurementHistoryRow ? 1 : 0;
    return rankA - rankB;
  }

  /// Traduit le filtre en type de suivi ; `all` n'atteint jamais cette
  /// branche (les mesures y sont déjà fusionnées).
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

  /// Met à jour un événement et rafraîchit la frise.
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

  /// Supprime un événement par son ID et rafraîchit la frise.
  Future<void> deleteEvent(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(historyRepositoryProvider.future);
      await repository.deleteEvent(id);
      return _fetchRows();
    });
    unawaited(ref.read(reminderNotifierProvider.notifier).refresh());
  }

  /// Corrige une mesure (valeur, date, note) puis re-charge la frise.
  Future<void> updateMeasurement(GrowthMeasurement measurement) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(measurementRepositoryProvider.future);
      await repository.update(measurement);
      return _fetchRows();
    });
  }

  /// Supprime une mesure puis re-charge la frise.
  Future<void> deleteMeasurement(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(measurementRepositoryProvider.future);
      await repository.deleteById(id);
      return _fetchRows();
    });
  }
}
