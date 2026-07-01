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
    test('is due when no last completed date', () {
      final weekly = const Weekly(1); // Monday
      expect(weekly.isDue(DateTime(2025, 1, 6), null), isTrue);
    });

    test('is not due on same day within week', () {
      final weekly = const Weekly(1); // Monday
      final now = DateTime(2025, 3, 17); // Monday Mar 17
      expect(weekly.isDue(now, DateTime(2025, 3, 17)), isFalse);
    });

    test('is due on different week', () {
      final weekly = const Weekly(1); // Monday
      final now = DateTime(2025, 3, 24); // Mon Mar 24 (next week)
      expect(weekly.isDue(now, DateTime(2025, 3, 17)), isTrue);
    });
  });

  group('Monthly', () {
    test('is due when no last completed date', () {
      final monthly = const Monthly(15);
      expect(monthly.isDue(DateTime(2025, 3, 15), null), isTrue);
    });

    test('is not due within same month', () {
      final monthly = const Monthly(15);
      expect(monthly.isDue(DateTime(2025, 3, 20), DateTime(2025, 3, 15)), isFalse);
    });

    test('is due in new month', () {
      final monthly = const Monthly(15);
      expect(monthly.isDue(DateTime(2025, 4, 1), DateTime(2025, 3, 15)), isTrue);
    });

    test('is due when year changes', () {
      final monthly = const Monthly(1);
      expect(monthly.isDue(DateTime(2026, 1, 1), DateTime(2025, 12, 31)), isTrue);
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
      expect(const Weekly(1), isA<ReminderFrequency>());
      expect(const Monthly(15), isA<ReminderFrequency>());
      expect(const CustomInterval(days: 7), isA<ReminderFrequency>());
    });

    test('exhaustive switch over all frequency types', () {
      final frequencies = [
        const Daily(),
        const Weekly(3),
        const Monthly(10),
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
