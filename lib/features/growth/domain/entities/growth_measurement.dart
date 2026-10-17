import 'package:freezed_annotation/freezed_annotation.dart';

import 'measure_kind.dart';

part 'growth_measurement.freezed.dart';

/// A growth measurement (weight, height, temperature), explained.
///
/// [value] is expressed in base units (g, cm, °C); `null` if the encryption is.
/// "Unreadable (lost key) — in this case, the user interface displays "unreadable value" instead."
/// that is an arbitrary number. The `[babyId]` field is `null` for measurements taken before.
/// the creation of a profile.
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
