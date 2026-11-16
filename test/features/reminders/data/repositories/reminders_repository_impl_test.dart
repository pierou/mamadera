import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// The "Drift" line type is also known as `CustomReminder`: it is hidden by default.
// profit of the entity within the domain, which is the only one named in this file.
import 'package:mamadera/data/local/app_db.dart' hide CustomReminder;
import 'package:mamadera/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item_setting.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

void main() {
  group('RemindersRepositoryImpl', () {
    late AppDatabase database;
    late RemindersRepositoryImpl repository;

    setUp(() async {
      final connection = LazyDatabase(NativeDatabase.memory);
      database = AppDatabase(connection);
      // Trigger migration to create tables before any test runs.
      await database.select(database.reminderDismissals).get();
      repository = RemindersRepositoryImpl(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    final vitaminDItem = ReminderItemPresets.vitaminD;

    /// The switch alone, projected from the settings rows — what a consumer that
    /// cares only about enabled sees. `getSettingsByItemId` is the read; the
    /// repository has no separate "enabled map" query any more, and must not get
    /// one: two reads of `reminder_settings` is how a switch and an hour start
    /// disagreeing about the same reminder.
    Future<Map<String, bool>> enabledOf({String? babyId}) async {
      final rows = await repository.getSettingsByItemId(babyId: babyId);
      return {for (final entry in rows.entries) entry.key: entry.value.enabled};
    }

    group('getLastCompleted', () {
      test('returns null when no tracking events exist', () async {
        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNull);
      });

      test(
          'a solid food event does not complete milk feeding reminders (exact subtype match)',
          () async {
        // A puree does not rehydrate a newborn baby: the "Miam" recall campaign is underway.
        // the exact subtype (a deliberate choice, not an omission — BACKLOG).
        // B1). A mediocre match would "feed" and extinguish the [something - the original text is incomplete].
        // Recalls of malnourished infants.
        const miamNatural = ReminderItem(
          id: 'miam_natural',
          labelKey: 'miamNatural',
          frequency: Daily(),
          trackingType: TrackingType.miam,
          subtypeValue: 'natural',
        );
        const miamArtificial = ReminderItem(
          id: 'miam_artificial',
          labelKey: 'miamArtificial',
          frequency: Daily(),
          trackingType: TrackingType.miam,
          subtypeValue: 'artificial',
        );
        const miamSolid = ReminderItem(
          id: 'miam_solid',
          labelKey: 'miamSolid',
          frequency: Daily(),
          trackingType: TrackingType.miam,
          subtypeValue: 'solid',
        );

        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'g',
                type: 'miam',
                subtype: const Value('solid'),
                quantity: const Value(40.0),
                timestamp: DateTime.now(),
              ),
            );

        // The puree setting only controls the "solid" portion of the meal—it doesn't affect the liquids.
        expect(await repository.getLastCompleted(miamSolid), isNotNull);
        expect(await repository.getLastCompleted(miamNatural), isNull);
        expect(await repository.getLastCompleted(miamArtificial), isNull);
      });

      test('returns event from yesterday (not just today)', () async {
        // Regression: previously filtered to TODAY only, causing Vitamin K reminder
        // to show as due even when tracked 1 day ago. Now returns last completed ever.
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: yesterday,
              ),
            );

        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNotNull);
        expect(result!.day, equals(yesterday.day));
      });

      test('returns event timestamp from today', () async {
        final now = DateTime.now();
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: now,
              ),
            );

        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNotNull);
        expect(result!.year, equals(now.year));
        expect(result.month, equals(now.month));
        expect(result.day, equals(now.day));
      });

      test('returns most recent of multiple events across dates', () async {
        // Ensures query returns the latest event, not an older one.
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: weekAgo,
              ),
            );
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: yesterday,
              ),
            );

        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNotNull);
        // Should return yesterday's event (most recent), not week ago.
        expect(result!.day, equals(yesterday.day));
      });

      test('returns null for different tracking type', () async {
        final vitaminK = ReminderItemPresets.vitaminK;
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                wasteType: Value(vitaminDItem.subtypeValue),
                timestamp: DateTime.now(),
              ),
            );

        final result = await repository.getLastCompleted(vitaminK);
        expect(result, isNull);
      });

      test('ignores events of other babies when babyId is given', () async {
        // Regression: Vitamin D done for baby A must not suppress baby B's reminder.
        final babyAEvent = DateTime.now().subtract(const Duration(days: 5));
        final babyBEvent = DateTime.now().subtract(const Duration(days: 1));
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: babyAEvent,
                babyId: const Value('baby_a'),
              ),
            );
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: babyBEvent,
                babyId: const Value('baby_b'),
              ),
            );

        final forA =
            await repository.getLastCompleted(vitaminDItem, babyId: 'baby_a');
        final forB =
            await repository.getLastCompleted(vitaminDItem, babyId: 'baby_b');

        // Each baby sees only its own last event, not the sibling's newer one.
        expect(forA!.day, equals(babyAEvent.day));
        expect(forB!.day, equals(babyBEvent.day));
      });

      test('reads only profileless events when babyId is null', () async {
        // The stateless mode processes events before any specific user profile is loaded.
        // (`baby_id IS NULL`) - never an event for a baby: this.
        // The "all babies" reading group was a way for parents to connect with each other while their babies were together.
        // Presets related to a treatment.
        final older = DateTime.now().subtract(const Duration(days: 5));
        final recent = DateTime.now().subtract(const Duration(days: 1));
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: older,
                babyId: const Value('baby_a'),
              ),
            );
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: vitaminDItem.trackingType.name,
                subtype: Value(vitaminDItem.subtypeValue),
                timestamp: recent,
              ),
            );

        final result = await repository.getLastCompleted(vitaminDItem);

        expect(result, isNotNull);
        expect(result!.day, equals(recent.day));
      });
    });

    group('reminder settings (opt-out)', () {
      test('returns an empty map on a fresh database', () async {
        // Empty table = no one has selected anything yet, and therefore all the...
        // The reminders are enabled. This is not a mistake.
        expect(await enabledOf(), isEmpty);
      });

      test('persists a disabled reminder', () async {
        await repository.setEnabled(vitaminDItem.id, enabled: false);

        expect(await enabledOf(), {vitaminDItem.id: false});
      });

      test('upserts instead of stacking rows for the same item', () async {
        await repository.setEnabled(vitaminDItem.id, enabled: false);
        await repository.setEnabled(vitaminDItem.id, enabled: true);

        final rows = await database.select(database.reminderSettings).get();
        expect(rows, hasLength(1));
        expect(rows.single.itemId, vitaminDItem.id);
        expect(rows.single.enabled, isTrue);
        expect(await enabledOf(), {vitaminDItem.id: true});
      });

      test('keeps one row per reminder item', () async {
        await repository.setEnabled(vitaminDItem.id, enabled: false);
        await repository.setEnabled(ReminderItemPresets.eyeCleaning.id,
            enabled: false);

        expect(
          await enabledOf(),
          {
            vitaminDItem.id: false,
            ReminderItemPresets.eyeCleaning.id: false,
          },
        );
      });
    });

    // BACKLOG B30: one row now carries two decisions, so the interesting
    // failures are the ones where writing one column erases the other.
    group('the per-reminder hour (B30)', () {
      test('reads back the hour that was set, beside the switch', () async {
        await repository.setEnabled(vitaminDItem.id, enabled: true);
        await repository.setItemTime(
          vitaminDItem.id,
          timeOfDay: '21:05',
          enabledIfNew: true,
        );

        final settings = await repository.getSettingsByItemId();
        expect(settings[vitaminDItem.id],
            const ReminderItemSetting(enabled: true, timeOfDay: '21:05'));
      });

      test('a row with no hour reads as "inherit", not as a default hour',
          () async {
        await repository.setEnabled(vitaminDItem.id, enabled: true);

        expect(await repository.getSettingsByItemId(),
            {vitaminDItem.id: const ReminderItemSetting(enabled: true)});
        expect(
          (await database.getAllReminderSettings()).single.time,
          isNull,
          reason: 'NULL is the stored form of "inherit the global hour"',
        );
      });

      test('setting an hour on the default-off preset does not switch it on',
          () async {
        // B6's consent line: choosing an hour for vitamin D is not consent to
        // receive it, so the row created by the write carries the item's own
        // default, which the caller passes in.
        await repository.setItemTime(
          vitaminDItem.id,
          timeOfDay: '08:00',
          enabledIfNew: vitaminDItem.enabledByDefault,
        );

        final row = (await database.getAllReminderSettings()).single;
        expect(row.enabled, isFalse);
        expect(row.time, '08:00');
      });

      test('setting an hour leaves an existing switch exactly as it was',
          () async {
        await repository.setEnabled(vitaminDItem.id, enabled: false);
        await repository.setItemTime(
          vitaminDItem.id,
          timeOfDay: '08:00',
          enabledIfNew: true,
        );

        final row = (await database.getAllReminderSettings()).single;
        expect(row.enabled, isFalse,
            reason: 'enabledIfNew is for a new row only — never an update');
      });

      test('switching a reminder does not erase its hour', () async {
        // The regression this whole group exists for: setEnabled used to be a
        // DELETE + INSERT, which was invisible while the row had one column and
        // silently discarded the hour as soon as it had two.
        await repository.setItemTime(
          vitaminDItem.id,
          timeOfDay: '21:30',
          enabledIfNew: true,
        );
        await repository.setEnabled(vitaminDItem.id, enabled: false);
        await repository.setEnabled(vitaminDItem.id, enabled: true);

        final row = (await database.getAllReminderSettings()).single;
        expect(row.time, '21:30');
        expect(row.enabled, isTrue);
      });

      test('inheriting again clears the hour and keeps the row', () async {
        await repository.setItemTime(
          vitaminDItem.id,
          timeOfDay: '21:30',
          enabledIfNew: true,
        );
        await repository.setEnabled(vitaminDItem.id, enabled: false);

        await repository.clearItemTime(vitaminDItem.id);

        final rows = await database.getAllReminderSettings();
        expect(rows, hasLength(1), reason: '"inherit" is not "delete"');
        expect(rows.single.time, isNull);
        expect(rows.single.enabled, isFalse,
            reason: 'the switch is a different decision and stays put');
      });

      test('inheriting on a reminder with no row creates nothing', () async {
        await repository.clearItemTime(vitaminDItem.id);

        expect(await database.getAllReminderSettings(), isEmpty,
            reason: 'absence already means inherited; a created row would '
                'have to invent an enabled flag');
      });

      test('refuses an hour that does not exist', () async {
        // Write-strict: the picker cannot produce this and the importer refuses
        // it, so reaching the repository with it is a programming error.
        expect(
          () => repository.setItemTime(vitaminDItem.id,
              timeOfDay: '8:5', enabledIfNew: true),
          throwsA(isA<ArgumentError>()),
        );
        expect(await database.getAllReminderSettings(), isEmpty);
      });

      test('the hour is scoped per baby, like the switch', () async {
        await repository.setItemTime(
          vitaminDItem.id,
          timeOfDay: '07:00',
          enabledIfNew: true,
          babyId: 'baby_a',
        );

        expect(
            (await repository.getSettingsByItemId(babyId: 'baby_a'))
                .values
                .single
                .timeOfDay,
            '07:00');
        expect(await repository.getSettingsByItemId(babyId: 'baby_b'), isEmpty);
        expect(await repository.getSettingsByItemId(), isEmpty,
            reason: 'the profileless scope does not inherit a baby hour');
      });
    });

    group('custom reminders', () {
      CustomReminder reminder({
        int? id,
        String label = 'Crème du change',
        String subtypeValue = 'nettoyage_nez',
        ReminderFrequency frequency = const ReminderFrequency.daily(),
      }) =>
          CustomReminder(
            id: id,
            label: label,
            subtypeValue: subtypeValue,
            frequency: frequency,
          );

      Future<void> insertRaw({
        required String frequency,
        int? intervalDays,
        String label = 'Rappel brut',
      }) =>
          database.into(database.customReminders).insert(
                CustomRemindersCompanion.insert(
                  label: label,
                  subtypeValue: const Value('nettoyage_nez'),
                  frequency: frequency,
                  intervalDays: Value(intervalDays),
                ),
              );

      test('round-trips the four frequencies through their stored codes',
          () async {
        final frequencies = {
          'daily': const ReminderFrequency.daily(),
          'weekly': const ReminderFrequency.weekly(dayOfWeek: 3),
          'monthly': const ReminderFrequency.monthly(dayOfMonth: 27),
          'every_n_days': const ReminderFrequency.customInterval(days: 30),
        };

        for (final entry in frequencies.entries) {
          final id = await repository.insertCustomReminder(
            reminder(label: 'Rappel ${entry.key}', frequency: entry.value),
          );
          final stored = await (database.select(database.customReminders)
                ..where((t) => t.id.equals(id)))
              .getSingle();

          expect(stored.frequency, entry.key);
          // Only the drumbeat has a sustained length; the other rhythms fade away.
          // set the column to NULL; otherwise, a spurious value would remain after the operation.
          // changement de rythme.
          expect(
            stored.intervalDays,
            entry.key == 'every_n_days' ? 30 : isNull,
          );
        }

        final read = await repository.getCustomReminders();
        expect(read, hasLength(4));
        // Weekday and day-of-the-month designations don't survive intentionally.
        // the round trip: the first is a placeholder that `isDue` ignores, the second
        // It belongs to the baby, not to the recall process. A bearing, on the other hand, is returned.
        // exactement.
        expect(
          read.map((r) => r.frequency),
          [
            const ReminderFrequency.daily(),
            const ReminderFrequency.weekly(dayOfWeek: 1),
            const ReminderFrequency.monthly(
              dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
            ),
            const ReminderFrequency.customInterval(days: 30),
          ],
        );
      });

      // The duration of a monthly cycle is not determined by a specific reminder; it follows a natural pattern.
      // Date of birth of the active baby. The system cannot store this information.
      test(
          'a monthly reminder is stored without a day and read on the fallback day',
          () async {
        await repository.insertCustomReminder(
          reminder(frequency: const ReminderFrequency.monthly(dayOfMonth: 27)),
        );

        final stored =
            await database.select(database.customReminders).getSingle();
        expect(stored.frequency, 'monthly');
        expect(stored.intervalDays, isNull);

        final read = (await repository.getCustomReminders()).single;
        expect(
          read.frequency,
          const ReminderFrequency.monthly(
            dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
          ),
        );
      });

      // The unknown code likely originates from a manually edited JSON file or a future version.
      // of the app. Deleting it would deprive the parent of a reminder that they can still...
      // Correction: We're scaling back our plans, opting for a more cautious approach.
      test(
          'an unknown frequency code degrades to daily instead of dropping the row',
          () async {
        await insertRaw(frequency: 'every_fortnight');

        final read = (await repository.getCustomReminders()).single;
        expect(read.frequency, const ReminderFrequency.daily());
        expect(read.label, 'Rappel brut');
      });

      // `interval_days = 0` would ensure that the reminder is always due: the screen...
      // The waiting room is constantly full, and the parent doesn't understand why.
      test('an unreadable interval falls back to a rolling week', () async {
        await insertRaw(frequency: 'every_n_days', intervalDays: 0);

        final read = (await repository.getCustomReminders()).single;
        expect(read.frequency, const ReminderFrequency.customInterval(days: 7));
      });

      test('trims the label and refuses a blank or overlong one', () async {
        final id = await repository.insertCustomReminder(
          reminder(label: '  Sérum visage  '),
        );
        final read = await repository.getCustomReminders();
        expect(read.single.label, 'Sérum visage');
        expect(read.single.id, id);

        expect(
          () => repository.insertCustomReminder(reminder(label: '   ')),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => repository.insertCustomReminder(reminder(label: 'x' * 61)),
          throwsA(isA<ArgumentError>()),
        );
        // No extraneous lines appear after a rejection: the name is validated beforehand.
        // Writing, not afterwards.
        expect(await database.select(database.customReminders).get(),
            hasLength(1));
      });

      // The rejection of the wording should not also be an opportunity to leak the [information/document/details].
      // This is parental text, not a technical key.
      test('a rejected label does not reach the error message verbatim',
          () async {
        const secret =
            'Vaulto — problème de reflux très douloureux après chaque prise du soir';
        try {
          await repository.insertCustomReminder(reminder(label: secret));
          fail('un libellé de 60+ caractères aurait dû être refusé');
        } on ArgumentError catch (error) {
          expect('${error.message}'.contains(secret), isFalse);
          expect('${error.invalidValue}'.contains(secret), isFalse);
        }
      });

      test('an edit rewrites the row in place and can change the rhythm',
          () async {
        final id = await repository.insertCustomReminder(reminder());

        await repository.updateCustomReminder(reminder(
          id: id,
          label: 'Crème du change, le soir',
          frequency: const ReminderFrequency.customInterval(days: 2),
        ));

        final rows = await database.select(database.customReminders).get();
        expect(rows, hasLength(1));
        expect(rows.single.label, 'Crème du change, le soir');
        expect(rows.single.frequency, 'every_n_days');
        expect(rows.single.intervalDays, 2);
      });

      test('an edit without an id is refused before any write', () async {
        await repository.insertCustomReminder(reminder());

        await expectLater(
          repository.updateCustomReminder(reminder(label: 'Sans identifiant')),
          throwsA(isA<ArgumentError>()),
        );
        final read = await repository.getCustomReminders();
        expect(read.single.label, 'Crème du change');
      });

      // The core of the change involves three tables. A configuration adjustment is required.
      // An orphan process with the identifier `custom_<id>` would survive each export operation, and, more seriously, ...
      // It would prevent a future recall with the same identifier from being activated.
      test('deleting a reminder also deletes its setting and its dismissal',
          () async {
        final id = await repository.insertCustomReminder(reminder());
        final key = '${CustomReminderPresets.customIdPrefix}$id';
        await repository.setEnabled(key, enabled: false);
        // Manually inserted kill switch: imported backups.
        // contain, and the removal process should prioritize those elements.
        await database.into(database.reminderDismissals).insert(
              ReminderDismissalsCompanion.insert(
                itemId: key,
                dismissedAt: DateTime.now(),
              ),
            );
        expect(await enabledOf(), contains(key));
        expect(await database.getAllReminderDismissals(), hasLength(1));

        await repository.deleteCustomReminder(id);

        expect(await repository.getCustomReminders(), isEmpty);
        expect(await enabledOf(), isEmpty);
        expect(await database.getAllReminderDismissals(), isEmpty);
      });

      test('deleting an unknown id changes nothing and does not throw',
          () async {
        await repository.setEnabled('custom_99', enabled: false);

        await repository.deleteCustomReminder(1234);

        // A deletion that doesn't target any specific line should not affect the...
        // settings for other reminders.
        expect(await enabledOf(), {'custom_99': false});
      });

      test('a deleted custom reminder leaves no row in any table', () async {
        final id = await repository.insertCustomReminder(
          const CustomReminder(
            label: 'Crème du change',
            frequency: ReminderFrequency.daily(),
            subtypeValue: null,
          ),
        );
        final key = 'custom_$id';

        // The three satellite tables hold the key to the recall: each one must...
        // to die with him. Also, `reminder_completions`, because the export reads...
        // This unfiltered table – a sense of incompleteness would be evident in the...
        // save, restore, and would schedule a future reminder using that same ID.
        await repository.setEnabled(key, enabled: false);
        await repository.recordCompletion(key, at: DateTime(2026, 3, 1));
        await repository.dismissReminder(key, at: DateTime(2026, 3, 2));

        expect(await repository.getLastManualCompletion(key), isNotNull);

        await repository.deleteCustomReminder(id);

        expect(await repository.getCustomReminders(), isEmpty);
        expect(await enabledOf(), isNot(contains(key)));
        expect(await repository.getLastManualCompletion(key), isNull);
        expect(await repository.getLastDismissal(key), isNull);
      });
    });

    group('complétions manuelles (reminder_completions)', () {
      test('recordCompletion appends a row readable by getLastManualCompletion',
          () async {
        final at = DateTime(2026, 3, 12, 9, 30);
        await repository.recordCompletion('vitamine_d', at: at);

        expect(await repository.getLastManualCompletion('vitamine_d'), at);
      });

      test('the most recent completion wins', () async {
        await repository.recordCompletion('vitamine_d',
            at: DateTime(2026, 3, 1));
        await repository.recordCompletion('vitamine_d',
            at: DateTime(2026, 3, 2));

        expect(
          await repository.getLastManualCompletion('vitamine_d'),
          DateTime(2026, 3, 2),
        );
      });

      test('completions are per-baby: A does not settle B', () async {
        await repository.recordCompletion(
          'vitamine_d',
          babyId: 'baby_a',
          at: DateTime(2026, 3, 2),
        );

        expect(
          await repository.getLastManualCompletion('vitamine_d',
              babyId: 'baby_a'),
          isNotNull,
        );
        expect(
          await repository.getLastManualCompletion('vitamine_d',
              babyId: 'baby_b'),
          isNull,
        );
      });
    });

    group('invariant D2 (item détaché)', () {
      test(
          'an item without subtype is never settled by an event, even of its own type',
          () async {
        // The trap: a "health" event exists, within a reputable domain, even a very good one.
        // subtype – but the item is detached and can only be adjusted manually.
        final detached = ReminderItem(
          id: 'pedicure',
          labelKey: 'reminderPedicure',
          frequency: const ReminderFrequency.daily(),
          trackingType: TrackingType.sante,
        );
        await database.into(database.trackingEvents).insert(
              TrackingEventsCompanion.insert(
                unit: 'ml',
                type: 'sante',
                subtype: const Value('vitamine_d'),
                timestamp: DateTime.now(),
              ),
            );

        expect(await repository.getLastCompleted(detached), isNull);
        expect(await repository.getLastCompleted(detached, babyId: 'baby_a'),
            isNull);
      });
    });

    group('ignorer (reminder_dismissals)', () {
      test('dismissReminder keeps one row per (baby, item) and refreshes it',
          () async {
        await repository.dismissReminder('vitamine_d',
            at: DateTime(2026, 3, 1));
        await repository.dismissReminder('vitamine_d',
            at: DateTime(2026, 3, 2));

        final rows = await database.select(database.reminderDismissals).get();
        expect(rows, hasLength(1));
        expect(rows.single.dismissedAt, DateTime(2026, 3, 2));
      });

      test('dismissals are per-baby', () async {
        await repository.dismissReminder('vitamine_d', babyId: 'baby_a');

        expect(
          await repository.getLastDismissal('vitamine_d', babyId: 'baby_a'),
          isNotNull,
        );
        expect(
          await repository.getLastDismissal('vitamine_d', babyId: 'baby_b'),
          isNull,
        );
      });
    });

    group('deux bébés partageant un préréglage (item M)', () {
      test('enabled, dismissed et completed sont indépendants par bébé',
          () async {
        const presetId = 'vitamine_d';

        // Off for A, functional for B.
        await repository.setEnabled(presetId, enabled: false, babyId: 'baby_a');
        expect((await enabledOf(babyId: 'baby_a'))[presetId], isFalse);
        expect(
          await enabledOf(babyId: 'baby_b'),
          isNot(contains(presetId)),
        );

        // Brother B is not affected, even though brother A was.
        await repository.dismissReminder(presetId, babyId: 'baby_a');
        expect(await repository.getLastDismissal(presetId, babyId: 'baby_a'),
            isNotNull);
        expect(await repository.getLastDismissal(presetId, babyId: 'baby_b'),
            isNull);

        // Made for A, nothing for B.
        await repository.recordCompletion(presetId, babyId: 'baby_a');
        expect(
          await repository.getLastManualCompletion(presetId, babyId: 'baby_a'),
          isNotNull,
        );
        expect(
          await repository.getLastManualCompletion(presetId, babyId: 'baby_b'),
          isNull,
        );

        // One line per baby, per table: nothing was shared.
        // passage.
        expect(await database.getAllReminderSettings(), hasLength(1));
        expect(await database.getAllReminderDismissals(), hasLength(1));
        expect(await database.select(database.reminderCompletions).get(),
            hasLength(1));
      });
    });

    group("portage sans profil (sentinelle '')", () {
      test(
          "une ligne réglée sans profil ne s'applique à aucun bébé : le nouveau bébé part du défaut",
          () async {
        // This line originates from an installation without a profile: it was written without using baby fonts.
        await repository.setEnabled('vitamine_d', enabled: false);
        expect((await database.getAllReminderSettings()).single.babyId, '');

        // It's readable even without a profile.
        expect((await enabledOf())['vitamine_d'], isFalse);
        // ...but it is invisible to a baby born later: its presence is.
        // empty, so the preset remains active by default.
        expect(
          await enabledOf(babyId: 'nouveau'),
          isNot(contains('vitamine_d')),
        );
      });

      test('la ligne propre au bébé est la seule ligne lue, pour lui seul',
          () async {
        await repository.setEnabled('vitamine_d', enabled: false);
        await repository.setEnabled('vitamine_d',
            enabled: true, babyId: 'nouveau');

        expect((await enabledOf(babyId: 'nouveau'))['vitamine_d'], isTrue);
        // The "other" baby doesn't read either its own line (which is absent) or the line...
        // without profile: this is a default setting, so it is enabled.
        expect(
          await enabledOf(babyId: 'autre'),
          isNot(contains('vitamine_d')),
        );
        expect(await database.getAllReminderSettings(), hasLength(2));
      });

      test("un ignoré sans profil ne s'applique à aucun bébé", () async {
        await repository.dismissReminder('vitamine_d');

        expect(
          await repository.getLastDismissal('vitamine_d', babyId: 'bébé_tard'),
          isNull,
        );
        // However, it remains readable even without a profile.
        expect(await repository.getLastDismissal('vitamine_d'), isNotNull);
      });

      test('une complétion sans profil ne règle aucun bébé', () async {
        await repository.recordCompletion('vitamine_d');

        expect(
          await repository.getLastManualCompletion('vitamine_d',
              babyId: 'bébé_tard'),
          isNull,
        );
        expect(
            await repository.getLastManualCompletion('vitamine_d'), isNotNull);
      });

      test('a baby created later sees defaults, not another baby state',
          () async {
        // The first one turned off the Vitamin D, ignored it, and marked it as complete.
        await repository.setEnabled('vitamine_d', enabled: false, babyId: 'a');
        await repository.dismissReminder('vitamine_d', babyId: 'a');
        await repository.recordCompletion('vitamine_d', babyId: 'a');

        // The "baby b" object, created afterward, inherits nothing: no settings, no...
        // Ignored, no manual adjustment.
        expect(await enabledOf(babyId: 'b'), isEmpty);
        expect(await repository.getLastDismissal('vitamine_d', babyId: 'b'),
            isNull);
        expect(
            await repository.getLastManualCompletion('vitamine_d', babyId: 'b'),
            isNull);
      });
    });

    group('rappels personnalisés portés par la ligne', () {
      CustomReminder custom() => CustomReminder(
            label: 'Crème du change',
            subtypeValue: 'nettoyage_nez',
            frequency: const ReminderFrequency.daily(),
          );

      test("un rappel créé pour A n'est pas visible par B", () async {
        await repository.insertCustomReminder(custom(), babyId: 'baby_a');

        expect(await repository.getCustomReminders(babyId: 'baby_a'),
            hasLength(1));
        expect(await repository.getCustomReminders(babyId: 'baby_b'), isEmpty);
      });

      test("un rappel créé sans profil n'est visible que sans profil",
          () async {
        await repository.insertCustomReminder(custom());
        final row = await database.select(database.customReminders).getSingle();
        expect(row.babyId, '');

        expect(await repository.getCustomReminders(), hasLength(1));
        expect(await repository.getCustomReminders(babyId: 'baby_a'), isEmpty);
        expect(await repository.getCustomReminders(babyId: 'baby_b'), isEmpty);
      });
    });
  });
}
