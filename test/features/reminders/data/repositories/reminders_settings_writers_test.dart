import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/app_db.dart' hide CustomReminder;
import 'package:mamadera/data/local/db_constants.dart' as db_const;
import 'package:mamadera/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';

/// The B33 writers of `reminder_settings`, on a real database (D-R2, D-R5, D-R6).
///
/// M2 learned the lesson these tests exist to keep: a settings writer that
/// delete-and-reinserted the row silently erased a stored hour while appearing to
/// do its one job. Every B33 column could repeat it, so each writer here is pinned
/// twice — that it wrote what it owns, that it did not touch what it does not.
void main() {
  group('reminder_settings writers (B33, D-R2)', () {
    late AppDatabase database;
    late RemindersRepositoryImpl repository;

    setUp(() async {
      database = AppDatabase(LazyDatabase(NativeDatabase.memory));
      await database.select(database.reminderDismissals).get();
      repository = RemindersRepositoryImpl(database: database);
    });

    tearDown(() async => database.close());

    const baby = 'baby-1';
    final vitaminD = ReminderItemPresets.vitaminD;

    /// The stored row of [itemId], read straight from the table: these tests are
    /// about what the *columns* hold, not about what a reader projects.
    Future<ReminderSetting> rowOf(
      String itemId, {
      String babyId = baby,
    }) async {
      final query = database.select(database.reminderSettings)
        ..where((t) => t.babyId.equals(babyId) & t.itemId.equals(itemId));
      return query.getSingle();
    }

    test('naming a preset writes only its label', () async {
      await repository.setItemTime(
        vitaminD.id,
        timeOfDay: '19:00',
        enabledIfNew: false,
        babyId: baby,
      );
      await repository.setItemLabel(
        vitaminD.id,
        label: 'les gouttes',
        enabledIfNew: true,
        babyId: baby,
      );

      final row = await rowOf(vitaminD.id);
      expect(row.label, 'les gouttes');
      // The hour the other writer owns is still there — M2's bug, one column over.
      expect(row.time, '19:00');
      // …and renaming was not consent to switch vitamin D on (B6): the row was
      // created by a write with `enabledIfNew: false`, and a later write with
      // `true` must not have flipped it.
      expect(row.enabled, isFalse);
    });

    test(
        'a first write creates the row with the caller\'s enabled, never with consent',
        () async {
      await repository.setItemLabel(
        vitaminD.id,
        label: 'les gouttes',
        enabledIfNew: vitaminD.enabledByDefault,
        babyId: baby,
      );
      final row = await rowOf(vitaminD.id);
      expect(row.enabled, isFalse,
          reason:
              'vitamin D is the off-by-default item (B6); a rename must not switch '
              'it on for a scope that never touched it');
    });

    test('setting a rhythm writes the frequency columns and nothing else',
        () async {
      await repository.setItemLabel(
        vitaminD.id,
        label: 'les gouttes',
        enabledIfNew: true,
        babyId: baby,
      );
      await repository.setItemEnd(
        vitaminD.id,
        endAgeMonths: 8,
        enabledIfNew: true,
        babyId: baby,
      );
      await repository.setItemFrequency(
        vitaminD.id,
        frequency: const ReminderFrequency.customInterval(days: 2),
        enabledIfNew: true,
        babyId: baby,
      );

      final row = await rowOf(vitaminD.id);
      expect(row.frequency, db_const.freqEveryNDays);
      expect(row.intervalDays, 2);
      expect(row.label, 'les gouttes',
          reason: 'the nickname survives a re-pace');
      expect(row.endAgeMonths, 8);
    });

    test('switching to a one-shot clears the stored end (D-R5 exclusivity)',
        () async {
      await repository.setItemEnd(
        vitaminD.id,
        endDate: DateTime(2027, 3, 14),
        enabledIfNew: true,
        babyId: baby,
      );
      await repository.setItemFrequency(
        vitaminD.id,
        frequency: ReminderFrequency.oneTime(date: DateTime(2027, 3, 14)),
        enabledIfNew: true,
        babyId: baby,
      );

      final row = await rowOf(vitaminD.id);
      expect(row.frequency, db_const.freqOneTime);
      expect(row.endDate, isNull);
      expect(row.endAgeMonths, isNull,
          reason:
              'a one-shot has an occurrence, never an end; carrying the old end '
              'over would leave a date the picker can no longer show');
    });

    test('an end is stored as months and the date form is what is cleared',
        () async {
      await repository.setItemEnd(
        vitaminD.id,
        endDate: DateTime(2027, 3, 14),
        enabledIfNew: true,
        babyId: baby,
      );
      await repository.setItemEnd(
        vitaminD.id,
        endAgeMonths: 9,
        enabledIfNew: true,
        babyId: baby,
      );

      final row = await rowOf(vitaminD.id);
      // D-R5's canonical form: months stored, the date derived at read time, so a
      // corrected birthdate moves the end by itself.
      expect(row.endAgeMonths, 9);
      expect(row.endDate, isNull);
    });

    test('both end forms at once are refused at the write', () async {
      expect(
        () => repository.setItemEnd(
          vitaminD.id,
          endDate: DateTime(2027, 3, 14),
          endAgeMonths: 9,
          enabledIfNew: true,
          babyId: baby,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('removing leaves the switch alone and reads back as removed',
        () async {
      await repository.setEnabled(vitaminD.id, enabled: true, babyId: baby);
      await repository.setItemRemoved(
        vitaminD.id,
        removed: true,
        enabledIfNew: false,
        babyId: baby,
      );

      final row = await rowOf(vitaminD.id);
      expect(row.removed, isTrue);
      // D-R2's "the columns that answer different questions": the removal is not a
      // switch write, so `enabled` stays exactly as the parent left it — that is
      // what a restore comes back to (D-R4).
      expect(row.enabled, isTrue);

      await repository.setItemRemoved(
        vitaminD.id,
        removed: false,
        enabledIfNew: false,
        babyId: baby,
      );
      final restored = await repository.getSettingsByItemId(babyId: baby);
      expect(restored[vitaminD.id]!.removed, isFalse);
      expect(restored[vitaminD.id]!.enabled, isTrue);
    });

    test('an override belongs to one scope only (D-R9)', () async {
      await repository.setItemLabel(
        vitaminD.id,
        label: 'les gouttes',
        enabledIfNew: true,
        babyId: baby,
      );
      await repository.setItemFrequency(
        vitaminD.id,
        frequency: const ReminderFrequency.customInterval(days: 4),
        enabledIfNew: true,
        babyId: baby,
      );

      // Nothing was ever written for the other baby, and it has no row: it inherits
      // the preset as declared. This is D-R9 in one assertion — were the shared
      // scope (`babyId = ''`) consulted as a fallback, or an upsert matched on
      // `itemId` alone, a second baby would silently inherit a sibling's nickname
      // and a sibling's rhythm.
      expect(await repository.getSettingsByItemId(babyId: 'baby-2'), isEmpty);

      // Writing for baby 2 creates baby 2's row and leaves baby 1's untouched.
      await repository.setItemLabel(
        vitaminD.id,
        label: 'otra cosa',
        enabledIfNew: true,
        babyId: 'baby-2',
      );
      final mine = await repository.getSettingsByItemId(babyId: baby);
      expect(mine[vitaminD.id]!.label, 'les gouttes');
      expect(mine[vitaminD.id]!.frequency, db_const.freqEveryNDays);
      final theirs = await repository.getSettingsByItemId(babyId: 'baby-2');
      expect(theirs[vitaminD.id]!.label, 'otra cosa');
      expect(theirs[vitaminD.id]!.frequency, isNull);
    });

    test('resetting a rhythm erases the interval and the occurrence with it',
        () async {
      await repository.setItemFrequency(
        vitaminD.id,
        frequency: ReminderFrequency.oneTime(date: DateTime(2027, 3, 14)),
        enabledIfNew: true,
        babyId: baby,
      );
      await repository.setItemFrequency(
        vitaminD.id,
        frequency: null,
        enabledIfNew: true,
        babyId: baby,
      );

      final row = await rowOf(vitaminD.id);
      expect(row.frequency, isNull);
      expect(row.intervalDays, isNull);
      expect(row.frequencyDate, isNull);
    });
  });
}
