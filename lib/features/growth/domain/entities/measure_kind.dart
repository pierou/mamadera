import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/db_constants.dart' as db_const;

/// Les trois grandeurs de croissance mesurées (item 1 de v1.2.0).
///
/// L'enum porte ses propres bornes de validation (roadmap §8, verrouillées
/// par les tests) : un cran au-delà de `[min, max]` est refusé à la saisie,
/// jamais stocké puis expliqué dans l'historique. Métrique uniquement — pas
/// de toggle d'unités ni de °F en v1.2.0.
enum MeasureKind {
  /// Poids : grammes entiers, affichés en kg au-delà de 1 000 g.
  poids(
    dbValue: db_const.kindPoids,
    labelKey: 'homeButtonPoids',
    unit: db_const.unitG,
    icon: Icons.scale_outlined,
    min: 200,
    max: 20000,
    decimals: 0,
  ),

  /// Taille : centimètres, une décimale.
  taille(
    dbValue: db_const.kindTaille,
    labelKey: 'homeButtonTaille',
    unit: db_const.unitCm,
    icon: Icons.straighten,
    min: 30,
    max: 110,
    decimals: 1,
  ),

  /// Température : degrés Celsius, une décimale.
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

  /// Valeur de la colonne `measurements.kind` (contrat de la table, v1.1.1).
  final String dbValue;

  /// Clé l10n du libellé d'affichage (bouton d'accueil et titres).
  final String labelKey;

  /// Unité stockée en colonne `measurements.unit` (`g`, `cm`, `degC`).
  final String unit;

  /// Icône canonique du bouton d'accueil et de l'historique.
  final IconData icon;

  /// Borne basse inclusive, en unité de base (g, cm, °C).
  final double min;

  /// Borne haute inclusive, en unité de base (g, cm, °C).
  final double max;

  /// Nombre de décimales de saisie (0 = entier).
  final int decimals;

  /// Unité d'affichage — diffère de [unit] pour la température (`°C`).
  String get displayUnit => switch (this) {
        MeasureKind.poids => db_const.unitG,
        MeasureKind.taille => db_const.unitCm,
        MeasureKind.temperature => '°C',
      };

  /// Pas du slider, en unité de base.
  ///
  /// Le poids se règle par poignées de grammes (200 g), la taille par
  /// centimètre, la température par **dixième de degré** : la fièvre d'un
  /// nourrisson se suit à 37,1 près, et un cran de 0,5 ferait enregistrer
  /// 37,5 là où le thermomètre affichait 37,4 — une mesure arrondie n'est pas
  /// une mesure.
  ///
  /// Neuf crans par degré, soit 90 sur toute la plage : environ 3 px par cran
  /// sur un téléphone. Le slider est donc un réglage grossier assumé — la
  /// précision vient du champ de saisie, qui accepte le dixième et le conserve
  /// tel quel. Le slider sert à atteindre le voisinage, pas la valeur exacte.
  double get step => switch (this) {
        MeasureKind.poids => 200,
        MeasureKind.taille => 1,
        MeasureKind.temperature => 0.1,
      };

  /// Nombre de divisions du slider, borné à la plage et au pas ci-dessus.
  int get divisions => ((max - min) / step).round();

  /// Un cran au-delà des bornes est refusé : les intervalles sont inclusifs.
  bool contains(num value) => value >= min && value <= max;

  /// Formate une borne (nombre seul, sans unité) pour les messages d'erreur.
  ///
  /// Les bornes sont des entiers par construction : pas de séparateur
  /// décimal, donc aucun dépendance de locale — string stable et testable.
  String formatBound(num bound) => bound.toInt().toString();

  /// Formate [value] (en unité de base) pour l'affichage.
  ///
  /// Le séparateur décimal vient d'intl via [localeName] (virgule en
  /// français, point en anglais) — jamais codé en dur. Au-delà de 1 000 g,
  /// le poids est en kg avec trois décimales au plus ; ≤ 1 000 g, en
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

  /// Traduit la valeur stockée (`measurements.kind`) en enum ; `null` si
  /// inconnue — une ligne orpheline ne doit pas faire tomber la lecture.
  static MeasureKind? byValue(String? value) {
    for (final kind in values) {
      if (kind.dbValue == value) return kind;
    }
    return null;
  }
}
