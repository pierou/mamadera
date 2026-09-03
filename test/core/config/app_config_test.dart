import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('version is 1.0.1', () {
      expect(AppConfig.version, '1.0.1');
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
