import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    // Pas de version épinglée : un littéral dans un test oblige à le modifier
    // à chaque release, et un test qu'on modifie à chaque release finit par
    // n'être plus qu'un rituel. Ce qui compte n'est pas que la version vaille
    // telle valeur — c'est qu'elle soit **la même** que celle de pubspec.yaml,
    // l'invariant que la CI vérifie (`.github/workflows/ci.yml`) et dont une
    // rupture publie une app dont l'écran « À propos » ment sur elle-même.
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
