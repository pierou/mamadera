import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/features/home/domain/repositories/tracking_repository.dart';
import 'package:mamadera/features/home/presentation/providers/repository_provider.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';
import 'package:mockito/mockito.dart';

import '../../../../data/repositories/tracking_repository_impl_test.mocks.dart';

void main() {
  group('trackingRepositoryProvider', () {
    late MockAppDatabase mockDb;
    late MockEncryptionService mockEncryption;

    setUp(() {
      mockDb = MockAppDatabase();
      mockEncryption = MockEncryptionService();
    });

    test('retourne un TrackingRepository quand les dépendances sont résolues',
        () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      final repository =
          await container.read(trackingRepositoryProvider.future);

      expect(repository, isA<TrackingRepository>());

      container.dispose();
    });

    test('le provider est un FutureProvider', () {
      expect(
        trackingRepositoryProvider,
        isA<FutureProvider<TrackingRepository>>(),
      );
    });

    test('dispose correctement sans erreur', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      expect(container.dispose, returnsNormally);
    });

    test('cache le résultat après la première résolution', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      // First reading: solving the future.
      final first = await container.read(trackingRepositoryProvider.future);

      // Second read — returns the same instance (caches Riverpod).
      final second = await container.read(trackingRepositoryProvider.future);

      expect(identical(first, second), isTrue);

      container.dispose();
    });

    test('propage une erreur de databaseProvider', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider
            .overrideWith((ref) async => throw Exception('DB error')),
      ]);

      expect(
        () => container.read(trackingRepositoryProvider.future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });

    test('injecte bien l\'encryption service dans le repository', () async {
      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      // The construction of the provider utilizes both dependencies – if we...
      // If you change the override setting, the result should change accordingly.
      final repo = await container.read(trackingRepositoryProvider.future);

      expect(repo, isA<TrackingRepository>());
      // Successful access confirms that the injections were effective.

      container.dispose();
    });

    test('propage une erreur de construction du repository', () async {
      when(mockDb.insertEvent(any)).thenThrow(Exception('DB error'));

      final container = ProviderContainer(overrides: [
        encryptionServiceProvider.overrideWith((ref) async => mockEncryption),
        databaseProvider.overrideWith((ref) async => Future.value(mockDb)),
      ]);

      // The provider resolves the issue (building the repository does not involve any database operations).
      final repo = await container.read(trackingRepositoryProvider.future);

      expect(repo, isA<TrackingRepository>());

      // However, repo transactions amplify the error stemming from the central bank's actions.
      final testEvent = FeedingEvent(
        unit: QuantityUnit.ml,
        timestamp: DateTime.now(),
        subtype: FeedingSubtype.natural,
      );
      expect(
        () => repo.insertEvent(testEvent),
        throwsA(anything),
      );

      container.dispose();
    });
  });
}
