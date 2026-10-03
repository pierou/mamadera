import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// Le type de ligne Drift s'appelle aussi `CustomReminder` : on le masque au
// profit de l'entité du domaine, seule nommée dans ce fichier.
import 'package:mamadera/data/local/app_db.dart' hide CustomReminder;
import 'package:mamadera/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
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

    group('getLastCompleted', () {
      test('returns null when no tracking events exist', () async {
        final result = await repository.getLastCompleted(vitaminDItem);
        expect(result, isNull);
      });

      test('returns event from yesterday (not just today)', () async {
        // Regression: previously filtered to TODAY only, causing Vitamin K reminder
        // to show as due even when tracked 1 day ago. Now returns last completed ever.
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
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
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: weekAgo,
          ),
        );
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
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
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: babyAEvent,
            babyId: const Value('baby_a'),
          ),
        );
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: babyBEvent,
            babyId: const Value('baby_b'),
          ),
        );

        final forA = await repository.getLastCompleted(vitaminDItem, babyId: 'baby_a');
        final forB = await repository.getLastCompleted(vitaminDItem, babyId: 'baby_b');

        // Each baby sees only its own last event, not the sibling's newer one.
        expect(forA!.day, equals(babyAEvent.day));
        expect(forB!.day, equals(babyBEvent.day));
      });

      test('spans all babies when babyId is null', () async {
        // Backward compatibility: a pre-profile install keeps the old behaviour.
        final older = DateTime.now().subtract(const Duration(days: 5));
        final recent = DateTime.now().subtract(const Duration(days: 1));
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: older,
            babyId: const Value('baby_a'),
          ),
        );
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: vitaminDItem.trackingType.name,
            subtype: Value(vitaminDItem.subtypeValue),
            timestamp: recent,
            babyId: const Value('baby_b'),
          ),
        );

        final result = await repository.getLastCompleted(vitaminDItem);

        expect(result!.day, equals(recent.day));
      });
    });

    group('reminder settings (opt-out)', () {
      test('returns an empty map on a fresh database', () async {
        // Table vide = personne n'a encore rien décoché, et donc tous les
        // rappels sont activés. Ce n'est pas une erreur.
        expect(await repository.getEnabledByItemId(), isEmpty);
      });

      test('persists a disabled reminder', () async {
        await repository.setEnabled(vitaminDItem.id, enabled: false);

        expect(await repository.getEnabledByItemId(), {vitaminDItem.id: false});
      });

      test('upserts instead of stacking rows for the same item', () async {
        await repository.setEnabled(vitaminDItem.id, enabled: false);
        await repository.setEnabled(vitaminDItem.id, enabled: true);

        final rows = await database.select(database.reminderSettings).get();
        expect(rows, hasLength(1));
        expect(rows.single.itemId, vitaminDItem.id);
        expect(rows.single.enabled, isTrue);
        expect(await repository.getEnabledByItemId(), {vitaminDItem.id: true});
      });

      test('keeps one row per reminder item', () async {
        await repository.setEnabled(vitaminDItem.id, enabled: false);
        await repository.setEnabled(ReminderItemPresets.eyeCleaning.id, enabled: false);

        expect(
          await repository.getEnabledByItemId(),
          {
            vitaminDItem.id: false,
            ReminderItemPresets.eyeCleaning.id: false,
          },
        );
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
          // Seul le roulement porte une longueur : les autres rythmes laissent
          // la colonne à NULL, sinon une valeur parasite survivrait à un
          // changement de rythme.
          expect(
            stored.intervalDays,
            entry.key == 'every_n_days' ? 30 : isNull,
          );
        }

        final read = await repository.getCustomReminders();
        expect(read, hasLength(4));
        // Le jour de semaine et le jour du mois ne survivent pas volontairement
        // au détour : le premier est un placeholder que `isDue` ignore, le second
        // appartient au bébé et non au rappel. Un roulement, lui, est restitué
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

      // Le jour d'un rythme mensuel n'appartient pas au rappel : il suit la
      // date de naissance du bébé actif. La base ne peut pas le détenir.
      test('a monthly reminder is stored without a day and read on the fallback day',
          () async {
        await repository.insertCustomReminder(
          reminder(frequency: const ReminderFrequency.monthly(dayOfMonth: 27)),
        );

        final stored = await database.select(database.customReminders).getSingle();
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

      // Un code inconnu vient d'un JSON édité à la main ou d'une version future
      // de l'app. Le jeter priverait le parent d'un rappel qu'il peut encore
      // corriger : on redescend sur quotidien, le plus prudent.
      test('an unknown frequency code degrades to daily instead of dropping the row',
          () async {
        await insertRaw(frequency: 'every_fortnight');

        final read = (await repository.getCustomReminders()).single;
        expect(read.frequency, const ReminderFrequency.daily());
        expect(read.label, 'Rappel brut');
      });

      // interval_days = 0 rendrait le rappel dû en permanence : l'écran
      // d'accueil ne se vide plus jamais et le parent ne comprend pas pourquoi.
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
        // Aucune ligne parasites derrière les refus : le nom est validé avant
        // l'écriture, pas après.
        expect(await database.select(database.customReminders).get(), hasLength(1));
      });

      // Le refus du libellé ne doit pas non plus être l'occasion de fuiter le
      // texte saisi : c'est du texte de parent, pas une clé technique.
      test('a rejected label does not reach the error message verbatim', () async {
        const secret = 'Vaulto — problème de reflux très douloureux après chaque prise du soir';
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

      // Le cœur de la suppression : trois tables sont touchées. Un réglage
      // orphelin sous `custom_<id>` survivrait à chaque export et, plus grave,
      // interdirait à un futur rappel portant le même identifiant de s'allumer.
      test('deleting a reminder also deletes its setting and its dismissal',
          () async {
        final id = await repository.insertCustomReminder(reminder());
        final key = '${CustomReminderPresets.customIdPrefix}$id';
        await repository.setEnabled(key, enabled: false);
        // Ligne d'extinction insérée à la main : les sauvegardes importées en
        // contiennent, et la suppression doit les emporter.
        await database.into(database.reminderDismissals).insert(
          ReminderDismissalsCompanion.insert(
            itemId: key,
            dismissedAt: DateTime.now(),
          ),
        );
        expect(await repository.getEnabledByItemId(), contains(key));
        expect(await database.getAllReminderDismissals(), hasLength(1));

        await repository.deleteCustomReminder(id);

        expect(await repository.getCustomReminders(), isEmpty);
        expect(await repository.getEnabledByItemId(), isEmpty);
        expect(await database.getAllReminderDismissals(), isEmpty);
      });

      test('deleting an unknown id changes nothing and does not throw',
          () async {
        await repository.setEnabled('custom_99', enabled: false);

        await repository.deleteCustomReminder(1234);

        // Une suppression qui ne vise aucune ligne ne doit pas emporter les
        // réglages des autres rappels.
        expect(await repository.getEnabledByItemId(), {'custom_99': false});
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

        // Les trois tables satellites portent la clé du rappel : chacune doit
        // mourir avec lui. `reminder_completions` aussi, parce que l'export lit
        // cette table sans filtre — un achèvement orphelin serait écrit dans la
        // sauvegarde, restauré, et réglerait un futur rappel reprenant cet id.
        await repository.setEnabled(key, enabled: false);
        await repository.recordCompletion(key, at: DateTime(2026, 3, 1));
        await repository.dismissReminder(key, at: DateTime(2026, 3, 2));

        expect(await repository.getLastManualCompletion(key), isNotNull);

        await repository.deleteCustomReminder(id);

        expect(await repository.getCustomReminders(), isEmpty);
        expect(await repository.getEnabledByItemId(), isNot(contains(key)));
        expect(await repository.getLastManualCompletion(key), isNull);
        expect(await repository.getLastDismissal(key), isNull);
      });
    });

    group('complétions manuelles (reminder_completions)', () {
      test('recordCompletion appends a row readable by getLastManualCompletion', () async {
        final at = DateTime(2026, 3, 12, 9, 30);
        await repository.recordCompletion('vitamine_d', at: at);

        expect(await repository.getLastManualCompletion('vitamine_d'), at);
      });

      test('the most recent completion wins', () async {
        await repository.recordCompletion('vitamine_d', at: DateTime(2026, 3, 1));
        await repository.recordCompletion('vitamine_d', at: DateTime(2026, 3, 2));

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
          await repository.getLastManualCompletion('vitamine_d', babyId: 'baby_a'),
          isNotNull,
        );
        expect(
          await repository.getLastManualCompletion('vitamine_d', babyId: 'baby_b'),
          isNull,
        );
      });
    });

    group('invariant D2 (item détaché)', () {
      test('an item without subtype is never settled by an event, even of its own type',
          () async {
        // Le piège : un événement `sante` existe, du bon domaine, même du bon
        // sous-type — mais l'item est détaché, il ne se règle qu'à la main.
        final detached = ReminderItem(
          id: 'pedicure',
          labelKey: 'reminderPedicure',
          frequency: const ReminderFrequency.daily(),
          trackingType: TrackingType.sante,
        );
        await database.into(database.trackingEvents).insert(
          TrackingEventsCompanion.insert(
            type: 'sante',
            subtype: const Value('vitamine_d'),
            timestamp: DateTime.now(),
          ),
        );

        expect(await repository.getLastCompleted(detached), isNull);
        expect(await repository.getLastCompleted(detached, babyId: 'baby_a'), isNull);
      });
    });

    group('ignorer (reminder_dismissals)', () {
      test('dismissReminder keeps one row per (baby, item) and refreshes it',
          () async {
        await repository.dismissReminder('vitamine_d', at: DateTime(2026, 3, 1));
        await repository.dismissReminder('vitamine_d', at: DateTime(2026, 3, 2));

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
      test('enabled, dismissed et completed sont indépendants par bébé', () async {
        const presetId = 'vitamine_d';

        // Éteint pour A, intact pour B.
        await repository.setEnabled(presetId, enabled: false, babyId: 'baby_a');
        expect((await repository.getEnabledByItemId(babyId: 'baby_a'))[presetId], isFalse);
        expect(
          await repository.getEnabledByItemId(babyId: 'baby_b'),
          isNot(contains(presetId)),
        );

        // Ignoré pour A, le frère B n'est pas touché.
        await repository.dismissReminder(presetId, babyId: 'baby_a');
        expect(await repository.getLastDismissal(presetId, babyId: 'baby_a'), isNotNull);
        expect(await repository.getLastDismissal(presetId, babyId: 'baby_b'), isNull);

        // Fait pour A, rien pour B.
        await repository.recordCompletion(presetId, babyId: 'baby_a');
        expect(
          await repository.getLastManualCompletion(presetId, babyId: 'baby_a'),
          isNotNull,
        );
        expect(
          await repository.getLastManualCompletion(presetId, babyId: 'baby_b'),
          isNull,
        );

        // Une ligne par bébé par table : rien de partagé n'a été créé au
        // passage.
        expect(await database.getAllReminderSettings(), hasLength(1));
        expect(await database.getAllReminderDismissals(), hasLength(1));
        expect(await database.select(database.reminderCompletions).get(), hasLength(1));
      });
    });

    group("portage partagé (sentinelle '')", () {
      test("une ligne réglée sans profil s'applique à un bébé créé après coup",
          () async {
        // Ligne héritée d'une installation sans profil : écrite sans bébé.
        await repository.setEnabled('vitamine_d', enabled: false);
        expect((await database.getAllReminderSettings()).single.babyId, '');

        expect(
          (await repository.getEnabledByItemId(babyId: 'nouveau'))['vitamine_d'],
          isFalse,
        );
      });

      test('une ligne propre au bébé écrase la ligne partagée, pour lui seul', () async {
        await repository.setEnabled('vitamine_d', enabled: false);
        await repository.setEnabled('vitamine_d', enabled: true, babyId: 'nouveau');

        expect((await repository.getEnabledByItemId(babyId: 'nouveau'))['vitamine_d'], isTrue);
        expect((await repository.getEnabledByItemId(babyId: 'autre'))['vitamine_d'], isFalse);
        expect(await database.getAllReminderSettings(), hasLength(2));
      });

      test("un ignoré partagé s'applique à tous les bébés", () async {
        await repository.dismissReminder('vitamine_d');

        expect(
          await repository.getLastDismissal('vitamine_d', babyId: 'bébé_tard'),
          isNotNull,
        );
      });

      test('une complétion partagée règle un bébé créé après coup', () async {
        await repository.recordCompletion('vitamine_d');

        expect(
          await repository.getLastManualCompletion('vitamine_d', babyId: 'bébé_tard'),
          isNotNull,
        );
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

        expect(await repository.getCustomReminders(babyId: 'baby_a'), hasLength(1));
        expect(await repository.getCustomReminders(babyId: 'baby_b'), isEmpty);
      });

      test('un rappel créé sans profil est visible par tous les bébés', () async {
        await repository.insertCustomReminder(custom());
        final row = await database.select(database.customReminders).getSingle();
        expect(row.babyId, '');

        expect(await repository.getCustomReminders(babyId: 'baby_a'), hasLength(1));
        expect(await repository.getCustomReminders(babyId: 'baby_b'), hasLength(1));
      });
    });
  });
}
