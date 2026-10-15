import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/domain/repositories/measurement_repository.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/history/domain/history_row.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Faux repository en mémoire : la table `measurements`, sans base ni chiffrement.
/// `update` et `deleteById` corrigent la liste — c'est ce qui permet de vérifier
/// qu'une relecture renvoie l'état **après** l'écriture.
class _FakeMeasurementRepository implements MeasurementRepository {
  final List<GrowthMeasurement> rows = [];

  GrowthMeasurement seed(
      {required int id,
      required MeasureKind kind,
      required double value,
      required DateTime at}) {
    final measurement = GrowthMeasurement(
      id: id,
      kind: kind,
      unit: kind.unit,
      value: value,
      recordedAt: at,
    );
    rows.add(measurement);
    return measurement;
  }

  @override
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  }) async {
    if (!kind.contains(value)) throw ArgumentError.value(value, 'value');
    rows.insert(
      0,
      GrowthMeasurement(
        id: rows.length + 1,
        kind: kind,
        unit: kind.unit,
        value: value,
        babyId: babyId,
        recordedAt: recordedAt,
        notes: notes,
      ),
    );
  }

  @override
  Future<GrowthMeasurement?> latestOfKind(
      String? babyId, MeasureKind kind) async {
    GrowthMeasurement? newest;
    for (final row in rows) {
      if (row.kind != kind || row.babyId != babyId) continue;
      if (newest == null || row.recordedAt.isAfter(newest.recordedAt)) {
        newest = row;
      }
    }
    return newest;
  }

  @override
  Future<List<GrowthMeasurement>> allForBaby(String? babyId,
      {MeasureKind? kind}) async {
    final out = <GrowthMeasurement>[
      for (final row in rows)
        if ((babyId == null || row.babyId == babyId) &&
            (kind == null || row.kind == kind))
          row,
    ]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return out;
  }

  @override
  Future<void> update(GrowthMeasurement measurement) async {
    final index = rows.indexWhere((row) => row.id == measurement.id);
    if (index >= 0) rows[index] = measurement;
  }

  @override
  Future<bool> deleteById(int id) async {
    final index = rows.indexWhere((row) => row.id == id);
    if (index < 0) return false;
    rows.removeAt(index);
    return true;
  }
}

/// Frise sans événement : sous le filtre « tout » elle ne porte que les mesures,
/// et le vrai repository d'historique n'est jamais construit — donc jamais la base.
class _EmptyEventHistoryRepository implements HistoryRepository {
  @override
  Future<List<TrackingEvent>> getAllEventsOrdered({String? babyId}) async =>
      const [];

  @override
  Future<List<TrackingEvent>> getEventsByType(TrackingType type,
          {String? babyId}) async =>
      const [];

  @override
  Future<bool> updateEvent(
          {required int id, required TrackingEvent event}) async =>
      true;

  @override
  Future<bool> deleteEvent(int id) async => true;
}

/// Bébé actif synchronise à `null` — jamais les préférences ni le stockage sécurisé.
class _QuietActiveBabyNotifier extends ActiveBabyNotifier {
  @override
  Future<BabyProfile?> build() {
    state = const AsyncValue.data(null);
    return Future.value(null);
  }
}

void main() {
  late _FakeMeasurementRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeMeasurementRepository();
    container = ProviderContainer(
      overrides: [
        measurementRepositoryProvider.overrideWith((_) async => repo),
        historyRepositoryProvider
            .overrideWith((_) async => _EmptyEventHistoryRepository()),
        activeBabyProvider.overrideWith(_QuietActiveBabyNotifier.new),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Épingle la rangée d'accueil et la frise pendant le test : la seconde est
  /// `autoDispose`, sans auditeur elle se libère entre deux lectures et son état
  /// lu revient `null`.
  void watchBoth() {
    final home = container.listen(measurementNotifierProvider, (_, __) {});
    addTearDown(home.close);
    final frise = container.listen(
        historyNotifierProvider(HistoryFilter.all), (_, __) {});
    addTearDown(frise.close);
  }

  Future<List<GrowthMeasurement>> homeRow() =>
      container.read(measurementNotifierProvider.future);

  HistoryNotifier friseNotifier() =>
      container.read(historyNotifierProvider(HistoryFilter.all).notifier);

  group('MeasurementNotifier — relecture après écriture', () {
    test('refresh() voit la ligne ajoutée par la feuille de saisie', () async {
      // Le contrat que `MeasurementSheet._save` appelle après `repository.add` :
      // sans lui, l'accueil reste sur la valeur précédente jusqu'à changer de bébé.
      await homeRow();
      expect(container.read(measurementNotifierProvider).value, isEmpty);

      await repo.add(
        babyId: null,
        kind: MeasureKind.poids,
        value: 4300,
        recordedAt: DateTime(2026, 10, 13, 8),
      );
      await container.read(measurementNotifierProvider.notifier).refresh();

      expect(container.read(measurementNotifierProvider).value!.single.value,
          4300);
    });
  });

  group('Éditer une mesure depuis la frise rafraîchit l\'accueil', () {
    late GrowthMeasurement mPoids;

    setUp(() {
      watchBoth();
      mPoids = repo.seed(
        id: 10,
        kind: MeasureKind.poids,
        value: 3000,
        at: DateTime(2026, 10, 12, 8),
      );
    });

    test('updateMeasurement : « dernier poids » passe à la valeur corrigée',
        () async {
      // L'accueil et l'écran Croissance watchent `measurementNotifierProvider`,
      // jamais la frise : sans invalidation à l'édition, « dernier poids » est
      // resté 3 kg après une correction à 3,5 kg.
      expect((await homeRow()).single.value, 3000);

      await friseNotifier().updateMeasurement(mPoids.copyWith(value: 3500));

      expect((await homeRow()).single.value, 3500,
          reason: 'la rangée d\'accueil doit la valeur corrigée, pas la valeur '
              'restée en cache avant l\'édition');
    });

    test('deleteMeasurement : la valeur supprimée ne reste pas à l\'accueil',
        () async {
      expect((await homeRow()), hasLength(1));

      await friseNotifier().deleteMeasurement(mPoids.id);

      expect(await homeRow(), isEmpty,
          reason:
              'une mesure supprimée ne doit plus faire le « dernier poids »');
    });

    test('la frise elle-même reste juste après l\'édition', () async {
      // Garde-fou : l'invalidation de l'accueil ne doit rien casser côté frise.
      final notifier = friseNotifier();
      await notifier.updateMeasurement(mPoids.copyWith(value: 3500));

      final rows =
          container.read(historyNotifierProvider(HistoryFilter.all)).value!;
      expect(rows.whereType<MeasurementHistoryRow>().single.measurement.value,
          3500);
    });
  });
}
