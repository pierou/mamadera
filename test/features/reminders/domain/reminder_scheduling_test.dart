import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/services/reminder_end.dart';
import 'package:mamadera/features/reminders/domain/services/reminder_scheduling.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Fixed preferred time of day for the matrix (D1 default shape).
const int _h = 8;
const int _m = 0;

/// The 24 h dismissal window, mirroring RemindersService.dismissalWindow.
const Duration _window = Duration(hours: 24);

/// An item carrying [endsAt] directly: from B33 the end reaches `nextDueAt` on the
/// item, resolved by `effectiveItemsForScope` — this file therefore tests the
/// scheduling consequence of an end, and `reminder_end_test.dart` tests the
/// resolution of the stored columns into one (`end_date` / `end_age_months` +
/// birthdate).
ReminderItem _item(
  ReminderFrequency frequency, {
  String id = 'test',
  DateTime? endsAt,
}) =>
    ReminderItem(
      id: id,
      labelKey: 'unused',
      frequency: frequency,
      trackingType: TrackingType.sante,
      subtypeValue: 'vitamine_d',
      endsAt: endsAt,
    );

/// The §3.4 test matrix: every row is a test, all instants fixed, no
/// DateTime.now() anywhere. 2026-07-15 is a Wednesday.
void main() {
  group('nextDueAt — Daily', () {
    test('never completed, preferred time still ahead: fires at T today', () {
      final now = DateTime(2026, 7, 15, 7, 0);
      expect(
        nextDueAt(_item(Daily()),
            now: now,
            dismissalWindow: _window,
            preferredHour: _h,
            preferredMinute: _m),
        DateTime(2026, 7, 15, 8, 0),
      );
    });

    test('never completed, T already passed: due now (D3 catch-up)', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      expect(
        nextDueAt(_item(Daily()),
            now: now,
            dismissalWindow: _window,
            preferredHour: _h,
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

  // B30: the hour the function is handed is now resolved **per item** by the
  // scheduler, so this pair is the seam that makes "a 06:15 reminder under a
  // 20:30 global" fire on its own schedule. `nextDueAt` itself is unchanged
  // (D-R3) — it simply receives a different `preferredHour`.
  group('nextDueAt — the hour is a parameter, not a constant (B30)', () {
    test('the same daily item is due at the hour it is given', () {
      final now = DateTime(2026, 7, 15, 5, 0);
      // `!` from here on: a never-completed recurring item always has a next
      // instant. `null` is B33's new answer for an item that can *no longer* be due,
      // asserted where that claim belongs.
      DateTime due(int hour) => nextDueAt(_item(Daily()),
          now: now,
          dismissalWindow: _window,
          preferredHour: hour,
          preferredMinute: 15)!;

      expect(due(6), DateTime(2026, 7, 15, 6, 15));
      expect(due(20), DateTime(2026, 7, 15, 20, 15));
    });

    test('an early item is already overdue where a late one is not', () {
      // 07:00: the 06:15 item has passed its time (⇒ D3 catch-up, `now`), the
      // 20:30 item is still ahead.
      final now = DateTime(2026, 7, 15, 7, 0);
      expect(
        nextDueAt(_item(Daily()),
            now: now,
            dismissalWindow: _window,
            preferredHour: 6,
            preferredMinute: 15),
        now,
        reason: 'the early item is due: the scheduler will nudge it',
      );
      expect(
        nextDueAt(_item(Daily()),
            now: now,
            dismissalWindow: _window,
            preferredHour: 20,
            preferredMinute: 30),
        DateTime(2026, 7, 15, 20, 30),
      );
    });
  });

  group('nextDueAt — Weekly', () {
    test('never done, target weekday not yet reached', () {
      final now = DateTime(2026, 7, 15, 7, 0); // Wednesday
      expect(
        nextDueAt(_item(Weekly(dayOfWeek: 5)),
            now: now,
            dismissalWindow: _window,
            preferredHour: _h,
            preferredMinute: _m),
        DateTime(2026, 7, 17, 8, 0), // Friday
      );
    });

    test('never done, target weekday T already passed: due now', () {
      final now = DateTime(2026, 7, 15, 9, 0); // Wednesday, T=08:00 passed
      expect(
        nextDueAt(_item(Weekly(dayOfWeek: 3)),
            now: now,
            dismissalWindow: _window,
            preferredHour: _h,
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
            now: now,
            dismissalWindow: _window,
            preferredHour: _h,
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

    test('done on the 31st with dayOfMonth 15: fires next month the 15th', () {
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
            now: now,
            dismissalWindow: _window,
            preferredHour: _h,
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

    test(
        'spring-forward T inside the skipped hour: next valid instant, '
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
      )!; // a daily item never completed always has an instant (B33's null is
      // for an item that can *no longer* be due)
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

    test('fall-back T on the repeated hour: fires once, deterministically', () {
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
      )!; // B33: recurring and never completed ⇒ always schedulable
      final second = nextDueAt(
        _item(Daily()),
        now: now,
        dismissalWindow: _window,
        preferredHour: 1,
        preferredMinute: 30,
      )!; // B33: recurring and never completed ⇒ always schedulable
      expect(first.hour, 1);
      expect(first.minute, 30);
      expect(first, equals(second),
          reason: 'the pure function must return one instant, not two');
    });
  });

  // B33 Part 1: `nextDueAt` gained a second answer. `null` means "this item can
  // no longer be due" — a settled one-shot (D-R7) or a series past its end
  // (D-R5) — and the scheduler turns it into a plan removal, which is how the OS
  // notification actually disappears.
  group('OneTime — the single occurrence', () {
    test('schedules one notification on its own day at the hour it is given',
        () {
      final now = DateTime(2026, 7, 10, 9, 0);
      expect(
        nextDueAt(
          _item(OneTime(date: DateTime(2026, 12, 15))),
          now: now,
          dismissalWindow: _window,
          preferredHour: 21,
          preferredMinute: 30,
        ),
        DateTime(2026, 12, 15, 21, 30),
      );
    });

    test('a future one-shot is not due now', () {
      final now = DateTime(2026, 7, 10, 9, 0);
      final due = nextDueAt(
        _item(OneTime(date: DateTime(2026, 12, 15))),
        now: now,
        dismissalWindow: _window,
        preferredHour: _h,
        preferredMinute: _m,
      );
      expect(due!.isAfter(now), isTrue);
    });

    test('a passed one-shot is due now, and stays so (D-R7 catch-up)', () {
      final now = DateTime(2026, 12, 20, 9, 0);
      expect(
        nextDueAt(
          _item(OneTime(date: DateTime(2026, 12, 15))),
          now: now,
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        now,
        reason: 'a missed dose must ask again, not expire quietly',
      );
    });

    test('a completed one-shot has no next instant — at all (D-R7)', () {
      final result = nextDueAt(
        _item(OneTime(date: DateTime(2026, 12, 15))),
        now: DateTime(2026, 12, 16, 9, 0),
        dismissalWindow: _window,
        preferredHour: _h,
        preferredMinute: _m,
        lastCompleted: DateTime(2026, 12, 15, 10, 0),
      );
      expect(result, isNull,
          reason: 'the plan must drop it; the diff cancels the OS entry');
    });

    test('a dateless one-shot (D-R8) is due now', () {
      final now = DateTime(2026, 5, 5, 12, 0);
      expect(
        nextDueAt(
          _item(const OneTime(date: null)),
          now: now,
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
        ),
        now,
      );
    });

    test('a dismissed one-shot waits for the window, not for a next period',
        () {
      // There is no next occurrence to advance to, so "advance" can only mean
      // "let go of the snooze" — the loop must terminate on the second pass.
      final now = DateTime(2026, 12, 15, 9, 0);
      final dismissed = DateTime(2026, 12, 15, 8, 0);
      final due = nextDueAt(
        _item(OneTime(date: DateTime(2026, 12, 15))),
        now: now,
        dismissalWindow: const Duration(hours: 24),
        preferredHour: _h,
        preferredMinute: _m,
        lastDismissal: dismissed,
      );
      expect(due, dismissed.add(const Duration(hours: 24)));
    });
  });

  group('Series end (D-R5)', () {
    test('an occurrence on the end day itself still fires (inclusive)', () {
      final now = DateTime(2026, 7, 15, 6, 0);
      expect(
        nextDueAt(
          _item(Daily(), endsAt: DateTime(2026, 7, 15)),
          now: now,
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
          lastCompleted: DateTime(2026, 7, 14, 8, 0),
        ),
        DateTime(2026, 7, 15, 8, 0),
      );
    });

    test('the first occurrence after the end day does not exist', () {
      final now = DateTime(2026, 7, 15, 6, 0);
      expect(
        nextDueAt(
          _item(Daily(), endsAt: DateTime(2026, 7, 14)),
          now: now,
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
          lastCompleted: DateTime(2026, 7, 14, 8, 0),
        ),
        isNull,
        reason: 'the series ended yesterday: no notification, ever again',
      );
    });

    test('a monthly cycle that would next fall past the end returns null', () {
      expect(
        nextDueAt(
          _item(Monthly(dayOfMonth: 20), endsAt: DateTime(2026, 7, 10)),
          now: DateTime(2026, 6, 25, 9, 0),
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
          lastCompleted: DateTime(2026, 6, 25, 6, 0),
        ),
        isNull,
        reason: 'its next occurrence (20 July) is after 10 July',
      );
    });

    test('an age-end is resolved against the birthdate given here and now', () {
      // The same stored row, two birthdates: correcting a birthdate moves the
      // schedule on the next sync because nothing about the end is stored as a
      // date (D-R5's read-time resolution).
      DateTime? dueFor(DateTime birthDate) => nextDueAt(
            // Resolved the way `effectiveItemsForScope` resolves it — the row
            // stores "1 month", the date is computed here, from this birthdate.
            _item(Daily(),
                endsAt: reminderEndFor(endAgeMonths: 1, birthDate: birthDate)),
            now: DateTime(2026, 3, 1, 9, 0),
            dismissalWindow: _window,
            preferredHour: _h,
            preferredMinute: _m,
            lastCompleted: DateTime(2026, 2, 28, 8, 0),
          );

      // Born 15 January ⇒ one month old on 15 February ⇒ already ended.
      expect(dueFor(DateTime(2026, 1, 15)), isNull);
      // Born 15 February ⇒ one month old on 15 March ⇒ still two weeks to run,
      // and today's 08:00 has already gone by ⇒ due now (the standing D3
      // catch-up, unchanged by the end model).
      expect(dueFor(DateTime(2026, 2, 15)), DateTime(2026, 3, 1, 9, 0));
    });

    test('a malformed stored end reads as no end, not as an immediate stop',
        () {
      // The seam where the lax read happens: `reminderEndFor` answers null for a
      // value that is not a date, and an item resolved from it keeps its whole
      // schedule. A hand-edited backup must not silently end a series.
      final now = DateTime(2026, 7, 15, 6, 0);
      expect(reminderEndFor(endDate: '15/07/2026'), isNull);
      expect(
        nextDueAt(
          _item(Daily(), endsAt: reminderEndFor(endDate: '15/07/2026')),
          now: now,
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
          lastCompleted: DateTime(2026, 7, 14, 8, 0),
        ),
        DateTime(2026, 7, 15, 8, 0),
      );
    });

    test('no stored end behaves exactly as before', () {
      final now = DateTime(2026, 7, 15, 6, 0);
      expect(
        nextDueAt(
          _item(Daily()),
          now: now,
          dismissalWindow: _window,
          preferredHour: _h,
          preferredMinute: _m,
          lastCompleted: DateTime(2026, 7, 14, 8, 0),
        ),
        DateTime(2026, 7, 15, 8, 0),
      );
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

    test('profile: four items, vitamin K one-shot clamped off a 31 January',
        () {
      final profile = BabyProfile(
          id: 'baby-1', name: 'Léa', birthDate: DateTime(2026, 1, 31));
      final items = reminderItemsFor(profile);
      expect(
        items.map((i) => i.id),
        orderedEquals(
            ['vitamine_d', 'vitamine_k', 'eye_cleaning', 'face_cleaning']),
      );
      // The parity this file exists for: whatever the UI shows as vitamin K's
      // rhythm is what the scheduler schedules — now a clamped one-shot
      // (2026 has no 31 February), not a monthly cycle.
      expect(items[1].frequency, OneTime(date: DateTime(2026, 2, 28)));
      expect(items[0].frequency, Daily());
    });

    test(
        'profile with a mid-month birth day: vitamin K one-shot at that day '
        'next month', () {
      final profile = BabyProfile(
          id: 'baby-2', name: 'Noah', birthDate: DateTime(2026, 2, 10));
      expect(reminderItemsFor(profile)[1].frequency,
          OneTime(date: DateTime(2026, 3, 10)));
    });
  });
}
