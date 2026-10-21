import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/data/local/db_constants.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/features/reminders/presentation/widgets/home_reminders_section.dart';
import 'package:mamadera/features/reminders/presentation/widgets/reminder_row.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

import '../../data/repositories/mock_reminders_repository.dart';
import '../providers/no_poll_reminders_notifier.dart';

/// Switchable baby monitor for testing: allows parents to switch between monitoring different babies.
/// and the list of duties needs to be redefined.
class _SwitchableBabyNotifier extends ActiveBabyNotifier {
  _SwitchableBabyNotifier(this.profile);

  BabyProfile? profile;

  void switchTo(BabyProfile? profile) {
    this.profile = profile;
    state = AsyncValue.data(profile);
  }

  @override
  Future<BabyProfile?> build() async => profile;
}

/// A personalized, standalone reminder (D2): No treatment, manually adjusted.
CustomReminder thermometer() => CustomReminder(
      id: 1,
      label: 'Thermomètre',
      frequency: const ReminderFrequency.daily(),
      subtypeValue: null,
      completionSource: completionManual,
    );

Finder rowFor(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(ReminderRow),
    );

void main() {
  final babyA = BabyProfile(
    id: 'a',
    name: 'Anna',
    birthDate: DateTime(2024, 1, 15),
  );
  final babyB = BabyProfile(
    id: 'b',
    name: 'Boris',
    birthDate: DateTime(2024, 5, 2),
  );

  /// Analyze the section and return the container (deconstruction, re-evaluation), and...
  /// notify of baby (change of baby during the test).
  ///
  /// The actual chain of providers is maintained – only the deposit (which is a false entry) is removed.
  /// The memory management and notification mechanisms (without polling timers) have been replaced.
  /// and the list of settings for the "active baby" mode, as well as the custom reminders.
  /// The data from the repository are displayed together on the screen.
  Future<(ProviderContainer, _SwitchableBabyNotifier)> pumpSection(
    WidgetTester tester, {
    required RemindersRepository repo,
    required BabyProfile? baby,
  }) async {
    final babyNotifier = _SwitchableBabyNotifier(baby);
    final container = ProviderContainer(
      overrides: [
        remindersRepositoryProvider.overrideWith((ref) async => repo),
        activeBabyProvider.overrideWith(() => babyNotifier),
        // No probe timer: it would remain in a waiting state and fail.
        // The "no pending timer" invariant of the widget test.
        reminderNotifierProvider.overrideWith(NoPollRemindersNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.theme,
          home: const Scaffold(body: HomeRemindersSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, babyNotifier);
  }

  group('affichage', () {
    testWidgets(
        'les rappels dus se listent dans l\'ordre du notifieur : '
        'préréglages d\'abord, personnalisés ensuite (D1)', (tester) async {
      final repo = MockRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      await pumpSection(tester, repo: repo, baby: babyA);

      // The title includes the baby's first name (version 1.2, with localization support).
      // (placeholder): The previous, more precise feature: "Reminders to do."
      // It described the state without a name, replacing it with the name of the channel.
      expect(find.text('Rappels de Anna à faire'), findsOneWidget);
      final rows = tester.widgetList<ReminderRow>(find.byType(ReminderRow));
      expect(
        rows.map((r) => r.item.id).toList(),
        [
          'vitamine_d',
          'vitamine_k',
          'eye_cleaning',
          'face_cleaning',
          'custom_1',
        ],
      );
      // The text entered by the parent is displayed exactly as it is, and never as a key or code.
      expect(find.text('Thermomètre'), findsOneWidget);
    });

    testWidgets(
        'sans rappel dû : une ligne discrète, pas de titre ni de '
        'ligne (D1)', (tester) async {
      final repo = MockRemindersRepository();
      // All the settings have been configured today: there's nothing else to do.
      final now = DateTime.now();
      for (final id in const [
        'vitamine_d',
        'vitamine_k',
        'eye_cleaning',
        'face_cleaning',
      ]) {
        repo.lastCompletedByItem[id] = now;
      }
      await pumpSection(tester, repo: repo, baby: babyA);

      expect(find.text("Rien à faire pour l'instant."), findsOneWidget);
      expect(find.text('Rappels à faire'), findsNothing);
      expect(find.byType(ReminderRow), findsNothing);
    });

    testWidgets(
        'chaque ligne montre libellé, rythme, dernière fois et les '
        'deux actions (D1)', (tester) async {
      final repo = MockRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      repo.manualCompletedByItem['custom_1'] = DateTime(2026, 9, 30, 8, 0);
      await pumpSection(tester, repo: repo, baby: babyA);

      // The daily presets and the personalized settings share the same rhythm.
      // Vitamin K is administered monthly, on the day of birth.
      expect(find.textContaining('Tous les jours'), findsNWidgets(4));
      expect(find.textContaining('Le 15 de chaque mois'), findsOneWidget);
      // The manual records the last "incident" involving personalized items.
      expect(find.textContaining('Dernière fois: 30/09/2026 08:00'),
          findsOneWidget);
      // The default settings, without any specific events configured, indicate "Never."
      expect(find.textContaining('Jamais fait'), findsNWidgets(4));
      // The actions are not the same everywhere, and that is intentional (D2):
      // "Favorite" only exists in the detached recall mode. The four presets...
      // Settings related to a specific treatment are adjusted within that treatment's settings – a "Done" button is located on...
      // Their line of code would produce a result that the system would never actually process or display.
      // So, a box ticked for no reason.
      expect(find.byTooltip('Ignorer ce rappel'), findsNWidgets(5));
      expect(find.byTooltip('Marquer comme fait'), findsOneWidget);
      expect(
        find.descendant(
          of: rowFor('Thermomètre'),
          matching: find.byTooltip('Marquer comme fait'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowFor('Vitamine D'),
          matching: find.byTooltip('Marquer comme fait'),
        ),
        findsNothing,
      );
    });

    testWidgets(
        'quatre rappels dus : les quatre sont lisibles, pas un '
        '« +2 » (D1)', (tester) async {
      final repo = MockRemindersRepository();
      await pumpSection(tester, repo: repo, baby: babyA);

      // Same title update as above: Baby's name revealed.
      // In the localization message, never use string concatenation.
      expect(find.text('Rappels de Anna à faire'), findsOneWidget);
      expect(find.byType(ReminderRow), findsNWidgets(4));
      expect(find.text('Vitamine D'), findsOneWidget);
      expect(find.text('Vitamine K'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
      expect(find.text('Nettoyage du visage'), findsOneWidget);
    });
  });

  group('actions de la ligne (D1/D2/D3)', () {
    testWidgets(
        '« fait » sur un détaché : la ligne part, le journal est '
        'scopé au bébé actif (D1)', (tester) async {
      final repo = MockRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      final (container, _) = await pumpSection(tester, repo: repo, baby: babyA);

      await tester.tap(
        find.descendant(
          of: rowFor('Thermomètre'),
          matching: find.byTooltip('Marquer comme fait'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.recordCompletionCallCount, 1);
      expect(repo.lastRecordCompletionBabyId, babyA.id);
      expect(find.text('Thermomètre'), findsNothing);

      // "Done" did not cancel the recall: we are clearing the log and the...
      // ligne revient.
      repo.manualCompletedByItem.remove('custom_1');
      await container.read(reminderNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsOneWidget);
    });

    testWidgets(
        'un préréglage lié à un soin n offre aucun bouton « fait » '
        '— impossible de fabriquer un faux achèvement (D2)', (tester) async {
      final repo = MockRemindersRepository();
      await pumpSection(tester, repo: repo, baby: babyA);

      // No tap: the affordance doesn't exist. It's stronger than "tap" itself.
      // "Did nothing" - the parent can't even believe they've resolved the recall issue.
      expect(
        find.descendant(
          of: rowFor('Vitamine D'),
          matching: find.byTooltip('Marquer comme fait'),
        ),
        findsNothing,
      );
      expect(repo.recordCompletionCallCount, 0,
          reason: 'un soin se règle par son événement, jamais par un journal '
              'manuel fabriqué par le bouton');
      expect(find.text('Vitamine D'), findsOneWidget);

      // He still has a way to clear himself from the screen.
      expect(
        find.descendant(
          of: rowFor('Vitamine D'),
          matching: find.byTooltip('Ignorer ce rappel'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '« ignorer » : la ligne part, tient 24 h, revient de '
        'soi-même (D3)', (tester) async {
      final repo = MockRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      final (container, _) = await pumpSection(tester, repo: repo, baby: babyA);

      await tester.tap(
        find.descendant(
          of: rowFor('Thermomètre'),
          matching: find.byTooltip('Ignorer ce rappel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.dismissCallCount, 1);
      expect(repo.lastDismissBabyId, babyA.id);
      expect(find.text('Thermomètre'), findsNothing);

      // One hour later: still deleted.
      repo.dismissedById['custom_1'] =
          DateTime.now().subtract(const Duration(hours: 1));
      await container.read(reminderNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsNothing);

      // Twenty-five hours later: the bill is due again.
      repo.dismissedById['custom_1'] =
          DateTime.now().subtract(const Duration(hours: 25));
      await container.read(reminderNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsOneWidget);
    });

    testWidgets(
        'un ignoré pour le bébé A reste affiché pour le bébé B '
        '(D3, à l\'écran)', (tester) async {
      final repo = ScopedDismissalRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      final (container, babyNotifier) =
          await pumpSection(tester, repo: repo, baby: babyA);
      expect(find.text('Thermomètre'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: rowFor('Thermomètre'),
          matching: find.byTooltip('Ignorer ce rappel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsNothing);
      expect(repo.lastDismissBabyId, babyA.id);

      // Parent B gives a reminder to baby B, which baby B remembers, while baby A ignores the reminder.
      // ne le concerne pas.
      babyNotifier.switchTo(babyB);
      await container.read(reminderNotifierProvider.future);
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsOneWidget);
    });
  });
}
