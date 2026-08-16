// ignore_for_file: avoid_print
/// Minimal driver for screenshot_capture integration test.
///
/// Runs the integration test, then pulls screenshots from the emulator's
/// shared storage to screenshots/android/ on the host machine.
library;

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  print('[DRIVER] Connected, waiting for tests...');
  await driver.waitUntilFirstFrameRasterized();
  print('[DRIVER] First frame rasterized, tests should be running.');
  await driver.close();
  print('[DRIVER] Test complete. Pulling screenshots from device...');

  // Pull all screenshots from the device's shared storage.
  const devicePath = '/sdcard/Download/screenshots/android';
  const hostPath = 'screenshots/android';

  // Create local directory if needed.
  Directory(hostPath).createSync(recursive: true);

  // Run adb pull for each expected screenshot.
  final files = [
    'home.png',
    'history.png',
    'menu.png',
    'feeding_dialog.png',
    'sleep_diagram.png',
    'diaper_dialog.png',
    'health_diagram.png',
  ];

  for (final file in files) {
    final result = Process.runSync(
      'adb',
      ['pull', '$devicePath/$file', '$hostPath/$file'],
    );
    if (result.exitCode == 0) {
      print('[DRIVER] ✓ Pulled $file');
    } else {
      print('[DRIVER] ✗ Failed to pull $file: ${result.stderr}');
    }
  }

  print('[DRIVER] Done. Screenshots saved to $hostPath/');
}
