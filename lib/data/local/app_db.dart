import 'package:drift/drift.dart';

import 'db_constants.dart' as db_const;

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
  TextColumn get type => text()(); // miam, caca, dodo, sante
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get duration => real().nullable()(); // en minutes (dodo, feeding)
  TextColumn get subtype => text().nullable()();  // typed event subtype: 'natural'|'artificial' for feeding, health subtype values
  TextColumn get notes => text().nullable()();    // encrypted user text only
  TextColumn get wasteType => text().nullable()(); // pipi, caca, les_deux (diaper events only)
  TextColumn get color => text().nullable()();     // couleur de la selle ou pipe-délimitée (pipi|caca)
  TextColumn get texture => text().nullable()();   // consistance de la selle (diaper events only)
  TextColumn get babyId => text().nullable()();    // nullable FK to baby_profiles(id), backward compatible
  RealColumn get quantity => real().nullable()();   // volume in ml (feeding) or minutes (sleep)
}

class ReminderDismissals extends Table {
  /// NOT NULL, `''` = partagé entre tous les bébés (sentinelle [db_const.sharedBabyId]).
  TextColumn get babyId =>
      text().withDefault(const Constant(db_const.sharedBabyId))();
  TextColumn get itemId => text()();
  DateTimeColumn get dismissedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {babyId, itemId};
}

class ReminderSettings extends Table {
  /// NOT NULL, `''` = partagé entre tous les bébés (sentinelle [db_const.sharedBabyId]).
  TextColumn get babyId =>
      text().withDefault(const Constant(db_const.sharedBabyId))();
  TextColumn get itemId => text()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column> get primaryKey => {babyId, itemId};
}

/// Rappels créés par le parent, à côté des quatre préréglages codés en dur.
///
/// Une ligne décrit *quand* réclamer, jamais *ce qui a été fait* : l'achèvement
/// reste déduit de `tracking_events` (type `sante` + `subtype_value`), comme pour
/// les préréglages. `label` est la saisie libre du parent : il n'est jamais
/// traduit, et ne passe donc par aucune clé ARB.
///
/// `enabled` n'est **pas** ici : un rappel personnalisé obéit à la même table
/// `reminder_settings` que les préréglages (clé `custom_<id>`), pour qu'il
/// n'existe qu'un seul mécanisme d'extinction dans l'app.
class CustomReminders extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// NOT NULL, `''` = rappel valable pour tous les bébés (lecture honnête des
  /// lignes héritées de v10, où la table n'était pas scopée).
  TextColumn get babyId =>
      text().withDefault(const Constant(db_const.sharedBabyId))();
  TextColumn get label => text().withLength(min: 1, max: 60)();

  /// Null = rappel **détaché** : aucun soin lié, achèvement manuel (D2).
  /// Valeur de `HealthSubtype` (`nettoyage_nez`, `nettoyage_nombril`, …) : le soin
  /// dont l'absence dans `tracking_events` rend le rappel dû.
  TextColumn get subtypeValue => text().nullable()();

  /// `daily` | `weekly` | `monthly` | `every_n_days` — voir [CustomReminder].
  TextColumn get frequency => text()();

  /// Seulement pour `every_n_days` : longueur du roulement en jours.
  IntColumn get intervalDays => integer().nullable()();

  /// `'from_events'` | `'manual'` — qui décide que le rappel est fait (D2).
  TextColumn get completionSource =>
      text().withDefault(const Constant(db_const.completionFromEvents))();
}

/// Mesures de croissance (poids, taille, température) — v11.
///
/// `value` est du **chiffré AES-GCM** (`iv:ciphertext` base64), pas un REAL :
/// le mandat de confidentialité (`AGENTS.md`) classe le poids comme donnée
/// sensible ; la température et la taille sont de la même famille (données de
/// santé RGPD). Le en-clair n'existe qu'au moment de l'export JSON, qui est
/// en clair par conception — comme les `notes`.
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nullable, comme `tracking_events.baby_id` : un suivi sans profil reste lisible.
  TextColumn get babyId => text().nullable()();
  TextColumn get kind => text()();          // 'poids' | 'taille' | 'temperature'
  TextColumn get value => text()();        // chiffré
  TextColumn get unit => text()();         // 'g' | 'cm' | 'degC'
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get notes => text().nullable()(); // chiffré, même pipeline que events
}

/// Achèvement **manuel** d'un rappel (`completion_source = 'manual'`, D2).
///
/// Journal append-only : une ligne par tap « Fait ». La lecture est
/// `MAX(completed_at)`, ce qui rend la forme identique à `getLastCompleted`
/// côté événements.
class ReminderCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get babyId =>
      text().withDefault(const Constant(db_const.sharedBabyId))();
  TextColumn get itemId => text()();
  DateTimeColumn get completedAt => dateTime()();
}

@DriftDatabase(
    tables: [
      BabyProfiles,
      TrackingEvents,
      ReminderDismissals,
      ReminderSettings,
      CustomReminders,
      Measurements,
      ReminderCompletions,
    ])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 11;

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
          // Index v11 : sans eux, les installations **neuves** n'auraient que les
          // deux index historiques alors que les bases migrées en ont quatre — un
          // écart invisible au test, visible sur un téléphone qui scrolle.
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_measurements_baby_kind_recorded ON measurements(baby_id, kind, recorded_at DESC)');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_reminder_completions_baby_item ON reminder_completions(baby_id, item_id, completed_at DESC)');
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
          // v6 → v7 : migration des valeurs de subtype feeding (sein/bib → natural/artificial)
          if (from < 7) {
            await m.database.customStatement(
                "UPDATE tracking_events SET subtype = 'natural' WHERE type = 'miam' AND (subtype IS NULL OR subtype IN ('sein', 'naturel'))");
            await m.database.customStatement(
                "UPDATE tracking_events SET subtype = 'artificial' WHERE type = 'miam' AND subtype IN ('bib', 'artificiel')");
          }
          // v7 → v8 : créer `reminder_settings` si absente.
          // La table était déclarée dans @DriftDatabase mais jamais créée par
          // onUpgrade : toute base créée avant la v7 (v3..v6) montait en v8
          // sans la table, et toute lecture/écriture de réglage de rappel
          // échouait avec « no such table: reminder_settings ».
          // IF NOT EXISTS : les installations neuves (onCreate → createAll) la
          // possèdent déjà.
          if (from < 8) {
            await m.database.customStatement(
              'CREATE TABLE IF NOT EXISTS reminder_settings ('
              'item_id TEXT NOT NULL PRIMARY KEY,'
              'enabled BOOLEAN NOT NULL'
              ')',
            );
          }
          // v8 → v9 : ajout de la colonne texture (consistance des selles).
          // Laissé NULL pour toutes les couches déjà enregistrées : on ne
          // devine pas la texture d'un change déjà noté.
          if (from < 9) {
            await m.database.customStatement(
                'ALTER TABLE tracking_events ADD COLUMN texture TEXT');
          }
          // v9 → v10 : table des rappels personnalisés. `m.createTable` reprend
          // la DDL de Drift (auto_increment) ; les installations neuves la
          // reçoivent déjà par onCreate → createAll.
          if (from < 10) {
            await m.createTable(customReminders);
          }

          // v10 → v11 : trois mouvements, un seul passage.
          //  (a) `reminder_settings` et `reminder_dismissals` sont re-clés par bébé :
          //      un rappel éteint pour l'un ne l'est plus pour l'autre (item M).
          //  (b) `custom_reminders` gagne `baby_id` + `completion_source` et surtout
          //      `subtype_value` NULLABLE, ce qu'`ALTER TABLE` ne sait pas faire : la
          //      table est reconstruite.
          //  (c) deux tables neuves : `measurements` et `reminder_completions`.
          // Les PRIMARY KEY composites déclarent `baby_id NOT NULL` : SQLite autorise
          // NULL dans une clé composite et l'autorise en double (vérifié, sqlite 3.51),
          // ce qui ferait deux lignes « partagées » pour un même rappel. La sentinelle
          // `''` signifie « tous les bébés ».
          // Les ids de `custom_reminders` sont recopiés explicitement : la clé
          // d'extinction `custom_<id>` de `reminder_settings` s'y rapporte, changer un id
          // éteindrait un rappel au hasard.
          if (from < 11) {
            // (a) settings
            await m.database.customStatement('''
              CREATE TABLE reminder_settings_new (
                baby_id TEXT    NOT NULL DEFAULT '',
                item_id TEXT    NOT NULL,
                enabled BOOLEAN NOT NULL,
                PRIMARY KEY (baby_id, item_id)
              )''');
            await m.database.customStatement(
              'INSERT INTO reminder_settings_new (baby_id, item_id, enabled) '
              "SELECT '', item_id, enabled FROM reminder_settings");
            await m.database.customStatement('DROP TABLE reminder_settings');
            await m.database.customStatement(
              'ALTER TABLE reminder_settings_new RENAME TO reminder_settings');

            // (a) dismissals
            await m.database.customStatement('''
              CREATE TABLE reminder_dismissals_new (
                baby_id      TEXT    NOT NULL DEFAULT '',
                item_id      TEXT    NOT NULL,
                dismissed_at TIMESTAMP NOT NULL,
                PRIMARY KEY (baby_id, item_id)
              )''');
            await m.database.customStatement(
              'INSERT INTO reminder_dismissals_new (baby_id, item_id, dismissed_at) '
              "SELECT '', item_id, dismissed_at FROM reminder_dismissals");
            await m.database.customStatement('DROP TABLE reminder_dismissals');
            await m.database.customStatement(
              'ALTER TABLE reminder_dismissals_new RENAME TO reminder_dismissals');

            // (b) custom reminders — rebuilt for the nullable subtype_value
            await m.database.customStatement('''
              CREATE TABLE custom_reminders_new (
                id               INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                baby_id          TEXT    NOT NULL DEFAULT '',
                label            TEXT    NOT NULL,
                subtype_value    TEXT,
                frequency        TEXT    NOT NULL,
                interval_days    INTEGER,
                completion_source TEXT   NOT NULL DEFAULT 'from_events'
              )''');
            await m.database.customStatement(
              'INSERT INTO custom_reminders_new (id, baby_id, label, subtype_value, frequency, interval_days) '
              "SELECT id, '', label, subtype_value, frequency, interval_days FROM custom_reminders");
            await m.database.customStatement('DROP TABLE custom_reminders');
            await m.database.customStatement(
              'ALTER TABLE custom_reminders_new RENAME TO custom_reminders');
            // Safety net : un AUTOINCREMENT renommé peut repartir de 1 et entrer en collision
            // avec un id recopié. Le test de migration l'attrape ; la ligne l'empêche.
            await m.database.customStatement(
              'UPDATE sqlite_sequence SET seq = (SELECT COALESCE(MAX(id), 0) FROM custom_reminders) '
              "WHERE name = 'custom_reminders'");

            // (c) new tables (drift emits the DDL from the classes above)
            await m.createTable(measurements);
            await m.createTable(reminderCompletions);

            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_measurements_baby_kind_recorded '
              'ON measurements(baby_id, kind, recorded_at DESC)');
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_reminder_completions_baby_item '
              'ON reminder_completions(baby_id, item_id, completed_at DESC)');
          }
        },
      );

  Future<List<TrackingEvent>> getEvents() => select(trackingEvents).get();

  Future<int> insertEvent(TrackingEventsCompanion event) =>
      into(trackingEvents).insert(event);

  /// Retourne uniquement les événements d'alimentation (natural/artificial).
  Future<List<TrackingEvent>> getFeedingEvents() {
    return (select(trackingEvents)
          ..where((t) => t.type.equals(db_const.typeMiam))
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

  /// Retourne le profil actif (avec is_active == true).
  ///
  /// Tri déterministe `birth_date` puis `id` : si deux lignes se retrouvent
  /// actives (fenêtre de bug avant la transaction de `setActiveProfile`), le
  /// profil retourné est toujours le même plutôt que le premier rendu par
  /// SQLite.
  Future<BabyProfile?> getActiveBabyProfile() async {
    final profiles = await (select(babyProfiles)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.birthDate), (t) => OrderingTerm.asc(t.id)]))
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

  /// Supprime tous les événements de suivi rattachés à [babyId].
  /// Retourne le nombre de lignes supprimées.
  ///
  /// À appeler dans la même transaction que [deleteBabyProfile] : sans clés
  /// étrangères ni cascade dans le schéma, c'est la seule chose qui empêche
  /// les événements de survivre à leur bébé.
  Future<int> deleteTrackingEventsByBabyId(String babyId) =>
      (delete(trackingEvents)..where((t) => t.babyId.equals(babyId))).go();

  /// Supprime toutes les mesures rattachées à [babyId].
  /// Retourne le nombre de lignes supprimées.
  ///
  /// Ne touche ni les mesures sans profil (`baby_id` NULL) ni celles des
  /// autres bébés : `WHERE baby_id = ?` ne les sélectionne pas.
  Future<int> deleteMeasurementsByBabyId(String babyId) =>
      (delete(measurements)..where((t) => t.babyId.equals(babyId))).go();

  /// Supprime tous les achèvements manuels rattachés à [babyId] (toutes les
  /// clés d'item). Retourne le nombre de lignes supprimées.
  ///
  /// Les lignes portées par la sentinelle `''` appartiennent à tous les bébés
  /// et survivent à la suppression d'un profil.
  Future<int> deleteReminderCompletionsByBabyId(String babyId) =>
      (delete(reminderCompletions)
            ..where((t) => t.babyId.equals(babyId)))
          .go();

  /// Supprime tous les réglages de rappels rattachés à [babyId] (toutes les
  /// clés d'item). Retourne le nombre de lignes supprimées.
  Future<int> deleteReminderSettingsByBabyId(String babyId) =>
      (delete(reminderSettings)..where((t) => t.babyId.equals(babyId))).go();

  /// Supprime tous les « ignorer aujourd'hui » rattachés à [babyId] (toutes
  /// les clés d'item). Retourne le nombre de lignes supprimées.
  Future<int> deleteReminderDismissalsByBabyId(String babyId) =>
      (delete(reminderDismissals)..where((t) => t.babyId.equals(babyId))).go();

  /// Supprime tous les rappels personnalisés rattachés à [babyId].
  /// Retourne le nombre de lignes supprimées.
  Future<int> deleteCustomRemindersByBabyId(String babyId) =>
      (delete(customReminders)..where((t) => t.babyId.equals(babyId))).go();

  /// Retourne les événements pour un bébé spécifique.
  Future<List<TrackingEvent>> getEventsByBabyId(String babyId) {
    return (select(trackingEvents)
          ..where((t) => t.babyId.equals(babyId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  /// ── Reminder Queries ─────────────────────────────────────────────

  /// Retourne toutes les lignes de `reminder_settings` (sans filtre).
  Future<List<ReminderSetting>> getAllReminderSettings() =>
      select(reminderSettings).get();

  /// Retourne toutes les lignes de `reminder_dismissals` (sans filtre).
  Future<List<ReminderDismissal>> getAllReminderDismissals() =>
      select(reminderDismissals).get();

  /// Retourne tous les rappels personnalisés, dans l'ordre de création.
  Future<List<CustomReminder>> getAllCustomReminders() =>
      (select(customReminders)
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Retourne toutes les lignes de `measurements` (sans filtre, export M4).
  Future<List<Measurement>> getAllMeasurements() => select(measurements).get();

  /// Retourne toutes les lignes de `reminder_completions` (sans filtre,
  /// export M4).
  Future<List<ReminderCompletion>> getAllReminderCompletions() =>
      select(reminderCompletions).get();

  /// Supprime les réglages dont la clé d'item fait partie de [itemIds],
  /// **quel que soit le bébé**. Sert au nettoyage des clés `custom_<id>`
  /// orphelines quand un rappel personnalisé est supprimé.
  Future<int> deleteReminderSettingsByItemIds(List<String> itemIds) =>
      (delete(reminderSettings)..where((t) => t.itemId.isIn(itemIds))).go();

  /// Supprime les « ignorer aujourd'hui » dont la clé d'item fait partie de
  /// [itemIds], quel que soit le bébé (même usage que
  /// [deleteReminderSettingsByItemIds]).
  Future<int> deleteReminderDismissalsByItemIds(List<String> itemIds) =>
      (delete(reminderDismissals)..where((t) => t.itemId.isIn(itemIds))).go();

  /// Supprime les achèvements dont la clé d'item fait partie de [itemIds],
  /// quel que soit le bébé (même usage que
  /// [deleteReminderSettingsByItemIds]).
  Future<int> deleteReminderCompletionsByItemIds(List<String> itemIds) =>
      (delete(reminderCompletions)..where((t) => t.itemId.isIn(itemIds))).go();
}


