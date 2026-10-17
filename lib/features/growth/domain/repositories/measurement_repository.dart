import '../entities/growth_measurement.dart';
import '../entities/measure_kind.dart';

/// Access to growth measurements (weight, height, temperature).
///
/// Any reading operation is restricted to the baby: `babyId == null` reads **all** the...
/// lines (no baby selected - installation without profile or loading).
/// currently being developed), such as the event repository.
abstract class MeasurementRepository {
  /// Records a measurement; [value] in base units (g, cm, °C).
  ///
  /// Raises a [ArgumentError] if [value] is out of range for [kind]:
  /// The beach towel is not subject to seizure and should never be pursued in a legal claim.
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  });

  /// Last measurement of [kind] for the baby, `null` if no measurement has ever been taken.
  Future<GrowthMeasurement?> latestOfKind(String? babyId, MeasureKind kind);

  /// Baby's medical history, with the most recent information first; [kind] is optional.
  Future<List<GrowthMeasurement>> allForBaby(String? babyId,
      {MeasureKind? kind});

  /// Updates an existing measure: value, date, and note.
  ///
  /// Kindness, unity, and babies never change – only the line [or design] is adjusted.
  /// (roadmap v1.2.1: "an editing sheet where the value can be...")
  /// "corrected, with deletions"). The measure must include its `id`; a...
  /// A value outside the acceptable range will raise a [ArgumentError], just like when inserting a value.
  Future<void> update(GrowthMeasurement measurement);

  /// Deletes a record based on its ID. Returns true if a record was deleted.
  /// deleted.
  Future<bool> deleteById(int id);
}
