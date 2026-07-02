// ignore_for_file: lines_longer_than_80_chars // Tests des propriétés et méthodes de BabyProfile

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

void main() {
  group('BabyProfile', () {
    final String testId = 'test-id-123';
    const testName = 'Luna';
    final testBirthDate = DateTime(2024, 3, 15, 8, 30);

    group('constructor', () {
      test('requires id, name, birthDate — isActive defaults to true', () {
        final profile = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);

        expect(profile.id, testId);
        expect(profile.name, testName);
        expect(profile.birthDate, testBirthDate);
        expect(profile.isActive, isTrue);
      });

      test('allows isActive to be set explicitly to false', () {
        final profile = BabyProfile(id: testId, name: testName, birthDate: testBirthDate, isActive: false);

        expect(profile.isActive, isFalse);
      });
    });

    group('birthDayOfMonth', () {
      test('returns the day component of birthDate for March 15 → 15', () {
        final profile = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);

        expect(profile.birthDayOfMonth, 15);
      });

      test('returns correct day for first of month (January 1)', () {
        final profile = BabyProfile(
          id: 'id-2',
          name: 'Nova',
          birthDate: DateTime(2024, 1, 1),
        );

        expect(profile.birthDayOfMonth, 1);
      });

      test('returns correct day for last of month (February 29 leap year)', () {
        final profile = BabyProfile(
          id: 'id-3',
          name: 'Sol',
          birthDate: DateTime(2024, 2, 29),
        );

        expect(profile.birthDayOfMonth, 29);
      });
    });

    group('copyWith', () {
      test('returns a new instance with unchanged properties when no args provided', () {
        final original = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.birthDate, original.birthDate);
        expect(copied.isActive, original.isActive);
      });

      test('updates name when provided', () {
        final original = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);
        final updated = original.copyWith(name: 'Luna 2');

        expect(updated.name, 'Luna 2');
        expect(updated.id, original.id);
      });

      test('updates birthDate when provided', () {
        final newBirth = DateTime(2024, 5, 20);
        final profile = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);
        final updated = profile.copyWith(birthDate: newBirth);

        expect(updated.birthDate, newBirth);
        expect(updated.name, profile.name);
      });

      test('updates isActive when provided', () {
        final activeProfile = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);
        final updated = activeProfile.copyWith(isActive: false);

        expect(updated.isActive, isFalse);
        expect(updated.name, activeProfile.name);
      });

      test('updates multiple properties at once', () {
        final profile = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);
        final updated = profile.copyWith(name: 'Star', isActive: false);

        expect(updated.name, 'Star');
        expect(updated.isActive, isFalse);
        expect(updated.id, profile.id);
        expect(updated.birthDate, profile.birthDate);
      });

      test('preserves original (immutability) after copyWith', () {
        final original = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);
        original.copyWith(name: 'Changed');

        expect(original.name, testName);
      });
    });

    group('toString', () {
      test('includes id, name, and birthDate in output', () {
        final profile = BabyProfile(id: testId, name: testName, birthDate: testBirthDate);

        expect(
          profile.toString(),
          'BabyProfile(id: $testId, name: $testName, birthDate: $testBirthDate)',
        );
      });
    });
  });
}
