import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
// Alias for drift-generated row types (distinct from domain entities)
import '../../../../data/local/app_db.dart' as db_app;
import '../../domain/repositories/app_settings_repository.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  /// Explicit injection — no fallback singleton.
  const AppSettingsRepositoryImpl({required this.database});

  final db_app.AppDatabase database;
  static final Logger _logger = appLogger();

  @override
  Future<String?> get(String key) async {
    try {
      final row = await (database.select(database.appSettings)
            ..where((t) => t.key.equals(key)))
          .getSingleOrNull();
      return row?.value;
    } catch (e, stack) {
      _logger.e('get($key) error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> set(String key, String value) async {
    try {
      await database.into(database.appSettings).insert(
            db_app.AppSettingsCompanion.insert(key: key, value: value),
            onConflict: DoUpdate(
              (_) => db_app.AppSettingsCompanion.custom(
                value: Variable(value),
              ),
            ),
          );
    } catch (e, stack) {
      _logger.e('set($key) error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await database.delete(database.appSettings).go();
    } catch (e, stack) {
      _logger.e('deleteAll() error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> getAll() async {
    try {
      final rows = await database.select(database.appSettings).get();
      return {for (final row in rows) row.key: row.value};
    } catch (e, stack) {
      _logger.e('getAll() error', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
