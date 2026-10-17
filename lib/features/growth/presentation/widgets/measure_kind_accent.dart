import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../domain/entities/measure_kind.dart';

/// Accent color for the main section, focusing on presentation (the domain is not familiar with...).
/// (Not the actual theme): weight → yum, height → sleep, temperature → health.
extension MeasureKindAccent on MeasureKind {
  /// Accent of the home button, the leaf, and the recent cards.
  /// value - a color that remains consistent across different screens.
  Color get accent => switch (this) {
        MeasureKind.poids => AppTheme.miam,
        MeasureKind.taille => AppTheme.dodo,
        MeasureKind.temperature => AppTheme.sante,
      };
}
