import '../entities/growth_measurement.dart';
import '../entities/measure_kind.dart';

/// Accès aux mesures de croissance (poids, taille, température).
///
/// Toute lecture est bornée au bébé : `babyId == null` lit **toutes** les
/// lignes (aucun bébé sélectionné — installation sans profil ou chargement
/// en cours), comme le repository d'événements.
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
  Future<List<GrowthMeasurement>> allForBaby(String? babyId,
      {MeasureKind? kind});

  /// Met à jour une mesure existante : valeur, date, note.
  ///
  /// Kind, unité et bébé ne changent jamais — seule la ligne est corrigée
  /// (roadmap v1.2.1 : « une feuille d'édition où la valeur peut être
  /// corrigée, avec suppression »). La mesure doit porter son `id` ; une
  /// valeur hors bornes lève une [ArgumentError], comme à l'insertion.
  Future<void> update(GrowthMeasurement measurement);

  /// Supprime une mesure par son id. Retourne true si une ligne a été
  /// supprimée.
  Future<bool> deleteById(int id);
}
