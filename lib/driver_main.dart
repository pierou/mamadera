/// Driver entry-point for integration testing on iOS simulators.
///
/// Enables the Flutter driver extension so tests can programmatically:
/// - Take screenshots for visual regression checks
/// - Query widget bounds, offsets, and dimensions
/// - Validate full-screen rendering across orientations and device sizes
///
/// Usage: `flutter test integration_test/rendering_validation_test.dart`

import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' as app;

void main() {
  // Enable the driver extension before running the app.
  enableFlutterDriverExtension();

  // Run the actual app.
  app.main();
}
