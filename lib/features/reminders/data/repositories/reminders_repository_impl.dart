import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

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
  static final Logger _logger = Logger();

  @override
  Future<DateTime?> getLastCompleted(ReminderItem item) async {
    try {
      // Query tracking_events for events matching this reminder's type (+ subtype for health).
      final type = item.trackingType.name;
      final subtypeValue = item.subtypeValue;
      
      // Get most recent event — no date restriction, returns last completed ever.
      final q = (database.select(database.trackingEvents)
        ..where((t) {
          final exp = t.type.equals(type) & (subtypeValue == null ? const Constant(true) : t.subtype.equals(subtypeValue));
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
}
