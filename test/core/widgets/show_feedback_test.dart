import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/widgets/show_feedback.dart';

void main() {
  group('showFeedback', () {
    testWidgets('displays snackbar with message text', (tester) async {
      late BuildContext feedbackContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                feedbackContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showFeedback(feedbackContext, 'Action completed');
      await tester.pump();

      expect(find.text('Action completed'), findsOneWidget);
    });

    testWidgets('uses default duration on standard call', (tester) async {
      late BuildContext feedbackContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                feedbackContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showFeedback(feedbackContext, 'Quick feedback');
      await tester.pump();

      expect(find.text('Quick feedback'), findsOneWidget);
    });

    testWidgets('uses custom duration when specified', (tester) async {
      late BuildContext feedbackContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                feedbackContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showFeedback(feedbackContext, 'Longer message', duration: const Duration(seconds: 5));
      await tester.pump();

      expect(find.text('Longer message'), findsOneWidget);
    });

    testWidgets('triggers lightImpact haptic feedback', (tester) async {
      late BuildContext feedbackContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                feedbackContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showFeedback(feedbackContext, 'With haptics');

      expect(tester.takeException(), isNull);
    });
  });

  group('showError', () {
    testWidgets('displays snackbar with error message text', (tester) async {
      late BuildContext errorContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                errorContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showError(errorContext, 'Something went wrong');
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays with error background color', (tester) async {
      late BuildContext errorContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                errorContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showError(errorContext, 'Error displayed');
      await tester.pump();

      expect(find.text('Error displayed'), findsOneWidget);
    });

    testWidgets('uses default duration on standard call', (tester) async {
      late BuildContext errorContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                errorContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showError(errorContext, 'Default duration error');
      await tester.pump();

      expect(find.text('Default duration error'), findsOneWidget);
    });

    testWidgets('uses custom duration when specified', (tester) async {
      late BuildContext errorContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                errorContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showError(errorContext, 'Custom 1.5s error', duration: const Duration(milliseconds: 1500));
      await tester.pump();

      expect(find.text('Custom 1.5s error'), findsOneWidget);
    });

    testWidgets('does not trigger haptic feedback on error', (tester) async {
      late BuildContext errorContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                errorContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      showError(errorContext, 'No haptics here');

      expect(tester.takeException(), isNull);
    });
  });
}
