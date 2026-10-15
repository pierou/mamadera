// ignore_for_file: avoid_print
/// Driver du pass v1.2.1 : exécute le test, récupère les captures d'écran
/// dans `reportData` (mécanique identique à
/// `screenshot_capture.driver.dart`, Flutter ≥ 3.44) et les écrit sur le
/// hôte. Le répertoire est donné par `SHOT_DIR` pour séparer les deux
/// émulateurs.
library;

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart' show Response;

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  print('[DRIVER] Connected, waiting for tests...');
  final result = await driver.requestData('request_data');
  print('[DRIVER] Tests finished.');
  await driver.close();

  final response = Response.fromJson(result);
  if (!response.allTestsPassed) {
    print('[DRIVER] ✗ Some tests failed:\n${response.formattedFailureDetails}');
    exitCode = 1;
  }

  final hostPath = Platform.environment['SHOT_DIR'] ?? 'screenshots/upgrade-v1.2.1';
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

  final exportedJson = response.data?['exportedJson'] as String?;
  if (exportedJson != null) {
    final jsonPath = '$hostPath/exported.json';
    File(jsonPath).writeAsStringSync(exportedJson);
    print('[DRIVER] ✓ Saved exported.json (${exportedJson.length} chars)');
  } else {
    print('[DRIVER] ! No exported JSON in reportData (export test absent or failed)');
  }

  print('[DRIVER] Done. Screenshots saved to $hostPath/');
}
