import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';

/// The name the app shows for [item] — the one place the label override is
/// applied (B33/D-R6).
///
/// A preset renamed by the parent (`reminder_settings.label`) shows that wording
/// **everywhere**: Home, this screen's list, the notification title. A surface
/// that resolves `labelKey` on its own instead keeps calling the reminder by a
/// name the parent already changed, which is the B31 defect class in its most
/// confusing form — the app disagreeing with itself about what a thing is called.
///
/// Two entry points because the app localizes in two contexts: widgets (a
/// [BuildContext]) and the notification builder (an [AppLocalizations] looked up
/// from the parent's stored locale, with no element tree). Both take the
/// site's own localised resolution as [localised] rather than duplicating the
/// preset mapping, which differs per surface on purpose (Home prefers the short
/// care label, Settings the full one).
String reminderDisplayName(
  BuildContext context,
  ReminderItem item, {
  required String Function() localised,
}) =>
    overrideOr(item, localised);

/// The [AppLocalizations] variant, for notification text.
String reminderDisplayNameL10n(
  AppLocalizations l10n,
  ReminderItem item, {
  required String Function() localised,
}) =>
    overrideOr(item, localised);

/// [item]'s parent-chosen wording if it has one, otherwise [localised].
///
/// Public so the existing resolution sites can wrap what they already compute;
/// none of them may return a name without passing through here.
String overrideOr(ReminderItem item, String Function() localised) {
  final override = item.labelOverride;
  if (override != null && override.isNotEmpty) return override;
  return localised();
}

/// Whether [item] is a personalized reminder, whose `labelKey` field carries the
/// parent's free text rather than a localization key (it must never be
/// translated, and never is).
bool isCustomItem(ReminderItem item) =>
    item.id.startsWith(CustomReminderPresets.customIdPrefix);

/// The full care name for a health-linked preset ("Vitamin D", not the Home
/// abbreviation), falling back to `labelKey` for an item with no subtype.
String presetCareLabel(BuildContext context, ReminderItem item) {
  final subtypeValue = item.subtypeValue;
  if (subtypeValue != null) {
    final subtype = HealthSubtype.byValue(subtypeValue);
    if (subtype != null) return resolveHealthLabel(context, subtype);
  }
  final l = context.l;
  return switch (item.labelKey) {
    'reminderVitaminD' => l.reminderVitaminD,
    'reminderVitaminK' => l.reminderVitaminK,
    'reminderEyeCleaning' => l.reminderEyeCleaning,
    'reminderFaceCleaning' => l.reminderFaceCleaning,
    _ => item.labelKey,
  };
}
