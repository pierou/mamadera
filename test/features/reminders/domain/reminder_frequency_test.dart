import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';

void main() {
  group('Daily', () {
    test('is due when no last completed date', () {
      final daily = const Daily();
      expect(daily.isDue(DateTime(2025, 1, 1), null), isTrue);
    });

    test('is not due on same day', () {
      final daily = const Daily();
      final now = DateTime(2025, 3, 15, 14, 30);
      expect(daily.isDue(now, DateTime(2025, 3, 15)), isFalse);
    });

    test('is due on different day', () {
      final daily = const Daily();
      final now = DateTime(2025, 3, 16);
      expect(daily.isDue(now, DateTime(2025, 3, 15)), isTrue);
    });

    test('is due on different month', () {
      final daily = const Daily();
      final now = DateTime(2025, 4, 1);
      expect(daily.isDue(now, DateTime(2025, 3, 31)), isTrue);
    });
  });

  group('Weekly', () {
    // 2025 ISO weeks used here (Monday-anchored):
    //   W12: Mon 17 Mar → Sun 23 Mar
    //   W13: Mon 24 Mar → Sun 30 Mar
    //   W14: Mon 31 Mar → Sun 06 Apr   (spans March/April)
    //   2025-12-29 Mon → 2026-01-04 Sun (spans 2025/2026)
    test('is due when no last completed date', () {
      final weekly = const Weekly(dayOfWeek: 1); // Monday
      expect(weekly.isDue(DateTime(2025, 1, 6), null), isTrue);
    });

    test('is not due on same day within week', () {
      final weekly = const Weekly(dayOfWeek: 1); // Monday
      final now = DateTime(2025, 3, 17); // Monday Mar 17
      expect(weekly.isDue(now, DateTime(2025, 3, 17)), isFalse);
    });

    test('is due on different week', () {
      final weekly = const Weekly(dayOfWeek: 1); // Monday
      final now = DateTime(2025, 3, 24); // Mon Mar 24 (next week)
      expect(weekly.isDue(now, DateTime(2025, 3, 17)), isTrue);
    });

    // Regression: this is the case the old implementation got wrong — it compared
    // weekdays and a rolling 7-day window, so a weekly reminder fired EVERY day.
    test('is not due on a different day of the same week', () {
      final weekly = const Weekly(dayOfWeek: 1); // Monday
      final now = DateTime(2025, 3, 19); // Wed, two days after Monday completion
      expect(weekly.isDue(now, DateTime(2025, 3, 17)), isFalse);
    });

    test('is not due at the end of the same week', () {
      final weekly = const Weekly(dayOfWeek: 1);
      final now = DateTime(2025, 3, 23); // Sunday of the Mon 17 → Sun 23 week
      expect(weekly.isDue(now, DateTime(2025, 3, 17)), isFalse);
    });

    test('is due on the first day of the next week', () {
      final weekly = const Weekly(dayOfWeek: 1);
      final now = DateTime(2025, 3, 24); // Monday of the next ISO week
      expect(weekly.isDue(now, DateTime(2025, 3, 23)), isTrue);
    });

    test('is not due mid-week across a month boundary', () {
      final weekly = const Weekly(dayOfWeek: 1);
      // Mon 31 Mar and Fri 04 Apr fall in the same ISO week (W14).
      final now = DateTime(2025, 4, 4); // Friday
      expect(weekly.isDue(now, DateTime(2025, 3, 31)), isFalse);
    });

    test('is due in the new week across a month boundary', () {
      final weekly = const Weekly(dayOfWeek: 1);
      final now = DateTime(2025, 4, 7); // Mon 07 Apr — first day of the next week
      expect(weekly.isDue(now, DateTime(2025, 3, 31)), isTrue);
    });

    test('is not due mid-week across a year boundary', () {
      final weekly = const Weekly(dayOfWeek: 1);
      // Mon 29 Dec 2025 → Sun 04 Jan 2026 is a single ISO week.
      final now = DateTime(2026, 1, 3); // Saturday
      expect(weekly.isDue(now, DateTime(2025, 12, 30)), isFalse);
    });

    test('is due in the new week across a year boundary', () {
      final weekly = const Weekly(dayOfWeek: 1);
      final now = DateTime(2026, 1, 5); // Monday — first day of the next ISO week
      expect(weekly.isDue(now, DateTime(2025, 12, 30)), isTrue);
    });

    test('is due in a new week before its configured day of week', () {
      // Documented semantics: dayOfWeek records the intended day, it does not
      // gate the check — otherwise a Wednesday completion would silence a Friday
      // reminder until the following Friday.
      final weekly = const Weekly(dayOfWeek: 5); // Friday
      final now = DateTime(2025, 3, 25); // Tue of the week after Wed 19 Mar
      expect(weekly.isDue(now, DateTime(2025, 3, 19)), isTrue);
    });

    test('is due after several weeks', () {
      final weekly = const Weekly(dayOfWeek: 3); // Wednesday
      final now = DateTime(2025, 6, 2); // Monday, many weeks later
      expect(weekly.isDue(now, DateTime(2025, 3, 19)), isTrue);
    });
  });

  group('Monthly', () {
    test('is due when no last completed date', () {
      final monthly = const Monthly(dayOfMonth: 15);
      expect(monthly.isDue(DateTime(2025, 3, 15), null), isTrue);
    });

    test('is not due within same month', () {
      final monthly = const Monthly(dayOfMonth: 15);
      expect(monthly.isDue(DateTime(2025, 3, 20), DateTime(2025, 3, 15)), isFalse);
    });

    // Regression: dayOfMonth used to be ignored entirely — any new month fired.
    test('is not due in a new month before the configured day', () {
      final monthly = const Monthly(dayOfMonth: 15);
      expect(monthly.isDue(DateTime(2025, 4, 1), DateTime(2025, 3, 15)), isFalse);
      expect(monthly.isDue(DateTime(2025, 4, 14), DateTime(2025, 3, 15)), isFalse);
    });

    test('is due in a new month on the configured day', () {
      final monthly = const Monthly(dayOfMonth: 15);
      expect(monthly.isDue(DateTime(2025, 4, 15), DateTime(2025, 3, 15)), isTrue);
    });

    test('is due in a new month after the configured day', () {
      final monthly = const Monthly(dayOfMonth: 15);
      expect(monthly.isDue(DateTime(2025, 4, 20), DateTime(2025, 3, 15)), isTrue);
    });

    test('is not due before the configured day even if last month was earlier', () {
      final monthly = const Monthly(dayOfMonth: 20);
      expect(monthly.isDue(DateTime(2025, 3, 10), DateTime(2025, 2, 20)), isFalse);
    });

    test('is due when year changes', () {
      final monthly = const Monthly(dayOfMonth: 1);
      expect(monthly.isDue(DateTime(2026, 1, 1), DateTime(2025, 12, 31)), isTrue);
    });

    test('is due across a year boundary with a late configured day', () {
      // Month index must be monotonic: 2026-01 is later than 2025-12 even though
      // `now.month` (1) is numerically smaller than `lastCompleted.month` (12).
      final monthly = const Monthly(dayOfMonth: 15);
      expect(monthly.isDue(DateTime(2026, 1, 20), DateTime(2025, 12, 20)), isTrue);
    });

    test('is not due across a year boundary before the configured day', () {
      final monthly = const Monthly(dayOfMonth: 15);
      expect(monthly.isDue(DateTime(2026, 1, 10), DateTime(2025, 12, 20)), isFalse);
    });

    test('clamps dayOfMonth 31 to a 28-day month', () {
      final monthly = const Monthly(dayOfMonth: 31);
      // February 2025 has 28 days → the 31st is scheduled on the last day.
      expect(monthly.isDue(DateTime(2025, 2, 27), DateTime(2025, 1, 31)), isFalse);
      expect(monthly.isDue(DateTime(2025, 2, 28), DateTime(2025, 1, 31)), isTrue);
    });

    test('clamps dayOfMonth 31 to a leap February', () {
      final monthly = const Monthly(dayOfMonth: 31);
      // February 2024 has 29 days.
      expect(monthly.isDue(DateTime(2024, 2, 28), DateTime(2024, 1, 31)), isFalse);
      expect(monthly.isDue(DateTime(2024, 2, 29), DateTime(2024, 1, 31)), isTrue);
    });

    test('clamps dayOfMonth 31 to a 30-day month', () {
      final monthly = const Monthly(dayOfMonth: 31);
      expect(monthly.isDue(DateTime(2025, 4, 29), DateTime(2025, 1, 31)), isFalse);
      expect(monthly.isDue(DateTime(2025, 4, 30), DateTime(2025, 1, 31)), isTrue);
    });
  });

  group('CustomInterval', () {
    test('is due when no last completed date', () {
      final custom = const CustomInterval(days: 7);
      expect(custom.isDue(DateTime(2025, 1, 1), null), isTrue);
    });

    test('is not due within interval period', () {
      final custom = const CustomInterval(days: 7);
      // Completed yesterday — less than 7 days ago
      expect(custom.isDue(DateTime(2025, 3, 16), DateTime(2025, 3, 15)), isFalse);
    });

    test('is due after interval period', () {
      final custom = const CustomInterval(days: 7);
      // Completed exactly 7 days ago
      expect(custom.isDue(DateTime(2025, 3, 22), DateTime(2025, 3, 15)), isTrue);
    });

    test('is due after interval period with custom days', () {
      final custom = const CustomInterval(days: 14);
      expect(custom.isDue(DateTime(2025, 3, 29), DateTime(2025, 3, 15)), isTrue);
    });

    test('is not due before interval period with custom days', () {
      final custom = const CustomInterval(days: 14);
      expect(custom.isDue(DateTime(2025, 3, 28), DateTime(2025, 3, 15)), isFalse);
    });
  });

  group('ReminderFrequency sealed class', () {
    test('all subclasses extend ReminderFrequency', () {
      expect(const Daily(), isA<ReminderFrequency>());
      expect(const Weekly(dayOfWeek: 1), isA<ReminderFrequency>());
      expect(const Monthly(dayOfMonth: 15), isA<ReminderFrequency>());
      expect(const CustomInterval(days: 7), isA<ReminderFrequency>());
    });

    test('exhaustive switch over all frequency types', () {
      final frequencies = [
        const Daily(),
        const Weekly(dayOfWeek: 3),
        const Monthly(dayOfMonth: 10),
        const CustomInterval(days: 5),
      ];

      for (final freq in frequencies) {
        // Exhaustive switch — Dart will error if a case is missing.
        final label = switch (freq) {
          Daily() => 'Daily',
          Weekly(:final dayOfWeek) => 'Weekly($dayOfWeek)',
          Monthly(:final dayOfMonth) => 'Monthly($dayOfMonth)',
          CustomInterval(:final days) => 'CustomInterval($days)',
        };

        expect(label, isNotEmpty);
      }
    });
  });
}
