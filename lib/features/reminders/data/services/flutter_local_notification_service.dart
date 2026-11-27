import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/services/app_logger.dart';
import '../../domain/services/local_notification_service.dart';

/// Fixed channel constants (D7): one channel, default importance, sound on,
/// no badge, no UI to change any of it.
const String _channelId = 'reminders';
const String _channelName = 'Reminders';
const String _channelDescription = 'Care reminders';

/// Wraps `flutter_local_notifications` behind [LocalNotificationService]
/// (plan §3.2/§3.6, M4). The plugin instance is constructor-injected so
/// tests drive a recording fake — no method-channel mocking.
///
/// R13: an [init] failure (e.g. `tz.initializeTimeZones()` throwing) leaves
/// the service *unhealthy* — every schedule/cancel becomes a silent no-op
/// until the next successful `init` (the sync cycle retries `init()` first),
/// so the app never crashes over the reminder channel and never leaves a
/// half-scheduled plan (init either completes fully or not at all).
class FlutterLocalNotificationService implements LocalNotificationService {
  /// Creates the service. [plugin] defaults to the shared plugin singleton.
  ///
  /// [onNotificationTapped] is the seam B22 requires: the data layer must not
  /// import `core/router.dart`, so the service owns nothing about *what a tap
  /// means* and simply forwards the payload the OS delivered (`null` when the tap
  /// carried none). Injection happens in the presentation layer, at
  /// `localNotificationServiceProvider`, where navigation is allowed.
  FlutterLocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this.onNotificationTapped,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Called for every notification tap, with the payload that notification was
  /// scheduled with — the encoded `ReminderNotificationPayload`, or `null` when the
  /// tap carried none (a notification scheduled before B15, or a bare OS tap).
  final void Function(String? payload)? onNotificationTapped;
  final Logger _logger = appLogger();

  /// True once [init] has fully succeeded; false while healthy-uninitialized
  /// or after a failed init (unhealthy).
  bool _initialized = false;

  /// The inexact-fallback warning (one line, D7-adjacent) is emitted at most
  /// once per process.
  bool _inexactWarned = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        // B22: without this callback the tap falls through to the OS default,
        // which is *restore the app where it was* — the owner-reported defect.
        // Registered here rather than in `main()` because this service owns the
        // plugin's lifecycle and its init/health state (R13); the behaviour it
        // triggers is injected, so no routing lives below the data layer.
        //
        // Deliberately **not** `onDidReceiveBackgroundNotificationResponse`: that
        // fires only for notification *actions* that do not show the UI, and this
        // app has no actions (B22 To-do 2).
        onDidReceiveNotificationResponse: (response) =>
            onNotificationTapped?.call(response.payload),
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: IOSInitializationSettings(
            // D8: permissions are requested explicitly on opt-in, never at
            // launch.
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      );
      await _ensureAndroidChannel();
      _initialized = true;
    } catch (error, stackTrace) {
      // One line only (R13): unhealthy until the next successful init.
      _logger.e(
        'Local notification init failed; reminder notifications stay silent until the next init retry',
        error: error,
        stackTrace: stackTrace,
      );
      _initialized = false;
    }
  }

  @override
  bool get ready => _initialized;

  @override
  Future<bool> ensurePermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android == null) return false;
        final granted = await android.requestNotificationsPermission();
        if (granted != null) return granted;
        // Below Android 13 the request is a native no-op and may report
        // null ⇒ ask the system whether notifications are enabled at all
        // (there is no prompt to show there, D8).
        return (await android.areNotificationsEnabled()) ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (ios == null) return false;
        return (await ios.requestPermissions(
              alert: true,
              sound: true,
              badge: false,
            )) ??
            false;
      default:
        // Mobile-only in v1.3.0.
        return false;
    }
  }

  @override
  Future<bool> get permissionGranted async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android == null) return false;
        return (await android.areNotificationsEnabled()) == true;
      case TargetPlatform.iOS:
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (ios == null) return false;
        final status = await ios.checkPermissions();
        return status?.isEnabled ?? false;
      default:
        return false;
    }
  }

  @override
  Future<bool> get exactAlarmsAllowed async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return (await android.canScheduleExactNotifications()) == true;
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    if (!_ready()) return;
    await _plugin.zonedSchedule(
      id: id,
      // Both platforms parse the scheduled wall-clock with the zone name the
      // channel carries. Scheduling the same instant expressed in UTC keeps
      // that pair exact without ever discovering the device's IANA zone.
      scheduledDate: tz.TZDateTime.from(at, tz.getLocation('UTC')),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: await _scheduleMode(),
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    // The plugin has no zonedTimer: a one-shot `now + delay` schedule is the
    // exact same primitive for the D3 catch-up.
    await scheduleAt(
      id: id,
      title: title,
      body: body,
      at: DateTime.now().add(delay),
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  /// [init] must have been attempted (the sync cycle awaits it first); while
  /// the service is unhealthy every call is a silent no-op (R13). No init
  /// retry from here: retrying per call would multiply the failure log line.
  bool _ready() => _initialized;

  Future<AndroidScheduleMode> _scheduleMode() async {
    if (await exactAlarmsAllowed) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    if (!_inexactWarned) {
      _inexactWarned = true;
      _logger.w(
        'Exact alarms not allowed; reminder notifications may drift until the next reconciliation',
      );
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _ensureAndroidChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
        playSound: true,
        showBadge: false,
      ),
    );
  }

  NotificationDetails _notificationDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
        iOS: DarwinNotificationDetails(),
      );
}
