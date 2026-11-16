/// The items of one scope **as they are for this parent** — D-R2's single
/// effective-item function.
///
/// Three consumers call it (the settings list, Home via
/// `enabledRemindersProvider`, and `ReminderScheduler._itemsForScope`) and they
/// must not have three implementations of "what does this reminder look like
/// today": that disagreement is exactly what a parent experiences as *the switch
/// says off and it still rings* (B31's defect class, and the reason B33's ticket
/// says the override function must sit below both).
///
/// Applied here, in order:
///
/// 1. **removal** — a row with `removed = 1` leaves the list (D-R2/D-R4). It is
///    not deleted, so [isRemoved] lets the settings screen show it again in the
///    Removed section;
/// 2. **label** — `reminder_settings.label` overrides the preset's localized name
///    (D-R6);
/// 3. **frequency** — a stored code replaces the preset's rhythm, decoded through
///    the one codec the data layer also uses (D-R8's order: the occurrence date is
///    consulted only for `one_time`);
/// 4. **the series end** — `end_date` / `end_age_months` resolved against
///    the scope profile's birthdate, which is why the profile is a parameter and why the
///    age form needs a birthdate to mean anything (D-R10).
///
/// The **enabled** flag is deliberately *not* applied here: the settings list must
/// show a switched-off reminder (with its switch off) while Home and the scheduler
/// must hide it. Those two consumers filter on `enabled` themselves, right after
/// calling this — one table (D-R2's), one reading of it per consumer, no third.
library;

import '../../../../shared/domain/entities/baby_profile.dart';
import '../entities/reminder_item.dart';
import '../entities/reminder_item_setting.dart';
import 'reminder_end.dart';
import 'reminder_frequency_codec.dart';

/// The effective item list for one scope. See the file comment for the rules.
List<ReminderItem> effectiveItemsForScope({
  required List<ReminderItem> items,
  required Map<String, ReminderItemSetting> settings,
  BabyProfile? profile,
}) {
  return [
    for (final item in items)
      if (!_isRemovedFrom(settings[item.id]))
        _apply(item, settings[item.id], profile),
  ];
}

/// Whether [setting] marks its reminder as removed (D-R4's Removed section needs
/// the same answer the list applies, from the same row).
bool isRemoved(ReminderItemSetting? setting) => _isRemovedFrom(setting);

bool _isRemovedFrom(ReminderItemSetting? setting) => setting?.removed ?? false;

/// The item with [setting]'s overrides, or the item itself when the parent never
/// touched it — no row means no override, and never a synthesised default.
ReminderItem _apply(
  ReminderItem item,
  ReminderItemSetting? setting,
  BabyProfile? profile,
) {
  if (setting == null) return item;
  final code = setting.frequency;
  return item.copyWith(
    labelOverride: setting.label,
    frequency: code == null
        ? item.frequency
        // The preset override carries the frequency's parameters in the same row,
        // exactly as `custom_reminders` carries them in its own columns.
        : decodeFrequency(
            code,
            setting.intervalDays,
            occurrenceDate: setting.frequencyDate,
          ),
    endsAt: reminderEndFor(
      endDate: setting.endDate,
      endAgeMonths: setting.endAgeMonths,
      birthDate: profile?.birthDate,
    ),
  );
}
