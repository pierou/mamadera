// ignore_for_file: lines_longer_than_80_chars // Tests for encryptionServiceProvider

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';

void main() {
  group('encryptionServiceProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns an EncryptionService instance', () {
      final service = container.read(encryptionServiceProvider);
      expect(service, isA<EncryptionService>());
    });

    test('EncryptionService can be initialized', () async {
      final service = container.read(encryptionServiceProvider);
      await service.initialize();
      expect(service.isUsingMemoryFallback, anyOf(isTrue, isFalse)); // Should not throw
    });
  });
}
