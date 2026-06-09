import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/widgets/bottom_nav.dart';

void main() {
  group('AppBottomNav', () {
    testWidgets('Affiche 3 items : Accueil, Historique, Menu',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(currentIndex: 0, onTap: (_) {}),
          ),
        ),
      );

      // Assert : les 3 labels sont présents
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('Item sélectionné correspond à currentIndex',
        (WidgetTester tester) async {
      // Arrange : currentIndex = 1 → Historique est actif
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(currentIndex: 1, onTap: (_) {}),
          ),
        ),
      );

      // Assert : récupérer le BottomNavigationBar et vérifier currentIndex
      final navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(1));

      // Act & Assert : changer pour index 2 → Menu est actif
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(currentIndex: 2, onTap: (_) {}),
          ),
        ),
      );

      final navBarUpdated =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBarUpdated.currentIndex, equals(2));
    });

    testWidgets('Callback onTap appelé avec le bon index',
        (WidgetTester tester) async {
      // Arrange
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
                currentIndex: 0, onTap: (index) => tappedIndex = index),
          ),
        ),
      );

      // Act : taper sur le deuxième item "Historique" (index 1)
      await tester.tap(find.text('Historique'));
      await tester.pump();

      // Assert : le callback a été appelé avec l'index 1
      expect(tappedIndex, equals(1));

      // Act : taper sur le troisième item "Menu" (index 2)
      await tester.tap(find.text('Menu'));
      await tester.pump();

      // Assert : le callback a été appelé avec l'index 2
      expect(tappedIndex, equals(2));

      // Act : taper sur le premier item "Accueil" (index 0)
      await tester.tap(find.text('Accueil'));
      await tester.pump();

      // Assert : le callback a été appelé avec l'index 0
      expect(tappedIndex, equals(0));
    });
  });
}
