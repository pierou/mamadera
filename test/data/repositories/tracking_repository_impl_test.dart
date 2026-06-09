import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen displays track buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('Miam'), findsOneWidget);
    expect(find.text('Santé'), findsOneWidget);
    expect(find.text('Caca'), findsOneWidget);
    expect(find.text('Dodo'), findsOneWidget);
  });
}
