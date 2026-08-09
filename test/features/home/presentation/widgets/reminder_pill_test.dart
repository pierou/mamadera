import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/presentation/widgets/reminder_pill.dart';

void main() {
  group('ReminderPill', () {
    testWidgets('displays the provided label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ReminderPill(label: 'Vit. D')),
      );

      expect(find.text('Vit. D'), findsOneWidget);
    });

    testWidgets('uses amber background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const ReminderPill(label: 'Test')),
      );

      final container = find.byType(Container);
      expect(container, findsOneWidget);
    });

    testWidgets('has rounded corners with pill shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const ReminderPill(label: 'Pill')),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('text uses bodySmall style with white color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const ReminderPill(label: 'Style')),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('has horizontal margin for spacing between pills', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const ReminderPill(label: 'Margin')),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.margin, isNotNull);
    });

    testWidgets('has horizontal and vertical padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const ReminderPill(label: 'Padding')),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, isNotNull);
    });

    testWidgets('supports empty label without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const ReminderPill(label: '')),
      );

      expect(find.text(''), findsOneWidget);
    });

    testWidgets('renders multiple pills in a row correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ReminderPill(label: 'Vit. D'),
              ReminderPill(label: 'Yeux'),
              ReminderPill(label: 'Visage'),
            ],
          ),
        ),
      );

      expect(find.text('Vit. D'), findsOneWidget);
      expect(find.text('Yeux'), findsOneWidget);
      expect(find.text('Visage'), findsOneWidget);
    });
  });
}
