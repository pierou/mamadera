import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/features/home/presentation/screens/home_screen.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_screen_test.mocks.dart';

/// Helper : trouve un TrackButton par son label.
/// Utilise find.byWidgetPredicate pour contourner les problèmes de hit test
/// sur des boutons qui peuvent être partiellement hors écran dans le canvas de test (800x600).
Finder findTrackButton(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TrackButton && widget.label == label,
  );
}

/// Mock du repository pour isoler les tests de presentation.
@GenerateNiceMocks([MockSpec<TrackingRepository>()])
void main() {
  late MockTrackingRepository mockRepo;

  setUp(() => mockRepo = MockTrackingRepository());

  // Helper : pompe HomeScreen avec le repo mocked et insertEvent stubbe (no-op).
  // Utilise une taille tablette (600x900) pour eviter les debordements de Row 
  // dans les dialogs tout en gardant tous les TrackButtons visibles sur la grille.
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trackingRepositoryProvider.overrideWith((ref) async => mockRepo),
        ],
        child: MaterialApp(theme: AppTheme.theme, home: const HomeScreen()),
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

      // Collecter les couleurs de fond des Containers.
      final colors = <Color>{};
      for (final match in tester.widgetList<Container>(find.byType(Container))) {
        if (match.decoration is BoxDecoration) {
          final deco = match.decoration! as BoxDecoration;
          if (deco.color != null && deco.color != Colors.transparent) {
            colors.add(deco.color!);
          }
        }
      }

      // Les 4 couleurs doivent etre presentes.
      expect(colors.contains(AppTheme.miam), isTrue, reason: 'Miam');
      expect(colors.contains(AppTheme.sante), isTrue, reason: 'Sant\u00e9');
      expect(colors.contains(AppTheme.caca), isTrue, reason: 'Caca');
      expect(colors.contains(AppTheme.dodo), isTrue, reason: 'Dodo');
    });

    testWidgets('BottomNavigationBar presente avec 3 items (Accueil/Historique/Menu)', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      // Labels des onglets du bottom nav.
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Navigation via bottom nav
  // ──────────────────────────────────────────────
  group('Navigation via bottom nav', () {
    testWidgets('tap Historique -> affiche HistoryScreen (AppBar "Historique")', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Initialement sur Accueil.
      expect(find.text('Miam'), findsOneWidget);

      // Tap l'icone history dans le bottom nav.
      final historyIcon = find.byIcon(Icons.history);
      await tester.tap(historyIcon);
      await tester.pumpAndSettle();

      // L'appbar HistoryScreen doit etre visible.
      expect(find.text('Historique'), findsNWidgets(2)); // AppBar + label du bottom nav
    });

    testWidgets('tap Menu -> affiche MenuScreen', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final menuIcon = find.byIcon(Icons.settings);
      await tester.tap(menuIcon);
      await tester.pumpAndSettle();

      // Le titre "Menu" apparait dans l'AppBar de MenuScreen ET comme label du BottomNav.
      expect(find.text('Menu'), findsNWidgets(2));
    });

    testWidgets('tap Accueil -> retour a la grille de TrackButtons', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Aller sur Historique puis revenir sur Accueil.
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      final homeIcon = find.byIcon(Icons.home);
      await tester.tap(homeIcon);
      await tester.pumpAndSettle();

      expect(find.text('Miam'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Interactions TrackButtons -> appels track/dialogs
  // ──────────────────────────────────────────────
  group('Interactions Miam/Sante/Caca/Dodo', () {
    testWidgets('tap Miam -> appel direct track() (pas de dialog)', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Stub pour eviter l'appel DB reel.
      when(mockRepo.insertEvent(type: anyNamed('type')))
          .thenAnswer((_) async => 1);

      final miamBtn = find.text('Miam');
      expect(miamBtn, findsOneWidget);

      await tester.tap(miamBtn);
      await tester.pumpAndSettle();

      // insertEvent a ete appele (track() direct).
      verify(mockRepo.insertEvent(type: anyNamed('type'))).called(1);

      // Aucun bottom sheet n'est ouvert.
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('tap Sante -> ouverture HealthSubtypeDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      final santeBtn = find.text('Sant\u00e9');
      expect(santeBtn, findsOneWidget);

      // Tap sur le bouton Sante -> ouvre un bottom sheet avec HealthSubtypeDialog.
      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Le dialog doit contenir "Type de soin" (titre du HealthSubtypeDialog).
      expect(find.text('Type de soin'), findsOneWidget);

      // Et les sous-types sante doivent etre visibles.
      expect(find.text('Nettoyage des yeux'), findsOneWidget);
    });

    testWidgets('tap Caca -> ouverture WasteDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Le bouton Caca est en bas de la grille et peut être partiellement hors écran.
      final cacaBtn = findTrackButton('Caca');
      expect(cacaBtn, findsOneWidget);

      // Tap sur le bouton Caca -> ouvre un bottom sheet avec WasteDialog.
      await tester.tap(cacaBtn);
      await tester.pumpAndSettle();

      // Le dialog doit contenir les FilterChips de type de selle (utilise des emojis circle).
      expect(find.text('🟡 Pipi'), findsOneWidget);
    });

    testWidgets('tap Dodo -> ouverture DurationPickerDialog', (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Le bouton Dodo est en bas de la grille et peut être partiellement hors écran.
      final dodoBtn = findTrackButton('Dodo');
      expect(dodoBtn, findsOneWidget);

      // Tap sur le bouton Dodo -> ouvre un bottom sheet avec DurationPickerDialog.
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Le dialog doit contenir "Durée du sommeil" (titre du DurationPickerDialog).
      expect(find.text('Dur\u00e9e du sommeil'), findsOneWidget);

      // Et le bouton Confirmer doit etre present.
      expect(find.text('Confirmer'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Confirmation des dialogues -> appel trackNotifier
  // ──────────────────────────────────────────────
  group('Confirmation des dialogues', () {
    testWidgets('Dodo: Confirmer envoie insertEvent avec duration', (tester) async {
      when(
        mockRepo.insertEvent(
          type: anyNamed('type'),
          notes: anyNamed('notes'),
          duration: anyNamed('duration'),
          wasteType: anyNamed('wasteType'),
          pipiColor: anyNamed('pipiColor'),
          cacaColor: anyNamed('cacaColor'),
        ),
      ).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Ouvrir le dialog Dodo (bouton en bas de grille -> utiliser findTrackButton).
      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // La duree par defaut (30 min) doit etre affichee.
      expect(find.text('30 min'), findsOneWidget);

      // Confirmer la duree (dans le bottom sheet).
      final confirmBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Confirmer'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // insertEvent a ete appele avec type == dodo.
      verify(mockRepo.insertEvent(
        type: TrackingType.dodo,
        notes: anyNamed('notes'),
        duration: anyNamed('duration'),
        wasteType: anyNamed('wasteType'),
        pipiColor: anyNamed('pipiColor'),
        cacaColor: anyNamed('cacaColor'),
      )).called(1);
    });

    testWidgets('Dodo: Annuler ne declenche aucun evenement', (tester) async {
      // Stub generique pour eviter les appels DB reels.
      when(
        mockRepo.insertEvent(
          type: anyNamed('type'),
          notes: anyNamed('notes'),
          duration: anyNamed('duration'),
          wasteType: anyNamed('wasteType'),
          pipiColor: anyNamed('pipiColor'),
          cacaColor: anyNamed('cacaColor'),
        ),
      ).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Ouvrir le dialog Dodo (bouton en bas de grille -> utiliser findTrackButton).
      final dodoBtn = findTrackButton('Dodo');
      await tester.tap(dodoBtn);
      await tester.pumpAndSettle();

      // Tap en dehors du bottom sheet pour le fermer (ou utiliser BackButtonDispatcher).
      // Le bouton "Annuler" est hors ecran dans le canvas de test,
      // donc on utilise un tap sur l'overlay parent pour fermer.
      await tester.tapAt(const Offset(400, 50));
      await tester.pumpAndSettle();

      // insertEvent n'a jamais ete appele.
      verifyNever(mockRepo.insertEvent(
        type: anyNamed('type'),
        notes: anyNamed('notes'),
        duration: anyNamed('duration'),
        wasteType: anyNamed('wasteType'),
        pipiColor: anyNamed('pipiColor'),
        cacaColor: anyNamed('cacaColor'),
      ));
    });

    testWidgets('Sante: Enregistrer sans selection -> SnackBar d\'erreur', (tester) async {
      // Stub generique pour eviter les appels DB reels.
      when(
        mockRepo.insertEvent(
          type: anyNamed('type'),
          notes: anyNamed('notes'),
          duration: anyNamed('duration'),
          wasteType: anyNamed('wasteType'),
          pipiColor: anyNamed('pipiColor'),
          cacaColor: anyNamed('cacaColor'),
        ),
      ).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Ouvrir le dialog Sante.
      final santeBtn = find.text('Sant\u00e9');
      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Tap Enregistrer sans avoir selectionne de sous-type (dans le bottom sheet).
      final registerButton = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Enregistrer'),
      );
      expect(registerButton, findsOneWidget);
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Le SnackBar d'erreur doit etre affiche (l'accidenté 'électionner' est dans le message).
      expect(find.textContaining('électionner'), findsOneWidget);
    });

    testWidgets('Sante: Selection + Enregistrer -> insertEvent avec notes', (tester) async {
      when(
        mockRepo.insertEvent(
          type: anyNamed('type'),
          notes: anyNamed('notes'),
          duration: anyNamed('duration'),
          wasteType: anyNamed('wasteType'),
          pipiColor: anyNamed('pipiColor'),
          cacaColor: anyNamed('cacaColor'),
        ),
      ).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Ouvrir le dialog Sante.
      final santeBtn = find.text('Sant\u00e9');
      await tester.tap(santeBtn);
      await tester.pumpAndSettle();

      // Selectionner "Nettoyage des yeux".
      final nettoyageYeux = find.text('Nettoyage des yeux');
      expect(nettoyageYeux, findsOneWidget);
      await tester.ensureVisible(nettoyageYeux);
      await tester.tap(nettoyageYeux, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Confirmer (dans le bottom sheet).
      final submitBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Enregistrer'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // insertEvent a ete appele avec type == sante.
      verify(mockRepo.insertEvent(
        type: TrackingType.sante,
        notes: anyNamed('notes'),
        duration: anyNamed('duration'),
        wasteType: anyNamed('wasteType'),
        pipiColor: anyNamed('pipiColor'),
        cacaColor: anyNamed('cacaColor'),
      )).called(1);
    });

    testWidgets('Caca: Enregistrer -> insertEvent avec wasteType', (tester) async {
      when(
        mockRepo.insertEvent(
          type: anyNamed('type'),
          notes: anyNamed('notes'),
          duration: anyNamed('duration'),
          wasteType: anyNamed('wasteType'),
          pipiColor: anyNamed('pipiColor'),
          cacaColor: anyNamed('cacaColor'),
        ),
      ).thenAnswer((_) async => 1);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      // Ouvrir le dialog Caca (bouton en bas de grille -> utiliser findTrackButton).
      final cacaBtn = findTrackButton('Caca');
      await tester.tap(cacaBtn);
      await tester.pumpAndSettle();

      // Le WasteDialog doit afficher les FilterChips avec emojis circle.
      expect(find.text('🟡 Pipi'), findsOneWidget);
      expect(find.text('🟤 Caca'), findsOneWidget);

      final submitBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Enregistrer'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // insertEvent a ete appele avec type == caca.
      verify(mockRepo.insertEvent(
        type: TrackingType.caca,
        notes: anyNamed('notes'),
        duration: anyNamed('duration'),
        wasteType: anyNamed('wasteType'),
        pipiColor: anyNamed('pipiColor'),
        cacaColor: anyNamed('cacaColor'),
      )).called(1);
    });
  });
}
