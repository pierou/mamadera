import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/utils/calendar_date.dart';
import 'package:mamadera/core/utils/date_arithmetic.dart';

/// B18's month arithmetic and the `'yyyy-MM-dd'` storage form, tested directly
/// since v1.4.0 M3 extracted them (`addMonthsClamped` used to be a private
/// helper inside `baby_profile_section.dart`, where only the age label
/// exercised it).
///
/// The reminder end model (`reminderEndFor`) resolves "until an age" through
/// [addMonthsClamped], so a clamp bug here is a reminder firing on the wrong
/// day — these are not cosmetic rows.
void main() {
  group('addMonthsClamped', () {
    test('shifts a plain date by whole months', () {
      expect(addMonthsClamped(DateTime(2026, 1, 10), 1), DateTime(2026, 2, 10));
      expect(
          addMonthsClamped(DateTime(2026, 1, 10), 12), DateTime(2027, 1, 10));
    });

    test('clamps 31 January + 1 month to the last day of February', () {
      // 2026 is not a leap year, 2024 is: the clamp must follow the calendar,
      // not a hard-coded 28.
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonthsClamped(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    });

    test('never lands on a day that does not exist, at any month count', () {
      for (var months = 0; months <= 36; months++) {
        final moved = addMonthsClamped(DateTime(2026, 1, 31), months);
        final lastDay = DateTime(moved.year, moved.month + 1, 0).day;
        expect(moved.day, lessThanOrEqualTo(lastDay),
            reason: '$months months after 31 Jan gave the impossible '
                '$moved');
      }
    });

    test('crosses a year boundary with zero months unchanged', () {
      expect(
          addMonthsClamped(DateTime(2026, 12, 31), 0), DateTime(2026, 12, 31));
      expect(
          addMonthsClamped(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 31));
    });
  });

  group('wholeMonthsOld (B18 anniversary rule)', () {
    test('a month counts on the clamped anniversary, not before', () {
      final born = DateTime(2026, 1, 31);
      expect(wholeMonthsOld(born, DateTime(2026, 2, 27)), 0);
      expect(wholeMonthsOld(born, DateTime(2026, 2, 28)), 1,
          reason: '28 February is the anniversary of a 31 January birthday');
    });

    test('a March read of a 31 January birthday is 1 month, not 2', () {
      expect(wholeMonthsOld(DateTime(2026, 1, 31), DateTime(2026, 3, 1)), 1);
    });

    test('years are counted in months, and a future birthdate is 0', () {
      expect(wholeMonthsOld(DateTime(2024, 6, 1), DateTime(2026, 5, 31)), 23);
      expect(wholeMonthsOld(DateTime(2024, 6, 1), DateTime(2026, 6, 1)), 24);
      expect(wholeMonthsOld(DateTime(2027, 1, 1), DateTime(2026, 6, 1)), 0);
    });
  });

  group('parseCalendarDate', () {
    test('reads a real date as local midnight', () {
      final parsed = parseCalendarDate('2026-12-15');
      expect(parsed, DateTime(2026, 12, 15));
      // Local, never UTC: `DateTime.tryParse` on this same string answers UTC,
      // which is a day off the moment the device sits west of Greenwich.
      expect(parsed!.isUtc, isFalse);
      expect(parsed.hour, 0);
    });

    test('rejects a date that does not exist', () {
      expect(parseCalendarDate('2026-02-30'), isNull,
          reason: 'Dart would normalise this to 2 March and call it valid');
      expect(parseCalendarDate('2026-13-01'), isNull);
      expect(parseCalendarDate('2026-00-10'), isNull);
      expect(parseCalendarDate('2026-04-31'), isNull);
    });

    test('rejects a wrong shape rather than guessing', () {
      expect(parseCalendarDate(null), isNull);
      expect(parseCalendarDate(''), isNull);
      expect(parseCalendarDate('  '), isNull);
      expect(parseCalendarDate('2026-2-1'), isNull);
      expect(parseCalendarDate('15/12/2026'), isNull);
      expect(parseCalendarDate('2026-12-15T00:00:00'), isNull,
          reason: 'a timestamp is not a stored calendar date');
      expect(parseCalendarDate('abcd-ef-gh'), isNull);
    });

    test('accepts the leap day of a leap year only', () {
      expect(parseCalendarDate('2024-02-29'), DateTime(2024, 2, 29));
      expect(parseCalendarDate('2026-02-29'), isNull);
    });
  });

  group('formatCalendarDate', () {
    test('zero pads and keeps the local fields', () {
      expect(formatCalendarDate(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(formatCalendarDate(DateTime(2026, 12, 15)), '2026-12-15');
    });

    test('round trips through parse for every day it can produce', () {
      for (final day in [
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 28),
        DateTime(2026, 12, 31),
        DateTime(2024, 2, 29),
      ]) {
        expect(parseCalendarDate(formatCalendarDate(day)), day);
      }
    });
  });
}
