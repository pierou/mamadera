import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/db_constants.dart' as db_const;

/// The three growth metrics measured (item 1 of version 1.2.0).
///
/// The enumeration process has its own validation checkpoints (roadmap §8, locked).
/// (through testing): A value one step beyond the `[min, max]` range is rejected as input.
/// never stored and then explained in the history. Metric only — not.
/// No unit toggle or Fahrenheit (°F) support in version 1.2.0.
enum MeasureKind {
  /// Weight: Whole grams, displayed in kilograms for weights exceeding 1000 grams.
  poids(
    dbValue: db_const.kindPoids,
    labelKey: 'homeButtonPoids',
    unit: db_const.unitG,
    icon: Icons.scale_outlined,
    min: 200,
    max: 20000,
    decimals: 0,
  ),

  /// Size: centimeters, with one decimal place.
  taille(
    dbValue: db_const.kindTaille,
    labelKey: 'homeButtonTaille',
    unit: db_const.unitCm,
    icon: Icons.straighten,
    min: 30,
    max: 110,
    decimals: 1,
  ),

  /// Temperature: degrees Celsius, with one decimal place.
  temperature(
    dbValue: db_const.kindTemperature,
    labelKey: 'homeButtonTemperature',
    unit: db_const.unitDegC,
    icon: Icons.thermostat,
    min: 33,
    max: 42,
    decimals: 1,
  );

  const MeasureKind({
    required this.dbValue,
    required this.labelKey,
    required this.unit,
    required this.icon,
    required this.min,
    required this.max,
    required this.decimals,
  });

  /// Value of the `measurements.kind` column (table contract, v1.1.1).
  final String dbValue;

  /// Localization key for the display text (home button and titles).
  final String labelKey;

  /// The unit of measurement is stored in the `measurements.unit` column (e.g., `g`, `cm`, `degC`).
  final String unit;

  /// Canonical icon for the home button and history.
  final IconData icon;

  /// Lower limit, inclusive, using basic units (g, cm, °C).
  final double min;

  /// High limit setting, in basic units (g, cm, °C).
  final double max;

  /// Number of decimal places to be entered (0 = integer).
  final int decimals;

  /// Display unit — differs from [unit] for temperature (`°C`).
  String get displayUnit => switch (this) {
        MeasureKind.poids => db_const.unitG,
        MeasureKind.taille => db_const.unitCm,
        MeasureKind.temperature => '°C',
      };

  /// Not using a slider, but in its basic unit.
  ///
  /// The weight is measured in **tens of grams**: a newborn baby is weighed immediately after birth.
  /// a bath, and a 200g weight would eliminate the steps that the parent is observing.
  /// Size is measured in centimeters – a baby's measuring tape can't be any finer. The...
  /// Temperature measured to the nearest tenth of a degree: a change of 0.5 would be recorded.
  /// 37.5, while the thermometer showed 37.4, and a rounded measurement in another.
  /// Monitoring temperature is not an approximation; it's an inaccurate reading.
  ///
  /// Consequence accepted: 1980 steps for the weight, which is equivalent to half a pixel.
  /// cran — the slider is no longer a precision instrument and does not claim to be.
  /// It brings things closer; it features a control field and plus/minus buttons.
  /// They determine the exact value and preserve it as is.
  double get step => switch (this) {
        MeasureKind.poids => 10,
        MeasureKind.taille => 1,
        MeasureKind.temperature => 0.1,
      };

  /// Number of divisions for the slider, limited by the range and step size specified above.
  int get divisions => ((max - min) / step).round();

  /// Going beyond the specified limits is not allowed: the intervals are inclusive.
  bool contains(num value) => value >= min && value <= max;

  /// Initial value of the sheet, in base units.
  ///
  /// Always within the range `[min, max]` and on the grid with a step of [step]: the sheet.
  /// It opens without error, displaying a plausible value for a newborn.
  double get defaultValue => switch (this) {
        MeasureKind.poids => 3500,
        MeasureKind.taille => 50,
        MeasureKind.temperature => 37,
      };

  /// Format the error messages as a number only, without any units.
  ///
  /// By definition, the values are integers: there are no separators.
  /// decimal, therefore no locale dependency – a stable and testable string.
  String formatBound(num bound) => bound.toInt().toString();

  /// Format [value] (in base units) for display.
  ///
  /// The decimal separator is set to intl via [localeName] (using a comma).
  /// (French, point in English) — never hardcoded. Beyond 1000 grams,
  /// The weight is given in kilograms, with a maximum of three decimal places; for weights of ≤ 1000 grams, use:
  /// grammes entiers.
  String format(num value, {String localeName = 'fr'}) {
    if (this == MeasureKind.poids) {
      if (value > 1000) {
        return '${NumberFormat('0.###', localeName).format(value / 1000)} kg';
      }
      return '${value.round()} g';
    }
    final pattern = '0.${'0' * decimals}';
    return '${NumberFormat(pattern, localeName).format(value)} $displayUnit';
  }

  /// Translates the stored value (`measurements.kind`) into an enumeration; returns `null` if...
  /// unknown — a single, isolated line should not disrupt the flow of reading.
  static MeasureKind? byValue(String? value) {
    for (final kind in values) {
      if (kind.dbValue == value) return kind;
    }
    return null;
  }
}
