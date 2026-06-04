import 'package:drift/drift.dart';

part 'app_db.g.dart'; // Généré par build_runner

class TrackingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // miam, caca, dodo, sein, bib, sante
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get duration => real().nullable()(); // en minutes (dodo, sein)
  TextColumn get notes => text().nullable()();
}

@DriftDatabase(tables: [TrackingEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<List<TrackingEvent>> getEvents() => select(trackingEvents).get();
  Future<int> insertEvent(TrackingEventsCompanion event) => into(trackingEvents).insert(event);
  Future<List<TrackingEvent>> getFeedingEvents() {
  return (select(trackingEvents)
        ..where((t) => t.type.isIn(['sein', 'bib']))
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
}

