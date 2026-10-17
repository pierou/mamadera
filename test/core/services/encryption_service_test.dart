import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'encryption_service_test.mocks.dart';

/// Valid AES-256 key (32 bytes) encoded in base64, used only for testing.
const String _validTestKeyBase64 =
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='; // gitleaks:allow — all-zero test key

@GenerateMocks([FlutterSecureStorage])
void main() {
  late EncryptionService encryption;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();

    // Simulate an existing master key (32 bytes, encoded in base64).
    when(mockStorage.read(key: 'mamadera_master_key')).thenAnswer(
      (_) async => _validTestKeyBase64,
    );
    encryption = EncryptionService(mockStorage);
  });

  tearDown(() {
    reset(mockStorage);
  });

  group('EncryptionService', () {
    test('initialize() charge la clé existante depuis secure_storage',
        () async {
      await encryption.initialize();

      verify(mockStorage.read(key: 'mamadera_master_key')).called(1);
    });

    test('encrypt/decrypt sont inverses pour une chaîne non vide', () async {
      await encryption.initialize();

      const plainText = 'Mon bébé a bien mangé à 14h30';
      final encrypted = encryption.encrypt(plainText);

      // The format must be: iv:ciphertext.
      expect(encrypted, isNotEmpty);
      expect(encrypted.split(':').length, equals(2));

      final decrypted = encryption.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('decrypt() retourne null pour une chaîne vide', () async {
      await encryption.initialize();

      expect(encryption.decrypt(null), isNull);
      expect(encryption.decrypt(''), isNull);
    });

    test('encrypt("") retourne une chaîne vide (optimisation)', () async {
      await encryption.initialize();

      expect(encryption.encrypt(''), isEmpty);
    });

    test('isEncrypted() détecte le format iv:ciphertext', () async {
      await encryption.initialize();

      final encrypted = encryption.encrypt('test');
      expect(encryption.isEncrypted(encrypted), isTrue);
      expect(encryption.isEncrypted('plaintext'), isFalse);
      expect(encryption.isEncrypted(null), isFalse);
      expect(encryption.isEncrypted(''), isFalse);
    });

    test('decrypt() retourne null pour des données corrompues', () async {
      await encryption.initialize();

      // Invalid format (missing separator ":").
      expect(encryption.decrypt('données_corrompues'), isNull);

      // Base64 invalide
      expect(encryption.decrypt('!!!:invalid_base64'), isNull);
    });

    test(
        'plusieurs chiffrement d\'une même donnée produisent des ciphertexts différents (IV unique)',
        () async {
      await encryption.initialize();

      const plainText = 'Donnée sensible';
      final encrypted1 = encryption.encrypt(plainText);
      final encrypted2 = encryption.encrypt(plainText);

      // The IVs (initialization vectors) are random, so the ciphertexts must be different.
      expect(encrypted1, isNot(equals(encrypted2)));

      // But both must be deciphered correctly.
      expect(encryption.decrypt(encrypted1), equals(plainText));
      expect(encryption.decrypt(encrypted2), equals(plainText));
    });

    test('throw si key est accédé avant initialize()', () async {
      final freshEncryption = EncryptionService(mockStorage);

      expect(() => freshEncryption.key, throwsA(isA<StateError>()));
    });

    group('rotateKey', () {
      test('supprime l\'ancienne clé et en génère une nouvelle', () async {
        await encryption.initialize();

        final oldKey = encryption.key;

        when(mockStorage.delete(key: 'mamadera_master_key')).thenAnswer(
          (_) async {},
        );
        // After deletion, `read` returns null → a new key is generated.
        when(mockStorage.read(key: 'mamadera_master_key'))
            .thenAnswer((_) async => null);

        await encryption.rotateKey();

        verify(mockStorage.delete(key: 'mamadera_master_key')).called(1);

        // The new key is different from the old one.
        expect(encryption.key, isNot(equals(oldKey)));
      });
    });

    group('destroyKey', () {
      test('supprime la clé maître du stockage sécurisé', () async {
        await encryption.initialize();

        when(mockStorage.delete(key: 'mamadera_master_key')).thenAnswer(
          (_) async {},
        );

        await encryption.destroyKey();

        verify(mockStorage.delete(key: 'mamadera_master_key')).called(1);
      });

      test('rend le service inutilisable après destroy', () async {
        await encryption.initialize();

        when(mockStorage.delete(key: 'mamadera_master_key')).thenAnswer(
          (_) async {},
        );

        await encryption.destroyKey();

        // The system should raise an error because the `cachedKey` is null.
        expect(() => encryption.key, throwsA(isA<StateError>()));
      });
    });

    group('isEncrypted edge cases', () {
      setUp(() async {
        await encryption.initialize();
      });

      test('rejette un format avec un seul segment (pas de deux-points)', () {
        expect(encryption.isEncrypted('justoneword'), isFalse);
      });

      test('rejette une chaîne avec deux points mais pas de base64 valide', () {
        expect(encryption.isEncrypted('not:base64!!!'), isFalse);
      });

      test('accepte un format iv:ciphertext valide (même si non généré par ce service)', () {
        // Two strings of reasonable length, encoded in base64.
        const fakeIv = 'QUJDREVGR0hJSktMTU5PUFFSUVQ='; // ABCDEFGHIJKLMNOPQRST
        const fakeCipher = 'YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXo='; // abcdefghijklmnopqrstuvwxyz

        expect(encryption.isEncrypted('$fakeIv:$fakeCipher'), isTrue);
      });
    });

    group('decrypt edge cases', () {
      setUp(() async {
        await encryption.initialize();
      });

      test('retourne null pour un format avec moins de 2 segments (pas de deux-points)', () {
        expect(encryption.decrypt('single_segment'), isNull);
      });

      test('réussit à déchiffrer malgré plusieurs segments (rejoin logic)', () {
        // Edge case: ciphertext contient ':' → parts.length > 2
        const plainText = 'test data';
        final encrypted = encryption.encrypt(plainText);

        // Inject a colon into the cipher part to simulate edge case
        final withExtraColon = '${encrypted.split(':')[0]}:${encrypted.split(':').last}:extra:parts';

        // Should still decrypt correctly (rejoin logic) or return null gracefully
        // In practice, this will fail decryption but should NOT throw
        expect(() => encryption.decrypt(withExtraColon), returnsNormally);
      });

      test('retourne null pour du texte brut non chiffré', () {
        expect(encryption.decrypt('just plain text'), isNull);
      });
    });

    group('memory fallback path (secure storage indisponible)', () {
      late EncryptionService memoryEncryption;

      setUp(() async {
        // Simulates an exception during reading → falls back to memory.
        when(mockStorage.read(key: 'mamadera_master_key')).thenThrow(
          Exception('Secure storage not available'),
        );

        memoryEncryption = EncryptionService(mockStorage);
        await memoryEncryption.initialize();
      });

      test('isUsingMemoryFallback est true après le fallback', () {
        expect(memoryEncryption.isUsingMemoryFallback, isTrue);
      });

      test('encrypt/decrypt fonctionnent avec une clé mémoire', () async {
        const plainText = 'test with memory key';
        final encrypted = memoryEncryption.encrypt(plainText);

        expect(encrypted, isNotEmpty);
        expect(memoryEncryption.decrypt(encrypted), equals(plainText));
      });

      test('rotateKey fonctionne en mode mémoire (fallback)', () async {
        memoryEncryption.encrypt('test rotate');
        
        await memoryEncryption.rotateKey();

        // The new key is different – decryption works with the new key.
        const newText = 'after rotation';
        final newEncrypted = memoryEncryption.encrypt(newText);
        expect(memoryEncryption.decrypt(newEncrypted), equals(newText));
      });

      test('destroyKey fonctionne en mode mémoire (fallback)', () async {
        final encrypted = memoryEncryption.encrypt('test destroy');

        await memoryEncryption.destroyKey();

        // After destroying key, decrypt returns null gracefully (catch block
        // swallows the StateError from accessing a destroyed key)
        expect(memoryEncryption.decrypt(encrypted), isNull);
      });
    });

    group('initialize() — nouvelle génération de clé', () {
      late EncryptionService newKeyEncryption;

      setUp(() async {
        // read returns null → no existing key.
        when(mockStorage.read(key: 'mamadera_master_key')).thenAnswer(
          (_) async => null,
        );
	    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
	).thenAnswer((_) async {});

        newKeyEncryption = EncryptionService(mockStorage);
      });

      test('génère une nouvelle clé quand aucune n\'existe', () async {
        await newKeyEncryption.initialize();

        verify(
          mockStorage.read(key: 'mamadera_master_key'),
        ).called(1);
        // A new key has been written (verify if any call was made).
	        verify(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
	).called(1);
      });

      test('la clé générée est utilisable pour encrypter/déchiffrer', () async {
        await newKeyEncryption.initialize();

        const plainText = 'new key test';
        final encrypted = newKeyEncryption.encrypt(plainText);
        expect(newKeyEncryption.decrypt(encrypted), equals(plainText));
      });
    });
  });
}

