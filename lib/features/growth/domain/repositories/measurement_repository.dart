import '../entities/growth_measurement.dart';
import '../entities/measure_kind.dart';

/// Accès aux mesures de croissance (poids, taille, température).
///
/// Toute lecture est bornée au bébé : `babyId == null` lit les lignes sans
/// profil (suivi fait avant la création du profil), jamais celles d'un autre
/// bébé.
abstract class MeasurementRepository {
  /// Enregistre une mesure ; [value] en unité de base (g, cm, °C).
  ///
  /// Lance une [ArgumentError] si [value] est hors bornes pour [kind] :
  /// l'hors-plage est refusé à la saisie et ne doit jamais être persisté.
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  });

  /// Dernière mesure de [kind] pour le bébé, `null` s'il n'en a jamais.
  Future<GrowthMeasurement?> latestOfKind(String? babyId, MeasureKind kind);

  /// Historique du bébé, le plus récent en premier ; [kind] optionnel.
  Future<List<GrowthMeasurement>> allForBaby(String? babyId, {MeasureKind? kind});
}
