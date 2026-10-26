import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/data/services/flutter_local_notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// Recording fakes (no method-channel mocking): the service is handed a fake
// plugin and fake platform implementations that record every call.
// ---------------------------------------------------------------------------

class FakeAndroidPlugin implements AndroidFlutterLocalNotificationsPlugin {
  FakeAndroidPlugin({this.requestResult, this.enabled = true, this.exact = true});

  /// What `requestNotificationsPermission()` answers: `null` simulates the
  /// below-Android-13 no-op path.
  final bool? requestResult;
  final bool enabled;
  final bool exact;

  int requestCalls = 0;
  int enabledCalls = 0;
  int exactCalls = 0;
  AndroidNotificationChannel? createdChannel;

  @override
  Future<bool?> requestNotificationsPermission() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<bool?> areNotificationsEnabled() async {
    enabledCalls++;
    return enabled;
  }

  @override
  Future<bool?> canScheduleExactNotifications() async {
    exactCalls++;
    return exact;
  }

  @override
  Future<void> createNotificationChannel(AndroidNotificationChannel channel) async {
    createdChannel = channel;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      UnimplementedError('FakeAndroidPlugin: ${invocation.memberName}');
}

class FakeIosPlugin implements IOSFlutterLocalNotificationsPlugin {
  FakeIosPlugin({this.granted, this.isEnabled = true});

  final bool? granted;
  final bool isEnabled;

  int requestCalls = 0;
  bool? lastAlert;
  bool? lastSound;
  bool? lastBadge;
  int checkCalls = 0;

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requestCalls++;
    lastAlert = alert;
    lastSound = sound;
    lastBadge = badge;
    return granted;
  }

  @override
  Future<NotificationsEnabledOptions?> checkPermissions() async {
    checkCalls++;
    return NotificationsEnabledOptions(
      isEnabled: isEnabled,
      isSoundEnabled: isEnabled,
      isAlertEnabled: isEnabled,
      isBadgeEnabled: false,
      isProvisionalEnabled: false,
      isCriticalEnabled: false,
      isProvidesAppNotificationSettingsEnabled: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      UnimplementedError('FakeIosPlugin: ${invocation.memberName}');
}

class FakePlugin implements FlutterLocalNotificationsPlugin {
  FakePlugin({this.android, this.ios, this.initializeError});

  final FakeAndroidPlugin? android;
  final FakeIosPlugin? ios;

  /// When non-null, `initialize()` throws it (R13 failure path).
  Object? initializeError;

  int initializeCalls = 0;
  InitializationSettings? lastSettings;
  final List<(int, tz.TZDateTime, AndroidScheduleMode, String, String)>
  scheduled = [];
  final List<int> cancelled = [];
  int cancelAllCalls = 0;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalls++;
    final error = initializeError;
    if (error != null) throw error;
    lastSettings = settings;
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<T
    extends FlutterLocalNotificationsPlatform>() {
    if (android != null && T == AndroidFlutterLocalNotificationsPlugin) {
      return android as T;
    }
    if (ios != null && T == IOSFlutterLocalNotificationsPlugin) {
      return ios as T;
    }
    return null;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add((id, scheduledDate, androidScheduleMode, title ?? '', body ?? ''));
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      UnimplementedError('FakePlugin: ${invocation.memberName}');
}

void main() {
  const androidSettings = TargetPlatform.android;
  const iosSettings = TargetPlatform.iOS;

  group('FlutterLocalNotificationService.init', () {
    test('initializes the plugin, the tz data and the fixed channel (D7)', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final android = FakeAndroidPlugin();
      final plugin = FakePlugin(android: android);
      final service = FlutterLocalNotificationService(plugin: plugin);

      await service.init();

      expect(plugin.initializeCalls, 1);
      final channel = android.createdChannel;
      expect(channel, isNotNull);
      expect(channel!.id, 'reminders');
      expect(channel.name, 'Reminders');
      expect(channel.importance, Importance.defaultImportance);
      expect(channel.playSound, isTrue);
      expect(channel.showBadge, isFalse);
      // D8: the iOS settings never request permissions at init.
      expect(plugin.lastSettings?.iOS, isA<IOSInitializationSettings>());
      expect(
        (plugin.lastSettings!.iOS! as IOSInitializationSettings).requestAlertPermission,
        isFalse,
      );

      // Idempotent: a second init is a no-op.
      await service.init();
      expect(plugin.initializeCalls, 1);
    });

    test('a failing init leaves the service unhealthy: no-ops until re-init (R13)', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final plugin = FakePlugin(android: FakeAndroidPlugin());
      plugin.initializeError = StateError('tz data missing');
      final service = FlutterLocalNotificationService(plugin: plugin);

      await service.init(); // must not throw

      // Unhealthy: every schedule/cancel is a no-op, nothing was scheduled.
      await service.scheduleAt(id: 1, title: 't', body: 'b', at: DateTime(2026, 7, 16, 9));
      await service.scheduleIn(id: 2, title: 't', body: 'b', delay: const Duration(seconds: 60));
      await service.cancel(3);
      await service.cancelAll();
      expect(plugin.scheduled, isEmpty);
      expect(plugin.cancelled, isEmpty);
      expect(plugin.cancelAllCalls, 0);

      // The next tick retries init and heals the service.
      plugin.initializeError = null;
      await service.init();
      expect(plugin.initializeCalls, 2);
      await service.scheduleAt(id: 1, title: 't', body: 'b', at: DateTime(2026, 7, 16, 9));
      expect(plugin.scheduled.length, 1);
    });
  });

  group('FlutterLocalNotificationService.ensurePermission (D8)', () {
    test('Android 13+: the runtime request is the decision', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final granted = await FlutterLocalNotificationService(
        plugin: FakePlugin(android: FakeAndroidPlugin(requestResult: true)),
      ).ensurePermission();
      expect(granted, isTrue);

      final denied = await FlutterLocalNotificationService(
        plugin: FakePlugin(android: FakeAndroidPlugin(requestResult: false)),
      ).ensurePermission();
      expect(denied, isFalse);
    });

    test('below Android 13: the no-op request reports null ⇒ enabled query', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final android = FakeAndroidPlugin(requestResult: null, enabled: true);
      final plugin = FakePlugin(android: android);

      expect(await FlutterLocalNotificationService(plugin: plugin).ensurePermission(), isTrue);
      expect(android.requestCalls, 1);
      expect(android.enabledCalls, 1);
    });

    test('iOS: requestPermissions(alert: true, sound: true, badge: false)', () async {
      debugDefaultTargetPlatformOverride = iosSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final ios = FakeIosPlugin(granted: true);
      final plugin = FakePlugin(ios: ios);

      expect(await FlutterLocalNotificationService(plugin: plugin).ensurePermission(), isTrue);
      expect(ios.requestCalls, 1);
      expect(ios.lastAlert, isTrue);
      expect(ios.lastSound, isTrue);
      expect(ios.lastBadge, isFalse);
    });

    test('desktop: no permission path, false', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(
        await FlutterLocalNotificationService(plugin: FakePlugin()).ensurePermission(),
        isFalse,
      );
    });
  });

  group('FlutterLocalNotificationService.permissionGranted (query only)', () {
    test('Android: areNotificationsEnabled, no request prompt', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final android = FakeAndroidPlugin(enabled: false);
      final service = FlutterLocalNotificationService(plugin: FakePlugin(android: android));

      expect(await service.permissionGranted, isFalse);
      expect(android.enabledCalls, 1);
      expect(android.requestCalls, 0);
    });

    test('iOS: checkPermissions, no request prompt', () async {
      debugDefaultTargetPlatformOverride = iosSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final ios = FakeIosPlugin(isEnabled: false);
      final service = FlutterLocalNotificationService(plugin: FakePlugin(ios: ios));

      expect(await service.permissionGranted, isFalse);
      expect(ios.checkCalls, 1);
      expect(ios.requestCalls, 0);
    });
  });

  group('FlutterLocalNotificationService scheduling', () {
    test('scheduleAt: exact mode when exact alarms are allowed', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final plugin = FakePlugin(android: FakeAndroidPlugin(exact: true));
      final service = FlutterLocalNotificationService(plugin: plugin);
      await service.init();

      await service.scheduleAt(id: 7, title: 'Vitamin D', body: 'Léa: time', at: DateTime(2026, 7, 16, 9));

      expect(plugin.scheduled.length, 1);
      final (id, at, mode, title, body) = plugin.scheduled.single;
      expect(id, 7);
      expect(mode, AndroidScheduleMode.exactAllowWhileIdle);
      expect(title, 'Vitamin D');
      expect(body, 'Léa: time');
      // The plugin carries wall-clock + zone name to the platform; the
      // service schedules the instant in UTC, so the instant is the
      // invariant (host-local 09:00 in, the same epoch out).
      expect(at.millisecondsSinceEpoch, DateTime(2026, 7, 16, 9).millisecondsSinceEpoch);
      expect(at.timeZoneOffset, Duration.zero);
      expect(at.location.name, 'UTC');
    });

    test('scheduleAt: inexact fallback when exact alarms are denied', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final plugin = FakePlugin(android: FakeAndroidPlugin(exact: false));
      final service = FlutterLocalNotificationService(plugin: plugin);
      await service.init();

      await service.scheduleAt(id: 7, title: 't', body: 'b', at: DateTime(2026, 7, 16, 9));

      expect(plugin.scheduled.single.$3, AndroidScheduleMode.inexactAllowWhileIdle);
    });

    test('scheduleIn: the D3 catch-up is a one-shot ~60 s out', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final plugin = FakePlugin(android: FakeAndroidPlugin());
      final service = FlutterLocalNotificationService(plugin: plugin);
      await service.init();

      final before = DateTime.now();
      await service.scheduleIn(
        id: 9,
        title: 't',
        body: 'b',
        delay: const Duration(seconds: 60),
      );

      expect(plugin.scheduled.length, 1);
      final at = plugin.scheduled.single.$2.toLocal();
      expect(at.difference(before).inSeconds, inInclusiveRange(58, 65));
    });

    test('cancel and cancelAll reach the plugin once initialized', () async {
      debugDefaultTargetPlatformOverride = androidSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final plugin = FakePlugin(android: FakeAndroidPlugin());
      final service = FlutterLocalNotificationService(plugin: plugin);
      await service.init();

      await service.cancel(4);
      await service.cancelAll();

      expect(plugin.cancelled, [4]);
      expect(plugin.cancelAllCalls, 1);
    });

    test('exactAlarmsAllowed: true off Android, the query on Android', () async {
      debugDefaultTargetPlatformOverride = iosSettings;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(
        await FlutterLocalNotificationService(plugin: FakePlugin(ios: FakeIosPlugin())).exactAlarmsAllowed,
        isTrue,
      );

      debugDefaultTargetPlatformOverride = androidSettings;
      expect(
        await FlutterLocalNotificationService(
          plugin: FakePlugin(android: FakeAndroidPlugin(exact: false)),
        ).exactAlarmsAllowed,
        isFalse,
      );
    });
  });
}
