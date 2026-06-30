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
  Future<DateTime?> getLastCompletedToday(ReminderItem item) async {
    try {
      // Start of the current calendar day.
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      _logger.d('getLastCompletedToday(${item.id}) — querying from $todayStart');

      // Query the reminder_dismissals table for dismissals matching this item.
      final results = await (database.select(database.reminderDismissals)
        ..where((t) => t.itemId.equals(item.id))).get();

      // Filter to today in-memory — Drift doesn't support DateTime comparison operators
      // on GeneratedColumn, so we fetch by item_id and filter the small result set.
      final todayResults = results.where(
        (r) => r.dismissedAt.isAfter(todayStart.subtract(const Duration(seconds: 1))),
      ).toList();

      if (todayResults.isEmpty) return null;

      _logger.d('getLastCompletedToday(${item.id}) — found ${todayResults.length} dismissal(s) today');
      return todayResults.first.dismissedAt;
    } catch (e, stack) {
      _logger.e(
        'getLastCompletedToday error',
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

      // Use the generated companion class directly for upsert.
      final row = db_app.ReminderDismissalsCompanion.insert(
        itemId: itemId,
        dismissedAt: dismissedAt,
      );

      // Upsert on conflict (item_id is PK): replace old dismissal with new one.
      await database.into(database.reminderDismissals).insertOnConflictUpdate(row);
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
