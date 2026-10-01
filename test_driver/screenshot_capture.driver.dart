// ignore_for_file: avoid_print
/// Minimal driver for screenshot_capture integration test.
///
/// Runs the integration test, then saves the screenshots to
/// screenshots/android/ on the host machine.
///
/// Since Flutter 3.44, `binding.takeScreenshot()` no longer writes PNGs to
/// the device: the bytes travel back in-band, inside the test `reportData`
/// that the `request_data` command returns once all tests have finished.
library;

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart' show Response;

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  print('[DRIVER] Connected, waiting for tests...');
  // The integration_test binding only implements the `request_data` command
  // (see _IOCallbackManager): it resolves when ALL tests have finished,
  // so this single call is the wait. (waitFor/waitUntilFirstFrameRasterized
  // hit its UnimplementedError and crash the driver.)
  final result = await driver.requestData('request_data');
  print('[DRIVER] Tests finished.');
  await driver.close();

  final response = Response.fromJson(result);
  if (!response.allTestsPassed) {
    print('[DRIVER] ✗ Some tests failed:\n${response.formattedFailureDetails}');
    exitCode = 1;
  }

  const hostPath = 'screenshots/android';
  Directory(hostPath).createSync(recursive: true);

  final screenshots = response.data?['screenshots'] as List<dynamic>? ?? const [];
  for (final shot in screenshots) {
    final name = (shot as Map<dynamic, dynamic>)['screenshotName'] as String;
    final bytes = (shot['bytes'] as List<dynamic>).cast<int>().toList();
    File('$hostPath/$name.png').writeAsBytesSync(bytes);
    print('[DRIVER] ✓ Saved $name.png (${bytes.length} bytes)');
  }

  if (screenshots.isEmpty) {
    print('[DRIVER] ✗ No screenshots in reportData');
    exitCode = 1;
  }

  print('[DRIVER] Done. Screenshots saved to $hostPath/');
}
