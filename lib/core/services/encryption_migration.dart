import 'package:drift/drift.dart';
import '../../data/local/app_db.dart' hide TrackingEvent;
import 'encryption_service.dart';

/// Migration helper : re-chiffre les notes en clair existantes lors du premier lancement.
class EncryptionMigration {
  /// Constructeur avec injection des dépendances.
  EncryptionMigration(this._db, this._encryption);

  final AppDatabase _db;
  final EncryptionService _encryption;

  /// Vérifie et migère toutes les notes non chiffrées vers le format chiffré.
  Future<int> migratePlaintextNotes() async {
    // Récupère tous les événements avec des notes
    final allEvents = await _db.select(_db.trackingEvents).get();

    var migratedCount = 0;

    for (final event in allEvents) {
      if (event.notes != null && !_encryption.isEncrypted(event.notes)) {
        // La note est en clair → on la chiffre et on met à jour
        final encryptedNotes = _encryption.encrypt(event.notes!);
        await (_db.update(_db.trackingEvents)
              ..where(
                (t) => t.id.equals(event.id),
              ))
            .write(TrackingEventsCompanion(
          notes: Value(encryptedNotes),
        ));

        migratedCount++;
      }
    }

    return migratedCount;
  }
}
