import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/features/reminders/presentation/screens/reminder_settings_screen.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

import '../../data/repositories/mock_reminders_repository.dart';

/// Stub notifier that returns a fixed baby profile on build.
class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}

final _baby = BabyProfile(
  id: 'baby-1',
  name: 'Léa',
  birthDate: DateTime(2026, 1, 15),
);

/// Le switch de la ligne dont le titre est [label].
Finder _switchFor(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(SwitchListTile),
      ),
      matching: find.byType(Switch),
    );

bool _isOn(WidgetTester tester, String label) =>
    tester.widget<Switch>(find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(SwitchListTile),
      ),
      matching: find.byType(Switch),
    ))
        .value;

void main() {
  late MockRemindersRepository mockReminders;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remindersRepositoryProvider.overrideWith((ref) async => mockReminders),
          activeBabyProvider.overrideWith(() => _ActiveBabyStub(_baby)),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ReminderSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockReminders = MockRemindersRepository();
  });

  group('ReminderSettingsScreen', () {
    testWidgets('affiche le titre et la promesse de confidentialité', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Rappels'), findsOneWidget);
      expect(
        find.text(
          "Bandeaux affichés sur l'accueil tant que le soin n'a pas été saisi. "
          'Aucune notification système n\'est envoyée : tout reste sur cet appareil.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('liste les quatre rappels préréglés avec leur fréquence', (tester) async {
      await pumpScreen(tester);

      // Nom complet du soin, pas l'abréviation de la pastille d'accueil.
      expect(find.text('Vitamine D'), findsOneWidget);
      expect(find.text('Vitamine K'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
      expect(find.text('Nettoyage du visage'), findsOneWidget);

      expect(find.text('Tous les jours'), findsNWidgets(3));
      // Vit. K est calée sur le jour de naissance (15) du profil actif.
      expect(find.text('Le 15 de chaque mois'), findsOneWidget);
    });

    testWidgets('tout est activé par défaut : les rappels sont une option de retrait', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(SwitchListTile), findsNWidgets(4));
      for (final label in ['Vitamine D', 'Vitamine K', 'Nettoyage des yeux', 'Nettoyage du visage']) {
        expect(_isOn(tester, label), isTrue, reason: label);
      }
    });

    testWidgets('un rappel déjà éteint est affiché éteint', (tester) async {
      mockReminders.enabledById['eye_cleaning'] = false;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Nettoyage des yeux'), isFalse);
      expect(_isOn(tester, 'Vitamine D'), isTrue);
    });

    testWidgets('un enabled enregistré true laisse le rappel activé', (tester) async {
      mockReminders.enabledById['vitamine_d'] = true;

      await pumpScreen(tester);

      expect(_isOn(tester, 'Vitamine D'), isTrue);
    });

    testWidgets('éteindre un rappel l\'enregistre et le switch reste éteint', (tester) async {
      await pumpScreen(tester);

      await tester.tap(_switchFor('Vitamine D'));
      await tester.pumpAndSettle();

      expect(mockReminders.enabledById['vitamine_d'], isFalse);
      expect(mockReminders.setEnabledCallCount, 1);
      // Pas de retour en arrière le temps d'un rechargement.
      expect(_isOn(tester, 'Vitamine D'), isFalse);
    });

    testWidgets('rallumer un rappel éteint l\'enregistre', (tester) async {
      mockReminders.enabledById['face_cleaning'] = false;

      await pumpScreen(tester);

      await tester.tap(_switchFor('Nettoyage du visage'));
      await tester.pumpAndSettle();

      expect(mockReminders.enabledById['face_cleaning'], isTrue);
      expect(_isOn(tester, 'Nettoyage du visage'), isTrue);
    });

    testWidgets('la liste reste affichée quand tout est déjà fait aujourd\'hui', (tester) async {
      // Les réglages n'ont rien à voir avec le fait qu'un rappel soit dû ou non :
      // la liste des préréglages s'affiche même si aucun n'est en retard.
      mockReminders.lastCompletedByItem['vitamine_d'] = DateTime.now();
      mockReminders.lastCompletedByItem['vitamine_k'] = DateTime.now();
      mockReminders.lastCompletedByItem['eye_cleaning'] = DateTime.now();
      mockReminders.lastCompletedByItem['face_cleaning'] = DateTime.now();

      await pumpScreen(tester);

      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
