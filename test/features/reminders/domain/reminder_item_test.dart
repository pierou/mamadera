import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('ReminderItem factory constructors', () {
    test('vitaminD returns correct defaults', () {
      final item = ReminderItemPresets.vitaminD;

      expect(item.id, 'vitamine_d');
      expect(item.labelKey, 'reminderVitaminD');
      expect(item.frequency, isA<Daily>());
      expect(item.trackingType, TrackingType.sante);
      expect(item.subtypeValue, 'vitamine_d');
    });

    test('vitaminK returns correct defaults', () {
      final item = ReminderItemPresets.vitaminK;

      expect(item.id, 'vitamine_k');
      expect(item.labelKey, 'reminderVitaminK');
      expect(item.frequency, isA<CustomInterval>());
      final custom = item.frequency as CustomInterval;
      expect(custom.days, 30);
      expect(item.trackingType, TrackingType.sante);
      expect(item.subtypeValue, 'vitamine_k');
    });

    test('vitaminD and vitaminK have different IDs', () {
      final vitD = ReminderItemPresets.vitaminD;
      final vitK = ReminderItemPresets.vitaminK;

      expect(vitD.id, isNot(equals(vitK.id)));
    });
  });

  group('ReminderItem constructor', () {
    test('custom item with all fields', () {
      const item = ReminderItem(
        id: 'test_item',
        labelKey: 'test_label',
        frequency: const Weekly(dayOfWeek: 3),
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

  group('ReminderItem eyeCleaning factory', () {
    test('returns correct defaults for eye cleaning', () {
      final item = ReminderItemPresets.eyeCleaning;

      expect(item.id, 'eye_cleaning');
      expect(item.labelKey, 'reminderEyeCleaning');
      expect(item.frequency, isA<Daily>());
      expect(item.trackingType, TrackingType.sante);
      expect(item.subtypeValue, 'nettoyage_yeux');
    });
  });

  group('ReminderItem faceCleaning factory', () {
    test('returns correct defaults for face cleaning', () {
      final item = ReminderItemPresets.faceCleaning;

      expect(item.id, 'face_cleaning');
      expect(item.labelKey, 'reminderFaceCleaning');
      expect(item.frequency, isA<Daily>());
      expect(item.trackingType, TrackingType.sante);
      expect(item.subtypeValue, 'nettoyage_visage');
    });
  });



  group('ReminderItemPresets.buildForBaby()', () {
    test('returns 4 reminders for a baby profile', () {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 1, 15),
        isActive: true,
      );

      final reminders = ReminderItemPresets.buildForBaby(profile);

      expect(reminders, hasLength(4));
    });

    test('includes Vitamin D as first reminder', () {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 1, 15),
        isActive: true,
      );

      final reminders = ReminderItemPresets.buildForBaby(profile);
      expect(reminders[0].id, 'vitamine_d');
    });

    test('includes Vitamin K with CustomInterval(30 days)', () {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 3, 28),
        isActive: true,
      );

      final reminders = ReminderItemPresets.buildForBaby(profile);
      final vitaminK = reminders[1];
      expect(vitaminK.id, 'vitamine_k');
      expect(vitaminK.frequency, isA<CustomInterval>());
      final custom = vitaminK.frequency as CustomInterval;
      expect(custom.days, 30);
    });

    test('includes eye cleaning reminder', () {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 1, 15),
        isActive: true,
      );

      final reminders = ReminderItemPresets.buildForBaby(profile);
      expect(reminders[2].id, 'eye_cleaning');
    });

    test('includes face cleaning reminder', () {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 1, 15),
        isActive: true,
      );

      final reminders = ReminderItemPresets.buildForBaby(profile);
      expect(reminders[3].id, 'face_cleaning');
    });

    test('all reminders are for sante tracking type', () {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 1, 15),
        isActive: true,
      );

      final reminders = ReminderItemPresets.buildForBaby(profile);
      for (final reminder in reminders) {
        expect(reminder.trackingType, TrackingType.sante);
      }
    });

    test('reminders have unique IDs', () {
      final profile = BabyProfile(
        id: '1',
        name: 'Test Baby',
        birthDate: DateTime(2024, 1, 15),
        isActive: true,
      );

      final reminders = ReminderItemPresets.buildForBaby(profile);
      final ids = reminders.map((r) => r.id).toList();
      expect(ids.toSet().length, equals(ids.length)); // all unique
    });
  });
}
