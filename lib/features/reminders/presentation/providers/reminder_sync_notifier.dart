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
import '../../domain/services/notification_time.dart';
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
      // The settings screen may be open right now, showing a switch that is
      // about to be a lie. Re-read it so it reflects the revocation (D8).
      ref.invalidate(notificationSettingsProvider);
    }

    final time = (await settings.get(settingsKeyNotificationTime)) ??
        defaultNotificationTime;
    final (hour: preferredHour, minute: preferredMinute) =
        parseNotificationTime(time);

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

/// What the “System notifications” section shows: the persisted opt-in, the
/// persisted preferred time of day, and whether the OS permission is currently
/// missing.
///
/// `permissionDenied` is transient UI state, not a stored value: it is set
/// when the user flips the switch on and the OS refuses. The opt-in stays
/// `false` then — nothing is persisted as ON that the OS would not honour (D8).
@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.optIn,
    required this.hour,
    required this.minute,
    this.permissionDenied = false,
  });

  /// The stored `notifications_opt_in` flag, already reconciled with the OS.
  final bool optIn;

  /// The stored `notification_time_of_day`, split for display.
  final int hour;
  final int minute;

  /// `true` ⇒ show the “turn them on in system settings” hint.
  final bool permissionDenied;

  /// `HH:mm` for the time row.
  String get timeLabel => formatNotificationTime(hour: hour, minute: minute);

  NotificationPreferences copyWith({
    bool? optIn,
    int? hour,
    int? minute,
    bool? permissionDenied,
  }) =>
      NotificationPreferences(
        optIn: optIn ?? this.optIn,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        permissionDenied: permissionDenied ?? this.permissionDenied,
      );
}

/// The settings screen’s view of the notification preferences (M6).
///
/// Sits in this file with the sync notifier on purpose: the de-opt path
/// inside [ReminderSyncNotifier] invalidates it, and two files importing each
/// other for that would be a cycle for nothing.
///
/// Owns the D8 write path: the opt-in is persisted **only** after the OS has
/// granted the permission, and every accepted change ends with a `syncNow()`
/// so the OS plan tracks the switch instead of waiting for the next tick.
final notificationSettingsProvider = AsyncNotifierProvider<
    NotificationSettingsNotifier, NotificationPreferences>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final settings = await ref.watch(appSettingsRepositoryProvider.future);
    final optIn = (await settings.get(settingsKeyNotificationsOptIn)) == '1';
    final time = (await settings.get(settingsKeyNotificationTime)) ??
        defaultNotificationTime;
    final (hour: hour, minute: minute) = parseNotificationTime(time);
    return NotificationPreferences(optIn: optIn, hour: hour, minute: minute);
  }

  /// D8: returns `true` when the switch ended up ON.
  ///
  /// Turning it on asks the OS first; a refusal persists nothing and only
  /// sets [NotificationPreferences.permissionDenied]. Turning it off persists
  /// `'0'` and cancels every pending notification (the sync does the cancelling).
  Future<bool> setOptIn({required bool wanted}) async {
    final settings = await ref.read(appSettingsRepositoryProvider.future);
    if (!wanted) {
      await settings.set(settingsKeyNotificationsOptIn, '0');
      await ref.read(reminderSyncNotifierProvider.notifier).syncNow();
      _publish(optIn: false, permissionDenied: false);
      return false;
    }

    final notifications =
        await ref.read(localNotificationServiceProvider.future);
    if (!await notifications.ensurePermission()) {
      _publish(optIn: false, permissionDenied: true);
      return false;
    }

    await settings.set(settingsKeyNotificationsOptIn, '1');
    await ref.read(reminderSyncNotifierProvider.notifier).syncNow();
    _publish(optIn: true, permissionDenied: false);
    return true;
  }

  /// Persists the preferred time of day (`HH:mm`) and reconciles immediately.
  Future<void> setTime({required int hour, required int minute}) async {
    final settings = await ref.read(appSettingsRepositoryProvider.future);
    await settings.set(
      settingsKeyNotificationTime,
      formatNotificationTime(hour: hour, minute: minute),
    );
    await ref.read(reminderSyncNotifierProvider.notifier).syncNow();
    _publish(hour: hour, minute: minute);
  }

  /// Re-emits the current preferences with the given fields replaced. Always
  /// [AsyncData]: the screen is already on screen and a reload would flicker
  /// the whole reminder list to show a spinner for a switch.
  void _publish({
    bool? optIn,
    int? hour,
    int? minute,
    bool? permissionDenied,
  }) {
    final current = state.value ??
        NotificationPreferences(
          optIn: false,
          hour: notificationTimeDefaults().hour,
          minute: notificationTimeDefaults().minute,
        );
    state = AsyncData(
      current.copyWith(
        optIn: optIn,
        hour: hour,
        minute: minute,
        permissionDenied: permissionDenied,
      ),
    );
  }
}
