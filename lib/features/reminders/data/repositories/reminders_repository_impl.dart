import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/app_logger.dart';
// Alias for drift-generated row types (distinct from domain entities)
import '../../../../data/local/app_db.dart' as db_app;
import '../../../../data/local/db_constants.dart' as db_const;
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

  /// Portage effectif des écritures : le bébé demandé, sinon la sentinelle
  /// partagée — c'est ici, à la frontière, que `null` devient `''` ; les
  /// requêtes d'en-dessous ne voient plus que des bébés concrets.
  String _scope(String? babyId) => babyId ?? db_const.sharedBabyId;

  /// Portages visibles pour une lecture : la ligne du bébé **et** la ligne
  /// partagée, qui s'applique à tous les bébés (notamment les lignes héritées
  /// d'une installation sans profil).
  List<String> _visibleScopes(String? babyId) {
    final scope = _scope(babyId);
    return scope == db_const.sharedBabyId
        ? const [db_const.sharedBabyId]
        : [db_const.sharedBabyId, scope];
  }

  @override
  Future<DateTime?> getLastCompleted(ReminderItem item, {String? babyId}) async {
    try {
      // Invariant D2 : un item sans [ReminderItem.subtypeValue] est détaché
      // d'un soin — aucun événement ne peut le régler, même un `sante` du bon
      // type. Sa complétion n'arrive que par [getLastManualCompletion].
      // (Le vieil `Constant(true)` de repli matcherait n'importe quel
      // événement de santé et réglerait ce rappel à la première prise de
      // poids venue.)
      final subtypeValue = item.subtypeValue;
      if (subtypeValue == null) return null;

      // Query tracking_events for events matching this reminder's type (+ subtype for health).
      final scope = _scope(babyId);

      // Get most recent event — no date restriction, returns last completed ever.
      // Scoped to the active baby when one is known (see interface dartdoc).
      final q = (database.select(database.trackingEvents)
        ..where((t) {
          final exp = t.type.equals(item.trackingType.name) &
              t.subtype.equals(subtypeValue) &
              (scope == db_const.sharedBabyId
                  ? const Constant(true)
                  : t.babyId.equals(scope));
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
  Future<DateTime?> getLastManualCompletion(String itemId, {String? babyId}) async {
    try {
      // Journal append-only : la lecture est la plus récente ligne du portage
      // du bébé, la ligne partagée ('') s'ajoutant — même forme que
      // [getLastCompleted] côté événements.
      final scopes = _visibleScopes(babyId);
      final q = database.select(database.reminderCompletions)
        ..where((t) => t.itemId.equals(itemId) & t.babyId.isIn(scopes))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
        ..limit(1);
      final row = await q.getSingleOrNull();
      if (row == null) return null;
      _logger.d('getLastManualCompletion($itemId) — found: ${row.completedAt}');
      return row.completedAt;
    } catch (e, stack) {
      _logger.e(
        'getLastManualCompletion error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastDismissal(String itemId, {String? babyId}) async {
    try {
      // Au plus deux lignes (portage du bébé + partage), la plus récente gagne.
      final scopes = _visibleScopes(babyId);
      final q = database.select(database.reminderDismissals)
        ..where((t) => t.itemId.equals(itemId) & t.babyId.isIn(scopes))
        ..orderBy([(t) => OrderingTerm.desc(t.dismissedAt)])
        ..limit(1);
      final row = await q.getSingleOrNull();
      return row?.dismissedAt;
    } catch (e, stack) {
      _logger.e(
        'getLastDismissal error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> recordCompletion(String itemId, {String? babyId, DateTime? at}) async {
    try {
      final scope = _scope(babyId);
      final completedAt = at ?? DateTime.now();
      await database.into(database.reminderCompletions).insert(
        db_app.ReminderCompletionsCompanion.insert(
          babyId: Value(scope),
          itemId: itemId,
          completedAt: completedAt,
        ),
      );
      _logger.d('recordCompletion($itemId, $scope)');
    } catch (e, stack) {
      _logger.e(
        'recordCompletion error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> dismissReminder(String itemId, {String? babyId, DateTime? at}) async {
    try {
      final scope = _scope(babyId);
      final dismissedAt = at ?? DateTime.now();

      // Upsert (baby_id, item_id) dans une transaction : une coupure entre la
      // suppression et l'insertion laisserait le rappel « jamais ignoré »
      // pendant un instant, et l'index composite exigerait un aller-retour de
      // plus pour le constater.
      await database.transaction(() async {
        await (database.delete(database.reminderDismissals)
              ..where((t) => t.babyId.equals(scope) & t.itemId.equals(itemId)))
            .go();
        await database.into(database.reminderDismissals).insert(
          db_app.ReminderDismissalsCompanion.insert(
            babyId: Value(scope),
            itemId: itemId,
            dismissedAt: dismissedAt,
          ),
        );
      });
      _logger.d('dismissReminder($itemId, $scope)');
    } catch (e, stack) {
      _logger.e(
        'dismissReminder error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, bool>> getEnabledByItemId({String? babyId}) async {
    try {
      final scopes = _visibleScopes(babyId);
      final rows = await (database.select(database.reminderSettings)
            ..where((t) => t.babyId.isIn(scopes)))
          .get();
      // Une table vide est le cas normal (personne n'a encore rien décoché) :
      // ce n'est pas une erreur, et l'appelant interprète l'absence comme « activé ».
      // La ligne propre au bébé écrase la ligne partagée : on pose d'abord le
      // partage, puis le propre.
      final shared = rows.where((row) => row.babyId == db_const.sharedBabyId);
      final own = rows.where((row) => row.babyId != db_const.sharedBabyId);
      return {
        for (final row in shared) row.itemId: row.enabled,
        for (final row in own) row.itemId: row.enabled,
      };
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
  Future<void> setEnabled(String itemId, {required bool enabled, String? babyId}) async {
    try {
      final scope = _scope(babyId);
      _logger.d('setEnabled($itemId, $enabled, $scope)');

      // Transaction : le upsert (baby_id, item_id) doit être atomique, sinon
      // une coupure entre la suppression et l'insertion laisserait le rappel
      // « activé par défaut » — et le choix du parent se perdrait à chaque
      // basculement de bébé.
      await database.transaction(() async {
        await (database.delete(database.reminderSettings)
              ..where((t) => t.babyId.equals(scope) & t.itemId.equals(itemId)))
            .go();
        await database.into(database.reminderSettings).insert(
          db_app.ReminderSettingsCompanion.insert(
            babyId: Value(scope),
            itemId: itemId,
            enabled: enabled,
          ),
        );
      });
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
  /// Définis dans `db_constants.dart` : les renommer changerait de sens chaque
  /// installation existante, et l'importateur de sauvegarde doit valider ces
  /// mêmes codes sans dépendre de cette classe. `every_n_days` est écrit en
  /// toutes lettres parce que la colonne se relit telle quelle dans un JSON de
  /// sauvegarde.
  static const String _freqDaily = db_const.freqDaily;
  static const String _freqWeekly = db_const.freqWeekly;
  static const String _freqMonthly = db_const.freqMonthly;
  static const String _freqEveryNDays = db_const.freqEveryNDays;

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
        // Lu en retour tel quel : la colonne est la source de vérité de qui
        // règle le rappel, jamais un défaut recalculé ici.
        completionSource: row.completionSource,
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
  Future<List<CustomReminder>> getCustomReminders({String? babyId}) async {
    try {
      // Le rappel est porté par la ligne : créé pour un bébé, il ne sonne que
      // pour lui — sauf le portage partagé (''), hérité de v10, qui s'applique
      // à tous.
      final scopes = _visibleScopes(babyId);
      final rows = await (database.select(database.customReminders)
            ..where((t) => t.babyId.isIn(scopes))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();
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
  Future<int> insertCustomReminder(CustomReminder reminder, {String? babyId}) async {
    try {
      final scope = _scope(babyId);
      final (code: code, intervalDays: intervalDays) =
          _encodeFrequency(reminder.frequency);

      final id = await database.into(database.customReminders).insert(
        db_app.CustomRemindersCompanion.insert(
          label: _validatedLabel(reminder.label),
          subtypeValue: Value(reminder.subtypeValue),
          // L'invariant est posé ici, à la frontière d'écriture : un rappel sans
          // soin ne peut pas rester déduit des événements, il serait dû sur le
          // premier événement de santé venu.
          completionSource: Value(
            reminder.subtypeValue == null
                ? db_const.completionManual
                : db_const.completionFromEvents,
          ),
          babyId: Value(scope),
          frequency: code,
          intervalDays: Value(intervalDays),
        ),
      );
      _logger.d('insertCustomReminder(id: $id, $scope)');
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
  Future<void> updateCustomReminder(CustomReminder reminder, {String? babyId}) async {
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
      // Le portage n'est pas réécrit : renommer ou changer le rythme d'un
      // rappel ne change pas le bébé auquel il appartient.

      final updated = await (database.update(database.customReminders)
            ..where((t) => t.id.equals(id)))
          .write(
        db_app.CustomRemindersCompanion(
          label: Value(_validatedLabel(reminder.label)),
          subtypeValue: Value(reminder.subtypeValue),
          // Même invariant qu'à l'insertion : passer un rappel du détaché au lié
          // (ou l'inverse) change qui décide qu'il est fait.
          completionSource: Value(
            reminder.subtypeValue == null
                ? db_const.completionManual
                : db_const.completionFromEvents,
          ),
          frequency: Value(code),
          intervalDays: Value(intervalDays),
        ),
      );
      _logger.d('updateCustomReminder($id, ${_scope(babyId)}) — rows: $updated');
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
  Future<void> deleteCustomReminder(int id, {String? babyId}) async {
    try {
      final itemKey =
          '${CustomReminderPresets.customIdPrefix}$id';

      // Transaction : quatre tables sont touchées. Un rappel coupé en deux
      // laisserait un réglage orphelin dans chaque sauvegarde, et c'est
      // précisément ce que cette méthode doit empêcher.
      await database.transaction(() async {
        await (database.delete(database.customReminders)
              ..where((t) => t.id.equals(id)))
            .go();
        // Le réglage, l'ignorer et les achèvements sont purgés **tous bébés** :
        // la clé `custom_<id>` est unique avec la ligne, elle meurt avec elle, et
        // une ligne orpheline sous un autre portage survivrait aux exports.
        await database.customStatement(
          'DELETE FROM reminder_settings WHERE item_id = ?',
          [itemKey],
        );
        await database.customStatement(
          'DELETE FROM reminder_dismissals WHERE item_id = ?',
          [itemKey],
        );
        // Un achèvement survivant serait exporté (la table part entière dans la
        // sauvegarde, sans filtre), restauré, et pourrait régler un futur rappel
        // reprenant cet id après une restauration.
        await database.customStatement(
          'DELETE FROM reminder_completions WHERE item_id = ?',
          [itemKey],
        );
      });
      _logger.d('deleteCustomReminder($id, ${_scope(babyId)})');
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
