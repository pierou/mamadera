// Single-entry-point integration suite for CI.
//
// On a physical device, `flutter test a.dart b.dart c.dart` launches the app
// once PER FILE (stop → install → start → wait for the VM service). On the
// 2-core, software-emulated GitHub-hosted runners (no KVM) that per-file
// overhead — plus slow class verification — makes the full six-file suite
// impossible to finish in a reasonable CI window.
//
// Bundling the core-flow suites into one entrypoint means a single app launch
// runs all of them. Keep this list short on purpose: it is the blocking merge
// gate. The full suite (all six flow files) remains available locally:
//
//   flutter test integration_test/*_flow_test.dart integration_test/rendering_validation_test.dart
//
// (or on a KVM-capable runner, where per-file relaunches are cheap).

import 'baby_profile_flow_test.dart' as baby_profile;
import 'navigation_flow_test.dart' as navigation;
import 'onboarding_flow_test.dart' as onboarding;

void main() {
  // Each file's main() calls IntegrationTestWidgetsFlutterBinding
  // .ensureInitialized() (idempotent) and registers its own group, so all
  // tests land in the single suite executed in this one app launch.
  onboarding.main();
  navigation.main();
  baby_profile.main();
}
