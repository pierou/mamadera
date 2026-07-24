import 'package:drift/drift.dart';

import '../../../../shared/domain/entities/tracking_enums.dart';

part 'app_db.g.dart'; // Généré par build_runner

class BabyProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get birthDate => integer()(); // Unix timestamp (milliseconds)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class TrackingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // miam, caca, dodo, sein, bib, sante
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get duration => real().nullable()(); // en minutes (dodo, sein)
  TextColumn get subtype => text().nullable()();  // typed event subtype: 'sein'|'bib' for feeding, health subtype values
  TextColumn get notes => text().nullable()();    // encrypted user text only
  TextColumn get wasteType => text().nullable()(); // pipi, caca, les_deux (diaper events only)
  TextColumn get color => text().nullable()();     // couleur de la selle ou pipe-délimitée (pipi|caca)
  TextColumn get babyId => text().nullable()();    // nullable FK to baby_profiles(id), backward compatible
  RealColumn get quantity => real().nullable()();   // volume in ml (feeding) or minutes (sleep)
}

class ReminderDismissals extends Table {
  TextColumn get itemId => text().unique()();

  DateTimeColumn get dismissedAt => dateTime()();
}

class ReminderSettings extends Table {
  TextColumn get itemId => text().unique()();
  BoolColumn get enabled => boolean()();
}

@DriftDatabase(tables: [BabyProfiles, TrackingEvents, ReminderDismissals, ReminderSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  /// Index SQL créés automatiquement à l'initialisation de la DB.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Création des indexes après les tables
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tracking_events_type ON tracking_events(type)');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tracking_events_timestamp_type ON tracking_events(timestamp DESC, type)');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v2 → v3 : ajout de la table reminder_dismissals
          if (from < 3) {
            await m.createTable(reminderDismissals);
            // Recréer les indexes si absents (sécurisé avec IF NOT EXISTS)
            await m.database.customStatement(
                'CREATE INDEX IF NOT EXISTS idx_tracking_events_type ON tracking_events(type)');
            await m.database.customStatement(
                'CREATE INDEX IF NOT EXISTS idx_tracking_events_timestamp_type ON tracking_events(timestamp DESC, type)');
          }
          // v3 → v4 : ajout de baby_profiles + baby_id nullable sur tracking_events (backward compatible)
          if (from < 4) {
            await m.createTable(babyProfiles);
            await m.database.customStatement('ALTER TABLE tracking_events ADD COLUMN baby_id TEXT');
          }
          // v4 → v5 : ajout de subtype column + migration des données legacy (health subtypes dans wasteType)
          if (from < 5) {
            await m.database.customStatement('ALTER TABLE tracking_events ADD COLUMN subtype TEXT');
            // Migrer les événements health: copier wasteType → subtype et effacer wasteType
            await m.database.customStatement(
                "UPDATE tracking_events SET subtype = waste_type, waste_type = NULL WHERE type = 'sante'");
            // Migrer les événements feeding: définir subtype = 'sein' par défaut (bib n'était jamais persisté)
            await m.database.customStatement(
                "UPDATE tracking_events SET subtype = 'sein' WHERE type = 'miam' AND subtype IS NULL");
          }
          // v5 → v6 : ajout de la colonne quantity (volume ml feeding / minutes sleep)
          if (from < 6) {
            await m.database.customStatement('ALTER TABLE tracking_events ADD COLUMN quantity REAL');
          }
        },
      );

  Future<List<TrackingEvent>> getEvents() => select(trackingEvents).get();

  Future<int> insertEvent(TrackingEventsCompanion event) =>
      into(trackingEvents).insert(event);

  /// Retourne uniquement les événements d'alimentation (sein ou biberon).
  Future<List<TrackingEvent>> getFeedingEvents() {
    return (select(trackingEvents)
          ..where((t) => t.type.isIn(FeedingSubtype.values.map((e) => e.name).toList()))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  Future<List<TrackingEvent>> getAllEventsOrdered() {
    return (select(trackingEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  Future<List<TrackingEvent>> getEventsByType(String type) {
    return (select(trackingEvents)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  /// Met à jour un événement existant par son ID.
  Future<int> updateEvent(int id, TrackingEventsCompanion companion) {
    return (update(trackingEvents)..where((t) => t.id.equals(id))).write(companion);
  }

  /// Supprime un événement par son ID. Retourne true si une ligne a été supprimée.
  Future<bool> deleteEvent(int id) async {
    final deleted = await (delete(trackingEvents)..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  /// Retourne tous les événements sans tri spécifique.
  Future<List<TrackingEvent>> getAllTrackingEvents() => select(trackingEvents).get();

  /// Met à jour uniquement le champ notes d'un événement par son ID.
  Future<int> updateNotesForEvent(int id, String? newNotes) {
    return (update(trackingEvents)..where((t) => t.id.equals(id)))
        .write(TrackingEventsCompanion(notes: Value(newNotes)));
  }

  /// ── Baby Profiles Queries ────────────────────────────────────────

  Future<List<BabyProfile>> getAllBabyProfiles() {
    return (select(babyProfiles)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Retourne le profil actif (premier trouvé avec is_active == true).
  Future<BabyProfile?> getActiveBabyProfile() async {
    final profiles = await (select(babyProfiles)
          ..where((t) => t.isActive.equals(true)))
        .get();
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<int> insertBabyProfile(BabyProfilesCompanion profile) =>
      into(babyProfiles).insert(profile);

  Future<int> updateBabyProfile(String id, BabyProfilesCompanion companion) {
    return (update(babyProfiles)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<bool> deleteBabyProfile(String id) async {
    final deleted = await (delete(babyProfiles)..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  /// Retourne les événements pour un bébé spécifique.
  Future<List<TrackingEvent>> getEventsByBabyId(String babyId) {
    return (select(trackingEvents)
          ..where((t) => t.babyId.equals(babyId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }
}


