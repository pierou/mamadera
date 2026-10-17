import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    // No pinned version: A literal string in a test requires modification.
    // With each release, and a test that is modified with each release, eventually...
    // It shouldn't just be a ritual. What matters is not just that the version is good.
    // This value should be the **same** as the one specified in the `pubspec.yaml` file.
    // The invariant that the CI system checks (`.github/workflows/ci.yml`), and an example of:
    // Rupture has released an app whose "About" screen contains false information about itself.
    test('version matches pubspec.yaml — the invariant CI enforces', () {
      final pubspec = File('pubspec.yaml').readAsLinesSync();
      final line = pubspec.firstWhere((l) => l.startsWith('version:'));
      final pubspecVersion = line.split(':').last.trim().split('+').first;

      expect(AppConfig.version, pubspecVersion,
          reason: 'AppConfig.version et pubspec.yaml version doivent dire la '
              'même chose ; la CI romprait le build sinon');
    });

    test('version is a non-empty string', () {
      expect(AppConfig.version.isNotEmpty, true);
    });

    test('version follows semver format', () {
      final semverRegex = RegExp(r'^\d+\.\d+\.\d+$');
      expect(AppConfig.version, matches(semverRegex));
    });
  });
}
