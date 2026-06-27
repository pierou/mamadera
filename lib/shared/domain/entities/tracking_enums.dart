/// Enums et types typed pour remplacer les magic strings dans tout le codebase.
///
/// Chaque type contient :
/// - `value` : la valeur stockée en base de données (format DB)
/// - `label` : l'affichage utilisateur (format UI)
library;

// ──────────────────────────────────────────────
// Feeding subtypes (sous-types du type "miam")
// ──────────────────────────────────────────────

/// Sous-type d'alimentation stocké en DB.
enum FeedingSubtype {
  /// Sein maternel.
  sein, // 'sein'
  /// Biberon.
  bib; // 'bib'
}

// ──────────────────────────────────────────────
// Waste types (caca/pipi)
// ──────────────────────────────────────────────

/// Type de selle pour un nouveau-né.
enum WasteType {
  pipi, // 'pipi'
  caca, // 'caca'
  lesDeux; // 'les_deux'

  /// Retourne la valeur DB correspondante (snake_case).
  String get dbValue => switch (this) {
        WasteType.pipi => 'pipi',
        WasteType.caca => 'caca',
        WasteType.lesDeux => 'les_deux',
      };

  /// Convertit une valeur DB en enum, ou null si inconnu/nullable.
  static WasteType? fromDbValue(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case 'pipi':
        return WasteType.pipi;
      case 'caca':
        return WasteType.caca;
      case 'les_deux':
      case 'lesdeux':
        return WasteType.lesDeux;
      default:
        return null;
    }
  }

  /// Convertit une valeur DB en enum avec fallback par défaut (caca).
  static WasteType fromDbValueOrDefault(String? value) {
    final result = fromDbValue(value);
    if (result != null) return result;
    return WasteType.caca;
  }
}

// ──────────────────────────────────────────────
// Pipi colors
// ──────────────────────────────────────────────

/// Couleur d'urine pour un nouveau-né.
final class PipiColor {
  /// Constructeur constant pour les instances immuables.
  const PipiColor({
    required this.value,
    required this.label,
    required this.colorHex,
    required this.labelKey,
  });

  /// Convertit une valeur DB en enum avec fallback (incolore par défaut).
  factory PipiColor.fromDbValue(String? dbValue) {
    final result = byValue(dbValue);
    if (result != null) return result;
    return incolore;
  }

  // ── Valeurs stockées en base de données ───────

  /// Valeur stockée en base de données (ex: 'jaune_clair').
  final String value;

  /// Label affiché à l'écran — French fallback for domain-layer safety.
  final String label;

  /// Couleur visuelle hexadécimale pour l'UI.
  final int colorHex;

  /// ARB key for resolving the localized label at presentation time.
  final String labelKey;

  // ── Instances statiques ───────────────────────

  static const incolore = PipiColor(
      value: 'incolore', label: 'Incolore', colorHex: 0xFFE8F5E9, labelKey: 'pipiColorIncolore');
  static const jauneClair = PipiColor(
      value: 'jaune_clair', label: 'Jaune clair', colorHex: 0xFFFEEBC8, labelKey: 'pipiColorJauneClair');
  static const jauneFonce = PipiColor(
      value: 'jaune_fonce', label: 'Jaune foncé', colorHex: 0xFFE6C25B, labelKey: 'pipiColorJauneFonce');
  static const roseUrates = PipiColor(
      value: 'rose_urates',
      label: 'Rose/Orange (urates)',
      colorHex: 0xFFF4A89D,
      labelKey: 'pipiColorRoseUrates');

  // ── Liste de toutes les couleurs disponibles ──
  /// Liste statique initialisée après les constantes.
  static final List<PipiColor> values = [
    incolore,
    jauneClair,
    jauneFonce,
    roseUrates
  ];

  /// Lookup par valeur DB. Retourne null si inconnu ou nullable.
  static PipiColor? byValue(String? v) {
    if (v == null || v.isEmpty) return null;
    for (final c in values) {
      if (c.value == v) return c;
    }
    return null;
  }
}

// ──────────────────────────────────────────────
// Caca colors
// ──────────────────────────────────────────────

/// Couleur de selle pour un nouveau-né.
final class CacaColor {
  /// Constructeur constant pour les instances immuables.
  const CacaColor({
    required this.value,
    required this.label,
    required this.colorHex,
    required this.labelKey,
  });

  /// Convertit une valeur DB en enum avec fallback (jaune_moutarde par défaut).
  factory CacaColor.fromDbValue(String? dbValue) {
    final result = byValue(dbValue);
    if (result != null) return result;
    return jauneMoutarde;
  }

  // ── Valeurs stockées en base de données ───────

  /// Valeur stockée en base de données (ex: 'jaune_moutarde').
  final String value;

  /// Label affiché à l'écran — French fallback for domain-layer safety.
  final String label;

  /// Couleur visuelle hexadécimale pour l'UI.
  final int colorHex;

  /// ARB key for resolving the localized label at presentation time.
  final String labelKey;

  // ── Instances statiques ───────────────────────

  static const meconium = CacaColor(
      value: 'meconium', label: 'Mécônium', colorHex: 0xFF5D4E37, labelKey: 'cacaColorMeconium');
  static const vertOlive = CacaColor(
      value: 'vert_olive', label: 'Vert olive', colorHex: 0xFF8A9B6C, labelKey: 'cacaColorVertOlive');
  static const jauneMoutarde = CacaColor(
      value: 'jaune_moutarde', label: 'Jaune moutarde', colorHex: 0xFFF5D138, labelKey: 'cacaColorJauneMoutarde');
  static const jauneClair = CacaColor(
      value: 'jaune_clair', label: 'Jaune clair', colorHex: 0xFFEED976, labelKey: 'cacaColorJauneClair');

  // ── Liste de toutes les couleurs disponibles ──
  /// Liste statique initialisée après les constantes.
  static final List<CacaColor> values = [
    meconium,
    vertOlive,
    jauneMoutarde,
    jauneClair
  ];

  /// Lookup par valeur DB. Retourne null si inconnu ou nullable.
  static CacaColor? byValue(String? v) {
    if (v == null || v.isEmpty) return null;
    for (final c in values) {
      if (c.value == v) return c;
    }
    return null;
  }
}

// ──────────────────────────────────────────────
// Health subtypes (stockés dans la colonne notes)
// ──────────────────────────────────────────────

/// Sous-type de soin santé.
final class HealthSubtype {
  /// Constructeur constant pour les instances immuables.
  const HealthSubtype({
    required this.value,
    required this.label,
    required this.labelKey,
  });

  // ── Valeurs stockées en base de données ───────

  /// Valeur stockée en base de données (ex: 'nettoyage_yeux').
  final String value;

  /// Label affiché à l'écran — French fallback for domain-layer safety.
  final String label;

  /// ARB key for resolving the localized label at presentation time.
  final String labelKey;

  // ── Instances statiques ───────────────────────

  static const nettoyageYeux = HealthSubtype(
      value: 'nettoyage_yeux', label: 'Nettoyage des yeux', labelKey: 'healthNettoyageYeux');
  static const nettoyageNombril = HealthSubtype(
      value: 'nettoyage_nombril', label: 'Nettoyage du nombril', labelKey: 'healthNettoyageNombril');
  static const nettoyageVisage = HealthSubtype(
      value: 'nettoyage_visage', label: 'Nettoyage du visage', labelKey: 'healthNettoyageVisage');
  static const nettoyageNez = HealthSubtype(
      value: 'nettoyage_nez', label: 'Nettoyage du nez', labelKey: 'healthNettoyageNez');
  static const vitamineD = HealthSubtype(
      value: 'vitamine_d', label: 'Vitamine D', labelKey: 'healthVitamineD');
  static const vitamineK = HealthSubtype(
      value: 'vitamine_k', label: 'Vitamine K', labelKey: 'healthVitamineK');

  // ── Liste de tous les sous-types disponibles ──
  /// Liste statique initialisée après les constantes.
  static final List<HealthSubtype> values = [
    nettoyageYeux,
    nettoyageNombril,
    nettoyageVisage,
    nettoyageNez,
    vitamineD,
    vitamineK,
  ];

  /// Lookup par valeur DB. Retourne null si inconnu.
  static HealthSubtype? byValue(String v) {
    for (final h in values) {
      if (h.value == v) return h;
    }
    return null;
  }
}

// ──────────────────────────────────────────────
// Filter sentinel (remplace 'all')
// ──────────────────────────────────────────────

/// Filtre d'affichage pour l'historique.
enum HistoryFilter {
  /// Tous les événements.
  all, // 'all'
  /// Alimentation uniquement.
  miam, // 'miam'
  /// Sommeil uniquement.
  dodo, // 'dodo'
  /// Selles uniquement.
  caca, // 'caca'
  /// Santé uniquement.
  sante; // 'sante'

  /// Retourne le nom de l'enum pour la compatibilité DB (TrackingType.name).
  String get dbKey => name.toLowerCase();

  /// Convertit une valeur string en enum. 'all' reste all, sinon converti via TrackingType.fromString.
  static HistoryFilter fromString(String value) {
    final lower = value.toLowerCase();
    if (lower == 'all' || lower.isEmpty) return HistoryFilter.all;
    for (final f in HistoryFilter.values) {
      if (f.name == lower) return f;
    }
    return HistoryFilter.all; // fallback safe
  }

  /// Retourne le label affiché dans l'UI (French fallback).
  String get label {
    switch (this) {
      case HistoryFilter.all:
        return 'Tous';
      case HistoryFilter.miam:
        return 'Miam';
      case HistoryFilter.dodo:
        return 'Sommeil';
      case HistoryFilter.caca:
        return 'Caca';
      case HistoryFilter.sante:
        return 'Santé';
    }
  }

  /// ARB key for resolving the localized label at presentation time.
  String get labelKey {
    switch (this) {
      case HistoryFilter.all:
        return 'filterAll';
      case HistoryFilter.miam:
        return 'filterMiam';
      case HistoryFilter.dodo:
        return 'filterDodo';
      case HistoryFilter.caca:
        return 'filterCaca';
      case HistoryFilter.sante:
        return 'filterSante';
    }
  }

  /// Retourne le TrackingType correspondant (null pour all).
  String? get trackingType {
    switch (this) {
      case HistoryFilter.all:
        return null; // pas de type spécifique → tout récupérer
      default:
        return name.toLowerCase();
    }
  }
}
