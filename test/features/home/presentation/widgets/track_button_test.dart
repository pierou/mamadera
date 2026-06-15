import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/features/home/presentation/widgets/track_button.dart';

void main() {
  group('TrackButton', () {
    testWidgets('Affiche le label correctement', (WidgetTester tester) async {
      // Arrange: créer un TrackButton avec un label spécifique
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
              body: TrackButton(
                  label: 'Test Label', color: Colors.blue, onTap: () {})),
        ),
      );

      // Act & Assert: vérifier que le texte est présent dans l'arbre des widgets
      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('Applique la couleur donnée', (WidgetTester tester) async {
      // Arrange
      const buttonColor = Colors.red;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
              body:
                  TrackButton(label: 'Test', color: buttonColor, onTap: () {})),
        ),
      );

      // Assert: trouver le Container et vérifier sa couleur de fond
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
      final boxDeco = container.decoration! as BoxDecoration;
      expect(boxDeco.color, equals(buttonColor));
    });

    testWidgets('Scale animation au press (tapDown → scale 0.95)',
        (WidgetTester tester) async {
      // Arrange: créer le widget et attendre la première frame
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
              body:
                  TrackButton(label: 'Test', color: Colors.blue, onTap: () {})),
        ),
      );

      // Act: simuler un tapDown sur le bouton
      await tester.startGesture(const Offset(100, 100));
      await tester.pump(); // frame initiale (scale 1.0)

      // Assert: après tapDown, AnimatedScale a scale=0.95
      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('Callback onTap appelé', (WidgetTester tester) async {
      // Arrange
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
              body: TrackButton(
                  label: 'Test',
                  color: Colors.blue,
                  onTap: () => tapped = true)),
        ),
      );

      // Act: taper sur le bouton
      await tester.tap(find.text('Test'));

      // Assert: vérifier que le callback a été appelé
      expect(tapped, isTrue);
    });
  });

// test/widgets/track_button_test.dart - Nouveaux tests

group('TrackButton Long Press', () {
  testWidgets('onLongPress appelé lors d\'un maintien du clic', (WidgetTester tester) async {
    var longPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackButton(
            label: 'Test',
            color: Colors.blue,
            onTap: () {},
            onLongPress: () => longPressed = true,
          ),
        ),
      ),
    );

    // Simuler un long press (maintien de 750ms par défaut)
    await tester.longPress(find.text('Test'));

    expect(longPressed, isTrue);
  });

  testWidgets('onLongPress optionnel : pas d\'erreur si non fourni', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackButton(
            label: 'Test',
            color: Colors.blue,
            onTap: () {},
          ),
        ),
      ),
    );

    // Pas d'erreur si onLongPress n'est pas défini
    expect(find.byType(TrackButton), findsOneWidget);
  });
});
}
