/// Shared icon mappings for tracking types, subtypes, and waste categories.
///
/// Single source of truth: every screen (creation dialogs, history tiles, edit screens)
/// uses these extensions to get consistent IconData values across contexts.
library;

import 'package:flutter/material.dart';

import 'tracking_enums.dart';
import 'tracking_type.dart';

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
// FeedingSubtype → canonical IconData (outlined variants)
// ──────────────────────────────────────────────

/// Extension on [FeedingSubtype] returning an outlined Material icon for FilterChips / inline rows.
extension FeedingSubtypeIcon on FeedingSubtype {
  /// Returns the canonical icon for this feeding subtype.
  /// Outlined variants are preferred for better visual hierarchy against filled type icons.
  IconData get icon => switch (this) {
        FeedingSubtype.natural => Icons.local_drink_outlined,
        FeedingSubtype.artificial => Icons.coffee_rounded,
      };
}

// ──────────────────────────────────────────────
// WasteType → canonical IconData
// ──────────────────────────────────────────────

/// Extension on [WasteType] returning a Material icon for inline display.
extension WasteTypeIcon on WasteType {
  /// Returns the canonical icon for this waste type.
  IconData get icon => switch (this) {
        WasteType.pipi => Icons.water_drop_outlined,
        WasteType.caca => Icons.water_drop,
        WasteType.lesDeux => Icons.wb_sunny,
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
