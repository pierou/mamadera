/// Test driver entry-point for rendering validation integration tests.
///
/// This file is used when running:
/// ```bash
/// flutter drive \
///   --target=lib/driver_main.dart \
///   --driver=test_driver/rendering_driver_test.dart
/// ```
library;

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
