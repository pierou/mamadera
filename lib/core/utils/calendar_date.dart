/// A stored calendar date — `'yyyy-MM-dd'`, no time of day — in one place.
///
/// Introduced by v1.4.0 M3 for B33's date columns (`frequency_date`, `end_date`)
/// because neither of the obvious shortcuts is safe here:
///
/// - `DateTime.tryParse('2026-12-15')` succeeds and returns **UTC** midnight.
///   Compared against a device-local `now`, that is 01:00 the same day east of
///   Greenwich and **19:00 the day before** west of it — a reminder would end a
///   day early for one parent and a day late for another, silently.
/// - `DateTime.parse` throws on the malformed values the domain is designed to
///   survive.
///
/// So [parseCalendarDate] builds a **local** midnight from fields it validates,
/// and rejects anything that is not a real date on the calendar.
library;

/// Parses `'yyyy-MM-dd'` into a **local** midnight.
///
/// Returns `null` for a null/blank string, a wrong shape, a non-numeric part, or
/// a date that does not exist (`2026-02-30`, month 13, year 0). Read lax on
/// purpose where a stored value can only have come from a hand-edited backup:
/// the caller then behaves as if the field were absent, which is the softer
/// outcome — the reminder keeps running rather than vanishing. Writers validate
/// before storing (write-strict).
DateTime? parseCalendarDate(String? stored) {
  if (stored == null) return null;
  final text = stored.trim();
  if (text.length != 10 || text[4] != '-' || text[7] != '-') return null;
  final year = int.tryParse(text.substring(0, 4));
  final month = int.tryParse(text.substring(5, 7));
  final day = int.tryParse(text.substring(8, 10));
  if (year == null || month == null || day == null) return null;
  if (year < 1 || month < 1 || month > 12 || day < 1) return null;
  // Round trip: Dart normalises out-of-range days, so 30 February becomes
  // 2 March — which would sail through the checks above. Only the date that
  // comes back with the same fields is a real date.
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

/// The `'yyyy-MM-dd'` form of [date]'s calendar day (zero padded). Built from
/// the **local** fields, never from the instant, so a device west of Greenwich
/// does not write the day before.
String formatCalendarDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}
