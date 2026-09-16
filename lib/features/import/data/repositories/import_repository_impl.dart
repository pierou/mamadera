import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show compute;
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/db_constants.dart' as db_const;
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../domain/repositories/import_repository.dart';

/// Format version this build can restore.
///
/// The exporter owns this number; anything above it belongs to a future app and
/// must not be guessed at.
const int _supportedFormatVersion = 1;

/// `generator` value written by documents this app exports.
const String _generatorName = 'mamadera';

/// Labels of the `label` column, matching `withLength(min: 1, max: 60)`.
const int _maxLabelLength = 60;

/// Lower bound of any plausible restored instant (exclusive of anything older).
final DateTime _plausibleMin = DateTime.utc(1990);

/// Upper bound of any plausible restored instant.
final DateTime _plausibleMax = DateTime.utc(2100);

/// What the pure parser needs: the text, plus the schema it may restore into.
typedef _ParseRequest = ({String json, int schemaVersion});

/// Parses and validates a backup document. Pure: no database, no file IO, no
/// clock, no encryption.
///
/// Runs on a background isolate (see [ImportRepositoryImpl.parseExport]) so a
/// multi-megabyte `jsonDecode` never janks the UI. Every rejection throws
/// [ImportFormatException] with a reason from the closed
/// [ImportRejectionReason] set — no row content ever reaches the exception.
///
/// Strictness note, deliberately different from the reminders layer:
/// `RemindersRepositoryImpl._decodeFrequency` decodes tolerantly on *read*
/// because a reminder nobody can see can never be fixed. This is the *write*
/// side of a trust boundary — a file the parent hand-edited or found on disk —
/// where restoring a plausible-looking-but-wrong row silently is the worse
/// failure. So a bad row rejects the whole file, atomically, before anything is
/// touched.
ParsedExport _parseAndValidate(_ParseRequest request) {
  dynamic decoded;
  try {
    decoded = jsonDecode(request.json);
  } on FormatException {
    throw const ImportFormatException(ImportRejectionReason.invalidJson);
  }
  if (decoded is! Map<String, dynamic>) {
    throw const ImportFormatException(ImportRejectionReason.invalidJson);
  }
  final document = decoded;

  _validateHeader(document, request.schemaVersion);

  final profileIds = <String>{};
  final eventIds = <int>{};
  final reminderIds = <int>{};
  final settingItemIds = <String>{};
  final dismissalItemIds = <String>{};

  final babyProfiles = _section<ImportedBabyProfile>(document, 'babyProfiles',
      (row) => _parseProfile(row, profileIds));
  final trackingEvents = _section<ImportedTrackingEvent>(
      document, 'trackingEvents', (row) => _parseEvent(row, eventIds));
  final customReminders = _section<ImportedCustomReminder>(
      document, 'customReminders', (row) => _parseCustomReminder(row, reminderIds));
  final reminderSettings = _section<ImportedReminderSetting>(
      document, 'reminderSettings', (row) => _parseSetting(row, settingItemIds));
  final reminderDismissals = _section<ImportedReminderDismissal>(
      document, 'reminderDismissals',
      (row) => _parseDismissal(row, dismissalItemIds));

  _validateCounts(document, {
    'babyProfiles': babyProfiles.length,
    'trackingEvents': trackingEvents.length,
    'customReminders': customReminders.length,
    'reminderSettings': reminderSettings.length,
    'reminderDismissals': reminderDismissals.length,
  });

  final parsed = ParsedExport(
    babyProfiles: babyProfiles,
    trackingEvents: trackingEvents,
    customReminders: customReminders,
    reminderSettings: reminderSettings,
    reminderDismissals: reminderDismissals,
  );
  if (parsed.hasNoRestorableData) {
    throw const ImportFormatException(ImportRejectionReason.emptyFile);
  }
  return parsed;
}

// ── Document level ───────────────────────────────────────────────────────

/// Checks identity, format version and schema version of [document].
///
/// The `databaseSchemaVersion` guard is the one that prevents a *restore* from
/// losing data: a document written by a future schema may carry fields this
/// build has nowhere to put, and it can still say `exportFormatVersion: 1`.
/// Restoring such a file would silently drop those fields from the device.
void _validateHeader(Map<String, dynamic> document, int schemaVersion) {
  final generator = document['generator'];
  if (generator is! String || generator != _generatorName) {
    throw const ImportFormatException(ImportRejectionReason.notAMamaderaFile);
  }

  final formatVersion = document['exportFormatVersion'];
  if (formatVersion is! int) {
    throw const ImportFormatException(ImportRejectionReason.notAMamaderaFile);
  }
  if (formatVersion > _supportedFormatVersion) {
    throw const ImportFormatException(ImportRejectionReason.newerFormatVersion);
  }
  if (formatVersion < _supportedFormatVersion) {
    throw const ImportFormatException(ImportRejectionReason.notAMamaderaFile);
  }

  final writtenSchema = document['databaseSchemaVersion'];
  if (writtenSchema is int && writtenSchema > schemaVersion) {
    throw const ImportFormatException(ImportRejectionReason.newerSchemaVersion);
  }
}

/// Reads one of the five table sections and maps its rows with [parseRow].
List<T> _section<T>(
  Map<String, dynamic> document,
  String key,
  T Function(Map<String, dynamic> row) parseRow,
) {
  final raw = document[key];
  if (raw is! List) {
    throw ImportFormatException(ImportRejectionReason.missingTable, section: key);
  }
  final rows = <T>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) {
      throw ImportFormatException(ImportRejectionReason.invalidRow, section: key);
    }
    rows.add(parseRow(entry));
  }
  return rows;
}

/// The export writes `counts` from the same read as the payloads; a file whose
/// counts disagree was not produced by the exporter (or was edited), so nothing
/// in it can be trusted.
void _validateCounts(Map<String, dynamic> document, Map<String, int> actual) {
  final counts = document['counts'];
  if (counts is! Map<String, dynamic>) {
    throw const ImportFormatException(ImportRejectionReason.countsMismatch);
  }
  for (final expected in actual.entries) {
    if (counts[expected.key] != expected.value) {
      throw ImportFormatException(
        ImportRejectionReason.countsMismatch,
        section: expected.key,
      );
    }
  }
}

// ── Row level ────────────────────────────────────────────────────────────

ImportedBabyProfile _parseProfile(Map<String, dynamic> row, Set<String> seenIds) {
  const section = 'babyProfiles';
  final id = _requiredString(row, 'id', section);
  _requireUnique(id, seenIds, section);
  return ImportedBabyProfile(
    id: id,
    name: _requiredString(row, 'name', section),
    // Stored as epoch MILLISECONDS in a plain integer column — not a Drift
    // dateTime() column, so no conversion happens on either side.
    birthDateEpochMs: _milliseconds(row, 'birthDateEpochMs', 'birthDateUtc', section),
    // Absent means "true" — the same default as the table column.
    isActive: _boolWithTrueDefault(row, 'isActive', section),
  );
}

ImportedTrackingEvent _parseEvent(Map<String, dynamic> row, Set<int> seenIds) {
  const section = 'trackingEvents';
  final id = _requiredInt(row, 'id', section);
  _requireUnique(id, seenIds, section);

  // `type` is validated strictly (it decides which sealed entity the row
  // becomes); the enum-ish columns below are passed through as strings on
  // purpose: `mapToEntity` already falls back on unknown values, and rejecting
  // them here would break a restore on the first future enum addition.
  final type = _requiredString(row, 'type', section);
  if (!db_const.allTypeValues.contains(type)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }

  final notes = _optionalString(row, 'notes', section);
  // `notesUndecryptable: true` is tolerated and ignored: it means `notes` is
  // null because the source device had lost the key. There is nothing to
  // restore, and refusing the file would punish the parent for it.
  return ImportedTrackingEvent(
    id: id,
    type: type,
    timestamp: _seconds(row, 'timestampEpochSeconds', 'timestampUtc', section),
    duration: _optionalFiniteDouble(row, 'durationMinutes', section),
    subtype: _optionalString(row, 'subtype', section),
    notes: notes,
    wasteType: _optionalString(row, 'wasteType', section),
    color: _optionalString(row, 'color', section),
    texture: _optionalString(row, 'texture', section),
    // Orphans (babyId present but not among the file's profiles) are kept: the
    // export kept them, there is no foreign key to violate, and nulling them
    // would rewrite history.
    babyId: _optionalString(row, 'babyId', section),
    quantity: _optionalFiniteDouble(row, 'quantity', section),
  );
}

ImportedCustomReminder _parseCustomReminder(
    Map<String, dynamic> row, Set<int> seenIds) {
  const section = 'customReminders';
  final id = _requiredInt(row, 'id', section);
  _requireUnique(id, seenIds, section);

  final label = _requiredString(row, 'label', section);
  if (label.length > _maxLabelLength) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  // Validated against the domain enum: a reminder pointing at a care this build
  // does not know could never be marked done, and would sit there undiagnosable.
  final subtypeValue = _requiredString(row, 'subtypeValue', section);
  if (HealthSubtype.byValue(subtypeValue) == null) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final frequency = _requiredString(row, 'frequency', section);
  if (!db_const.allFrequencyValues.contains(frequency)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return ImportedCustomReminder(
    id: id,
    label: label,
    subtypeValue: subtypeValue,
    frequency: frequency,
    intervalDays: _optionalPositiveInt(row, 'intervalDays', section),
  );
}

ImportedReminderSetting _parseSetting(Map<String, dynamic> row, Set<String> seenIds) {
  const section = 'reminderSettings';
  final itemId = _requiredString(row, 'itemId', section);
  _requireUnique(itemId, seenIds, section);
  final enabled = row['enabled'];
  if (enabled is! bool) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return ImportedReminderSetting(itemId: itemId, enabled: enabled);
}

ImportedReminderDismissal _parseDismissal(
    Map<String, dynamic> row, Set<String> seenIds) {
  const section = 'reminderDismissals';
  final itemId = _requiredString(row, 'itemId', section);
  _requireUnique(itemId, seenIds, section);
  return ImportedReminderDismissal(
    itemId: itemId,
    dismissedAt: _seconds(row, 'dismissedAtEpochSeconds', 'dismissedAtUtc', section),
  );
}

// ── Field extraction ─────────────────────────────────────────────────────
//
// Explicit helpers rather than `as` casts everywhere: the analyzer runs with
// strict-casts/strict-raw-types, and every rejection must name its section so
// the parent gets "the file is malformed" and not a Dart type message.

String _requiredString(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value is! String || value.isEmpty) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  return value;
}

String? _optionalString(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  return value;
}

int _requiredInt(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value is! int) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  return value;
}

int? _optionalPositiveInt(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! int || value < 1) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  return value;
}

double? _optionalFiniteDouble(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! num) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  final converted = value.toDouble();
  if (!converted.isFinite) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  return converted;
}

bool _boolWithTrueDefault(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return true;
  if (value is! bool) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  return value;
}

/// Instant stored as epoch SECONDS, with the ISO twin as fallback.
DateTime _seconds(
    Map<String, dynamic> row, String epochKey, String isoKey, String section) {
  final epoch = row[epochKey];
  if (epoch is int) {
    return _checkRange(DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true), section);
  }
  if (epoch == null) {
    final iso = row[isoKey];
    if (iso is String) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) return _checkRange(parsed, section);
    }
  }
  throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
}

/// Instant stored as epoch MILLISECONDS (`baby_profiles.birth_date`), with the
/// ISO twin as fallback.
int _milliseconds(
    Map<String, dynamic> row, String epochKey, String isoKey, String section) {
  final epoch = row[epochKey];
  if (epoch is int) {
    _checkRange(DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true), section);
    return epoch;
  }
  if (epoch == null) {
    final iso = row[isoKey];
    if (iso is String) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) {
        _checkRange(parsed, section);
        return parsed.millisecondsSinceEpoch;
      }
    }
  }
  throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
}

/// Rejects instants outside 1990-2100: a wrong unit (milliseconds where seconds
/// were expected, a hand-edited value) lands there, and restoring it would put
/// a baby event in 1970 with nothing raised to notice.
DateTime _checkRange(DateTime moment, String section) {
  final utc = moment.toUtc();
  if (utc.isBefore(_plausibleMin) || !utc.isBefore(_plausibleMax)) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
  return moment;
}

void _requireUnique(Object id, Set<Object> seen, String section) {
  if (!seen.add(id)) {
    throw ImportFormatException(ImportRejectionReason.invalidRow, section: section);
  }
}

/// Deterministic `(birthDate, id)` ordering, the same one
/// `AppDatabase.getActiveBabyProfile` uses to pick the active profile.
ImportedBabyProfile _firstByBirthDateThenId(List<ImportedBabyProfile> profiles) {
  var first = profiles.first;
  for (final candidate in profiles) {
    final earlier = candidate.birthDateEpochMs < first.birthDateEpochMs ||
        (candidate.birthDateEpochMs == first.birthDateEpochMs &&
            candidate.id.compareTo(first.id) < 0);
    if (earlier) first = candidate;
  }
  return first;
}

/// Concrete implementation of [ImportRepository].
///
/// The parse half is pure and runs off the UI isolate; the restore half is the
/// only code in this feature that writes, and it writes inside one transaction.
/// Only counts and timings are ever logged — never a name, a note, a label or a
/// file path (same rule the export repository follows).
class ImportRepositoryImpl implements ImportRepository {
  const ImportRepositoryImpl({
    required this.database,
    required this.encryption,
  });

  final db_app.AppDatabase database;
  final EncryptionService encryption;

  static final Logger _logger = appLogger();

  @override
  Future<ParsedExport> parseExport(String json) => compute(
        _parseAndValidate,
        (json: json, schemaVersion: database.schemaVersion),
      );

  @override
  Future<ImportCounts> restore(ParsedExport parsed) async {
    final stopwatch = Stopwatch()..start();

    await database.transaction(() async {
      // Full replace, in dependency-free order (there are no foreign keys).
      await database.delete(database.babyProfiles).go();
      await database.delete(database.trackingEvents).go();
      await database.delete(database.customReminders).go();
      await database.delete(database.reminderSettings).go();
      await database.delete(database.reminderDismissals).go();

      for (final profile in parsed.babyProfiles) {
        await database.insertBabyProfile(db_app.BabyProfilesCompanion.insert(
          id: profile.id,
          name: profile.name,
          birthDate: profile.birthDateEpochMs,
          isActive: Value(profile.isActive),
        ));
      }

      for (final event in parsed.trackingEvents) {
        await database.insertEvent(db_app.TrackingEventsCompanion.insert(
          // Explicit rowid: the autoincrement column is a plain `Value<int>`
          // in the companion, so the id survives without raw SQL.
          id: Value(event.id),
          type: event.type,
          timestamp: event.timestamp,
          duration: Value(event.duration),
          subtype: Value(event.subtype),
          // The file holds plaintext (the export decrypted it); the database
          // invariant is ciphertext at rest, so it goes back through the same
          // service with a fresh IV. An empty note encrypts to '' and reads
          // back as no note — that is the encryption service's behaviour, not
          // something this restore invents.
          notes: Value(event.notes == null ? null : encryption.encrypt(event.notes!)),
          wasteType: Value(event.wasteType),
          color: Value(event.color),
          texture: Value(event.texture),
          babyId: Value(event.babyId),
          quantity: Value(event.quantity),
        ));
      }

      for (final reminder in parsed.customReminders) {
        await database.into(database.customReminders).insert(
              db_app.CustomRemindersCompanion.insert(
                id: Value(reminder.id),
                label: reminder.label,
                subtypeValue: reminder.subtypeValue,
                frequency: reminder.frequency,
                intervalDays: Value(reminder.intervalDays),
              ),
            );
      }

      for (final setting in parsed.reminderSettings) {
        await database.into(database.reminderSettings).insert(
              db_app.ReminderSettingsCompanion.insert(
                itemId: setting.itemId,
                enabled: setting.enabled,
              ),
            );
      }

      for (final dismissal in parsed.reminderDismissals) {
        await database.into(database.reminderDismissals).insert(
              db_app.ReminderDismissalsCompanion.insert(
                itemId: dismissal.itemId,
                dismissedAt: dismissal.dismissedAt,
              ),
            );
      }

      await _promoteActiveProfile(parsed.babyProfiles);
    });

    stopwatch.stop();
    // Counts and duration only — never any restored content.
    _logger.d(
      'restore: profiles=${parsed.babyProfiles.length} '
      'events=${parsed.trackingEvents.length} '
      'customReminders=${parsed.customReminders.length} '
      'settings=${parsed.reminderSettings.length} '
      'dismissals=${parsed.reminderDismissals.length} '
      'in ${stopwatch.elapsedMilliseconds} ms',
    );
    return parsed.counts;
  }

  /// Guarantees the app never lands without an active baby after a restore.
  ///
  /// A file can legitimately contain profiles and no active one (exported
  /// during the brief window where the parent is choosing, or hand-edited). The
  /// oldest profile wins, by the exact ordering `getActiveBabyProfile` would
  /// have used.
  Future<void> _promoteActiveProfile(List<ImportedBabyProfile> profiles) async {
    if (profiles.isEmpty || profiles.any((profile) => profile.isActive)) return;
    final promoted = _firstByBirthDateThenId(profiles);
    await (database.update(database.babyProfiles)
          ..where((t) => t.id.equals(promoted.id)))
        .write(const db_app.BabyProfilesCompanion(isActive: Value(true)));
  }
}
