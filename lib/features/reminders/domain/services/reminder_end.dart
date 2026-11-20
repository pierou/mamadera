import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/date_arithmetic.dart';

/// Which of D-R5's three end forms a row carries, and what the picker must
/// therefore show.
///
/// A row can hold at most one end (D-R5's mutual exclusivity, enforced at write
/// and at import — *not* by the schema, which just has three nullable columns).
/// This is the read side of that rule, and it is deliberately not a boolean
/// soup: a row that somehow holds two ends has to resolve to **one** answer,
/// because "the reminder stops when…" cannot mean two things at once.
enum ReminderEndKind {
  /// No end: the series runs until the parent stops it (today's behaviour).
  none,

  /// `end_date`: an inclusive calendar date.
  date,

  /// `end_age_months`: the baby's age in whole months, resolved at read time.
  age,
}

/// The row's stored `end_date` (`'yyyy-MM-dd'`), resolved for display.
///
/// Lax: an unparseable stored date reads as absent, which is the softer outcome
/// for a value that can only have arrived from a hand-edited backup — the
/// reminder keeps running rather than vanishing.
DateTime? reminderEndDate(String? storedEndDate) =>
    parseCalendarDate(storedEndDate);

/// The date a reminder's series ends, or `null` when it never does (D-R5/D-R2).
///
/// Resolution order — [ReminderEndKind.date] first, because an explicit date is
/// the more recent, more specific intent, and a row that carries both (which the
/// writer must never produce) should honour the date the parent typed rather
/// than a leftover age:
///
/// 1. `endDate` → that calendar day (inclusive: the day itself still fires, see `isPastSeriesEnd`);
/// 2. `endAgeMonths` **and** a known [birthDate] → `birthdate + n months` with
///    B18's clamped anniversary ([addMonthsClamped]) — resolved **here, at read
///    time**, which is what makes a corrected birthdate move the end with no
///    stored value to go stale;
/// 3. anything else → no end.
///
/// Case 3 includes the one the plan calls out: an age without a birthdate. The
/// legacy profileless (`''`) scope has no birthdate, so "until an age" is
/// disabled in the picker there (D-R10) — and if such a row arrives anyway, the
/// reminder simply does not end, rather than ending on a guessed day.
DateTime? reminderEndFor({
  String? endDate,
  int? endAgeMonths,
  DateTime? birthDate,
}) {
  final explicit = reminderEndDate(endDate);
  if (explicit != null) return explicit;
  final months = endAgeMonths;
  if (months == null || birthDate == null) return null;
  // The canonical range the picker writes (0–180 months). Out of range reads as
  // "no end": a negative age would end the series in the past for no reason a
  // parent chose, and 181+ months is not an infant's age.
  if (months < 0 || months > maxReminderEndAgeMonths) return null;
  return addMonthsClamped(birthDate, months);
}

/// Upper bound of the canonical `end_age_months` range (15 years — D-R5).
const int maxReminderEndAgeMonths = 180;

/// The end form a row expresses, for the picker's selection.
ReminderEndKind reminderEndKindOf({
  String? endDate,
  int? endAgeMonths,
}) {
  if (reminderEndDate(endDate) != null) return ReminderEndKind.date;
  if (endAgeMonths != null) return ReminderEndKind.age;
  return ReminderEndKind.none;
}
