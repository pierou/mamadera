// M5: ReminderSyncNotifier — coalescing, D8 de-opt, and settings passthrough.
//
// The provider graph is fully overridden (no database, no plugin, no
// path_provider): the scheduler is a recorder, the settings repository and
// the notification service are in-memory fakes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/locale_service.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/repositories/app_settings_repository.dart';
import 'package:mamadera/features/reminders/domain/services/local_notification_service.dart';
import 'package:mamadera/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_sync_notifier.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

class _FakeSettings implements AppSettingsRepository {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteAll() async {
    values.clear();
  }

  @override
  Future<Map<String, String>> getAll() async => Map.of(values);
}

class _FakeNotificationService implements LocalNotificationService {
  _FakeNotificationService();

  Duration initDelay = Duration.zero;
  final List<String> log = [];
  int initCalls = 0;
  bool readyFlag = true;
  bool grantedFlag = true;

  @override
  Future<void> init() async {
    initCalls++;
    if (initDelay != Duration.zero) {
      await Future<void>.delayed(initDelay);
    }
    readyFlag = true;
  }

  @override
  bool get ready => readyFlag;

  @override
  Future<bool> ensurePermission() async => grantedFlag;

  @override
  Future<bool> get permissionGranted async {
    log.add('permissionGranted');
    return grantedFlag;
  }

  @override
  Future<bool> get exactAlarmsAllowed async => true;

  @override
  Future<void> scheduleAt(
      {required int id,
      required String title,
      required String body,
      required DateTime at}) async {}

  @override
  Future<void> scheduleIn(
      {required int id,
      required String title,
      required String body,
      required Duration delay}) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {
    log.add('cancelAll');
  }
}

class _RecordingScheduler implements ReminderScheduler {
  int syncCalls = 0;
  bool? lastOptIn;
  int? lastHour;
  int? lastMinute;
  List<BabyProfile>? lastBabies;
  String Function(ReminderItem, BabyProfile?)? lastTitle;
  String Function(ReminderItem, BabyProfile?)? lastBody;

  @override
  Future<int> sync({
    required List<BabyProfile> babies,
    required bool notificationsOptIn,
    required int preferredHour,
    required int preferredMinute,
    required String Function(ReminderItem, BabyProfile?) title,
    required String Function(ReminderItem, BabyProfile?) body,
    DateTime? now,
  }) async {
    syncCalls++;
    lastOptIn = notificationsOptIn;
    lastHour = preferredHour;
    lastMinute = preferredMinute;
    lastBabies = babies;
    lastTitle = title;
    lastBody = body;
    return 0;
  }
}

/// Deterministic locale for the content closures (no path_provider on the
/// test platform).
class _EnLocaleNotifier extends LocaleNotifier {
  @override
  Future<LocalePreference> build() async =>
      const LocalePreference(languageCode: 'en', isManualOverride: true);
}

final _bea = BabyProfile(
  id: 'béa-id',
  name: 'Béa',
  birthDate: DateTime(2026, 6, 5),
  isActive: false,
);
final _zora = BabyProfile(
  id: 'zora-id',
  name: 'Zora',
  birthDate: DateTime(2026, 6, 20),
);

void main() {
  late _FakeSettings settings;
  late _FakeNotificationService notifications;
  late _RecordingScheduler scheduler;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    List<BabyProfile> babies = const [],
  }) {
    settings = _FakeSettings();
    notifications = _FakeNotificationService();
    scheduler = _RecordingScheduler();
    container = ProviderContainer(
      overrides: [
        appSettingsRepositoryProvider.overrideWith(
          (ref) async => settings,
        ),
        localNotificationServiceProvider.overrideWith(
          (ref) async => notifications,
        ),
        reminderSchedulerProvider.overrideWith(
          (ref) async => scheduler,
        ),
        babyProfileListProvider.overrideWith(
          (ref) async => List.of(babies),
        ),
        localeProvider.overrideWith(_EnLocaleNotifier.new),
      ],
    );
    return container;
  }

  tearDown(() => container.dispose());

  group('syncNow', () {
    test('two in-flight syncNow() calls coalesce into one scheduler.sync()',
        () async {
      buildContainer(babies: [_bea]);
      notifications.initDelay = const Duration(milliseconds: 50);
      final notifier = container.read(reminderSyncNotifierProvider.notifier);

      final first = notifier.syncNow();
      final second = notifier.syncNow();
      await Future.wait([first, second]);

      expect(notifications.initCalls, 1);
      expect(scheduler.syncCalls, 1);
    });

    test('passes opt-in, parsed time, and the baby list through to sync()',
        () async {
      buildContainer(babies: [_zora, _bea]);
      settings.values[settingsKeyNotificationsOptIn] = '1';
      settings.values[settingsKeyNotificationTime] = '08:30';

      await container.read(reminderSyncNotifierProvider.notifier).syncNow();

      expect(scheduler.lastOptIn, isTrue);
      expect(scheduler.lastHour, 8);
      expect(scheduler.lastMinute, 30);
      expect(scheduler.lastBabies, [_zora, _bea]);
    });

    test('missing settings fall back to the defaults (off, 09:00)', () async {
      buildContainer();

      await container.read(reminderSyncNotifierProvider.notifier).syncNow();

      expect(scheduler.lastOptIn, isFalse);
      expect(scheduler.lastHour, 9);
      expect(scheduler.lastMinute, 0);
      expect(scheduler.lastBabies, isEmpty);
    });

    test('malformed stored time falls back to the default without failing',
        () async {
      buildContainer();
      settings.values[settingsKeyNotificationTime] = '0830';

      await container.read(reminderSyncNotifierProvider.notifier).syncNow();

      expect(scheduler.lastHour, 9);
      expect(scheduler.lastMinute, 0);
    });

    test(
        'D8 de-opt: opt-in ON but OS permission revoked ⇒ persist 0, '
        'sync with opt-in off', () async {
      buildContainer(babies: [_bea]);
      settings.values[settingsKeyNotificationsOptIn] = '1';
      notifications.grantedFlag = false;

      await container.read(reminderSyncNotifierProvider.notifier).syncNow();

      expect(settings.values[settingsKeyNotificationsOptIn], '0');
      expect(scheduler.lastOptIn, isFalse);
    });

    test('opt-in OFF skips the permission check entirely', () async {
      buildContainer();
      settings.values[settingsKeyNotificationsOptIn] = '0';

      await container.read(reminderSyncNotifierProvider.notifier).syncNow();

      expect(
        notifications.log,
        isNot(contains('permissionGranted')),
      );
      expect(scheduler.lastOptIn, isFalse);
    });

    test('unhealthy service still runs the sync (cancel-all path is safe)',
        () async {
      buildContainer();
      notifications.readyFlag = false;
      settings.values[settingsKeyNotificationsOptIn] = '1';

      await container.read(reminderSyncNotifierProvider.notifier).syncNow();

      // init() ran: a healthy re-init is the recovery, so ready is true now.
      expect(notifications.initCalls, 1);
      expect(notifications.ready, isTrue);
      expect(scheduler.lastOptIn, isTrue);
    });
  });

  group('localized content closures', () {
    test('presets resolve the localized care label, custom labels pass through',
        () async {
      buildContainer(babies: [_bea]);
      settings.values[settingsKeyNotificationsOptIn] = '1';

      await container.read(reminderSyncNotifierProvider.notifier).syncNow();

      final title = scheduler.lastTitle!;
      final body = scheduler.lastBody!;
      final vitD = ReminderItemPresets.vitaminD;
      expect(title(vitD, _bea), 'Vitamin D');
      expect(body(vitD, _bea), 'Béa: time for Vitamin D.');
      expect(body(vitD, null), 'Time for Vitamin D.');
      final custom = ReminderItem(
        id: 'custom_42',
        labelKey: 'Sirop de guimauve',
        frequency: const Daily(),
        trackingType: TrackingType.sante,
      );
      expect(title(custom, _bea), 'Sirop de guimauve');
      expect(body(custom, _bea), 'Béa: time for Sirop de guimauve.');
    });
  });
}
