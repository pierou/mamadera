import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show compute;
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/db_constants.dart' as db_const;
import '../../../../shared/domain/entities/quantity_unit.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
// The reminders feature owns these settings; the importer validates them with
// the same rule the scheduler reads them with, not with a regex of its own
// (precedent: baby/data imports reminders/domain/entities).
import '../../../reminders/domain/services/notification_time.dart';
import '../../domain/repositories/import_repository.dart';

/// Newest format version this build can restore.
///
/// The exporter owns this number; anything above it belongs to a future app and
/// must not be guessed at. 3 (v1.2.x) adds `unit` to every event row; 4
/// (v1.3.0, item 12) adds the `appSettings` section.
///
/// Bumped in the same change as `ExportRepositoryImpl._exportFormatVersion`:
/// an importer that lags its own exporter refuses the backups this very build
/// writes.
const int _supportedFormatVersion = 4;

/// Oldest document format this build can still restore.
///
/// A format-1 backup (pre-M4) must keep restoring: it may omit the
/// `measurements` and `reminderCompletions` sections and the `babyId` fields,
/// and both absences mean "shared" or "empty" — never "missing table". Only the
/// upper limit is a wall; formats above [_supportedFormatVersion] belong to a
/// future app.
const int _oldestFormatVersion = 1;

/// The `app_settings` keys this build understands, and the value each accepts.
///
/// A closed set, like the rest of this importer. `app_settings` is a generic
/// key/value table, so a hand-edited file could name any key at all — and a
/// key this build does not know has no value format to check, which makes it
/// unverifiable rather than harmless. Adding a setting means adding its key and
/// its validator here, in the change that adds it.
const Set<String> _knownSettingKeys = {
  db_const.settingsKeyNotificationsOptIn,
  db_const.settingsKeyNotificationTime,
};

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
  // Composite keys (baby, item): The same item can be configured to be included or excluded.
  // Once per baby, without duplicates.
  final settingKeys = <Object>{};
  final dismissalKeys = <Object>{};
  final measurementIds = <int>{};
  final completionKeys = <Object>{};
  // Setting names: `key` is the primary key, so a repeated one is a duplicate
  // row and the last write would silently win.
  final settingNames = <Object>{};

  final babyProfiles = _section<ImportedBabyProfile>(
      document, 'babyProfiles', (row) => _parseProfile(row, profileIds));
  final trackingEvents = _section<ImportedTrackingEvent>(
      document, 'trackingEvents', (row) => _parseEvent(row, eventIds));
  final customReminders = _section<ImportedCustomReminder>(document,
      'customReminders', (row) => _parseCustomReminder(row, reminderIds));
  final reminderSettings = _section<ImportedReminderSetting>(
      document, 'reminderSettings', (row) => _parseSetting(row, settingKeys));
  final reminderDismissals = _section<ImportedReminderDismissal>(document,
      'reminderDismissals', (row) => _parseDismissal(row, dismissalKeys));
  final measurements = _section<ImportedMeasurement>(
      document, 'measurements', (row) => _parseMeasurement(row, measurementIds),
      optional: true);
  final reminderCompletions = _section<ImportedReminderCompletion>(document,
      'reminderCompletions', (row) => _parseCompletion(row, completionKeys),
      optional: true);
  final appSettings = _section<ImportedAppSetting>(
      document, 'appSettings', (row) => _parseAppSetting(row, settingNames),
      optional: true);

  _validateCounts(document, {
    'babyProfiles': babyProfiles.length,
    'trackingEvents': trackingEvents.length,
    'customReminders': customReminders.length,
    'reminderSettings': reminderSettings.length,
    'reminderDismissals': reminderDismissals.length,
    'measurements': measurements.length,
    'reminderCompletions': reminderCompletions.length,
    'appSettings': appSettings.length,
  });

  final parsed = ParsedExport(
    babyProfiles: babyProfiles,
    trackingEvents: trackingEvents,
    customReminders: customReminders,
    reminderSettings: reminderSettings,
    reminderDismissals: reminderDismissals,
    measurements: measurements,
    reminderCompletions: reminderCompletions,
    appSettings: appSettings,
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
  if (formatVersion < _oldestFormatVersion) {
    throw const ImportFormatException(ImportRejectionReason.notAMamaderaFile);
  }

  final writtenSchema = document['databaseSchemaVersion'];
  if (writtenSchema is int && writtenSchema > schemaVersion) {
    throw const ImportFormatException(ImportRejectionReason.newerSchemaVersion);
  }
}

/// Reads one of the eight table sections and maps its rows with [parseRow].
///
/// [optional] marks the sections newer formats may omit: `measurements` and
/// `reminderCompletions` (absent from a format-1 backup) and `appSettings`
/// (absent from anything before format 4). Absent means **empty**, never
/// "missing table" — refusing an old backup because it predates a feature
/// would brick every restore taken before it. The five historical sections are
/// always mandatory.
List<T> _section<T>(
  Map<String, dynamic> document,
  String key,
  T Function(Map<String, dynamic> row) parseRow, {
  bool optional = false,
}) {
  final raw = document[key];
  if (raw == null && optional) return const [];
  if (raw is! List) {
    throw ImportFormatException(ImportRejectionReason.missingTable,
        section: key);
  }
  final rows = <T>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) {
      throw ImportFormatException(ImportRejectionReason.invalidRow,
          section: key);
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
    final declared = counts[expected.key];
    if (declared == null) {
      // A backup of format 1 does not declare both tables of the format.
      // 2: The missing key is interpreted as "zero lines" – but only if...
      // The section is empty, otherwise the file wouldn't be from here.
      if (expected.value != 0) {
        throw ImportFormatException(
          ImportRejectionReason.countsMismatch,
          section: expected.key,
        );
      }
      continue;
    }
    if (declared != expected.value) {
      throw ImportFormatException(
        ImportRejectionReason.countsMismatch,
        section: expected.key,
      );
    }
  }
}

// ── Row level ────────────────────────────────────────────────────────────

ImportedBabyProfile _parseProfile(
    Map<String, dynamic> row, Set<String> seenIds) {
  const section = 'babyProfiles';
  final id = _requiredString(row, 'id', section);
  _requireUnique(id, seenIds, section);
  return ImportedBabyProfile(
    id: id,
    name: _requiredString(row, 'name', section),
    // Stored as epoch MILLISECONDS in a plain integer column — not a Drift
    // dateTime() column, so no conversion happens on either side.
    birthDateEpochMs:
        _milliseconds(row, 'birthDateEpochMs', 'birthDateUtc', section),
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
  //
  // `unit` — absent in formats 1 and 2, and those documents must keep
  // restoring: the row gets the unit the parent saw on screen
  // (`natural` → ml, never min). Present (format 3), it is validated against
  // the closed unit set AND against the row's own type/subtype, because a
  // `solid` row claiming `ml` is a wrong health number waiting to be shown:
  // rejected, never coerced.
  final rawUnit = _optionalString(row, 'unit', section);
  final unit = _resolveEventUnit(
    rawUnit: rawUnit,
    type: type,
    subtype: _optionalString(row, 'subtype', section),
    section: section,
  );
  return ImportedTrackingEvent(
    id: id,
    type: type,
    timestamp: _seconds(row, 'timestampEpochSeconds', 'timestampUtc', section),
    duration: _optionalFiniteDouble(row, 'durationMinutes', section),
    subtype: _optionalString(row, 'subtype', section),
    unit: unit,
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
  // Validated against the domain enum when present: a reminder pointing at a
  // care this build does not know could never be marked done, and would sit
  // there undiagnosable. `null` = reminder **detached** from any care (M4/D2):
  // Only the parent's "Fait" button can complete the process.
  final subtypeValue = _optionalString(row, 'subtypeValue', section);
  if (subtypeValue != null && HealthSubtype.byValue(subtypeValue) == null) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final frequency = _requiredString(row, 'frequency', section);
  if (!db_const.allFrequencyValues.contains(frequency)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  // Absent (format 1): `from_events`, which was the only value that existed at that time.
  final completionSource = _optionalString(row, 'completionSource', section) ??
      db_const.completionFromEvents;
  if (!db_const.allCompletionSourceValues.contains(completionSource)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return ImportedCustomReminder(
    id: id,
    label: label,
    subtypeValue: subtypeValue,
    frequency: frequency,
    intervalDays: _optionalPositiveInt(row, 'intervalDays', section),
    // Absent (format 1): A shared memory accessible to all babies.
    babyId: _optionalString(row, 'babyId', section) ?? db_const.sharedBabyId,
    completionSource: completionSource,
  );
}

ImportedReminderSetting _parseSetting(
    Map<String, dynamic> row, Set<Object> seenKeys) {
  const section = 'reminderSettings';
  // Absent (format 1): Setting shared by all babies.
  final babyId =
      _optionalString(row, 'babyId', section) ?? db_const.sharedBabyId;
  final itemId = _requiredString(row, 'itemId', section);
  _requireUnique((babyId, itemId), seenKeys, section);
  final enabled = row['enabled'];
  if (enabled is! bool) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return ImportedReminderSetting(
    babyId: babyId,
    itemId: itemId,
    enabled: enabled,
  );
}

ImportedReminderDismissal _parseDismissal(
    Map<String, dynamic> row, Set<Object> seenKeys) {
  const section = 'reminderDismissals';
  // Absent (format 1): Shared rejection among all the babies.
  final babyId =
      _optionalString(row, 'babyId', section) ?? db_const.sharedBabyId;
  final itemId = _requiredString(row, 'itemId', section);
  _requireUnique((babyId, itemId), seenKeys, section);
  return ImportedReminderDismissal(
    babyId: babyId,
    itemId: itemId,
    dismissedAt:
        _seconds(row, 'dismissedAtEpochSeconds', 'dismissedAtUtc', section),
  );
}

ImportedMeasurement _parseMeasurement(
    Map<String, dynamic> row, Set<int> seenIds) {
  const section = 'measurements';
  final id = _requiredInt(row, 'id', section);
  _requireUnique(id, seenIds, section);
  final kind = _requiredString(row, 'kind', section);
  if (!db_const.allMeasureKindValues.contains(kind)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final unit = _requiredString(row, 'unit', section);
  if (unit != db_const.unitG &&
      unit != db_const.unitCm &&
      unit != db_const.unitDegC) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  // The file contains the number in plain text (the export process decrypted it): it should...
  // remain a number to be re-calculated exactly when inserted. A measurement.
  // The `valueUndecryptable` property, which has a `value` of `null`, is rejected here: no further action.
  // The number is valid, and there is nothing to restore in this line. Accepting it would register a measurement.
  // empty instead of having weight.
  final value = _requiredString(row, 'value', section);
  if (double.tryParse(value) == null) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return ImportedMeasurement(
    id: id,
    // Orphaned (babyId present but profile missing from the file): retained.
    // like events.
    babyId: _optionalString(row, 'babyId', section),
    kind: kind,
    value: value,
    unit: unit,
    recordedAt:
        _seconds(row, 'recordedAtEpochSeconds', 'recordedAtUtc', section),
    notes: _optionalString(row, 'notes', section),
  );
}

ImportedReminderCompletion _parseCompletion(
    Map<String, dynamic> row, Set<Object> seenKeys) {
  const section = 'reminderCompletions';
  final babyId =
      _optionalString(row, 'babyId', section) ?? db_const.sharedBabyId;
  final itemId = _requiredString(row, 'itemId', section);
  _requireUnique((babyId, itemId), seenKeys, section);
  return ImportedReminderCompletion(
    babyId: babyId,
    itemId: itemId,
    completedAt:
        _seconds(row, 'completedAtEpochSeconds', 'completedAtUtc', section),
  );
}

/// One `app_settings` row: a known key, and a value that key accepts.
///
/// The time is checked with `isValidNotificationTime` — the very predicate the
/// scheduler relies on for the same string. This importer once owned its own
/// `^[0-2][0-9]:[0-5][0-9]$` and that pattern accepts `24:00`, because the
/// digit class behind `[0-2]` allows 4.
///
/// The opt-in is restored as written, even on a device where the OS permission
/// is missing — a backup is the owner's stated intent, and refusing a file
/// because of the phone it landed on would make the backup useless. The next
/// sync cycle runs the D8 de-opt (`notifications_opt_in` back to `'0'`) and the
/// switch stops lying; the intent survives the revocation, so re-granting the
/// permission does not need re-toggling anything but that switch.
ImportedAppSetting _parseAppSetting(
    Map<String, dynamic> row, Set<Object> seenKeys) {
  const section = 'appSettings';
  final key = _requiredString(row, 'key', section);
  final value = _requiredString(row, 'value', section);
  _requireUnique(key, seenKeys, section);

  if (!_knownSettingKeys.contains(key)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final valid = switch (key) {
    db_const.settingsKeyNotificationsOptIn => value == '0' || value == '1',
    db_const.settingsKeyNotificationTime => isValidNotificationTime(value),
    _ => false,
  };
  if (!valid) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return ImportedAppSetting(key: key, value: value);
}

/// Unit of an event row in the restore document.
///
/// Absent means a format-1/2 file: the row takes the unit the parent saw on
/// screen (`natural` → ml, never min), so an old backup restores unchanged
/// instead of being re-interpreted. Present means format 3: it is checked
/// against the closed unit set, and against the row's own type and subtype —
/// a `solid` row claiming `ml` is a wrong health number waiting to be shown,
/// so it rejects the file rather than being coerced into something plausible.
QuantityUnit _resolveEventUnit({
  required String? rawUnit,
  required String type,
  required String? subtype,
  required String section,
}) {
  final expected = defaultUnitFor(typeValue: type, subtypeValue: subtype);
  if (rawUnit == null) return expected;
  final unit = QuantityUnit.fromDbValue(rawUnit);
  if (unit == null) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  // The breast bears two legitimate units; everything else only has one, and...
  // A line that claims to represent something else is, in effect, lying about its own quantity.
  final allowed =
      type == db_const.typeMiam && subtype == db_const.subtypeNatural
          ? const {QuantityUnit.ml, QuantityUnit.min}
          : {expected};
  if (!allowed.contains(unit)) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return unit;
}

// ── Field extraction ─────────────────────────────────────────────────────
//
// Explicit helpers rather than `as` casts everywhere: the analyzer runs with
// strict-casts/strict-raw-types, and every rejection must name its section so
// the parent gets "the file is malformed" and not a Dart type message.

String _requiredString(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value is! String || value.isEmpty) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

String? _optionalString(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

int _requiredInt(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value is! int) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

int? _optionalPositiveInt(
    Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! int || value < 1) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

double? _optionalFiniteDouble(
    Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! num) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final converted = value.toDouble();
  if (!converted.isFinite) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return converted;
}

bool _boolWithTrueDefault(
    Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return true;
  if (value is! bool) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

/// Instant stored as epoch SECONDS, with the ISO twin as fallback.
DateTime _seconds(
    Map<String, dynamic> row, String epochKey, String isoKey, String section) {
  final epoch = row[epochKey];
  if (epoch is int) {
    return _checkRange(
        DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true),
        section);
  }
  if (epoch == null) {
    final iso = row[isoKey];
    if (iso is String) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) return _checkRange(parsed, section);
    }
  }
  throw ImportFormatException(ImportRejectionReason.invalidRow,
      section: section);
}

/// Instant stored as epoch MILLISECONDS (`baby_profiles.birth_date`), with the
/// ISO twin as fallback.
int _milliseconds(
    Map<String, dynamic> row, String epochKey, String isoKey, String section) {
  final epoch = row[epochKey];
  if (epoch is int) {
    _checkRange(
        DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true), section);
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
  throw ImportFormatException(ImportRejectionReason.invalidRow,
      section: section);
}

/// Rejects instants outside 1990-2100: a wrong unit (milliseconds where seconds
/// were expected, a hand-edited value) lands there, and restoring it would put
/// a baby event in 1970 with nothing raised to notice.
DateTime _checkRange(DateTime moment, String section) {
  final utc = moment.toUtc();
  if (utc.isBefore(_plausibleMin) || !utc.isBefore(_plausibleMax)) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return moment;
}

void _requireUnique(Object id, Set<Object> seen, String section) {
  if (!seen.add(id)) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
}

/// Deterministic `(birthDate, id)` ordering, the same one
/// `AppDatabase.getActiveBabyProfile` uses to pick the active profile.
ImportedBabyProfile _firstByBirthDateThenId(
    List<ImportedBabyProfile> profiles) {
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
      // The two tables in format 2 (M4) are being added to the existing five historical tables.
      // All or nothing, never half-hearted.
      await database.delete(database.measurements).go();
      await database.delete(database.reminderCompletions).go();
      await database.delete(database.babyProfiles).go();
      await database.delete(database.trackingEvents).go();
      await database.delete(database.customReminders).go();
      await database.delete(database.reminderSettings).go();
      await database.delete(database.reminderDismissals).go();
      // Last, and only here: a restore replaces preferences too, so an
      // opt-in the parent turned off before restoring must not survive it.
      await database.delete(database.appSettings).go();

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
          notes: Value(
              event.notes == null ? null : encryption.encrypt(event.notes!)),
          wasteType: Value(event.wasteType),
          color: Value(event.color),
          texture: Value(event.texture),
          babyId: Value(event.babyId),
          quantity: Value(event.quantity),
          // Written from the parsed entity: present in the file (format 3).
          // or backfilled by the parser (formats 1-2). The DEFAULT value should never be:
          // The column, which has no knowledge of the row's subtype.
          unit: event.unit.dbValue,
        ));
      }

      for (final reminder in parsed.customReminders) {
        await database.into(database.customReminders).insert(
              db_app.CustomRemindersCompanion.insert(
                id: Value(reminder.id),
                label: reminder.label,
                subtypeValue: Value(reminder.subtypeValue),
                // M4: The nullable column exists, and the derivation becomes a reality.
                // — The same rule applies as for all other text (D2): single-spaced.
                // (`subtypeValue == null`) ⟺ `manual`. The value it holds is:
                // The file is validated during parsing, but it is not written as is.
                // It is inconsistent with the `subtypeValue` and therefore cannot...
                // to settle in by renovating.
                completionSource: Value(
                  reminder.subtypeValue == null
                      ? db_const.completionManual
                      : db_const.completionFromEvents,
                ),
                frequency: reminder.frequency,
                intervalDays: Value(reminder.intervalDays),
                // Absent in format 1 backups: shared.
                babyId: Value(reminder.babyId),
              ),
            );
      }

      for (final setting in parsed.reminderSettings) {
        await database.into(database.reminderSettings).insert(
              db_app.ReminderSettingsCompanion.insert(
                // The `babyId` column has a default value defined: the parameter.
                // The `insertion` option is optional, so we enclose it in parentheses.
                babyId: Value(setting.babyId),
                itemId: setting.itemId,
                enabled: setting.enabled,
              ),
            );
      }

      for (final dismissal in parsed.reminderDismissals) {
        await database.into(database.reminderDismissals).insert(
              db_app.ReminderDismissalsCompanion.insert(
                babyId: Value(dismissal.babyId),
                itemId: dismissal.itemId,
                dismissedAt: dismissal.dismissedAt,
              ),
            );
      }

      for (final measurement in parsed.measurements) {
        await database.into(database.measurements).insert(
              db_app.MeasurementsCompanion.insert(
                // Explicit rowid, similar to events: the file ID is...
                // l'id de la table.
                id: Value(measurement.id),
                babyId: Value(measurement.babyId),
                kind: measurement.kind,
                // The file contains the number in plain text (the export process decrypted it).
                // The "resting state" invariant value is being processed again by the same department.
                // IV. Expenses, such as event costs.
                value: encryption.encrypt(measurement.value),
                unit: measurement.unit,
                recordedAt: measurement.recordedAt,
                notes: Value(
                  measurement.notes == null
                      ? null
                      : encryption.encrypt(measurement.notes!),
                ),
              ),
            );
      }

      for (final completion in parsed.reminderCompletions) {
        await database.into(database.reminderCompletions).insert(
              db_app.ReminderCompletionsCompanion.insert(
                babyId: Value(completion.babyId),
                itemId: completion.itemId,
                completedAt: completion.completedAt,
              ),
            );
      }

      for (final setting in parsed.appSettings) {
        await database.into(database.appSettings).insert(
              db_app.AppSettingsCompanion.insert(
                key: setting.key,
                value: setting.value,
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
      'measurements=${parsed.measurements.length} '
      'completions=${parsed.reminderCompletions.length} '
      'appSettings=${parsed.appSettings.length} '
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
