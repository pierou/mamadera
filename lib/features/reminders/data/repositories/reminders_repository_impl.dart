import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
// Alias for drift-generated row types (distinct from domain entities)
import '../../../../data/local/app_db.dart' as db_app;
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/reminders_repository.dart';
class RemindersRepositoryImpl implements RemindersRepository {
  /// Explicit injection — no fallback singleton.
  const RemindersRepositoryImpl({
    required this.database,
  });

  final db_app.AppDatabase database;
  static final Logger _logger = appLogger();

  @override
  Future<DateTime?> getLastCompleted(ReminderItem item, {String? babyId}) async {
    try {
      // Query tracking_events for events matching this reminder's type (+ subtype for health).
      final type = item.trackingType.name;
      final subtypeValue = item.subtypeValue;
      
      // Get most recent event — no date restriction, returns last completed ever.
      // Scoped to the active baby when one is known (see interface dartdoc).
      final q = (database.select(database.trackingEvents)
        ..where((t) {
          final exp = t.type.equals(type)
              & (subtypeValue == null ? const Constant(true) : t.subtype.equals(subtypeValue))
              & (babyId == null ? const Constant(true) : t.babyId.equals(babyId));
          return exp;
        })
        ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
        ..limit(1));

      final results = await q.get();
      if (results.isEmpty) return null;

      _logger.d('getLastCompleted(${item.id}) — found: ${results.first.timestamp}');
      return results.first.timestamp;
    } catch (e, stack) {
      _logger.e(
        'getLastCompleted error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> saveDismissalTime(String itemId, DateTime dismissedAt) async {
    try {
      _logger.d('saveDismissalTime($itemId, $dismissedAt)');

      // Manual upsert: delete existing row then insert new one.
      await database.customStatement(
        'DELETE FROM reminder_dismissals WHERE item_id = ?',
        [itemId],
      );
      await database.into(database.reminderDismissals).insert(
        db_app.ReminderDismissalsCompanion.insert(
          itemId: itemId,
          dismissedAt: dismissedAt,
        ),
      );
    } catch (e, stack) {
      _logger.e(
        'saveDismissalTime error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<DateTime?> getDismissalTime(String itemId) async {
    try {
      final dismissals = (database.select(database.reminderDismissals)
        ..where((t) => t.itemId.equals(itemId)))
          .get();

      final results = await dismissals;
      if (results.isEmpty) return null;

      _logger.d('getDismissalTime($itemId) — found dismissal: ${results.first.dismissedAt}');
      return results.first.dismissedAt;
    } catch (e, stack) {
      _logger.e(
        'getDismissalTime error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, bool>> getEnabledByItemId() async {
    try {
      final rows = await database.select(database.reminderSettings).get();
      // Une table vide est le cas normal (personne n'a encore rien décoché) :
      // ce n'est pas une erreur, et l'appelant interprète l'absence comme « activé ».
      return {for (final row in rows) row.itemId: row.enabled};
    } catch (e, stack) {
      _logger.e(
        'getEnabledByItemId error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    try {
      _logger.d('setEnabled($itemId, $enabled)');

      // Même upsert manuel que saveDismissalTime : `item_id` est UNIQUE, et un
      // delete + insert garde la table à une ligne par rappel. Pas de
      // transaction : une coupure entre les deux requêtes ne perd qu'un choix
      // (le rappel redevient activé par défaut), jamais de données de suivi.
      await database.customStatement(
        'DELETE FROM reminder_settings WHERE item_id = ?',
        [itemId],
      );
      await database.into(database.reminderSettings).insert(
        db_app.ReminderSettingsCompanion.insert(
          itemId: itemId,
          enabled: enabled,
        ),
      );
    } catch (e, stack) {
      _logger.e(
        'setEnabled error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
