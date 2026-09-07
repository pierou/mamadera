import 'dart:convert';

import 'package:logger/logger.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/tracking_event_mapper.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../domain/repositories/export_repository.dart';

/// Concrete implementation of [ExportRepository].
///
/// Reads the entire database (all four tables, unfiltered), decrypts event
/// notes through the shared tracking event mapper — the single place in the
/// codebase where decryption happens — and serializes everything into the
/// export document. Only counts and timings are logged; no exported content,
/// no name, no note ever reaches the log.
class ExportRepositoryImpl implements ExportRepository {
  const ExportRepositoryImpl({
    required this.database,
    required this.encryption,
  });

  final db_app.AppDatabase database;
  final EncryptionService encryption;

  static final Logger _logger = appLogger();

  @override
  Future<String> buildExportJson() async {
    final stopwatch = Stopwatch()..start();

    // UNFILTERED reads: every row of every table, including events whose
    // babyId is null. A backup that quietly omits rows is worse than none.
    final profiles = await database.getAllBabyProfiles();
    final events = await database.getAllTrackingEvents();
    final settings = await database.getAllReminderSettings();
    final dismissals = await database.getAllReminderDismissals();
    stopwatch.stop();

    // Counts and timings only — never any exported content.
    _logger.d(
      'buildExportJson: profiles=${profiles.length} events=${events.length} '
      'settings=${settings.length} dismissals=${dismissals.length} '
      'in ${stopwatch.elapsedMilliseconds} ms',
    );

    final document = <String, Object?>{
      'exportFormatVersion': 1,
      'generator': 'mamadera',
      'appVersion': AppConfig.version,
      'databaseSchemaVersion': database.schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'counts': <String, Object?>{
        'babyProfiles': profiles.length,
        'trackingEvents': events.length,
        'reminderSettings': settings.length,
        'reminderDismissals': dismissals.length,
      },
      'babyProfiles': _mapProfiles(profiles),
      'trackingEvents': _mapEvents(events),
      'reminderSettings': [
        for (final setting in settings)
          <String, Object?>{
            'itemId': setting.itemId,
            'enabled': setting.enabled,
          },
      ],
      'reminderDismissals': [
        for (final dismissal in dismissals)
          <String, Object?>{
            'itemId': dismissal.itemId,
            'dismissedAtEpochSeconds':
                dismissal.dismissedAt.millisecondsSinceEpoch ~/ 1000,
            'dismissedAtUtc':
                dismissal.dismissedAt.toUtc().toIso8601String(),
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(document);
  }

  @override
  Future<ExportCounts> counts() async {
    final profiles = await database.getAllBabyProfiles();
    final events = await database.getAllTrackingEvents();
    final settings = await database.getAllReminderSettings();
    final dismissals = await database.getAllReminderDismissals();
    return ExportCounts(
      babyProfiles: profiles.length,
      trackingEvents: events.length,
      reminderSettings: settings.length,
      reminderDismissals: dismissals.length,
    );
  }

  /// Maps baby profile rows. `birth_date` is stored as epoch MILLISECONDS,
  /// so it is emitted both as the lossless integer and as an ISO8601 UTC
  /// string for humans — deliberately two fields.
  List<Map<String, Object?>> _mapProfiles(List<db_app.BabyProfile> profiles) => [
        for (final profile in profiles)
          <String, Object?>{
            'id': profile.id,
            'name': profile.name,
            'birthDateEpochMs': profile.birthDate,
            'birthDateUtc': DateTime.fromMillisecondsSinceEpoch(
              profile.birthDate,
              isUtc: true,
            ).toIso8601String(),
            'isActive': profile.isActive,
          },
      ];

  /// Maps event rows. `timestamp` is stored as epoch SECONDS, so it is
  /// emitted both as the lossless integer and as an ISO8601 UTC string —
  /// deliberately two fields.
  List<Map<String, Object?>> _mapEvents(List<db_app.TrackingEvent> events) => [
        for (final row in events) _mapEvent(row),
      ];

  Map<String, Object?> _mapEvent(db_app.TrackingEvent row) {
    // The mapper is the SINGLE place where decryption happens.
    final entity = mapToEntity(row, encryption);
    final notes = _decryptedNotes(entity);

    // A row whose ciphertext exists in the database but does not decrypt
    // (lost/rotated key) must NOT be emitted as a plain null — that would
    // look like "the user wrote no note". Flag it explicitly so the silent
    // loss is visible to whoever reads the backup.
    final notesUndecryptable = row.notes != null && notes == null;

    final event = <String, Object?>{
      'id': row.id,
      'type': row.type,
      'timestampEpochSeconds': row.timestamp.millisecondsSinceEpoch ~/ 1000,
      'timestampUtc': row.timestamp.toUtc().toIso8601String(),
      'durationMinutes': row.duration,
      'subtype': row.subtype,
      'notes': notes,
      'wasteType': row.wasteType,
      'color': row.color,
      'babyId': row.babyId,
      'quantity': row.quantity,
    };
    if (notesUndecryptable) {
      event['notesUndecryptable'] = true;
    }
    return event;
  }

  /// Récupère le champ `notes` (déchiffré par le mapper) quel que soit le
  /// sous-type : la classe de base sealed ne l'expose pas directement.
  String? _decryptedNotes(TrackingEvent entity) => entity.when(
        (id0, ts0, baby0) => null,
        feeding: (id, ts, baby, sub, qty, notes) => notes,
        sleep: (id, ts, baby, dur, qty, notes) => notes,
        diaper: (id, ts, baby, wt, pc, cc, notes) => notes,
        health: (id, ts, baby, sub, notes) => notes,
      );
}
