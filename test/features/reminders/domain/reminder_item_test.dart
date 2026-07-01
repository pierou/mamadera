import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('ReminderItem factory constructors', () {
    test('vitaminD returns correct defaults', () {
      final item = ReminderItem.vitaminD();

      expect(item.id, 'vitamine_d');
      expect(item.labelKey, 'reminderVitaminD');
      expect(item.frequency, isA<Daily>());
      expect(item.trackingType, TrackingType.sante);
      expect(item.subtypeValue, 'vitamine_d');
    });

    test('vitaminK returns correct defaults', () {
      final item = ReminderItem.vitaminK();

      expect(item.id, 'vitamine_k');
      expect(item.labelKey, 'reminderVitaminK');
      expect(item.frequency, isA<Daily>());
      expect(item.trackingType, TrackingType.sante);
      expect(item.subtypeValue, 'vitamine_k');
    });

    test('vitaminD and vitaminK have different IDs', () {
      final vitD = ReminderItem.vitaminD();
      final vitK = ReminderItem.vitaminK();

      expect(vitD.id, isNot(equals(vitK.id)));
    });
  });

  group('ReminderItem constructor', () {
    test('custom item with all fields', () {
      const item = ReminderItem(
        id: 'test_item',
        labelKey: 'test_label',
        frequency: Weekly(3),
        trackingType: TrackingType.miam,
        subtypeValue: 'feedingSubtypeBiberon',
      );

      expect(item.id, 'test_item');
      expect(item.labelKey, 'test_label');
      expect(item.frequency, isA<Weekly>());
      final weekly = item.frequency as Weekly;
      expect(weekly.dayOfWeek, 3);
      expect(item.trackingType, TrackingType.miam);
      expect(item.subtypeValue, 'feedingSubtypeBiberon');
    });

    test('custom item with null subtype', () {
      const item = ReminderItem(
        id: 'test_no_subtype',
        labelKey: 'no_subtype_label',
        frequency: Daily(),
        trackingType: TrackingType.dodo,
      );

      expect(item.subtypeValue, isNull);
    });
  });
}
