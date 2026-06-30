import 'package:drift/drift.dart';

import '../../../../shared/domain/entities/tracking_enums.dart';

part 'app_db.g.dart'; // Généré par build_runner

class TrackingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // miam, caca, dodo, sein, bib, sante
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get duration => real().nullable()(); // en minutes (dodo, sein)
  TextColumn get notes => text().nullable()();
  TextColumn get wasteType => text().nullable()(); // pipi, caca, les_deux
  TextColumn get color => text().nullable()();     // couleur de la selle ou pipe-délimitée (pipi|caca)
}

class ReminderDismissals extends Table {
TextColumn get itemId => text()();

  DateTimeColumn get dismissedAt => dateTime()();

  @override
  List<String> get tableConstraints => ['PRIMARY KEY ("itemId")'];
}

@DriftDatabase(tables: [TrackingEvents, ReminderDismissals])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

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
}


