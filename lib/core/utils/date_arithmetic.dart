/// Calendar month arithmetic with clamped anniversaries — B18's rule, in one
/// place.
///
/// Extracted from `baby_profile_section.dart` (where it made the age label
/// correct for a baby born on the 31st) when v1.4.0 M3 needed the same
/// arithmetic to resolve a reminder's "until an age" end into a date
/// (`docs/PLAN-v1.4.0.md` D-R5). Two implementations of a clamped anniversary is
/// how a reminder starts firing a day before the age it claims, so there is
/// exactly one: this file.
///
/// Pure Dart, no framework import — the domain layer is allowed to call it (see
/// `domain_framework_imports` in `scripts/check_architecture.py`).
library;

/// [date] shifted by [months], the day clamped to the last day of the target
/// month (31 January + 1 month = 28/29 February).
DateTime addMonthsClamped(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final firstOfNext =
      month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  final lastDay = firstOfNext.subtract(const Duration(days: 1)).day;
  return DateTime(year, month, date.day.clamp(1, lastDay));
}

/// Whole months of age at [now], anniversary-based (B18): a month counts only
/// once the clamped anniversary of that many months has been reached, so a baby
/// born on 31 January turns one month old on 28/29 February — and reads as
/// 1 month old on 1 March, not 2. A future birthdate clamps to 0 instead of
/// going negative.
int wholeMonthsOld(DateTime birthDate, DateTime now) {
  var months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
  if (months < 0) months = 0;
  if (now.isBefore(addMonthsClamped(birthDate, months))) months--;
  return months < 0 ? 0 : months;
}
