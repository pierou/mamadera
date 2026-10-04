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

/// Notifier de bébé commutable en test : le parent passe d'un bébé à l'autre,
/// et la liste des dus doit se ré-scoper.
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

/// Un rappel personnalisé détaché (D2) : pas de soin, réglé à la main.
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

  /// Pompe la section et renvoie le container (teardown, ré-évaluation) et
  /// le notifier de bébé (changement de bébé au milieu du test).
  ///
  /// La chaîne de providers réelle est conservée — seuls le dépôt (faux, en
  /// mémoire) et le notifier (sans timer de sondage) sont remplacés : c'est
  /// ainsi que la liste des préréglages du bébé actif et les rappels custom
  /// du dépôt montent ensemble à l'écran.
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
        // Pas de timer de sondage : il resterait en attente et ferait échouer
        // l'invariant « no pending timer » du test de widget.
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

      // Le titre porte le prénom du bébé actif (v1.2, message l10n avec
      // placeholder) : l'ancienne attente exacte « Rappels à faire »
      // décrivait l'état sans prénom, remplacé par celui de la chaîne.
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
      // Le libellé saisi par le parent s'affiche tel quel, jamais comme clé.
      expect(find.text('Thermomètre'), findsOneWidget);
    });

    testWidgets('sans rappel dû : une ligne discrète, pas de titre ni de '
        'ligne (D1)', (tester) async {
      final repo = MockRemindersRepository();
      // Tous les préréglages réglés aujourd'hui : plus rien à faire.
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

    testWidgets('chaque ligne montre libellé, rythme, dernière fois et les '
        'deux actions (D1)', (tester) async {
      final repo = MockRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      repo.manualCompletedByItem['custom_1'] = DateTime(2026, 9, 30, 8, 0);
      await pumpSection(tester, repo: repo, baby: babyA);

      // Les préréglages quotidiens et le personnalisé partagent le rythme ;
      // la vitamine K est mensuelle, au jour de naissance.
      expect(find.textContaining('Tous les jours'), findsNWidgets(4));
      expect(find.textContaining('Le 15 de chaque mois'), findsOneWidget);
      // Le journal manuel date le dernier « fait » du personnalisé.
      expect(find.textContaining('Dernière fois: 30/09/2026 08:00'),
          findsOneWidget);
      // Les préréglages, sans événement, disent « Jamais fait ».
      expect(find.textContaining('Jamais fait'), findsNWidgets(4));
      // Les actions ne sont pas les mêmes partout, et c'est voulu (D2) :
      // « Fait » n'existe que sur le rappel détaché. Les quatre préréglages
      // liés à un soin se règlent en suivant le soin — un bouton « Fait » sur
      // leur ligne produirait un achèvement que le service ne lirait jamais,
      // donc une case cochée pour rien.
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

    testWidgets('quatre rappels dus : les quatre sont lisibles, pas un '
        '« +2 » (D1)', (tester) async {
      final repo = MockRemindersRepository();
      await pumpSection(tester, repo: repo, baby: babyA);

      // Même mise à jour du titre que plus haut : prénom du bébé actif
      // dans le message l10n, jamais de concaténation.
      expect(find.text('Rappels de Anna à faire'), findsOneWidget);
      expect(find.byType(ReminderRow), findsNWidgets(4));
      expect(find.text('Vitamine D'), findsOneWidget);
      expect(find.text('Vitamine K'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
      expect(find.text('Nettoyage du visage'), findsOneWidget);
    });
  });

  group('actions de la ligne (D1/D2/D3)', () {
    testWidgets('« fait » sur un détaché : la ligne part, le journal est '
        'scopé au bébé actif (D1)', (tester) async {
      final repo = MockRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      final (container, _) =
          await pumpSection(tester, repo: repo, baby: babyA);

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

      // « Fait » n'a pas supprimé le rappel : on vide le journal et la
      // ligne revient.
      repo.manualCompletedByItem.remove('custom_1');
      await container.read(reminderNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsOneWidget);
    });

    testWidgets('un préréglage lié à un soin n offre aucun bouton « fait » '
        '— impossible de fabriquer un faux achèvement (D2)', (tester) async {
      final repo = MockRemindersRepository();
      await pumpSection(tester, repo: repo, baby: babyA);

      // Pas de tap : l'affordance n'existe pas. C'est plus fort que « tap ne
      // fait rien » — le parent ne peut même pas croire avoir réglé le rappel.
      expect(
        find.descendant(
          of: rowFor('Vitamine D'),
          matching: find.byTooltip('Marquer comme fait'),
        ),
        findsNothing,
      );
      expect(repo.recordCompletionCallCount, 0,
          reason:
              'un soin se règle par son événement, jamais par un journal '
              'manuel fabriqué par le bouton');
      expect(find.text('Vitamine D'), findsOneWidget);

      // Il garde de quoi se faire effacer de l écran.
      expect(
        find.descendant(
          of: rowFor('Vitamine D'),
          matching: find.byTooltip('Ignorer ce rappel'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('« ignorer » : la ligne part, tient 24 h, revient de '
        'soi-même (D3)', (tester) async {
      final repo = MockRemindersRepository();
      repo.customRemindersById[1] = thermometer();
      final (container, _) =
          await pumpSection(tester, repo: repo, baby: babyA);

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

      // Une heure après : toujours supprimé.
      repo.dismissedById['custom_1'] =
          DateTime.now().subtract(const Duration(hours: 1));
      await container.read(reminderNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsNothing);

      // Vingt-cinq heures après : de nouveau dû.
      repo.dismissedById['custom_1'] =
          DateTime.now().subtract(const Duration(hours: 25));
      await container.read(reminderNotifierProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsOneWidget);
    });

    testWidgets('un ignoré pour le bébé A reste affiché pour le bébé B '
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

      // Le parent passe au bébé B : le rappel lui est dû, l'ignoré de A
      // ne le concerne pas.
      babyNotifier.switchTo(babyB);
      await container.read(reminderNotifierProvider.future);
      await tester.pumpAndSettle();
      expect(find.text('Thermomètre'), findsOneWidget);
    });
  });
}
