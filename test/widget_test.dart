import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';

import 'package:mamadera/main.dart';

/// Test helper: French locale preference for widget tests.
const frenchLocale = LocalePreference(languageCode: 'fr', isManualOverride: false);

void main() {
  testWidgets('HomeScreen displays track buttons', (WidgetTester tester) async {
    // Build our app and trigger a frame with locale override for French.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localeProvider.overrideWith(_TestLocaleNotifier.new)],
        child: const MyApp(),
      ),
    );

    // Verify that our home screen shows the four tracking buttons (French locale).
    expect(find.byType(TrackButton), findsNWidgets(4));

    // Verify no counter text from default template exists.
    expect(find.text('0'), findsNothing);
  });
}

class _TestLocaleNotifier extends LocaleNotifier {
  @override
  Future<LocalePreference> build() async => frenchLocale;
}
