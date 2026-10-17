/// Enums and typed data structures to replace "magic strings" throughout the codebase.
///
/// Chaque type contient :
/// - `value`: the value stored in the database (database format).
/// - `label` : l'affichage utilisateur (format UI)
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracking_enums.freezed.dart';

// ──────────────────────────────────────────────
// Feeding subtypes (subtypes of the "yum" category).
// ──────────────────────────────────────────────

/// Subtype of power supply stored in the database.
enum FeedingSubtype {
  /// Allaitement maternel (lait maternel).
  natural, // 'natural'
  /// Allaitement artificiel (lait artificiel).
  artificial, // 'artificial'
  /// Solid food (purees, introduction of solids) - the quantity is specified.
  /// en grammes, pas en millilitres.
  solid; // 'solid'

  /// Returns the corresponding DB value.
  String get dbValue => switch (this) {
        FeedingSubtype.natural => 'natural',
        FeedingSubtype.artificial => 'artificial',
        FeedingSubtype.solid => 'solid',
      };

  /// Converts a database value into an enumeration.
  /// Handles legacy values ('breast', 'nipple') for backward compatibility.
  static FeedingSubtype? fromDbValue(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value) {
      case 'natural':
        return FeedingSubtype.natural;
      case 'artificial':
        return FeedingSubtype.artificial;
      // Backward compatibility – legacy data.
      case 'sein':
        return FeedingSubtype.natural;
      case 'bib':
        return FeedingSubtype.artificial;
      case 'solid':
        return FeedingSubtype.solid;
      // No inherited alias exists for 'solid': no compatibility needs to be created.
      default:
        return null;
    }
  }
}

// ──────────────────────────────────────────────
// Waste types (caca/pipi)
// ──────────────────────────────────────────────

/// Type of seat for a newborn.
enum WasteType {
  pipi, // 'pipi'
  caca, // 'caca'
  lesDeux; // 'les_deux'

  /// Returns the corresponding database value (in snake_case format).
  String get dbValue => switch (this) {
        WasteType.pipi => 'pipi',
        WasteType.caca => 'caca',
        WasteType.lesDeux => 'les_deux',
      };

  /// Converts a database value to an enumeration, or returns null if the value is unknown or nullable.
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

  /// Converts a database value into an enumeration, with a default fallback value ("caca").
  static WasteType fromDbValueOrDefault(String? value) {
    final result = fromDbValue(value);
    if (result != null) return result;
    return WasteType.caca;
  }
}

// ──────────────────────────────────────────────
// Pipi colors
// ──────────────────────────────────────────────

/// Urine color for a newborn.
@freezed
abstract class PipiColor with _$PipiColor {
  const factory PipiColor({
    required String value,
    required String label,
    required int colorHex,
    required String labelKey,
  }) = _PipiColor;
}

/// Couleur incolore/transparente.
const pipiColorIncolore = PipiColor(
    value: 'incolore', label: 'Incolore', colorHex: 0xFFE8F5E9, labelKey: 'pipiColorIncolore');

/// Pale yellow.
const pipiColorJauneClair = PipiColor(
    value: 'jaune_clair', label: 'Jaune clair', colorHex: 0xFFFEEBC8, labelKey: 'pipiColorJauneClair');

/// Dark yellow.
const pipiColorJauneFonce = PipiColor(
    value: 'jaune_fonce', label: 'Jaune foncé', colorHex: 0xFFE6C25B, labelKey: 'pipiColorJauneFonce');

/// Rose/Orange (urates).
const pipiColorRoseUrates = PipiColor(
    value: 'rose_urates',
    label: 'Rose/Orange (urates)',
    colorHex: 0xFFF4A89D,
    labelKey: 'pipiColorRoseUrates');

/// List of all available "pipi" colors.
const List<PipiColor> pipiColors = [
  pipiColorIncolore,
  pipiColorJauneClair,
  pipiColorJauneFonce,
  pipiColorRoseUrates,
];

/// Lookup by database value. Returns null if the value is not found or if the value is nullable.
PipiColor? findPipiColorByValue(String? v) {
  if (v == null || v.isEmpty) return null;
  for (final c in pipiColors) {
    if (c.value == v) return c;
  }
  return null;
}

/// Converts a DB value into a PipiColor value, with a default fallback (transparent by default).
PipiColor findPipiColorFromDbValue(String? dbValue) =>
    findPipiColorByValue(dbValue) ?? pipiColorIncolore;

// ──────────────────────────────────────────────
// Caca colors
// ──────────────────────────────────────────────

/// Saddle color for a newborn.
@freezed
abstract class CacaColor with _$CacaColor {
  const factory CacaColor({
    required String value,
    required String label,
    required int colorHex,
    required String labelKey,
  }) = _CacaColor;
}

/// Meconium (the first stool).
const cacaColorMeconium = CacaColor(
    value: 'meconium', label: 'Mécônium', colorHex: 0xFF5D4E37, labelKey: 'cacaColorMeconium');

/// Vert olive.
const cacaColorVertOlive = CacaColor(
    value: 'vert_olive', label: 'Vert olive', colorHex: 0xFF8A9B6C, labelKey: 'cacaColorVertOlive');

/// Jaune moutarde (seins).
const cacaColorJauneMoutarde = CacaColor(
    value: 'jaune_moutarde', label: 'Jaune moutarde', colorHex: 0xFFF5D138, labelKey: 'cacaColorJauneMoutarde');

/// Jaune clair.
const cacaColorJauneClair = CacaColor(
    value: 'jaune_clair', label: 'Jaune clair', colorHex: 0xFFEED976, labelKey: 'cacaColorJauneClair');

/// List of all available "caca" colors.
const List<CacaColor> cacaColors = [
  cacaColorMeconium,
  cacaColorVertOlive,
  cacaColorJauneMoutarde,
  cacaColorJauneClair,
];

/// Lookup by database value. Returns null if the value is not found or if the value is nullable.
CacaColor? findCacaColorByValue(String? v) {
  if (v == null || v.isEmpty) return null;
  for (final c in cacaColors) {
    if (c.value == v) return c;
  }
  return null;
}

/// Converts a DB value into a CacaColor value, with a default fallback (mustard yellow).
CacaColor findCacaColorFromDbValue(String? dbValue) =>
    findCacaColorByValue(dbValue) ?? cacaColorJauneMoutarde;

// ──────────────────────────────────────────────
// Stool texture
// ──────────────────────────────────────────────

/// Consistency of a saddle, from the most liquid to the most firm.
///
/// A 5-point scale inspired by pediatric monitoring charts: it...
/// It is used to identify an unusual texture (watery = risk of dehydration).
/// (duration = constipation), but not to make a diagnosis.
@freezed
abstract class StoolTexture with _$StoolTexture {
  const factory StoolTexture({
    required String value,
    required String label,
    required String labelKey,
  }) = _StoolTexture;
}

/// Watery (liquid, discharge) — should be monitored in newborns.
const stoolTextureAqueuse = StoolTexture(
    value: 'aqueuse', label: 'Aqueuse', labelKey: 'stoolTextureAqueuse');

/// Grumeleuse (grumeaux type grain de ricin, molle).
const stoolTextureGrumeleuse = StoolTexture(
    value: 'grumeleuse',
    label: 'Grumeleuse',
    labelKey: 'stoolTextureGrumeleuse');

/// Smooth (creamy, uniform, forms a layer).
const stoolTexturePateuse = StoolTexture(
    value: 'pateuse', label: 'Pâteuse', labelKey: 'stoolTexturePateuse');

/// Molded (soft sausage, shaped).
const stoolTextureMoulee = StoolTexture(
    value: 'moulee', label: 'Moulée', labelKey: 'stoolTextureMoulee');

/// Hard (dry stools, difficult to pass).
const stoolTextureDure = StoolTexture(
    value: 'dure', label: 'Dure', labelKey: 'stoolTextureDure');

/// Here is a list of all available textures, ranging from the most liquid to the most solid.
///
/// The `value` data stored in the database remains in ASCII format (accent marks are not supported).
/// within the `label`) to ensure they remain readable when exporting to a manually edited JSON file.
const List<StoolTexture> stoolTextures = [
  stoolTextureAqueuse,
  stoolTextureGrumeleuse,
  stoolTexturePateuse,
  stoolTextureMoulee,
  stoolTextureDure,
];

/// Lookup by DB value. Returns null if unknown or column is empty: the texture.
/// It is optional, and no default value is defined.
StoolTexture? findStoolTextureByValue(String? v) {
  if (v == null || v.isEmpty) return null;
  for (final t in stoolTextures) {
    if (t.value == v) return t;
  }
  return null;
}

// ──────────────────────────────────────────────
// Health subtypes (stored in the notes column).
// ──────────────────────────────────────────────

/// Subtype of healthcare service.
@freezed
abstract class HealthSubtype with _$HealthSubtype {
  const factory HealthSubtype({
    required String value,
    required String label,
    required String labelKey,
  }) = _HealthSubtype;

  // ── Values stored in the database ───────

  /// Value stored in the database (e.g., 'eye_cleaning').
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

  // --- List of all available subtypes ---
  /// A static list initialized after the constants.
  static final List<HealthSubtype> values = [
    nettoyageYeux,
    nettoyageNombril,
    nettoyageVisage,
    nettoyageNez,
    vitamineD,
    vitamineK,
  ];

  /// Lookup by database value. Returns null if not found.
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

/// Display filter for the history.
enum HistoryFilter {
  /// All events.
  all, // 'all'
  /// Alimentation uniquement.
  miam, // 'miam'
  /// Sommeil uniquement.
  dodo, // 'dodo'
  /// Selles uniquement.
  caca, // 'caca'
  /// Health only.
  sante; // 'sante'

  /// Returns the name of the enum for database compatibility (e.g., TrackingType.name).
  String get dbKey => name.toLowerCase();

  /// Converts a string value into an enum. If the string is "all", it remains "all"; otherwise, it's converted using the `TrackingType.fromString` method.
  static HistoryFilter fromString(String value) {
    final lower = value.toLowerCase();
    if (lower == 'all' || lower.isEmpty) return HistoryFilter.all;
    for (final f in HistoryFilter.values) {
      if (f.name == lower) return f;
    }
    return HistoryFilter.all; // fallback safe
  }

  /// Returns the label displayed in the user interface (with French as the fallback language).
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

  /// Returns the corresponding TrackingType (null for all).
  String? get trackingType {
    switch (this) {
      case HistoryFilter.all:
        return null;         // No specific type → retrieve everything.
      default:
        return name.toLowerCase();
    }
  }
}
