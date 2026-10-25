import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/services/reminder_scheduling.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Fixed preferred time of day for the matrix (D1 default shape).
const int _h = 8;
const int _m = 0;

/// The 24 h dismissal window, mirroring RemindersService.dismissalWindow.
const Duration _window = Duration(hours: 24);

ReminderItem _item(ReminderFrequency frequency, {String id = 'test'}) =>
    ReminderItem(
      id: id,
      labelKey: 'unused',
      frequency: frequency,
      trackingType: TrackingType.sante,
      subtypeValue: 'vitamine_d',
    );

/// The §3.4 test matrix: every row is a test, all instants fixed, no
/// DateTime.now() anywhere. 2026-07-15 is a Wednesday.
void main() {
  group('nextDueAt — Daily', () {
    test('never completed, preferred time still ahead: fires at T today', () {
      final now = DateTime(2026, 7, 15, 7, 0);
      expect(
        nextDueAt(_item(Daily()),
            now: now, dismissalWindow: _window, preferredHour: _h,
            preferredMinute: _m),
        DateTime(2026, 7, 15, 8, 0),
      );
    });

    test('never completed, T already passed: due now (D3 catch-up)', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(_item(Daily()),
            now: now, dismissalWindow: _window, preferredHour: _h,
            preferredMinute: _m),
        now,
      );
    });

    test('completed today: suppressed until end of today, fires tomorrow T',
        () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(Daily()),
          now: now,
          lastCompleted: DateTime(2026, 7, 15, 6, 0),
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 7, 16, 8, 0),
      );
    });

    test('snoozed yesterday, window still open: fires tomorrow T', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(Daily()),
          now: now,
          lastDismissal: DateTime(2026, 7, 14, 10, 0), // open until 15th 10:00
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 7, 16, 8, 0),
      );
    });

    test('snoozed 25 h ago, window closed: due now (catch-up)', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(Daily()),
          now: now,
          lastDismissal: DateTime(2026, 7, 14, 8, 0), // closed at 15th 08:00
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        now,
      );
    });

    test(
        'completed today AND snoozed late today: the snooze window wins '
        'across multiple day advances (bounded loop)', () {
      final now = DateTime(2026, 7, 15, 22, 0);
      expect(
        nextDueAt(
          _item(Daily()),
          now: now,
          lastCompleted: DateTime(2026, 7, 15, 6, 0),
          lastDismissal: DateTime(2026, 7, 15, 20, 0), // open until 16th 20:00
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 7, 17, 8, 0),
      );
    });
  });

  group('nextDueAt — Weekly', () {
    test('never done, target weekday not yet reached', () {
      final now = DateTime(2026, 7, 15, 7, 0); // Wednesday
      expect(
        nextDueAt(_item(Weekly(dayOfWeek: 5)),
            now: now, dismissalWindow: _window, preferredHour: _h,
            preferredMinute: _m),
        DateTime(2026, 7, 17, 8, 0), // Friday
      );
    });

    test('never done, target weekday T already passed: due now', () {
      final now = DateTime(2026, 7, 15, 9, 0); // Wednesday, T=08:00 passed
      expect(
        nextDueAt(_item(Weekly(dayOfWeek: 3)),
            now: now, dismissalWindow: _window, preferredHour: _h,
            preferredMinute: _m),
        now,
      );
    });

    test('done this week: fires next week target', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(Weekly(dayOfWeek: 3)),
          now: now,
          lastCompleted: DateTime(2026, 7, 13, 10, 0), // Monday of this week
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 7, 22, 8, 0),
      );
    });

    test('a completion on Sunday belongs to that week\'s Monday index', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(Weekly(dayOfWeek: 3)),
          now: now,
          // Sunday 12th: the week 13th–19th is due; Wednesday T already
          // passed ⇒ catch-up now, NOT next week (which the wrong week-key
          // would produce).
          lastCompleted: DateTime(2026, 7, 12, 23, 0),
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        now,
      );
    });
  });

  group('nextDueAt — Monthly', () {
    test('never done, clamped day (31 in February ⇒ 28)', () {
      final now = DateTime(2026, 2, 10, 9, 0);
      expect(
        nextDueAt(_item(Monthly(dayOfMonth: 31)),
            now: now, dismissalWindow: _window, preferredHour: _h,
            preferredMinute: _m),
        DateTime(2026, 2, 28, 8, 0),
      );
    });

    test('done this month: fires next month clamped day', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(Monthly(dayOfMonth: 15)),
          now: now,
          lastCompleted: DateTime(2026, 7, 15, 6, 0),
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 8, 15, 8, 0),
      );
    });

    test('done on the 31st with dayOfMonth 15: fires next month the 15th',
        () {
      final now = DateTime(2026, 6, 10, 9, 0);
      expect(
        nextDueAt(
          _item(Monthly(dayOfMonth: 15)),
          now: now,
          lastCompleted: DateTime(2026, 5, 31, 6, 0),
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 6, 15, 8, 0),
      );
    });
  });

  group('nextDueAt — CustomInterval (7 days)', () {
    test('never done: due now (catch-up)', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(_item(CustomInterval(days: 7)),
            now: now, dismissalWindow: _window, preferredHour: _h,
            preferredMinute: _m),
        now,
      );
    });

    test('never done but snoozed: fires when the window closes, like the pill',
        () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(CustomInterval(days: 7)),
          now: now,
          lastDismissal: DateTime(2026, 7, 14, 10, 0), // open until 15th 10:00
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 7, 15, 10, 0),
      );
    });

    test('done n-1 days ago: fires tomorrow T (boundary not reached)', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(CustomInterval(days: 7)),
          now: now,
          lastCompleted: DateTime(2026, 7, 9, 10, 0), // 6 days ago
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 7, 16, 8, 0),
      );
    });

    test('done n days ago, T still ahead: fires today T', () {
      final now = DateTime(2026, 7, 15, 7, 0);
      expect(
        nextDueAt(
          _item(CustomInterval(days: 7)),
          now: now,
          lastCompleted: DateTime(2026, 7, 8, 10, 0), // boundary today
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        DateTime(2026, 7, 15, 8, 0),
      );
    });

    test('done n days ago at a later time than T: due now (catch-up)', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(
          _item(CustomInterval(days: 7)),
          now: now,
          lastCompleted: DateTime(2026, 7, 8, 10, 0),
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        now,
      );
    });
  });

  group('nextDueAt — DST (host zones without DST skip these rows)', () {
    /// First 2026 day on which the host zone's offset [increases] (spring
    /// forward) or [decreases] (fall back); null when the host zone has no
    /// DST (e.g. UTC CI runners).
    int? transitionDay(bool spring) {
      for (var day = 1; day < 366; day++) {
        final diff = DateTime(2026, 1, day + 1).timeZoneOffset -
            DateTime(2026, 1, day).timeZoneOffset;
        if (spring && diff > Duration.zero) return day;
        if (!spring && diff < Duration.zero) return day;
      }
      return null;
    }

    test('spring-forward T inside the skipped hour: next valid instant, '
        'no crash, drift ≤ 1 h', () {
      final day = transitionDay(true);
      if (day == null) return; // host zone has no DST
      // 02:30 is the skipped instant in the zones this estate targets
      // (Europe/Paris, America/*): the constructor must normalise, not throw.
      // now at 01:00 — the last certain hour of the old offset — so T
      // (02:30, inside the skipped 02:00–03:00 hour) is still ahead and the
      // test exercises the normalisation, not the catch-up branch.
      final now = DateTime(2026, 1, day + 1, 1, 0);
      final result = nextDueAt(
        _item(Daily()),
        now: now,
        dismissalWindow: _window,
        preferredHour: 2,
        preferredMinute: 30,
      );
      final reference = DateTime(2026, 1, day + 1, 3, 30);
      expect(result.minute, 30);
      expect(
        result.difference(reference).inMinutes.abs() <= 60,
        isTrue,
        reason: 'result=$result reference=$reference',
      );
      // And it must not be "due now": a future, normalised instant.
      expect(result.isAfter(now), isTrue);
    });

    test('fall-back T on the repeated hour: fires once, deterministically',
        () {
      final day = transitionDay(false);
      if (day == null) return; // host zone has no DST
      // now at 01:00 on the repeated hour (first occurrence), so T at 01:30
      // is ahead and the test exercises the ambiguity resolution, not the
      // catch-up branch.
      final now = DateTime(2026, 1, day + 1, 1, 0);
      final first = nextDueAt(
        _item(Daily()),
        now: now,
        dismissalWindow: _window,
        preferredHour: 1,
        preferredMinute: 30,
      );
      final second = nextDueAt(
        _item(Daily()),
        now: now,
        dismissalWindow: _window,
        preferredHour: 1,
        preferredMinute: 30,
      );
      expect(first.hour, 1);
      expect(first.minute, 30);
      expect(first, equals(second),
          reason: 'the pure function must return one instant, not two');
    });
  });

  group('reminderItemsFor — shared item set (UI ⇔ scheduler parity)', () {
    test('null profile: the two base items (Vitamin K on the 30-day cycle)',
        () {
      final items = reminderItemsFor(null);
      expect(
          items.map((i) => i.id), orderedEquals(['vitamine_d', 'vitamine_k']));
      expect(items[1].frequency, CustomInterval(days: 30));
      expect(items[1], ReminderItemPresets.vitaminK);
    });

    test('profile: four items, vitamin K monthly on the birth day', () {
      final profile = BabyProfile(
          id: 'baby-1', name: 'Léa', birthDate: DateTime(2026, 1, 31));
      final items = reminderItemsFor(profile);
      expect(
        items.map((i) => i.id),
        orderedEquals(
            ['vitamine_d', 'vitamine_k', 'eye_cleaning', 'face_cleaning']),
      );
      expect(items[1].frequency, Monthly(dayOfMonth: 31));
      expect(items[0].frequency, Daily());
    });

    test('profile with a mid-month birth day: vitamin K monthly on that day',
        () {
      final profile = BabyProfile(
          id: 'baby-2', name: 'Noah', birthDate: DateTime(2026, 2, 10));
      expect(reminderItemsFor(profile)[1].frequency, Monthly(dayOfMonth: 10));
    });
  });
}
