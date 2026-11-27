import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item_setting.dart';
import 'package:mamadera/features/reminders/domain/services/effective_reminders.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// The single place the `reminder_settings` overrides are applied (D-R2).
///
/// The defect this file exists to prevent is B31, which was not "the reminder is
/// wrong" but "the reminder is wrong **in one list**": Home projected the declared
/// presets, Settings projected the stored ones, and a cancel from Home put the
/// whole subscription back on screen. Any consumer that projects its own view of
/// the settings rows can drift from any other, so there is one function and this
/// file pins what it does to every kind of row.
/// Markers: "use the profile" / "run this without one" (D-R10), so the helper's
/// default can stay the profile without `null` meaning two different things.
///
/// Two distinct classes, not two `const Object()`s: Dart canonicalises identical
/// const constructor calls, so both markers would have been the *same* instance
/// and the "no profile" case would have silently run with one.
class _ProfileDefault {
  const _ProfileDefault();
}

class _NoProfile {
  const _NoProfile();
}

const _profileDefault = _ProfileDefault();
const _noProfile = _NoProfile();

void main() {
  group('effectiveItemsForScope (B33, D-R2)', () {
    final birth = DateTime(2026, 3, 1);
    final profile = BabyProfile(
      id: 'baby-1',
      name: 'Maya',
      birthDate: birth,
    );

    const eye = ReminderItem(
      id: 'eye_cleaning',
      labelKey: 'reminderEyeCleaning',
      frequency: ReminderFrequency.daily(),
      trackingType: TrackingType.sante,
    );

    ReminderItemSetting row({
      bool enabled = true,
      String? label,
      String? frequency,
      int? intervalDays,
      String? frequencyDate,
      String? endDate,
      int? endAgeMonths,
      bool removed = false,
    }) =>
        ReminderItemSetting(
          enabled: enabled,
          label: label,
          frequency: frequency,
          intervalDays: intervalDays,
          frequencyDate: frequencyDate,
          endDate: endDate,
          endAgeMonths: endAgeMonths,
          removed: removed,
        );

    /// [baby] defaults to the profile; pass `_noProfile` to ask the question
    /// without one (D-R10), which a plain `null` default could not express.
    List<ReminderItem> effective({
      Map<String, ReminderItemSetting> settings = const {},
      Object? baby = _profileDefault,
    }) =>
        effectiveItemsForScope(
          items: const [eye],
          settings: settings,
          profile: identical(baby, _noProfile) ? null : profile,
        );

    test('with nothing stored, a reminder comes back as it was declared', () {
      final items = effective();
      expect(items, hasLength(1));
      expect(items.single.labelOverride, isNull);
      expect(items.single.frequency, const ReminderFrequency.daily());
      expect(items.single.endsAt, isNull);
    });

    test('a nickname comes out as an override, never as the label key', () {
      // D-R6: the text has to reach `reminderDisplayName`, which falls back to the
      // preset's localized name only when there is no override. Overwriting
      // `labelKey` instead would render a raw string where a translated one
      // belongs — the B19/B25 failure mode.
      final items = effective(settings: {'eye_cleaning': row(label: 'rhume')});
      expect(items.single.labelOverride, 'rhume');
      expect(items.single.labelKey, 'reminderEyeCleaning');
    });

    test('a stored rhythm replaces the preset\'s', () {
      final items = effective(settings: {
        'eye_cleaning': row(frequency: 'every_n_days', intervalDays: 3)
      });
      expect(items.single.frequency,
          const ReminderFrequency.customInterval(days: 3));
    });

    test('an override back to null restores the declared rhythm', () {
      final items = effective(
          settings: {'eye_cleaning': row(frequency: null, intervalDays: 3)});
      // A leftover interval with no `every_n_days` is a leftover, not a rhythm.
      expect(items.single.frequency, const ReminderFrequency.daily());
    });

    test('a one-shot override carries its day (D-R8)', () {
      final items = effective(settings: {
        'eye_cleaning': row(frequency: 'one_time', frequencyDate: '2027-01-08')
      });
      expect(items.single.frequency,
          ReminderFrequency.oneTime(date: DateTime(2027, 1, 8)));
    });

    test('a one-shot without a readable day reads as due now, not as daily',
        () {
      // D-R8's tolerant half: the scheduler clamps a past occurrence anyway, so a
      // malformed date must not silently fall back to a rhythm the parent never
      // chose. The strict half lives at the write and at import.
      final items = effective(settings: {
        'eye_cleaning': row(frequency: 'one_time', frequencyDate: '8/1/2027')
      });
      expect(items.single.frequency, isA<OneTime>());
      expect((items.single.frequency as OneTime).date, isNull);
    });

    test('a removed reminder leaves the list', () {
      final items = effective(settings: {'eye_cleaning': row(removed: true)});
      expect(items, isEmpty);
    });

    test('a disabled reminder stays in the list', () {
      // The one thing this function must *not* do is apply `enabled`: Settings has
      // to show a switched-off reminder or the parent cannot switch it back on.
      // Home and the scheduler filter on `enabled` after calling this — which is
      // exactly why the rule is written down instead of being inferred from the
      // name, and why this test exists.
      final items = effective(settings: {'eye_cleaning': row(enabled: false)});
      expect(items, hasLength(1));
    });

    test('an age end is resolved against the birthdate, at read time (D-R5)',
        () {
      final items = effective(settings: {'eye_cleaning': row(endAgeMonths: 6)});
      // The *day*, at its start: inclusivity is the scheduler's job (`nextDueAt`
      // lets the whole end day through), not a 23:59 baked into the resolution —
      // an end stored as an instant would stop the reminder at midnight.
      expect(items.single.endsAt, DateTime(2026, 9, 1));
    });

    test('an age end without a profile stores nothing and resolves nothing',
        () {
      // D-R10: without a reliable birthdate an age cannot be resolved, and
      // inventing one would delete a reminder on a date nobody chose.
      final items = effective(
        settings: {'eye_cleaning': row(endAgeMonths: 6)},
        baby: _noProfile,
      );
      expect(items.single.endsAt, isNull);
    });

    test('a date end wins over an age when a row somehow holds both', () {
      // D-R5 refuses the pair at the write and at import; a row from an older
      // device, a hand-edited restore or a future bug still has to resolve to one
      // answer, and the explicit date is the one the parent wrote last.
      final items = effective(settings: {
        'eye_cleaning': row(endDate: '2027-03-14', endAgeMonths: 6)
      });
      expect(items.single.endsAt, DateTime(2027, 3, 14));
    });

    test('a malformed stored end resolves to no end rather than to a guess',
        () {
      final items =
          effective(settings: {'eye_cleaning': row(endDate: '2027-13-45')});
      expect(items.single.endsAt, isNull);
    });

    test('an override on one reminder never touches another', () {
      // D-R9 in the pure half: settings are keyed by `(scope, item)`, so a second
      // baby's map simply has nothing in it. The database half is in
      // `reminders_settings_writers_test.dart`.
      const nose = ReminderItem(
        id: 'nose_cleaning',
        labelKey: 'reminderNoseCleaning',
        frequency: ReminderFrequency.daily(),
        trackingType: TrackingType.sante,
      );
      final items = effectiveItemsForScope(
        items: const [eye, nose],
        settings: const {'eye_cleaning': ReminderItemSetting(enabled: true)},
        profile: profile,
      );
      expect(items.map((i) => i.id), ['eye_cleaning', 'nose_cleaning']);
      expect(items.last.labelOverride, isNull);
    });
  });
}
