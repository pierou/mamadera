import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/config/app_config.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/app_preferences_service.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/features/home/presentation/widgets/track_button.dart';

import 'package:mamadera/main.dart';

/// Test helper: French locale preference for widget tests.
const frenchLocale = LocalePreference(languageCode: 'fr', isManualOverride: false);

/// Test preferences with terms accepted so the router goes to /home.
/// [AppConfig.version] keeps the fixture in sync with the app version so the
/// patch-notes gate never fires in these tests.
const _testPrefs = AppPreferences(
  appVersion: AppConfig.version,
  termsAccepted: true,
  patchNotesOptOut: false,
);

void main() {
  testWidgets('HomeScreen displays track buttons', (WidgetTester tester) async {
    // Build our app and trigger a frame with locale override for French.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith(_TestLocaleNotifier.new),
          appPreferencesProvider.overrideWith(_TestAppPreferencesNotifier.new),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for async providers to resolve and router to redirect
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

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

/// Test notifier that returns accepted terms so the router goes to /home.
/// Sets state synchronously so the redirect callback sees data immediately.
class _TestAppPreferencesNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async {
    state = const AsyncValue.data(_testPrefs);
    return _testPrefs;
  }
}
