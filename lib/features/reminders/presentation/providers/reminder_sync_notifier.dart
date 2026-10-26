import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../data/local/db_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../data/repositories/app_settings_repository_impl.dart';
import '../../data/services/flutter_local_notification_service.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../../domain/services/local_notification_service.dart';
import '../../domain/services/reminder_scheduler.dart';
import 'reminder_providers.dart';

/// The M2 settings table needs its wiring; the sync notifier is the first
/// consumer (the M6 settings UI is the second).
final appSettingsRepositoryProvider =
    FutureProvider<AppSettingsRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return AppSettingsRepositoryImpl(database: database);
});

/// The process-lived plugin wrapper (M4): one instance per app run, so the
/// init/health state the scheduler relies on survives across syncs.
final localNotificationServiceProvider =
    FutureProvider<LocalNotificationService>((ref) async {
  return FlutterLocalNotificationService();
});

/// The reconciler (D2): one instance per app run — its `_plan` bookkeeping is
/// process state, not data.
final reminderSchedulerProvider =
    FutureProvider<ReminderScheduler>((ref) async {
  final repository = await ref.read(remindersRepositoryProvider.future);
  final notifications = await ref.read(localNotificationServiceProvider.future);
  return ReminderScheduler(
      repository: repository, notifications: notifications);
});

/// The notification sync cycle (plan §3.2, M5): one coalesced [ReminderSyncNotifier.syncNow]
/// per burst of triggers. Reads the app-level opt-in/time, every baby profile
/// (D6), applies the D8 de-opt, then runs the scheduler's reconciliation.
///
/// Stateless on purpose (`void`): the OS schedule is the derived cache, the
/// DB is the source of truth, and the sync count is only ever a log value.
final reminderSyncNotifierProvider =
    NotifierProvider<ReminderSyncNotifier, void>(ReminderSyncNotifier.new);

class ReminderSyncNotifier extends Notifier<void> {
  final Logger _logger = appLogger();

  @override
  void build() {
    // No baby-switch listen (D6: every baby is scheduled; switching is a
    // no-op). The first sync comes from the lifecycle widget (first frame +
    // each resume); mutations call [syncNow] directly.
  }

  /// Coalesced entry point: concurrent triggers (resume + the 5-min tick + a
  /// mutation in the same instant) share one in-flight run; a coalesced call
  /// loses nothing — the next tick reconciles.
  ///
  /// Never throws. A background reconciliation must not break the tap that
  /// triggered it: recording a feeding or dismissing a reminder always
  /// succeeds, and a failed sync is logged and retried by the next tick. (It
  /// also keeps the plugin and the database out of the tests that only
  /// exercise the mutation itself.)
  Future<void> syncNow() {
    _inFlight ??= _run().catchError((Object error) {
      _logger.w('reminder sync skipped', error: error);
    }).whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<void>? _inFlight;

  Future<void> _run() async {
    final settings = await ref.read(appSettingsRepositoryProvider.future);
    final notifications =
        await ref.read(localNotificationServiceProvider.future);
    // Idempotent (M4); must precede any schedule/cancel (plan §3.2).
    await notifications.init();

    var optIn = (await settings.get(settingsKeyNotificationsOptIn)) == '1';
    if (optIn && !(await notifications.permissionGranted)) {
      // D8 de-opt: the permission was revoked in system settings while
      // opt-in stayed on. Persist '0' first so the UI switch reads the
      // truth; the sync below then does the cancelAll.
      await settings.set(settingsKeyNotificationsOptIn, '0');
      optIn = false;
    }

    final time = (await settings.get(settingsKeyNotificationTime)) ??
        defaultNotificationTime;
    final (hour: preferredHour, minute: preferredMinute) =
        _parseTimeOfDay(time);

    // D6: every baby profile, name ascending (the repository's order).
    final babies = await ref.read(babyProfileListProvider.future);

    final locale = (await ref.read(localeProvider.future)).languageCode;
    final l10n = lookupAppLocalizations(Locale(locale));

    final scheduler = await ref.read(reminderSchedulerProvider.future);
    await scheduler.sync(
      babies: babies,
      notificationsOptIn: optIn,
      preferredHour: preferredHour,
      preferredMinute: preferredMinute,
      title: (item, _) =>
          l10n.reminderNotificationTitle(_careLabel(l10n, item)),
      body: (item, scope) => scope == null
          ? l10n.reminderNotificationBodyNoProfile(_careLabel(l10n, item))
          : l10n.reminderNotificationBody(
              scope.name,
              _careLabel(l10n, item),
            ),
    );
  }
}

/// Parses the stored `HH:mm` preference, falling back to
/// [defaultNotificationTime] on anything malformed.
///
/// The strictness is deliberate: `'0830'` parses as the integer 830, and an
/// hour of 830 does not fail — it silently schedules a notification for a
/// wall-clock time that does not exist. The settings UI cannot write that, but
/// a hand-edited or corrupted row can, and the schedule must not inherit it.
({int hour, int minute}) _parseTimeOfDay(String stored) {
  final fallback = defaultNotificationTime.split(':');
  final parts = stored.split(':');
  if (parts.length != 2) {
    return (
      hour: int.parse(fallback.first),
      minute: int.parse(fallback.last),
    );
  }
  final hour = int.tryParse(parts.first);
  final minute = int.tryParse(parts.last);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return (
      hour: int.parse(fallback.first),
      minute: int.parse(fallback.last),
    );
  }
  return (hour: hour, minute: minute);
}

/// The preset ids: these display the localized *health* label in notification
/// text (the same label the settings screen shows); every other item is a
/// custom reminder whose free-text label passes through untouched, never
/// translated.
const Set<String> _presetIds = {
  'vitamine_d',
  'vitamine_k',
  'eye_cleaning',
  'face_cleaning',
};

/// The `{care}` placeholder for [item] in the active locale.
String _careLabel(AppLocalizations l10n, ReminderItem item) {
  if (_presetIds.contains(item.id)) {
    final subtype = item.subtypeValue == null
        ? null
        : HealthSubtype.byValue(item.subtypeValue!);
    final labelKey = subtype?.labelKey;
    if (labelKey != null) {
      return switch (labelKey) {
        'healthNettoyageYeux' => l10n.healthNettoyageYeux,
        'healthNettoyageNombril' => l10n.healthNettoyageNombril,
        'healthNettoyageVisage' => l10n.healthNettoyageVisage,
        'healthNettoyageNez' => l10n.healthNettoyageNez,
        'healthVitamineD' => l10n.healthVitamineD,
        'healthVitamineK' => l10n.healthVitamineK,
        _ => item.labelKey,
      };
    }
  }
  return item.labelKey;
}
