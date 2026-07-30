/// Onboarding flow integration tests.
///
/// Validates the first-launch experience:
/// - Terms acceptance dialog appears when termsNotAccepted == true
/// - Accepting terms navigates to home screen with track buttons visible
/// - Patch notes dialog (when version mismatch) is skipped for now
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flow', () {
    testWidgets(
        'First launch shows terms acceptance dialog and navigating away on accept',
        (tester) async {
      // Pump app with terms not accepted — should redirect to /terms route.
      await pumpMamadera(tester, termsNotAccepted: true);

      // Verify the TermsAcceptanceDialog appears.
      expectUnique(tester, TestKeys.termsAcceptButton);

      // Tap the accept button — should navigate to /home and show track buttons.
      await tester.tap(findByKey(TestKeys.termsAcceptButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // After accepting, we should see the HomeScreen track buttons.
      expectUnique(tester, TestKeys.trackMiam);
      expectUnique(tester, TestKeys.trackSante);
    });

    testWidgets('Terms accepted skips onboarding and shows home directly',
        (tester) async {
      // Pump app with terms already pre-accepted.
      await pumpMamadera(tester, termsNotAccepted: false);

      // Verify track buttons are immediately visible — no terms dialog shown.
      expectUnique(tester, TestKeys.trackMiam);

      // Terms accept button should NOT appear on the home screen.
      expectAbsent(TestKeys.termsAcceptButton);

      // Home tab key should be rendered by the bottom nav bar.
      expectUnique(tester, TestKeys.homeTab);
    });

    testWidgets('Bottom nav shows home/history/menu tabs on home screen',
        (tester) async {
      await pumpMamadera(tester);

      // All three tabs should render in the BottomNavigationBar.
      for (final key in [TestKeys.homeTab, TestKeys.historyTab, TestKeys.menuTab]) {
        expectUnique(tester, key);
      }
    });
  });
}
