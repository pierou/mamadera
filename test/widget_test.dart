import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/main.dart';

void main() {
  testWidgets('HomeScreen displays track buttons', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that our home screen shows the four tracking buttons.
    expect(find.text('Miam'), findsOneWidget);
    expect(find.text('Santé'), findsOneWidget);
    expect(find.text('Caca'), findsOneWidget);
    expect(find.text('Dodo'), findsOneWidget);

    // Verify no counter text from default template exists.
    expect(find.text('0'), findsNothing);
  });
}
