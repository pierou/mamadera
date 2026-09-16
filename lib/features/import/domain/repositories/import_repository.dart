/// Import domain layer — pure Dart, no Flutter/Drift dependencies.
///
/// This is the mirror image of `features/export/domain`: the export document is
/// the ONE sanctioned copy of the data that ever leaves the device, so the
/// importer's contract is "accept exactly what the exporter writes, and nothing
/// else". Anything outside that contract is rejected as a whole file — a
/// backup that restores half is worse than no restore at all.
library;

/// Number of rows of each table held by a parsed backup file.
///
/// Used for the confirmation summary (the user must see what they are about to
/// swap their data for) and for the success message. Never logged with content.
class ImportCounts {
  const ImportCounts({
    required this.babyProfiles,
    required this.trackingEvents,
    required this.customReminders,
    required this.reminderSettings,
    required this.reminderDismissals,
  });

  /// Number of rows in `baby_profiles`.
  final int babyProfiles;

  /// Number of rows in `tracking_events`.
  final int trackingEvents;

  /// Number of rows in `custom_reminders`.
  final int customReminders;

  /// Number of rows in `reminder_settings`.
  final int reminderSettings;

  /// Number of rows in `reminder_dismissals`.
  final int reminderDismissals;
}

/// A `baby_profiles` row as read from a backup document.
///
/// [birthDateEpochMs] keeps the app-level storage convention verbatim (epoch
/// MILLISECONDS in a plain integer column) so the restore is a copy, not a
/// re-interpretation.
class ImportedBabyProfile {
  const ImportedBabyProfile({
    required this.id,
    required this.name,
    required this.birthDateEpochMs,
    required this.isActive,
  });

  /// Stable profile identifier, preserved from the file.
  final String id;

  /// Display name, as the parent typed it.
  final String name;

  /// Birth date in epoch milliseconds.
  final int birthDateEpochMs;

  /// Whether this profile was the active one when the file was written.
  final bool isActive;
}

/// A `tracking_events` row as read from a backup document.
///
/// [notes] is PLAINTEXT here: the export decrypts notes (a backup the owner
/// cannot read is no backup), and the importer re-encrypts on insert. Nothing
/// between the parser and the insert may write this value to a log or to disk.
class ImportedTrackingEvent {
  const ImportedTrackingEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.duration,
    required this.subtype,
    required this.notes,
    required this.wasteType,
    required this.color,
    required this.texture,
    required this.babyId,
    required this.quantity,
  });

  /// Event identifier, preserved from the file (explicit rowid on insert).
  final int id;

  /// Stored type code (`miam` | `caca` | `dodo` | `sante`), validated against
  /// `db_const.allTypeValues` by the parser.
  final String type;

  /// Event instant; the file's epoch seconds (or ISO fallback) already resolved.
  final DateTime timestamp;

  /// Duration in minutes, when present.
  final double? duration;

  /// Typed subtype, passed through un-interpreted (see the parser dartdoc).
  final String? subtype;

  /// Plaintext note, to be re-encrypted before it reaches the database.
  final String? notes;

  /// Diaper waste type, passed through.
  final String? wasteType;

  /// Colour code (or pipe-delimited pair), passed through.
  final String? color;

  /// Stool texture code, passed through.
  final String? texture;

  /// Owning profile id, or null. May reference a profile absent from the file
  /// (orphan): kept, exactly as the export kept it.
  final String? babyId;

  /// Quantity (ml for feeding, minutes for sleep), when present.
  final double? quantity;
}

/// A `custom_reminders` row as read from a backup document.
class ImportedCustomReminder {
  const ImportedCustomReminder({
    required this.id,
    required this.label,
    required this.subtypeValue,
    required this.frequency,
    required this.intervalDays,
  });

  /// Reminder identifier, preserved so the `custom_<id>` keys in
  /// `reminder_settings` keep pointing at the right reminder.
  final int id;

  /// Parent-typed name, never translated.
  final String label;

  /// `HealthSubtype` value: the care whose absence makes the reminder due.
  final String subtypeValue;

  /// Stored frequency code (`daily` | `weekly` | `monthly` | `every_n_days`).
  final String frequency;

  /// Roll length in days, only meaningful for `every_n_days`.
  final int? intervalDays;
}

/// A `reminder_settings` row as read from a backup document.
class ImportedReminderSetting {
  const ImportedReminderSetting({required this.itemId, required this.enabled});

  /// Preset key (`miam`, `caca`, …) or `custom_<id>`.
  final String itemId;

  /// Whether the parent left this reminder switched on.
  final bool enabled;
}

/// A `reminder_dismissals` row as read from a backup document.
class ImportedReminderDismissal {
  const ImportedReminderDismissal({
    required this.itemId,
    required this.dismissedAt,
  });

  /// Reminder key this dismissal belongs to.
  final String itemId;

  /// When the parent dismissed it.
  final DateTime dismissedAt;
}

/// A validated backup document: five typed row lists, nothing else.
///
/// Produced by [ImportRepository.parseExport] and consumed by
/// [ImportRepository.restore]. Deliberately contains only primitives,
/// [DateTime]s and strings so it can cross an isolate boundary.
class ParsedExport {
  const ParsedExport({
    required this.babyProfiles,
    required this.trackingEvents,
    required this.customReminders,
    required this.reminderSettings,
    required this.reminderDismissals,
  });

  /// Profiles to restore.
  final List<ImportedBabyProfile> babyProfiles;

  /// Events to restore (orphans included).
  final List<ImportedTrackingEvent> trackingEvents;

  /// Parent-invented reminders to restore.
  final List<ImportedCustomReminder> customReminders;

  /// On/off switches to restore.
  final List<ImportedReminderSetting> reminderSettings;

  /// Dismissals to restore.
  final List<ImportedReminderDismissal> reminderDismissals;

  /// Row counts for the confirmation summary and the success message.
  ImportCounts get counts => ImportCounts(
        babyProfiles: babyProfiles.length,
        trackingEvents: trackingEvents.length,
        customReminders: customReminders.length,
        reminderSettings: reminderSettings.length,
        reminderDismissals: reminderDismissals.length,
      );

  /// True when the file holds neither a profile nor an event.
  ///
  /// Mirrors the export's own definition of empty: restoring such a file would
  /// only erase the current database.
  bool get hasNoRestorableData =>
      babyProfiles.isEmpty && trackingEvents.isEmpty;

  /// True when the file holds at least one baby profile.
  ///
  /// A file with events but no profile is restorable and legal, but leaves the
  /// app without an active baby — the UI must warn before applying it.
  bool get hasBabyProfiles => babyProfiles.isNotEmpty;
}

/// Why a file was rejected.
///
/// A CLOSED set, deliberately: each value maps to exactly one ARB key, so no
/// exception text, file name, path or `content://` URI can ever reach the
/// screen (or a screenshot). Adding a reason means adding a translation, which
/// is the point.
enum ImportRejectionReason {
  /// Not JSON at all, or not a JSON object.
  invalidJson,

  /// Valid JSON, but not a document this app wrote.
  notAMamaderaFile,

  /// `exportFormatVersion` is newer than this importer understands.
  newerFormatVersion,

  /// `databaseSchemaVersion` is newer than the installed schema: the document
  /// may carry fields this build would silently drop on restore.
  newerSchemaVersion,

  /// A table section is missing or is not an array.
  missingTable,

  /// `counts` disagrees with the payload lengths: the file cannot be trusted.
  countsMismatch,

  /// The file is well formed but holds nothing worth restoring.
  emptyFile,

  /// A row violates the contract (unknown type, duplicate id, bad timestamp…).
  invalidRow,

  /// The picked file is far bigger than any backup this app writes: the parent
  /// almost certainly picked the wrong file, so it is refused before it is read.
  fileTooLarge,

  /// The picked file could not be read at all (permission revoked, moved away).
  unreadableFile,
}

/// Thrown by [ImportRepository.parseExport] for any rejected file.
///
/// Carries only [reason] and the name of the offending [section] (a table key,
/// never a row's content), so it is safe to log.
class ImportFormatException implements Exception {
  const ImportFormatException(this.reason, {this.section});

  /// Why the file was rejected; decides the message shown to the parent.
  final ImportRejectionReason reason;

  /// Table key the problem was found in, when known (`trackingEvents`, …).
  final String? section;

  @override
  String toString() => 'ImportFormatException(${reason.name}'
      '${section == null ? '' : ', section: $section'})';
}

/// Largest backup file this app is willing to read, in bytes.
///
/// A full backup of years of entries is well under 1 MB; 5 MB is therefore not
/// a feature limit but a guard against picking a random large file (a photo,
/// a video) and waiting for it to be decoded before saying no.
const int maxBackupBytes = 5 * 1024 * 1024;

/// Rejects a picked file that is far too big to be a backup.
///
/// Pure and separate from the picker so the gate itself is testable: pass the
/// length the platform reported (`null` when it reported none) and, if the file
/// was already read, its actual byte count. Throws [ImportFormatException] with
/// [ImportRejectionReason.fileTooLarge]; it never sees file content.
void enforceBackupSizeLimit({
  required int? knownLength,
  int actualBytes = 0,
}) {
  final size = knownLength ?? actualBytes;
  if (size > maxBackupBytes) {
    throw const ImportFormatException(ImportRejectionReason.fileTooLarge);
  }
}

/// Contract for restoring the local database from an export document.
///
/// Two steps, and the split is the whole safety story:
/// - [parseExport] is pure and destructive-free. It validates the §3 contract
///   of the plan and throws [ImportFormatException] with a specific reason.
///   A failure here leaves the database untouched, by construction.
/// - [restore] is the only method that writes. It replaces the content of all
///   five tables inside ONE transaction, so a mid-way failure rolls back to
///   the exact pre-restore state.
abstract class ImportRepository {
  /// Parses and validates [json], returning the rows to restore.
  ///
  /// Performs no database access and no file IO. Throws
  /// [ImportFormatException] for any violation; the parsed rows are still
  /// plaintext notes at this point and must not be persisted anywhere.
  Future<ParsedExport> parseExport(String json);

  /// Replaces the entire content of the five tables with [parsed].
  ///
  /// Runs in a single transaction: delete all rows, re-insert with the ids from
  /// the file, notes re-encrypted with a fresh IV. Returns the counts actually
  /// written.
  Future<ImportCounts> restore(ParsedExport parsed);
}
