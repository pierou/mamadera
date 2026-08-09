// This file is used for automated screenshot capture using Flutter Driver / DTD.
// To run screenshots: flutter run --target=lib/driver_main.dart -d <device_id>

import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;

void main() {
  // Enable the driver extension for automated UI interactions
  enableFlutterDriverExtension();

  // Run the app
  app.main();
}
