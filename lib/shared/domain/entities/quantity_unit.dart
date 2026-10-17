import '../../../data/local/db_constants.dart' as db_const;
import 'tracking_enums.dart';

/// Unit of a tracked quantity, stored per row in `tracking_events.unit`
/// (schema v12).
///
/// Before v12 the unit was **inferred** from the row's type and subtype, and
/// that inference stopped being sufficient the day `natural` could legitimately
/// hold either millilitres (expressed milk) or minutes (a feed at the breast):
/// one subtype, two units, and no column to tell them apart. The unit is now
/// data, carried by the row that owns the number.
///
/// Grams are shared with `measurements.unit` (`db_const.unitG`), which states
/// its own unit since v11 — both tables now say what their number means,
/// which is the whole point of this column.
enum QuantityUnit {
  /// Millilitres — bottle, expressed milk.
  ml,

  /// Minutes — sleep, and a feed timed at the breast.
  min,

  /// Grams — solids, and the stored unit of a weight measurement.
  g;

  /// Value written to the `unit` column: the enum name, spelled out so a
  /// backup stays readable without this file.
  String get dbValue => switch (this) {
        QuantityUnit.ml => db_const.unitMl,
        QuantityUnit.min => db_const.unitMin,
        QuantityUnit.g => db_const.unitG,
      };

  /// Reverse of [dbValue]; `null` for anything this build does not know, so
  /// a future unit rejects a restore instead of silently reading as ml.
  static QuantityUnit? fromDbValue(String? value) {
    for (final unit in QuantityUnit.values) {
      if (unit.dbValue == value) return unit;
    }
    return null;
  }

  /// Whether a quantity in this unit is a duration rather than an amount of
  /// matter. Aggregates must refuse to add the two together — summing minutes
  /// into millilitres is not an approximation, it is a category error.
  bool get isDuration => this == QuantityUnit.min;
}

/// The unit a row carries when the UI made no choice — and, identically, the
/// unit to backfill a pre-v12 row (or a format-1/2 backup) with.
///
/// One rule for both, because both ask the same question: what did the parent
/// see on the screen? A parent who typed "20" while breastfeeding was shown "20 ml," so...
/// the row means 20 ml. Converting a historical `natural` value to minutes
/// would invent a measurement that was never taken, in an app whose promise is
/// that the numbers it displays were entered. No arithmetic here, on purpose.
///
/// For a **new** `natural` row the parent does choose (ml or min, in the
/// feeding dialog) and the dialog always passes that choice, so this default
/// never silently relabels a fresh entry.
QuantityUnit defaultUnitFor({required String typeValue, String? subtypeValue}) {
  if (typeValue == db_const.typeDodo) return QuantityUnit.min;
  if (typeValue == db_const.typeMiam) {
    return FeedingSubtype.fromDbValue(subtypeValue) == FeedingSubtype.solid
        ? QuantityUnit.g
        : QuantityUnit.ml;
  }
  // Diaper and health rows carry no quantity; ml is the column default and
  // means nothing until a quantity appears there.
  return QuantityUnit.ml;
}
