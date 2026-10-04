import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/l10n/app_localizations.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/home/presentation/screens/home_screen.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

import '../../../reminders/data/repositories/mock_reminders_repository.dart';
import '../../../reminders/presentation/providers/no_poll_reminders_notifier.dart';

/// Harnais de l'accueil pour le prénom du bébé actif : mêmes overrides
/// que le harnais principal (dépôt de rappels en mémoire, notifier sans
/// timer, mesures vides, profil existant) plus un notifier de bébé
/// commutable pour prouver que l'en-tête est vivant, pas capturé.
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

  /// Pompe l'accueil complet et renvoie le notifier de bébé pour un
  /// changement de profil au milieu du test.
  Future<_SwitchableBabyNotifier> pumpHome(
    WidgetTester tester, {
    required BabyProfile? baby,
  }) async {
    final babyNotifier = _SwitchableBabyNotifier(baby);
    tester.view.physicalSize = const Size(600, 900);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // La rangée de croissance ne doit pas ouvrir la vraie base en test.
          measurementNotifierProvider
              .overrideWith(() => _NoMeasurementsNotifier()),
          activeBabyProvider.overrideWith(() => babyNotifier),
          anyBabyExistsProvider
              .overrideWith(() => _BabyExistsNotifier()),
          // La section de rappels se remplit sans base : dépôt en mémoire,
          // notifier sans timer de sondage (même recette que le harnais
          // principal).
          remindersRepositoryProvider
              .overrideWith((ref) async => MockRemindersRepository()),
          reminderNotifierProvider
              .overrideWith(NoPollRemindersNotifier.new),
        ],
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
          home: Scaffold(body: const HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return babyNotifier;
  }

  group('Prénom du bébé actif sur l’accueil', () {
    testWidgets('shows the active baby name on home', (tester) async {
      await pumpHome(tester, baby: babyA);

      // L'en-tête porte le prénom, lisible, au-dessus de la grille.
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('the name is carried by the AppBar title, not the body',
        (tester) async {
      await pumpHome(tester, baby: babyA);

      // Le prénom vit dans le titre de la barre d'app (dans le SafeArea du
      // Scaffold) : posé en tête du corps de l'écran, il passait sous la
      // bande de statut du système sur Android.
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
      expect((appBar.title! as Text).data, 'Anna');
    });

    testWidgets('no active baby means no AppBar on home', (tester) async {
      await pumpHome(tester, baby: null);

      // Pas de bébé actif : pas de barre d'app, et le contenu reste
      // sous la bande de statut par son propre SafeArea.
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('switching the active baby updates the name shown',
        (tester) async {
      final babyNotifier = await pumpHome(tester, baby: babyA);
      expect(find.text('Anna'), findsOneWidget);

      // Le parent passe à l'autre bébé : l'en-tête et le titre des rappels
      // suivent — un prénom capturé à la première construction resterait
      // sur « Anna » et ferait échouer le test.
      babyNotifier.switchTo(babyB);
      await tester.pumpAndSettle();

      expect(find.text('Anna'), findsNothing);
      expect(find.text('Boris'), findsOneWidget);
    });

    testWidgets('no active baby renders no name and no null text',
        (tester) async {
      await pumpHome(tester, baby: null);

      // Pas de « null », pas de faux identité : le premier lancement
      // gère la création du profil.
      expect(find.text('null'), findsNothing);

      // Le titre des rappels retombe sur la forme neutre, sans prénom.
      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));
      expect(find.text(l10n.reminderListTitle), findsOneWidget);
    });

    testWidgets('reminders header contains the name via the l10n placeholder',
        (tester) async {
      await pumpHome(tester, baby: babyA);

      // L'assertion porte sur le message rendu par la chaîne, pas sur une
      // chaîne française recopiée ici.
      final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));
      expect(find.text(l10n.reminderListTitleFor('Anna')), findsOneWidget);
      // Et la forme neutre n'existe plus dès qu'un prénom est présent.
      expect(find.text(l10n.reminderListTitle), findsNothing);
    });

    testWidgets('a 30 character baby name does not overflow', (tester) async {
      const longName = 'Aaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final baby = BabyProfile(
        id: 'long',
        name: longName,
        birthDate: DateTime(2024, 3, 10),
      );
      await pumpHome(tester, baby: baby);

      // L'en-tête tronque (ellipsis) : aucun rapport d'overflow.
      expect(tester.takeException(), isNull);
      expect(find.text(longName), findsOneWidget);
    });
  });
}

/// Notifier de bébé commutable : le changement de profil publie l'état
/// directement, comme un [ActiveBabyNotifier.switchProfile] abouti.
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

/// Un profil existe : l'onboarding ne s'ouvre pas et cache l'accueil.
class _BabyExistsNotifier extends AnyBabyExistsNotifier {
  _BabyExistsNotifier();

  @override
  Future<bool> build() async => true;
}

/// Mesures vides : la rangée de croissance affiche des tirets sans base.
class _NoMeasurementsNotifier extends MeasurementNotifier {
  _NoMeasurementsNotifier();

  @override
  Future<List<GrowthMeasurement>> build() async => const [];
}
