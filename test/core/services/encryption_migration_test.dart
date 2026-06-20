import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/services/encryption_migration.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' as drift;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'encryption_migration_test.mocks.dart';

/// Note en clair utilisée pour les tests.
const String _plaintextNote = 'Mon bébé a bien mangé à 14h30';

/// Format chiffré simulé (iv:ciphertext).
const String _encryptedNoteValue = 'aGVsbG8=:Y2lwaGVydGV4dA==';

@GenerateMocks([drift.AppDatabase, EncryptionService])
void main() {
  late EncryptionMigration migration;
  late MockAppDatabase mockDb;
  late MockEncryptionService mockEncryption;

  setUp(() {
    mockDb = MockAppDatabase();
    mockEncryption = MockEncryptionService();

    migration = EncryptionMigration(mockDb, mockEncryption);
  });

  tearDown(() {
    reset(mockDb);
    reset(mockEncryption);
  });

  group('migratePlaintextNotes', () {
    test(
        'retourne 0 et ne fait rien sur une base vide (aucun événement)',
        () async {
      // DB vide : aucun événement à migrer.
      when(mockDb.getAllTrackingEvents()).thenAnswer((_) async => []);

      final result = await migration.migratePlaintextNotes();

      expect(result, 0);
      verify(mockDb.getAllTrackingEvents()).called(1);
      // Aucune mise à jour doit être appelée car il n'y a pas d'événements.
      verifyNever(mockDb.updateNotesForEvent(any, any));
    });

    test('migre une note en clair vers le format chiffré', () async {
      final event = drift.TrackingEvent(
        id: 1,
        type: 'miam',
        timestamp: DateTime(2024, 1, 1),
        notes: _plaintextNote,
      );

      when(mockDb.getAllTrackingEvents()).thenAnswer((_) async => [event]);
      // La note est détectée comme NON chiffrée.
      when(mockEncryption.isEncrypted(_plaintextNote)).thenReturn(false);
      // Le chiffrement retourne une valeur simulée.
      when(
        mockEncryption.encrypt(_plaintextNote),
      ).thenReturn(_encryptedNoteValue);
      // L'update de la DB réussit.
      when(mockDb.updateNotesForEvent(any, any)).thenAnswer((_) async => 1);

      final result = await migration.migratePlaintextNotes();

      expect(result, 1);
      verify(mockEncryption.isEncrypted(_plaintextNote)).called(1);
      verify(mockEncryption.encrypt(_plaintextNote)).called(1);
      verify(mockDb.updateNotesForEvent(1, _encryptedNoteValue)).called(1);
    });

    test('ne migre pas une note déjà chiffrée', () async {
      final event = drift.TrackingEvent(
        id: 2,
        type: 'dodo',
        timestamp: DateTime(2024, 1, 2),
        notes: _encryptedNoteValue,
      );

      when(mockDb.getAllTrackingEvents()).thenAnswer((_) async => [event]);
      // La note est détectée comme DÉJÀ chiffrée → pas de migration.
      when(mockEncryption.isEncrypted(_encryptedNoteValue)).thenReturn(true);

      final result = await migration.migratePlaintextNotes();

      expect(result, 0);
      verify(mockEncryption.isEncrypted(_encryptedNoteValue)).called(1);
      // encrypt et update ne doivent pas être appelés.
      verifyNever(mockEncryption.encrypt(any));
      verifyNever(mockDb.updateNotesForEvent(any, any));
    });

    test('saute les événements sans notes (notes == null)', () async {
      final event = drift.TrackingEvent(
        id: 3,
        type: 'caca',
        timestamp: DateTime(2024, 1, 3),
        // Pas de notes.
      );

      when(mockDb.getAllTrackingEvents()).thenAnswer((_) async => [event]);

      final result = await migration.migratePlaintextNotes();

      expect(result, 0);
      // isEncrypted ne doit pas être appelé car le code short-circuit sur null.
      verifyNever(mockEncryption.isEncrypted(any));
      verifyNever(mockDb.updateNotesForEvent(any, any));
    });

    test('compte correctement plusieurs notes en clair parmi divers états',
        () async {
      // Événement 1 : note en clair → doit être migrée.
      final plaintext = drift.TrackingEvent(
        id: 10,
        type: 'miam',
        timestamp: DateTime(2024, 1, 1),
        notes: _plaintextNote,
      );

      // Événement 2 : déjà chiffré → ignorée.
      final alreadyEncrypted = drift.TrackingEvent(
        id: 20,
        type: 'dodo',
        timestamp: DateTime(2024, 1, 2),
        notes: _encryptedNoteValue,
      );

      // Événement 3 : pas de notes → ignorée.
      final noNotes = drift.TrackingEvent(
        id: 30,
        type: 'caca',
        timestamp: DateTime(2024, 1, 3),
      );

      when(mockDb.getAllTrackingEvents())
          .thenAnswer((_) async => [plaintext, alreadyEncrypted, noNotes]);

      // Plaintext note detection.
      when(mockEncryption.isEncrypted(_plaintextNote)).thenReturn(false);
      when(
        mockEncryption.encrypt(_plaintextNote),
      ).thenReturn(_encryptedNoteValue);

      // Already encrypted note detection.
      when(mockEncryption.isEncrypted(_encryptedNoteValue)).thenReturn(true);

      when(mockDb.updateNotesForEvent(any, any)).thenAnswer((_) async => 1);

      final result = await migration.migratePlaintextNotes();

      expect(result, 1); // Seule la note en clair est migrée.
      verify(mockEncryption.encrypt(_plaintextNote)).called(1);
      verify(mockDb.updateNotesForEvent(10, _encryptedNoteValue)).called(1);
    });
  });
}
