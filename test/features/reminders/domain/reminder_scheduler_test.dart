import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/data/local/db_constants.dart' show completionManual;
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:mamadera/features/reminders/domain/services/local_notification_service.dart';
import 'package:mamadera/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

/// Fixed instants (M5 test matrix): 2026-07-15 is a Wednesday.
DateTime _at(int y, int m, int d, [int h = 8, int min = 0]) =>
    DateTime(y, m, d, h, min);

final _now = _at(2026, 7, 15, 6); // before the 08:00 preferred time

BabyProfile _baby(String id, String name, int birthDay) => BabyProfile(
      id: id,
      name: name,
      birthDate: _at(2026, 6, birthDay),
      isActive: id == _aimeeId,
    );

const _aimeeId = 'aimée-id'; // born day 20 → vit K on 2026-07-20
const _beaId = 'béa-id'; // born day 5 → vit K on 2026-07-05 (already past)

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotificationService implements LocalNotificationService {
  bool readyFlag = true;
  bool granted = true;
  bool exactAlarms = true;

  final Map<int, (String title, String body, DateTime at)> entries = {};
  final List<int> cancelled = [];
  final List<int> scheduledIn = [];
  int cancelAllCount = 0;
  int scheduleAtCalls = 0;
  int initCalls = 0;

  @override
  Future<void> init() async => initCalls++;

  @override
  Future<bool> ensurePermission() async => granted;

  @override
  Future<bool> get permissionGranted async => granted;

  @override
  Future<bool> get exactAlarmsAllowed async => exactAlarms;

  @override
  bool get ready => readyFlag;

  @override
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    scheduleAtCalls++;
    entries[id] = (title, body, at);
  }

  @override
  Future<void> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    if (delay != const Duration(seconds: 60)) {
      fail('catch-up delay must be 60 s, got $delay');
    }
    scheduledIn.add(id);
    entries[id] = (title, body, _now.add(const Duration(seconds: 60)));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    entries.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    entries.clear();
  }
}

class FakeRemindersRepository implements RemindersRepository {
  /// Per scope (babyId, `''` sentinel when null): enabled overrides.
  final Map<String, Map<String, bool>> enabledByScope = {};
  final Map<String, List<CustomReminder>> customsByScope = {};
  final Map<String, DateTime> lastCompletedByScopeItem = {};
  final Map<String, DateTime> lastManualByScopeItem = {};
  final Map<String, DateTime> lastDismissalByScopeItem = {};
  final Set<String> enabledScopesSeen = {};

  static String _scope(String? babyId) => babyId ?? '';

  String? _key(String? scope, String item) => '${_scope(scope)}::$item';

  @override
  Future<Map<String, bool>> getEnabledByItemId({String? babyId}) async {
    enabledScopesSeen.add(_scope(babyId));
    return Map.of(enabledByScope[_scope(babyId)] ?? const {});
  }

  @override
  Future<List<CustomReminder>> getCustomReminders({String? babyId}) async {
    // Mirrors the real repository: `..orderBy([OrderingTerm.asc(t.id)])`.
    // The scheduler relies on this order for plan indices, so the fake must
    // honour the contract, not the seed order.
    final rows =
        List<CustomReminder>.of(customsByScope[_scope(babyId)] ?? const []);
    rows.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    return rows;
  }

  @override
  Future<DateTime?> getLastCompleted(
    ReminderItem item, {
    String? babyId,
  }) async =>
      lastCompletedByScopeItem[_key(babyId, item.id)];

  @override
  Future<DateTime?> getLastManualCompletion(
    String itemId, {
    String? babyId,
  }) async =>
      lastManualByScopeItem[_key(babyId, itemId)];

  @override
  Future<DateTime?> getLastDismissal(
    String itemId, {
    String? babyId,
  }) async =>
      lastDismissalByScopeItem[_key(babyId, itemId)];

  @override
  Future<void> recordCompletion(
    String itemId, {
    String? babyId,
    DateTime? at,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> dismissReminder(
    String itemId, {
    String? babyId,
    DateTime? at,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> setEnabled(
    String itemId, {
    required bool enabled,
    String? babyId,
  }) =>
      throw UnimplementedError();
  @override
  Future<int> insertCustomReminder(
    CustomReminder reminder, {
    String? babyId,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> updateCustomReminder(
    CustomReminder reminder, {
    String? babyId,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> deleteCustomReminder(
    int id, {
    String? babyId,
  }) =>
      throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

List<BabyProfile> _defaultBabies() => [
      _baby(_aimeeId, 'Aimée', 20),
      _baby(_beaId, 'Béa', 5),
    ];

class _Harness {
  _Harness({List<BabyProfile>? babies})
      : repo = FakeRemindersRepository(),
        notifications = FakeNotificationService(),
        babies = babies ?? _defaultBabies() {
    scheduler = ReminderScheduler(
      repository: repo,
      notifications: notifications,
    );
  }

  final List<BabyProfile> babies;
  final FakeRemindersRepository repo;
  final FakeNotificationService notifications;
  late final ReminderScheduler scheduler;

  String _title(ReminderItem item, BabyProfile? scope) =>
      scope == null ? 'T:${item.labelKey}' : '${scope.name}:${item.labelKey}';

  String _body(ReminderItem item, BabyProfile? scope) => scope == null
      ? 'B:${item.labelKey}'
      : '${scope.name} : c\'est l\'heure de ${item.labelKey}.';

  Future<int> sync({
    List<BabyProfile>? babies,
    bool optIn = true,
    DateTime? now,
  }) =>
      scheduler.sync(
        babies: babies ?? this.babies,
        notificationsOptIn: optIn,
        preferredHour: 8,
        preferredMinute: 0,
        title: _title,
        body: _body,
        now: now ?? _now,
      );
}

void main() {
  group('ReminderScheduler.sync()', () {
    test('two babies with different birth days: 8 entries, per-baby vit K',
        () async {
      final h = _Harness();
      final count = await h.sync();
      expect(count, 8);

      // Scope reads are per-baby, never the profileless sentinel.
      expect(h.repo.enabledScopesSeen, {_aimeeId, _beaId});

      // Aimée (ids 1-4, name order) — born day 20: vit K on 2026-07-20 08:00.
      expect(h.notifications.entries[1]!.$2,
          'Aimée : c\'est l\'heure de reminderVitaminD.');
      expect(h.notifications.entries[2]!.$3, _at(2026, 7, 20));
      // Béa (ids 5-8) — born day 5: vit K already due at 2026-07-15 ⇒ catch-up.
      expect(h.notifications.entries[5]!.$1, 'Béa:reminderVitaminD');
      // Béa's vit K is due, so it is a catch-up — and catch-ups live in
      // their own id band, never in the plan indices (D3/D5).
      expect(h.notifications.scheduledIn, [catchUpIdBase + 1]);
      expect(h.notifications.entries[catchUpIdBase + 1]!.$1,
          'Béa:reminderVitaminK');
      expect(h.notifications.cancelled, isEmpty);
    });

    test('profileless run: 2 entries, no baby name in the body', () async {
      final h = _Harness(babies: const []);
      final count = await h.sync();
      expect(count, 2);
      expect(h.repo.enabledScopesSeen, {''});
      expect(h.notifications.entries[1]!.$2, 'B:reminderVitaminD');
      // vit K is a 30-day custom interval, never completed ⇒ due ⇒ catch-up.
      expect(h.notifications.scheduledIn, [catchUpIdBase + 1]);
    });

    test('per-baby disablement reshuffles the plan and cancels the tail',
        () async {
      final h = _Harness();
      await h.sync();
      final callsAfterFirst = h.notifications.scheduleAtCalls;

      // Disable Aimée's eye cleaning (id 3): her face cleaning moves to id 3,
      // ids 4-8 shift down by one, id 8 becomes stale.
      h.repo.enabledByScope[_aimeeId] = {'eye_cleaning': false};
      final count = await h.sync();
      expect(count, 7); // 6 scheduled + Béa's live catch-up nudge
      // The plan compacts: ids 1-6, so the old id 7 goes stale.
      expect(h.notifications.cancelled, [7]);
      // id 3 now carries Aimée's face cleaning (new content at that id).
      expect(h.notifications.entries[3]!.$1, 'Aimée:reminderFaceCleaning');
      expect(h.notifications.scheduleAtCalls, greaterThan(callsAfterFirst));
    });

    test('opt-in off ⇒ cancelAll, 0 pending, bookkeeping cleared', () async {
      final h = _Harness();
      await h.sync();
      expect(await h.sync(optIn: false), 0);
      expect(h.notifications.cancelAllCount, 1);
      expect(h.notifications.entries, isEmpty);

      // A later opt-in resubmits the full plan from scratch (the catch-up
      // key was cleared with the opt-out, so the nudge is re-armed).
      final count = await h.sync();
      expect(count, 8);
      expect(h.notifications.cancelAllCount, 1);
      expect(h.notifications.scheduledIn,
          [catchUpIdBase + 1, catchUpIdBase + 2]);
    });

    test('unchanged state ⇒ zero plugin calls (steady tick)', () async {
      final h = _Harness();
      await h.sync();
      final atCalls = h.notifications.scheduleAtCalls;
      final inCalls = h.notifications.scheduledIn.length;

      final count = await h.sync();
      expect(count, 8);
      expect(h.notifications.scheduleAtCalls, atCalls);
      expect(h.notifications.scheduledIn.length, inCalls);
    });

    test('catch-up is not re-armed by a second sync in the same process',
        () async {
      final h = _Harness();
      final nudgeId = catchUpIdBase + 1;
      await h.sync(); // arms Béa's vit K catch-up.
      expect(h.notifications.scheduledIn, [nudgeId]);
      // Second sync, same due window: no second arm, and — the load-bearing
      // half — the live nudge is NOT cancelled. Cancelling it would wipe a
      // notification the user has not tapped yet on the next 5-minute tick.
      await h.sync();
      expect(h.notifications.scheduledIn, [nudgeId]);
      expect(h.notifications.cancelled, isEmpty);
      expect(h.notifications.entries[nudgeId]!.$1, 'Béa:reminderVitaminK');
    });

    test('deleting a baby cancels its entries, keeps the others', () async {
      final h = _Harness();
      await h.sync();
      final count = await h.sync(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      expect(count, 4);
      // Her scheduled ids go stale, and so does Béa's pending nudge: a
      // notification for a deleted baby must not fire.
      expect(h.notifications.cancelled, [5, 6, 7, catchUpIdBase + 1]);
      expect(h.notifications.entries[1]!.$1, 'Aimée:reminderVitaminD');
    });

    test('adding a baby schedules its items without touching the rest',
        () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      await h.sync();
      final aimeeIds = h.notifications.entries.keys.toSet();

      final count = await h.sync(
        babies: [_baby(_aimeeId, 'Aimée', 20), _baby(_beaId, 'Béa', 5)],
      );
      expect(count, 8); // 7 scheduled + Béa's catch-up nudge
      // Aimée keeps her ids and entries (name order: Aimée first).
      for (final id in aimeeIds) {
        expect(h.notifications.entries[id]!.$1, startsWith('Aimée:'));
      }
      expect(h.notifications.cancelled, isEmpty);
    });

    test('baby rename reshuffles ids ⇒ no entry keeps the old name', () async {
      final h = _Harness();
      await h.sync();

      // Aimée → Zora: name order flips (Béa now leads), so every entry's
      // title moves and every scheduled id is re-submitted.
      final count = await h.sync(
        babies: [_baby(_beaId, 'Béa', 5), _baby(_aimeeId, 'Zora', 20)],
      );
      expect(count, 8);
      for (final entry in h.notifications.entries.values) {
        expect(entry.$1.contains('Aimée'), isFalse,
            reason: 'stale name in "${entry.$1}"');
      }
      expect(h.notifications.entries[1]!.$1, 'Béa:reminderVitaminD');
      expect(h.notifications.entries[4]!.$1, 'Zora:reminderVitaminD');
    });

    test('custom reminders follow the presets by dbId and carry the label',
        () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      h.repo.customsByScope[_aimeeId] = [
        CustomReminder(
          id: 2,
          label: 'Lait de croissance',
          frequency: const Daily(),
          subtypeValue: null,
          completionSource: completionManual,
        ),
        CustomReminder(
          id: 1,
          label: 'Sirop',
          frequency: const Daily(),
          subtypeValue: null,
          completionSource: completionManual,
        ),
      ];
      final count = await h.sync();
      expect(count, 6);
      // Presets first (ids 1-4), customs after, dbId ascending.
      expect(h.notifications.entries[5]!.$1, 'Aimée:Sirop');
      expect(h.notifications.entries[6]!.$1, 'Aimée:Lait de croissance');
    });

    test('disabled customs are skipped before plan-index assignment', () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      h.repo.customsByScope[_aimeeId] = [
        CustomReminder(
          id: 1,
          label: 'Sirop',
          frequency: const Daily(),
          subtypeValue: null,
          completionSource: completionManual,
        ),
      ];
      await h.sync();
      expect(h.notifications.entries[5]!.$1, 'Aimée:Sirop');

      h.repo.enabledByScope[_aimeeId] = {'custom_1': false};
      final count = await h.sync();
      expect(count, 4);
      expect(h.notifications.cancelled, [5]);
    });

    test('unhealthy service ⇒ sync returns 0 and touches nothing', () async {
      final h = _Harness();
      await h.sync();
      final pending = h.notifications.entries;

      h.notifications.readyFlag = false;
      final count = await h.sync();
      expect(count, 0);
      expect(h.notifications.cancelAllCount, 0);
      expect(h.notifications.cancelled, isEmpty);
      expect(h.notifications.entries, pending);

      // Next healthy tick: unchanged ⇒ zero submissions, same plan kept.
      h.notifications.readyFlag = true;
      final calls = h.notifications.scheduleAtCalls;
      expect(await h.sync(), 8);
      expect(h.notifications.scheduleAtCalls, calls);
    });

    test('completed yesterday ⇒ today 08:00; completed today ⇒ tomorrow',
        () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      // Vitamin D completed yesterday ⇒ due today at 08:00.
      h.repo.lastCompletedByScopeItem['$_aimeeId::vitamine_d'] =
          _at(2026, 7, 14, 20);
      await h.sync();
      expect(h.notifications.entries[1]!.$3, _at(2026, 7, 15));

      // Completed today ⇒ suppressed until end of today ⇒ tomorrow 08:00.
      h.repo.lastCompletedByScopeItem['$_aimeeId::vitamine_d'] =
          _at(2026, 7, 15, 7);
      await h.sync();
      expect(h.notifications.entries[1]!.$3, _at(2026, 7, 16));
    });

    test('dismissed item is suppressed for the 24 h window', () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      // Dismissed at 2026-07-15 05:00 ⇒ suppressed until 07-16 05:00 ⇒
      // the daily candidate (today 08:00) advances to tomorrow 08:00.
      h.repo.lastDismissalByScopeItem['$_aimeeId::vitamine_d'] =
          _at(2026, 7, 15, 5);
      await h.sync();
      expect(h.notifications.entries[1]!.$3, _at(2026, 7, 16));
    });
  });
}
