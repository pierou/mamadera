import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/l10n/app_localizations.dart';

import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/home/presentation/screens/home_screen.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_screen_test.mocks.dart';

/// Helper : trouve un TrackButton par son label.
Finder findTrackButton(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TrackButton && widget.label == label,
  );
}

@GenerateNiceMocks([MockSpec<TrackingRepository>()])
void main() {
  late MockTrackingRepository mockRepo;

  setUp(() => mockRepo = MockTrackingRepository());

  /// Helper : pompe HomeScreen avec le repo mocked.
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trackingRepositoryProvider.overrideWith((ref) async => mockRepo),
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
          home: const HomeScreen(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Affichage des TrackButtons
  // ──────────────────────────────────────────────
  group('Affichage des 4 TrackButtons', () {
    testWidgets('Miam, Sante, Caca, Dodo sont affiches', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('Miam'), findsOneWidget);
      expect(find.text('Sant\u00e9'), findsOneWidget);
      expect(find.text('Caca'), findsOneWidget);
      expect(find.text('Dodo'), findsOneWidget);
    });

    testWidgets('chaque TrackButton a la couleur AppTheme attendue', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final colors = <Color>{};
      for (final match in tester.widgetList<Container>(find.byType(Container))) {
        if (match.decoration is BoxDecoration) {
          final deco = match.decoration! as BoxDecoration;
          if (deco.color != null && deco.color != Colors.transparent) {
            colors.add(deco.color!);
          }
        }
      }

      expect(colors.contains(AppTheme.miam), isTrue, reason: 'Miam');
      expect(colors.contains(AppTheme.sante), isTrue, reason: 'Sant\u00e9');
      expect(colors.contains(AppTheme.caca), isTrue, reason: 'Caca');
      expect(colors.contains(AppTheme.dodo), isTrue, reason: 'Dodo');
    });

    testWidgets('BottomNavigationBar presente avec 3 items', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Navigation via bottom nav
  // ──────────────────────────────────────────────
  group('Navigation via bottom nav', () {
    testWidgets('tap Historique -> affiche HistoryScreen', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('Miam'), findsOneWidget);

      final historyIcon = find.byIcon(Icons.history);
      await tester.tap(historyIcon);
      await tester.pumpAndSettle();

      // AppBar "Historique" + label du bottom nav.
      expect(find.text('Historique'), findsNWidgets(2));
    });

    testWidgets('tap Menu -> affiche MenuScreen', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final menuIcon = find.byIcon(Icons.settings);
      await tester.tap(menuIcon);
      await tester.pumpAndSettle();

      // AppBar "Menu" + label du bottom nav.
      expect(find.text('Menu'), findsNWidgets(2));
    });

    testWidgets('tap Accueil -> retour a la grille', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      final homeIcon = find.byIcon(Icons.home);
      await tester.tap(homeIcon);
      await tester.pumpAndSettle();

      expect(find.text('Miam'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Interactions TrackButtons -> dialogs ouverts
  // ──────────────────────────────────────────────
  group('Interactions Miam/Sante/Caca/Dodo', () {
    testWidgets('tap Miam -> appel direct insertEvent (pas de dialog)', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      final miamBtn = find.text('Miam');
      expect(miamBtn, findsOneWidget);

      await tester.tap(miamBtn);
      await tester.pumpAndSettle();

      // insertEvent a ete appele. Verifier que c'est un FeedingEvent.
      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<FeedingEvent>());

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('tap Sante -> ouverture HealthSubtypeDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final santeBtn = find.text('Sant\u00e9');
      expect(santeBtn, findsOneWidget);

      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Dialog doit contenir "Type de soin".
      expect(find.text('Type de soin'), findsOneWidget);
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
    });

    testWidgets('tap Caca -> ouverture WasteDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final cacaBtn = findTrackButton('Caca');
      expect(cacaBtn, findsOneWidget);

      await tester.tap(cacaBtn);
      await tester.pumpAndSettle();

      // FilterChips avec emojis.
        expect(find.text('🟡 Pipi'), findsOneWidget);
    });

    testWidgets('tap Dodo -> ouverture DurationPickerDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      expect(dodoBtn, findsOneWidget);

      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Titre du DurationPickerDialog.
      expect(find.text('Dur\u00e9e du sommeil'), findsOneWidget);
      expect(find.text('Confirmer'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Confirmation des dialogues -> insertEvent appele
  // ──────────────────────────────────────────────
  group('Confirmation des dialogues', () {
    testWidgets('Dodo: Confirmer envoie SleepEvent via insertEvent', (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Durée par défaut (30 min).
  expect(find.text('30 min'), findsOneWidget);

      // Confirmer.
      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // insertEvent a ete appele avec un SleepEvent.
      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<SleepEvent>());
    });

    testWidgets('Dodo: Annuler ne declenche aucun evenement', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Tap en dehors du bottom sheet pour fermer.
      await tester.tapAt(const Offset(400, 50));
      await tester.pumpAndSettle();

      verifyNever(mockRepo.insertEvent(any));
    });

    testWidgets('Sante: Enregistrer sans selection -> SnackBar d\'erreur', (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final santeBtn = find.text('Sant\u00e9');
      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Tap Enregistrer sans selection.
      final registerButton = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Enregistrer'),
      );
      expect(registerButton, findsOneWidget);
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // SnackBar d'erreur.
      expect(find.textContaining('électionner'), findsOneWidget);
    });

    testWidgets('Sante: Selection + Enregistrer -> HealthEvent via insertEvent', (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final santeBtn = find.text('Sant\u00e9');
      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Selectionner "Nettoyage des yeux".
      final nettoyageYeux = find.text('Nettoyage des yeux');
      expect(nettoyageYeux, findsOneWidget);
      await tester.ensureVisible(nettoyageYeux);
      await tester.tap(nettoyageYeux, warnIfMissed: false);
      await tester.pumpAndSettle();

      final submitBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Enregistrer'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<HealthEvent>());
    });

    testWidgets('Caca: Enregistrer -> DiaperEvent via insertEvent', (tester) async {
      when(mockRepo.insertEvent(any)).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      final cacaBtn = findTrackButton('Caca');
      await tester.tap(cacaBtn);
      await tester.pumpAndSettle();

        expect(find.text('🟡 Pipi'), findsOneWidget);
        expect(find.text('🟤 Caca'), findsOneWidget);

      final submitBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Enregistrer'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      final captured = verify(mockRepo.insertEvent(captureAny)).captured;
      expect(captured.first, isA<DiaperEvent>());
    });
  });
}
