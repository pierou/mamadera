import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('CustomReminder', () {
    test('defaults completionSource to from_events', () {
      final reminder = CustomReminder(
        label: 'Crème du change',
        frequency: const ReminderFrequency.daily(),
        subtypeValue: 'nettoyage_nez',
      );

      expect(reminder.completionSource, completionFromEvents);
    });

    test('a detached reminder carries the manual source (D2 invariant)', () {
      final reminder = CustomReminder(
        label: 'Thermomètre',
        frequency: const ReminderFrequency.customInterval(days: 2),
        subtypeValue: null,
        completionSource: completionManual,
      );

      expect(reminder.subtypeValue, isNull);
      expect(reminder.completionSource, completionManual);
    });
  });

  group('CustomReminderPresets.forCustom', () {
    test('propagates completionSource onto the item it builds', () {
      final reminder = CustomReminder(
        id: 3,
        label: 'Crème du change',
        frequency: const ReminderFrequency.daily(),
        subtypeValue: 'nettoyage_nez',
        completionSource: completionFromEvents,
      );

      final item = CustomReminderPresets.forCustom(reminder);

      expect(item.id, 'custom_3');
      expect(item.labelKey, 'Crème du change');
      expect(item.subtypeValue, 'nettoyage_nez');
      expect(item.trackingType, TrackingType.sante);
      expect(item.completionSource, completionFromEvents);
    });

    test('a detached reminder stays without a care, settled manually', () {
      final reminder = CustomReminder(
        id: 4,
        label: 'Thermomètre',
        frequency: const ReminderFrequency.customInterval(days: 2),
        subtypeValue: null,
        completionSource: completionManual,
      );

      final item = CustomReminderPresets.forCustom(reminder);

      // No care is invented on the way out: null stays null, and the routing
      // source is manual, so no tracking event can settle it.
      expect(item.id, 'custom_4');
      expect(item.subtypeValue, isNull);
      expect(item.completionSource, completionManual);
      expect(item.frequency, const ReminderFrequency.customInterval(days: 2));
    });

    test('a monthly rhythm is anchored on the given day, source untouched', () {
      final reminder = CustomReminder(
        id: 5,
        label: 'Bilan',
        frequency: const ReminderFrequency.monthly(dayOfMonth: 1),
        subtypeValue: 'nettoyage_nez',
      );

      final item = CustomReminderPresets.forCustom(reminder, monthlyDay: 15);

      expect(item.frequency, const ReminderFrequency.monthly(dayOfMonth: 15));
      expect(item.completionSource, completionFromEvents);
    });
  });
}
