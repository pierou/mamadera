/// Export domain layer — pure Dart, no Flutter/Drift dependencies.
library;

/// Number of rows exported, per table.
///
/// Used both to fill the `counts` section of the export document and to let
/// the presentation layer detect a completely empty database (in which case
/// the share sheet must not be opened at all).
class ExportCounts {
  const ExportCounts({
    required this.babyProfiles,
    required this.trackingEvents,
    required this.reminderSettings,
    required this.reminderDismissals,
  });

  /// Number of rows in `baby_profiles`.
  final int babyProfiles;

  /// Number of rows in `tracking_events`.
  final int trackingEvents;

  /// Number of rows in `reminder_settings`.
  final int reminderSettings;

  /// Number of rows in `reminder_dismissals`.
  final int reminderDismissals;

  /// True when the database holds neither baby profile nor tracking event.
  ///
  /// Reminder rows alone do not make a useful backup: sharing an empty file
  /// is worse than not sharing at all.
  bool get isEmpty => babyProfiles == 0 && trackingEvents == 0;
}

/// Contract for producing a portable export of the entire local database.
///
/// The export is the ONE sanctioned way data ever leaves the device, so the
/// document must be complete and honest:
/// - events are exported UNFILTERED — every row, including rows whose
///   `babyId` is null and rows of every baby. A backup that quietly omits
///   rows is worse than no backup.
/// - notes come out DECRYPTED: a backup the recipient (the user) cannot read
///   is no backup. Decryption happens only through the shared tracking event
///   mapper, never elsewhere.
/// - no encryption key, no preferences, no file paths, no device identifier
///   ever appears in the document.
abstract class ExportRepository {
  /// Builds the complete export document as a pretty-printed UTF-8 JSON string.
  ///
  /// Contains the entire database (all four tables) with the shape described
  /// in the class dartdoc. Pure string building — no file IO, no sharing.
  Future<String> buildExportJson();

  /// Returns the row count of each of the four exported tables.
  Future<ExportCounts> counts();
}
