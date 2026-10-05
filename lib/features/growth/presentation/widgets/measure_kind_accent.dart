import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../domain/entities/measure_kind.dart';

/// Couleur d'accent par grande, côté présentation (le domain ne connaît
/// pas le thème) : poids → miam, taille → dodo, température → santé.
extension MeasureKindAccent on MeasureKind {
  /// Accent du bouton d'accueil, de la feuille et des cartes de dernière
  /// valeur — une couleur par grande, stable d'un écran à l'autre.
  Color get accent => switch (this) {
        MeasureKind.poids => AppTheme.miam,
        MeasureKind.taille => AppTheme.dodo,
        MeasureKind.temperature => AppTheme.sante,
      };
}
