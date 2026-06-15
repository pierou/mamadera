import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'encryption_service_test.mocks.dart';

/// Clé AES-256 valide (32 octets) encodée en base64, utilisée uniquement pour les tests.
const String _validTestKeyBase64 =
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='; // gitleaks:allow — all-zero test key

@GenerateMocks([FlutterSecureStorage])
void main() {
  late EncryptionService encryption;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();

    // Simule une clé maître existante (32 octets en base64)
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

      // Le format doit être iv:ciphertext
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

      // Format invalide (pas de séparateur :)
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

      // Les IV sont aléatoires, donc les ciphertexts doivent différer
      expect(encrypted1, isNot(equals(encrypted2)));

      // Mais les deux doivent se déchiffrer correctement
      expect(encryption.decrypt(encrypted1), equals(plainText));
      expect(encryption.decrypt(encrypted2), equals(plainText));
    });

    test('throw si key est accédé avant initialize()', () async {
      final freshEncryption = EncryptionService(mockStorage);

      expect(() => freshEncryption.key, throwsA(isA<StateError>()));
    });
  });
}

