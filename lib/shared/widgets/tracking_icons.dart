/// Shared icon mappings for tracking types, subtypes, and waste categories.
///
/// Single source of truth: every screen (creation dialogs, history tiles, edit screens)
/// uses these extensions to get consistent IconData values across contexts.
library;

import 'package:flutter/material.dart';

import '../domain/entities/tracking_enums.dart';
import '../domain/entities/tracking_type.dart';

// ──────────────────────────────────────────────
// TrackingType → canonical IconData
// ──────────────────────────────────────────────

/// Extension on [TrackingType] returning a Material icon for CircleAvatar / leading positions.
extension TrackingTypeIcon on TrackingType {
  /// Returns the canonical icon for this tracking type.
  /// Reused across home screen buttons, history tile avatars, and edit dialogs.
  IconData get icon => switch (this) {
        TrackingType.miam => Icons.lunch_dining,
        TrackingType.sante => Icons.favorite,
        TrackingType.caca => Icons.water_drop_outlined,
        TrackingType.dodo => Icons.nightlight,
      };
}

// ──────────────────────────────────────────────
// TrackingType → history-row glyph (outlined)
// ──────────────────────────────────────────────

/// Extension on [TrackingType] for the leading glyph of a history row.
///
/// Outlined on purpose: a row is a line of text with a small disc beside it, and a
/// solid glyph in that disc renders heavier than the words next to it — this file
/// already prefers the outlined variant for chips for the same reason. The two
/// mappings are kept apart rather than merging into one because the filled glyphs
/// are what the home grid ships with, and B29 measured those buttons into the live
/// store screenshots: restyling the list must not restyle the grid from here.
extension TrackingTypeListIcon on TrackingType {
  /// The outlined glyph a history row wears for this type.
  ///
  /// `favorite_border` rather than `favorite_outlined` for health: measured on a
  /// Small_Phone on 2026-11-21, `Icons.favorite_outlined` (codepoint 0xf04b in the
  /// Material font this Flutter ships) renders as a **solid** heart, so the name is
  /// not a promise about the glyph. `favorite_border` (0xe25c) is the outline.
  IconData get listIcon => switch (this) {
        TrackingType.miam => Icons.lunch_dining_outlined,
        TrackingType.sante => Icons.favorite_border,
        // The disc of a diaper row wears the *waste* glyph, not this one, so this
        // is the type-level fallback (`WasteTypeIcon` owns pipi/caca/les deux).
        TrackingType.caca => Icons.water_drop_outlined,
        TrackingType.dodo => Icons.nightlight_outlined,
      };
}

// ──────────────────────────────────────────────
// HistoryFilter → filter-pill icon (outlined)
// ──────────────────────────────────────────────

/// Extension on [HistoryFilter] for the glyph a filter pill wears.
///
/// Outlined, which is the rule this file already writes for [FeedingSubtypeIcon]:
/// a chip wears the outlined variant, the filled glyph stays with the type avatar.
/// A pill is read as a wall of words otherwise — the type accent alone was not
/// enough to tell « Sommeil » from « Caca » at a glance in a row of six.
///
/// `all` and `measurements` return `null` on purpose, for the same reason they
/// carry no accent in the pill row (B7): there is no tracking type behind them,
/// and the glyph for « everything » is a design decision, not something to invent
/// inside a widget.
extension HistoryFilterIcon on HistoryFilter {
  /// The pill's leading glyph, or `null` for a filter that is not one type.
  IconData? get pillIcon => switch (this) {
        HistoryFilter.miam => Icons.lunch_dining_outlined,
        HistoryFilter.dodo => Icons.nightlight_outlined,
        HistoryFilter.caca => Icons.water_drop_outlined,
        HistoryFilter.sante => Icons.favorite_border,
        HistoryFilter.all => null,
        HistoryFilter.measurements => null,
      };
}

// ──────────────────────────────────────────────
// FeedingSubtype → canonical IconData (outlined variants)
// ──────────────────────────────────────────────

/// Extension on [FeedingSubtype] returning an outlined Material icon for FilterChips / inline rows.
extension FeedingSubtypeIcon on FeedingSubtype {
  /// Returns the canonical icon for this feeding subtype.
  /// Outlined variants are preferred for better visual hierarchy against filled type icons.
  IconData get icon => switch (this) {
        FeedingSubtype.natural => Icons.local_drink_outlined,
        FeedingSubtype.artificial => Icons.coffee_rounded,
        FeedingSubtype.solid => Icons.rice_bowl,
      };
}

// ──────────────────────────────────────────────
// WasteType → canonical IconData
// ──────────────────────────────────────────────

/// Extension on [WasteType] returning a Material icon for inline display.
extension WasteTypeIcon on WasteType {
  /// Returns the canonical icon for this waste type — one drop family:
  /// pipi → outlined drop (light/empty), caca → filled drop (full),
  /// lesDeux → drop with satellite drops (both, at once). Was `wb_sunny`, a
  /// glyph found nowhere else in the app.
  IconData get icon => switch (this) {
        WasteType.pipi => Icons.water_drop_outlined,
        WasteType.caca => Icons.water_drop,
        WasteType.lesDeux => Icons.opacity,
      };
}

// ──────────────────────────────────────────────
// Health subtypes → canonical IconData (static lookup)
// ──────────────────────────────────────────────

/// Static helper for health subtype icons.
///
/// [HealthSubtype] uses freezed constants rather than an enum, so a static method
/// is used instead of an extension on the type itself. Pass [HealthSubtype.value] to look up icons.
class HealthIcons {
  const HealthIcons._();

  /// Returns the canonical icon for a given health subtype DB value string.
  ///
  /// Categories:
  /// - nettoyages (yeux, nombril, visage, nez) → [Icons.cleaning_services]
  /// - vitamines (D, K) → [Icons.medication]
  /// - unknown fallback → [Icons.health_and_safety]
  static IconData fromValue(String value) {
    return switch (value) {
      'nettoyage_yeux' ||
      'nettoyage_nombril' ||
      'nettoyage_visage' ||
      'nettoyage_nez' =>
        Icons.cleaning_services,
      'vitamine_d' || 'vitamine_k' => Icons.medication,
      _ => Icons.health_and_safety,
    };
  }

  /// Returns the canonical icon for a [HealthSubtype] instance.
  static IconData from(HealthSubtype subtype) {
    return fromValue(subtype.value);
  }
}
