import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/services/reminder_end.dart';

/// D-R5's end model, read side: the three forms a reminder can be ended in, and
/// the one cutoff check every frequency shares.
///
/// The boundary rows are the point of this file. "Until 15 December" means the
/// 15th still fires and the 16th does not; an off-by-one there is a reminder that
/// silently stops a day early, and nothing else in the app would notice.
void main() {
  group('reminderEndFor', () {
    test('no stored end means no end', () {
      expect(reminderEndFor(), isNull);
      expect(reminderEndFor(endDate: null, endAgeMonths: null), isNull);
    });

    test('an explicit date is the end, at local midnight', () {
      expect(reminderEndFor(endDate: '2026-12-15'), DateTime(2026, 12, 15));
    });

    test('an age resolves against the birthdate, with B18 clamping', () {
      expect(
        reminderEndFor(endAgeMonths: 6, birthDate: DateTime(2026, 1, 10)),
        DateTime(2026, 7, 10),
      );
      // 31 January + 6 months is 31 July (it exists); + 1 month is the last day
      // of February, which is exactly why the resolution is a clamp and not a
      // `Duration(days: 30 * n)`.
      expect(
        reminderEndFor(endAgeMonths: 6, birthDate: DateTime(2026, 1, 31)),
        DateTime(2026, 7, 31),
      );
      expect(
        reminderEndFor(endAgeMonths: 1, birthDate: DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        reminderEndFor(endAgeMonths: 18, birthDate: DateTime(2024, 8, 31)),
        DateTime(2026, 2, 28),
      );
    });

    test('an age of 0 ends on the birthdate itself', () {
      expect(reminderEndFor(endAgeMonths: 0, birthDate: DateTime(2026, 3, 4)),
          DateTime(2026, 3, 4));
    });

    test('an age without a birthdate ends nothing (D-R10 scope)', () {
      // The legacy profileless (`''`) scope: the picker disables this option,
      // and if such a row arrives anyway the reminder keeps running rather than
      // ending on a guessed day.
      expect(reminderEndFor(endAgeMonths: 6), isNull);
    });

    test('out-of-range ages read as no end', () {
      expect(reminderEndFor(endAgeMonths: -1, birthDate: DateTime(2026, 1, 1)),
          isNull);
      expect(
          reminderEndFor(
              endAgeMonths: maxReminderEndAgeMonths + 1,
              birthDate: DateTime(2026, 1, 1)),
          isNull);
      expect(
        reminderEndFor(
            endAgeMonths: maxReminderEndAgeMonths,
            birthDate: DateTime(2026, 1, 1)),
        DateTime(2041, 1, 1),
      );
    });

    test('a stored date that is not a date falls through to the age', () {
      // Read-lax: neither field is discarded silently — the more specific one
      // that survives is used, and the reminder still ends.
      expect(
        reminderEndFor(
            endDate: '2026-02-30',
            endAgeMonths: 3,
            birthDate: DateTime(2026, 1, 10)),
        DateTime(2026, 4, 10),
      );
    });

    test('an explicit date wins over an age when a row carries both', () {
      // The writer must never produce this (D-R5's exclusivity), but a row that
      // somehow holds two ends has to resolve to one answer: the date the parent
      // typed, not a leftover age.
      expect(
        reminderEndFor(
            endDate: '2026-05-01',
            endAgeMonths: 1,
            birthDate: DateTime(2026, 1, 10)),
        DateTime(2026, 5, 1),
      );
    });
  });

  group('reminderEndKindOf (what the picker shows)', () {
    test('maps the stored columns to the three options plus none', () {
      expect(reminderEndKindOf(), ReminderEndKind.none);
      expect(reminderEndKindOf(endDate: '2026-12-15'), ReminderEndKind.date);
      expect(reminderEndKindOf(endAgeMonths: 4), ReminderEndKind.age);
      // A garbage date is not an option the parent chose.
      expect(reminderEndKindOf(endDate: '15-12-2026'), ReminderEndKind.none);
      expect(reminderEndKindOf(endDate: '2026-12-15', endAgeMonths: 4),
          ReminderEndKind.date);
    });
  });

  group('isPastSeriesEnd — the inclusive boundary', () {
    final endsAt = DateTime(2026, 12, 15);

    test('the end day itself is still inside the series', () {
      expect(isPastSeriesEnd(DateTime(2026, 12, 15, 0, 0), endsAt), isFalse);
      expect(isPastSeriesEnd(DateTime(2026, 12, 15, 23, 59, 59, 999), endsAt),
          isFalse,
          reason: 'D-R5: the end date is inclusive, so it can still fire');
    });

    test('the first instant of the next day is past it', () {
      expect(isPastSeriesEnd(DateTime(2026, 12, 16), endsAt), isTrue);
      expect(isPastSeriesEnd(DateTime(2027, 1, 1, 8, 0), endsAt), isTrue);
    });

    test('before the end day, nothing is past', () {
      expect(isPastSeriesEnd(DateTime(2026, 12, 14, 23, 59), endsAt), isFalse);
    });

    test('no end never expires', () {
      expect(isPastSeriesEnd(DateTime(2099, 1, 1), null), isFalse);
    });

    test('seriesEndExpiry is the last millisecond of the day', () {
      final expiry = seriesEndExpiry(endsAt);
      expect(expiry.hour, 23);
      expect(expiry.minute, 59);
      expect(expiry.second, 59);
      expect(expiry.millisecond, 999);
    });
  });
}
