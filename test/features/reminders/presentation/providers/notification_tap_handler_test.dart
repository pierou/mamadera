import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/router.dart' show AppRoute;
import 'package:mamadera/data/local/db_constants.dart' show completionManual;
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/repositories/app_settings_repository.dart';
import 'package:mamadera/features/reminders/domain/services/local_notification_service.dart';
import 'package:mamadera/features/reminders/domain/services/notification_payload.dart';
import 'package:mamadera/features/reminders/presentation/providers/notification_tap_handler.dart';
import 'package:mamadera/features/reminders/presentation/providers/pending_care_sheet.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/features/reminders/presentation/providers/reminder_sync_notifier.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

import '../../data/repositories/mock_reminders_repository.dart';

// ---------------------------------------------------------------------------
// The seams the handler needs: a repository we fill by hand, one selected baby,
// the baby list, a settings table, and a notification service that records rather
// than reaches the plugin (the sync the completion triggers is real, its OS half
// is not).
// ---------------------------------------------------------------------------

class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}

class _FakeAppSettings implements AppSettingsRepository {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async => values[key] = value;

  @override
  Future<void> deleteAll() async => values.clear();

  @override
  Future<Map<String, String>> getAll() async => Map.of(values);
}

class _FakeNotifications implements LocalNotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> ensurePermission() async => false;
  @override
  Future<bool> get permissionGranted async => false;
  @override
  bool get ready => false;
  @override
  Future<bool> get exactAlarmsAllowed async => true;
  @override
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {}
  @override
  Future<void> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
}

final _aimee = BabyProfile(
  id: 'aimée-id',
  name: 'Aimée',
  birthDate: DateTime(2026, 6, 20),
);
final _bea = BabyProfile(
  id: 'béa-id',
  name: 'Béa',
  birthDate: DateTime(2026, 6, 5),
  isActive: false,
);

void main() {
  late MockRemindersRepository mock;
  late List<String> paths;
  late ProviderContainer container;

  /// Builds the container with [selected] as the active baby, and returns the
  /// handler under test — the same object `localNotificationServiceProvider` wires
  /// to the plugin's tap callback.
  NotificationTapHandler setUp_({required BabyProfile? selected}) {
    mock = MockRemindersRepository();
    paths = [];
    container = ProviderContainer(
      overrides: [
        remindersRepositoryProvider.overrideWith((ref) async => mock),
        activeBabyProvider.overrideWith(() => _ActiveBabyStub(selected)),
        babyProfileListProvider.overrideWith((ref) async => [_aimee, _bea]),
        appSettingsRepositoryProvider
            .overrideWith((ref) async => _FakeAppSettings()),
        localNotificationServiceProvider
            .overrideWith((ref) async => _FakeNotifications()),
        notificationTapHandlerProvider.overrideWith(
          (ref) => NotificationTapHandler(ref, navigate: paths.add),
        ),
      ],
    );
    addTearDown(container.dispose);
    // What `ReminderLifecycleSyncWidget` does in the app: a bare `read` would let
    // Riverpod 3 dispose the handler before the tap's detached work finished.
    container.listen(notificationTapHandlerProvider, (_, __) {});
    return container.read(notificationTapHandlerProvider);
  }

  String payloadFor(String scope, String itemId) =>
      ReminderNotificationPayload(scope: scope, itemId: itemId).encode();

  /// The async half of a tap runs detached (the plugin callback is `void`) and
  /// awaits several providers before it acts, so one microtask drain is not enough
  /// to observe it.
  Future<void> settle() async {
    for (var i = 0; i < 24; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('NotificationTapHandler (B22 + B15, D-R9)', () {
    test('a tap always lands on Home, even with a payload it cannot read',
        () async {
      final handler = setUp_(selected: _aimee);

      handler.handle('{"b":"aimée-id","i":"vitamine_d"}');
      await settle();

      expect(paths, [AppRoute.home.path],
          reason:
              'B22: the tap must not fall through to the OS default, which is '
              '"restore whatever screen was last open"');
    });

    test('a tap with no payload navigates and touches nothing', () async {
      final handler = setUp_(selected: _aimee);

      handler.handle(null);
      await settle();

      expect(paths, [AppRoute.home.path]);
      expect(mock.recordCompletionCallCount, 0);
      expect(container.read(pendingCareSheetProvider), isNull);
    });

    test(
        'a detached reminder settles for the scope that fired, not for the '
        'selected baby', () async {
      // D6 schedules every baby, so the reminder on the banner may belong to the
      // child who is *not* selected. Resolving it against the active baby would
      // credit the wrong one with a care that was never due to them.
      final handler = setUp_(selected: _aimee);
      mock.customRemindersById[7] = const CustomReminder(
        id: 7,
        label: 'Crème du change',
        frequency: ReminderFrequency.daily(),
        completionSource: completionManual,
      );

      handler.handle(payloadFor(_bea.id, 'custom_7'));
      await settle();
      await settle();

      expect(paths, [AppRoute.home.path]);
      expect(mock.recordCompletionCallCount, 1);
      expect(mock.lastRecordCompletionBabyId, _bea.id);
      expect(container.read(pendingCareSheetProvider), isNull,
          reason:
              'a detached reminder has no care sheet: the tap is the completion '
              'the app already accepts from the Home pill');
    });

    test('a treatment-linked reminder asks Home for the pre-filled care sheet',
        () async {
      // D-R9: the tap deep-links. It does not write the health event — the parent
      // confirms in the sheet, which is the product's one honest way to record a
      // care (D2). A mistap on a 3 a.m. banner must not reach the paediatrician's
      // export.
      final handler = setUp_(selected: _aimee);

      handler.handle(payloadFor(_aimee.id, 'eye_cleaning'));
      await settle();
      await settle();

      final pending = container.read(pendingCareSheetProvider);
      expect(pending, isNotNull);
      expect(pending!.subtype, HealthSubtype.nettoyageYeux);
      expect(pending.itemId, 'eye_cleaning');
      expect(mock.recordCompletionCallCount, 0,
          reason: 'tap is attention, never completion (B15 "Do not" 1)');
    });

    test('a treatment-linked tap for another baby stops at Home', () async {
      // The care sheet belongs to Home, and Home shows the selected baby: opening
      // it for Béa while Aimée is selected would record the care against Aimée.
      // The honest options are Home-only or switching the selected baby, and
      // switching is an owner decision (PLAN-v1.4.0 §9, M5).
      final handler = setUp_(selected: _aimee);

      handler.handle(payloadFor(_bea.id, 'eye_cleaning'));
      await settle();
      await settle();

      expect(paths, [AppRoute.home.path]);
      expect(container.read(pendingCareSheetProvider), isNull);
      expect(mock.recordCompletionCallCount, 0);
    });

    test('a reminder removed since the notification fired settles nothing',
        () async {
      // The payload is a hint, not a fact: it was encoded when the plan was built.
      // Everything after it is re-read, so a removal, a deletion or a re-pace in
      // between is respected.
      final handler = setUp_(selected: _aimee);
      mock.removedById.add('eye_cleaning');

      handler.handle(payloadFor(_aimee.id, 'eye_cleaning'));
      await settle();
      await settle();

      expect(container.read(pendingCareSheetProvider), isNull);
      expect(mock.recordCompletionCallCount, 0);
    });

    test('a reminder that no longer exists settles nothing', () async {
      final handler = setUp_(selected: _aimee);

      handler.handle(payloadFor(_aimee.id, 'custom_99'));
      await settle();
      await settle();

      expect(container.read(pendingCareSheetProvider), isNull);
      expect(mock.recordCompletionCallCount, 0);
    });

    test('a tap for a deleted baby settles nothing', () async {
      // A completion row against a scope no profile owns would be invisible in the
      // UI and undeletable from it.
      final handler = setUp_(selected: _aimee);

      handler.handle(payloadFor('ghost-id', 'custom_7'));
      await settle();
      await settle();

      expect(paths, [AppRoute.home.path]);
      expect(mock.recordCompletionCallCount, 0);
    });

    test('the profileless scope resolves without a profile (D-R10 path)',
        () async {
      // Legacy installs have no profile at all; their scope is `''` and the
      // profileless reminder set is a real set. A tap there must behave like any
      // other, and must not be read as "no payload".
      final handler = setUp_(selected: null);

      handler.handle(payloadFor('', 'vitamine_d'));
      await settle();
      await settle();

      expect(paths, [AppRoute.home.path]);
      // Vitamin D is treatment-linked, so the ask is the sheet, with the selected
      // (absent) baby matching the scope.
      expect(container.read(pendingCareSheetProvider)?.itemId, 'vitamine_d');
    });
  });

  group('PendingCareSheet request lifecycle', () {
    test('take() drains once, so the two Home entry points cannot stack sheets',
        () {
      final c = ProviderContainer(overrides: [
        appSettingsRepositoryProvider
            .overrideWith((ref) async => _FakeAppSettings()),
      ]);
      addTearDown(c.dispose);

      c.read(pendingCareSheetProvider.notifier).request(
            const PendingCareSheet(
              subtype: HealthSubtype.nettoyageYeux,
              itemId: 'eye_cleaning',
            ),
          );

      final first = c.read(pendingCareSheetProvider.notifier).take();
      final second = c.read(pendingCareSheetProvider.notifier).take();
      expect(first?.itemId, 'eye_cleaning');
      expect(second, isNull,
          reason:
              'the request predating Home\'s first build and the listener firing on '
              'the same tap must produce one sheet, not two');
    });
  });
}
