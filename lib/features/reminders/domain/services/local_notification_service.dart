/// The OS notification surface the reminder scheduler relies on.
///
/// Pure Dart interface (plan §3.2, M4): the concrete wrapper around
/// `flutter_local_notifications` lives in the data layer so tests can drive
/// a recording fake. All scheduling is one-shot: this interface deliberately
/// has no repeating/escalating primitives (D7).
abstract class LocalNotificationService {
  /// Plugin init + `tz.initializeTimeZones()` + the fixed "reminders"
  /// channel (D7). Idempotent: a second call on an initialized service is a
  /// no-op; after a failed init the service is unhealthy and this retries
  /// (R13).
  Future<void> init();

  /// D8: the opt-in request. Prompts on Android 13+ and iOS, queries
  /// (no prompt exists) below Android 13. Returns `true` only if the
  /// permission is granted afterwards.
  Future<bool> ensurePermission();

  /// Query only, never prompts. Used on start/resume to detect the user
  /// revoking the permission in system settings (D8).
  Future<bool> get permissionGranted;

  /// Android 33+: `canScheduleExactNotifications()`; every other
  /// platform/version ⇒ `true`. When `false`, scheduling falls back to
  /// inexact (batches may drift; start/resume reconciliation repairs).
  Future<bool> get exactAlarmsAllowed;

  /// Schedules a one-shot notification for the device-local wall-clock
  /// instant [at]. The OS owns the instant from then on.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  });

  /// Schedules a one-shot notification [delay] from now — the D3 catch-up
  /// (~60 s). (Implemented as a near-future [scheduleAt]; the plugin has no
  /// `zonedTimer` — plan §3.6 note, M4.)
  Future<void> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  });

  /// Cancels the pending notification with [id] (no-op if absent).
  Future<void> cancel(int id);

  /// Cancels every pending notification (opt-out, D8).
  Future<void> cancelAll();
}
