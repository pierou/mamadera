/// The frequency ⇄ stored-columns codec, in the domain.
///
/// It lives here rather than in the repository because **two** readers need it
/// and they must not disagree about what a stored code means: the data layer
/// decoding `custom_reminders`, and `effectiveItemsForScope` decoding a preset's
/// `reminder_settings.frequency` override (D-R2/D-R8). A codec copied into the
/// second reader is a preset that reads as daily in the list and as its real
/// rhythm in the scheduler — the B31 defect class.
///
/// Extraction note (M4): this code was the repository's private
/// `_encodeFrequency`/`_decodeFrequency`; the repository now delegates, so there
/// is one implementation of D-R8's rules.
library;

import '../../../../core/utils/calendar_date.dart';
import '../../../../data/local/db_constants.dart' as db_const;
import '../entities/custom_reminder.dart' show CustomReminderPresets;
import '../entities/reminder_frequency.dart';

/// The frequency ⇄ stored-columns codec, in the domain.
///
/// It lives here rather than in the repository because **two** readers need it
/// and they must not disagree about what a stored code means: the data layer
/// decoding `custom_reminders`, and `effectiveItemsForScope` decoding a preset's
/// `reminder_settings.frequency` override (D-R2/D-R8). A codec copied into the
/// second reader is a preset that reads as daily in the list and as its real
/// rhythm in the scheduler — the B31 defect class.
///
/// Extraction note (M4): this code was the repository's private
/// `_encodeFrequency`/`_decodeFrequency`; the repository now delegates, so there
/// is one implementation of D-R8's rules.
/// A frequency as the two (three, for a one-shot) columns that hold it.
typedef StoredFrequency = ({
  String code,
  int? intervalDays,
  String? occurrenceDate,
});

/// Weekday written for a `weekly` row.
///
/// `isDue` never consults it (a weekly item is suppressed for the rest of the
/// ISO week it is settled in, whatever the day), so the stored value exists to
/// keep a hand-written row legible.
const int weeklyStoredDayOfWeek = 1;

/// Fallback length for an unreadable `interval_days`.
///
/// `0` would make the reminder due on every check — a pill that is always red,
/// which the parent cannot connect to a column they never edited.
const int defaultIntervalDays = 7;

/// The frequency as stored columns: the code plus **its** parameter, in the
/// column belonging to that code (`interval_days` for `every_n_days`,
/// `frequency_date` for `one_time`).
///
/// Lossless by construction — the reason the one-shot's column landed in the same
/// v14 batch as the codec instead of after it: an encoder that could not write the
/// date would have had to drop it or refuse the reminder, and both are silent data
/// changes.
StoredFrequency encodeFrequency(ReminderFrequency frequency) => frequency.map(
      daily: (_) =>
          (code: db_const.freqDaily, intervalDays: null, occurrenceDate: null),
      weekly: (_) =>
          (code: db_const.freqWeekly, intervalDays: null, occurrenceDate: null),
      // The day of the month is deliberately not stored: a monthly reminder
      // follows the **active baby's** birth day, re-derived whenever the list is
      // built — the same choice as vitamin K.
      monthly: (_) => (
        code: db_const.freqMonthly,
        intervalDays: null,
        occurrenceDate: null
      ),
      customInterval: (f) => (
        code: db_const.freqEveryNDays,
        intervalDays: f.days,
        occurrenceDate: null
      ),
      oneTime: (f) => (
        code: db_const.freqOneTime,
        intervalDays: null,
        // A dateless one-shot is D-R8's *read* shape only; nothing writes one
        // (the picker requires a date), so the column keeps its invariant:
        // `one_time` in the database always has a date.
        occurrenceDate: f.date == null ? null : formatCalendarDate(f.date!),
      ),
    );

/// Tolerant decode of a stored code.
///
/// An unknown code — hand-edited JSON, or a version older than the file being
/// read — becomes a **daily** reminder rather than nothing: a reminder that
/// disappears cannot be corrected, while one that is too loud can.
///
/// D-R8's order, which is the difference between "one month after the birth" and
/// "due at birth" for the Vitamin K preset: [occurrenceDate] is consulted **only**
/// for `one_time`. A null date on a row whose code is null means "no override",
/// never "due now".
ReminderFrequency decodeFrequency(
  String code,
  int? intervalDays, {
  String? occurrenceDate,
}) {
  if (code == db_const.freqWeekly) {
    return const ReminderFrequency.weekly(dayOfWeek: weeklyStoredDayOfWeek);
  }
  if (code == db_const.freqMonthly) {
    return const ReminderFrequency.monthly(
      dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
    );
  }
  if (code == db_const.freqOneTime) {
    // A `one_time` whose date is missing or unparseable decodes to a one-shot
    // that is **due now**, not to a daily reminder and not to nothing. The
    // importer refuses such a file outright, so the only way here is a
    // hand-edited backup — and there "ask the parent now" beats "silently off,
    // or silently monthly".
    return ReminderFrequency.oneTime(date: parseCalendarDate(occurrenceDate));
  }
  if (code == db_const.freqEveryNDays) {
    // A negative or zero value would leave the reminder permanently outstanding.
    final days = intervalDays == null || intervalDays < 1
        ? defaultIntervalDays
        : intervalDays;
    return ReminderFrequency.customInterval(days: days);
  }
  return const ReminderFrequency.daily();
}
