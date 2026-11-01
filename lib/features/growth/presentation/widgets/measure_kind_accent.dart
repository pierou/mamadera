import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../domain/entities/measure_kind.dart';

/// Presentation decoration for [MeasureKind]: accent colour and icon.
///
/// The domain enum (`measure_kind.dart`) knows its `dbValue`, its unit and its
/// validation range — it does not know what a kilogram looks like. Both values
/// here are UI choices that must stay consistent across screens, so they are
/// co-located in one extension instead of being carried as enum fields.
extension MeasureKindAccent on MeasureKind {
  /// Accent of the home button, the leaf, and the recent cards.
  /// value - a color that remains consistent across different screens.
  Color get accent => switch (this) {
        MeasureKind.poids => AppTheme.miam,
        MeasureKind.taille => AppTheme.dodo,
        MeasureKind.temperature => AppTheme.sante,
      };

  /// Canonical icon for the home button and history.
  IconData get icon => switch (this) {
        MeasureKind.poids => Icons.scale_outlined,
        MeasureKind.taille => Icons.straighten,
        MeasureKind.temperature => Icons.thermostat,
      };
}
