import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
// Alias for drift-generated row types (distinct from domain entities)
import '../../../../data/local/app_db.dart' as db_app;
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_frequency.dart';
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

  // ── Rappels personnalisés ──────────────────────────────────────────

  /// Codes écrits dans `custom_reminders.frequency`.
  ///
  /// Gravés en dur : les renommer changerait de sens chaque installation
  /// existante. `every_n_days` est écrit en toutes lettres parce que la colonne
  /// se relit telle quelle dans un JSON de sauvegarde.
  static const String _freqDaily = 'daily';
  static const String _freqWeekly = 'weekly';
  static const String _freqMonthly = 'monthly';
  static const String _freqEveryNDays = 'every_n_days';

  /// Longueur maximale du libellé : `withLength(max: 60)` de la table, alignée
  /// sur le `maxLength` du formulaire.
  static const int _maxLabelLength = 60;

  /// Jour de semaine écrit pour un rythme hebdomadaire.
  ///
  /// `isDue` ne s'en sert jamais (achever un rappel hebdo le
  /// fait attendre à la semaine ISO suivante, quel que soit le jour) : on
  /// enregistre lundi pour que la ligne reste lisible à la main.
  static const int _weeklyStoredDayOfWeek = 1;

  /// Roulement appliqué à une valeur `interval_days` illisible.
  static const int _defaultIntervalDays = 7;

  ({String code, int? intervalDays}) _encodeFrequency(
          ReminderFrequency frequency) =>
      frequency.map(
        daily: (_) => (code: _freqDaily, intervalDays: null),
        weekly: (_) => (code: _freqWeekly, intervalDays: null),
        // Le jour du mois n'est pas stocké : c'est celui de naissance du bébé
        // actif, relu à chaque construction de la liste — comme la vitamine K.
        monthly: (_) => (code: _freqMonthly, intervalDays: null),
        customInterval: (f) =>
            (code: _freqEveryNDays, intervalDays: f.days),
      );

  /// Décodage tolérant : un code inconnu — JSON restauré à la main, version
  /// future du format — devient un rappel **quotidien** plutôt que de
  /// disparaître. Un rappel qu'on ne voit plus ne peut plus être corrigé.
  ReminderFrequency _decodeFrequency(String code, int? intervalDays) {
    if (code == _freqWeekly) {
      return const ReminderFrequency.weekly(
        dayOfWeek: _weeklyStoredDayOfWeek,
      );
    }
    if (code == _freqMonthly) {
      return const ReminderFrequency.monthly(
        dayOfMonth: CustomReminderPresets.monthlyFallbackDay,
      );
    }
    if (code == _freqEveryNDays) {
      // Une valeur négative ou nulle rendrait le rappel dû en permanence.
      final days = intervalDays == null || intervalDays < 1
          ? _defaultIntervalDays
          : intervalDays;
      return ReminderFrequency.customInterval(days: days);
    }
    return const ReminderFrequency.daily();
  }

  CustomReminder _toDomain(db_app.CustomReminder row) => CustomReminder(
        id: row.id,
        label: row.label,
        subtypeValue: row.subtypeValue,
        frequency: _decodeFrequency(row.frequency, row.intervalDays),
      );

  /// Le libellé est la seule saisie libre de ce chemin : nettoyé, contrôlé, et
  /// jamais écrit dans un log — c'est du texte de parent, pas une clé.
  String _validatedLabel(String raw) {
    final label = raw.trim();
    if (label.isEmpty) {
      throw ArgumentError.value(raw, 'label', 'Un rappel doit avoir un nom.');
    }
    if (label.length > _maxLabelLength) {
      // La longueur, jamais le texte : cette exception est remontée puis écrite
      // par le `catch` du dessus, et un nom de rappel est du texte de parent.
      throw ArgumentError.value(
        label.length,
        'label',
        'Nom de rappel trop long (max $_maxLabelLength caractères).',
      );
    }
    return label;
  }

  @override
  Future<List<CustomReminder>> getCustomReminders() async {
    try {
      final rows = await database.getAllCustomReminders();
      return [for (final row in rows) _toDomain(row)];
    } catch (e, stack) {
      _logger.e(
        'getCustomReminders error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<int> insertCustomReminder(CustomReminder reminder) async {
    try {
      final (code: code, intervalDays: intervalDays) =
          _encodeFrequency(reminder.frequency);

      final id = await database.into(database.customReminders).insert(
        db_app.CustomRemindersCompanion.insert(
          label: _validatedLabel(reminder.label),
          subtypeValue: reminder.subtypeValue,
          frequency: code,
          intervalDays: Value(intervalDays),
        ),
      );
      _logger.d('insertCustomReminder(id: $id)');
      return id;
    } catch (e, stack) {
      _logger.e(
        'insertCustomReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCustomReminder(CustomReminder reminder) async {
    try {
      final id = reminder.id;
      if (id == null) {
        // Aucune valeur : `reminder.toString()` contient le libellé du parent, et
        // cette exception part dans le log du `catch` en dessous.
        throw ArgumentError(
          'Un rappel à mettre à jour doit avoir un identifiant.',
        );
      }
      final (code: code, intervalDays: intervalDays) =
          _encodeFrequency(reminder.frequency);

      final updated = await (database.update(database.customReminders)
            ..where((t) => t.id.equals(id)))
          .write(
        db_app.CustomRemindersCompanion(
          label: Value(_validatedLabel(reminder.label)),
          subtypeValue: Value(reminder.subtypeValue),
          frequency: Value(code),
          intervalDays: Value(intervalDays),
        ),
      );
      _logger.d('updateCustomReminder($id) — rows: $updated');
    } catch (e, stack) {
      _logger.e(
        'updateCustomReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomReminder(int id) async {
    try {
      final itemKey =
          '${CustomReminderPresets.customIdPrefix}$id';

      // Transaction : trois tables sont touchées. Un rappel coupé en deux
      // laisserait un réglage orphelin dans chaque sauvegarde, et c'est
      // précisément ce que cette méthode doit empêcher.
      await database.transaction(() async {
        await (database.delete(database.customReminders)
              ..where((t) => t.id.equals(id)))
            .go();
        await database.customStatement(
          'DELETE FROM reminder_settings WHERE item_id = ?',
          [itemKey],
        );
        await database.customStatement(
          'DELETE FROM reminder_dismissals WHERE item_id = ?',
          [itemKey],
        );
      });
      _logger.d('deleteCustomReminder($id)');
    } catch (e, stack) {
      _logger.e(
        'deleteCustomReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
