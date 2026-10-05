import 'package:freezed_annotation/freezed_annotation.dart';

import 'measure_kind.dart';

part 'growth_measurement.freezed.dart';

/// Une mesure de croissance (poids, taille, température), déchiffrée.
///
/// [value] est en unité de base (g, cm, °C) ; `null` si le chiffrement est
/// illisible (clé perdue) — l'UI affiche alors « valeur illisible » plutôt
/// qu'un nombre inventé. [babyId] est `null` pour les mesures faites avant
/// la création d'un profil.
@freezed
abstract class GrowthMeasurement with _$GrowthMeasurement {
  const factory GrowthMeasurement({
    required int id,
    required MeasureKind kind,
    required String unit,
    required DateTime recordedAt,
    String? babyId,
    double? value,
    String? notes,
  }) = _GrowthMeasurement;
}
