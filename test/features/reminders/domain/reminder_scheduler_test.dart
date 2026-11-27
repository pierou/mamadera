import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/data/local/db_constants.dart' show completionManual;
import 'package:mamadera/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:mamadera/features/reminders/domain/entities/custom_reminder.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_frequency.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item.dart';
import 'package:mamadera/features/reminders/domain/entities/reminder_item_setting.dart';
import 'package:mamadera/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:mamadera/features/reminders/domain/services/local_notification_service.dart';
import 'package:mamadera/features/reminders/domain/services/notification_payload.dart';
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

  /// Per OS id: the payload the notification was scheduled with (B15). Recorded so
  /// a test can assert the identity that rides a notification — which must be the
  /// scope + stable item id, never the plan position.
  final Map<int, String?> payloads = {};

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
    String? payload,
  }) async {
    scheduleAtCalls++;
    entries[id] = (title, body, at);
    payloads[id] = payload;
  }

  @override
  Future<void> scheduleIn({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    if (delay != const Duration(seconds: 60)) {
      fail('catch-up delay must be 60 s, got $delay');
    }
    scheduledIn.add(id);
    entries[id] = (title, body, _now.add(const Duration(seconds: 60)));
    payloads[id] = payload;
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

  /// Per scope, then item: the reminder's own hour (B30). Absent = inherit.
  final Map<String, Map<String, String>> timesByScopeItem = {};
  final Map<String, List<CustomReminder>> customsByScope = {};
  final Map<String, DateTime> lastCompletedByScopeItem = {};
  final Map<String, DateTime> lastManualByScopeItem = {};
  final Map<String, DateTime> lastDismissalByScopeItem = {};

  /// Per scope, then item: the stored series end, as the v14 columns hold it
  /// (`end_date`, `end_age_months`) — D-R5. Absent = the series never ends.
  final Map<String, Map<String, (String? endDate, int? endAgeMonths)>>
      endsByScopeItem = {};

  /// Per scope: the items marked removed (D-R2's third state, D-R4).
  final Map<String, Set<String>> removedByScopeItem = {};
  final Set<String> enabledScopesSeen = {};

  static String _scope(String? babyId) => babyId ?? '';

  String? _key(String? scope, String item) => '${_scope(scope)}::$item';

  @override
  Future<Map<String, ReminderItemSetting>> getSettingsByItemId(
      {String? babyId}) async {
    enabledScopesSeen.add(_scope(babyId));
    final enabled = enabledByScope[_scope(babyId)] ?? const <String, bool>{};
    final times = timesByScopeItem[_scope(babyId)] ?? const <String, String>{};
    final ends =
        endsByScopeItem[_scope(babyId)] ?? const <String, (String?, int?)>{};
    final removed = removedByScopeItem[_scope(babyId)] ?? const <String>{};
    return {
      for (final id in {
        ...enabled.keys,
        ...times.keys,
        ...ends.keys,
        ...removed
      })
        id: ReminderItemSetting(
          enabled: enabled[id] ?? true,
          timeOfDay: times[id],
          endDate: ends[id]?.$1,
          endAgeMonths: ends[id]?.$2,
          removed: removed.contains(id),
        ),
    };
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
  Future<void> setItemTime(
    String itemId, {
    required String timeOfDay,
    required bool enabledIfNew,
    String? babyId,
  }) async =>
      (timesByScopeItem[_scope(babyId)] ??= {})[itemId] = timeOfDay;
  @override
  Future<void> clearItemTime(String itemId, {String? babyId}) async =>
      timesByScopeItem[_scope(babyId)]?.remove(itemId);
  // The scheduler only reads. The B33 writers exist for the settings screen, so
  // an implementation here would be a test that never runs; throwing is the
  // honest answer, and `setEnd` above is the seeding seam the end tests use.
  @override
  Future<void> setItemLabel(
    String itemId, {
    required String? label,
    required bool enabledIfNew,
    String? babyId,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> setItemFrequency(
    String itemId, {
    required ReminderFrequency? frequency,
    required bool enabledIfNew,
    String? babyId,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> setItemEnd(
    String itemId, {
    required bool enabledIfNew,
    DateTime? endDate,
    int? endAgeMonths,
    String? babyId,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> setItemRemoved(
    String itemId, {
    required bool removed,
    required bool enabledIfNew,
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
  /// [seedVitaminDOn] mirrors what a 1.3.x install looks like *after* the v14
  /// migration: the seed wrote an explicit `enabled = 1` vitamin D row for every
  /// scope that had none (B6, PLAN-v1.4.0 D-R1). Most of this file is about plan
  /// mechanics — ids, diffing, cancellation — so that row is present by default.
  /// A test that wants the 1.4.0 "never touched" state (no row ⇒ **off** for a
  /// new baby) passes `seedVitaminDOn: false`.
  _Harness({List<BabyProfile>? babies, bool seedVitaminDOn = true})
      : repo = FakeRemindersRepository(),
        notifications = FakeNotificationService(),
        babies = babies ?? _defaultBabies() {
    if (seedVitaminDOn) {
      for (final scope in this.babies.isEmpty
          ? const <String>['']
          : this.babies.map((b) => b.id)) {
        repo.enabledByScope[scope] = {'vitamine_d': true};
      }
    }
    scheduler = ReminderScheduler(
      repository: repo,
      notifications: notifications,
    );
  }

  /// Merge one override into a scope's settings rows.
  ///
  /// The maps are seeded (see [seedVitaminDOn]), so a test that switches one
  /// item off must not silently drop the vitamin D row along with it.
  void setEnabled(String scope, String item, {required bool enabled}) {
    repo.enabledByScope.putIfAbsent(scope, () => {})[item] = enabled;
  }

  /// Give one reminder a stored series end (D-R5).
  ///
  /// The picker that writes these columns is M4's; M3 owns the semantics, so the
  /// rows here are shaped exactly as the columns will hold them — `'yyyy-MM-dd'`
  /// and whole months — and the production read path is what is under test.
  void setEnd(
    String scope,
    String item, {
    String? endDate,
    int? endAgeMonths,
  }) {
    repo.endsByScopeItem.putIfAbsent(scope, () => {})[item] =
        (endDate, endAgeMonths);
  }

  /// Mark an item removed for [scope] (what `setItemRemoved` writes).
  void remove(String scope, String item, {bool removed = true}) {
    repo.removedByScopeItem.putIfAbsent(scope, () => <String>{});
    if (removed) {
      repo.removedByScopeItem[scope]!.add(item);
    } else {
      repo.removedByScopeItem[scope]!.remove(item);
    }
  }

  /// The plan id currently holding [title], or null when the OS holds nothing
  /// for it. Asserted through the title because the ids are positional: they
  /// compact when an item drops out, which is exactly what these tests change.
  int? idOf(String title) {
    for (final entry in notifications.entries.entries) {
      if (entry.value.$1 == title) return entry.key;
    }
    return null;
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
    int preferredHour = 8,
    int preferredMinute = 0,
  }) =>
      scheduler.sync(
        babies: babies ?? this.babies,
        notificationsOptIn: optIn,
        preferredHour: preferredHour,
        preferredMinute: preferredMinute,
        title: _title,
        body: _body,
        now: now ?? _now,
      );
}

/// The identity a payload string carries, as a `(scope, item id)` record, so a
/// failure prints both halves instead of two indistinguishable instances.
(Object?, Object?) _identity(String? payload) {
  final parsed = ReminderNotificationPayload.tryParse(payload);
  return (parsed?.scope, parsed?.itemId);
}

/// A stub active-baby provider that resolves [profile], so the provider side of
/// the B31 seam can be read against the very repository the scheduler was given.
class _StubActiveBaby extends ActiveBabyNotifier {
  _StubActiveBaby(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}

/// The item ids the OS plan holds for [scope], read out of the payloads the
/// scheduler attached (B15) — never out of plan indices, which are positional
/// and compact when an item drops out.
Set<String> _scheduledIds(_Harness h, String scope) =>
    h.notifications.payloads.values
        .map(ReminderNotificationPayload.tryParse)
        .whereType<ReminderNotificationPayload>()
        .where((p) => (p.scopeOrNull ?? '') == scope)
        .map((p) => p.itemId)
        .toSet();

/// The item ids Home would list for the same repository state.
Future<Set<String>> _homeIds(
    FakeRemindersRepository repo, BabyProfile baby) async {
  final container = ProviderContainer(
    overrides: [
      remindersRepositoryProvider.overrideWith((ref) async => repo),
      activeBabyProvider.overrideWith(() => _StubActiveBaby(baby)),
    ],
  );
  addTearDown(container.dispose);
  final items = await container.read(enabledRemindersProvider.future);
  return items.map((item) => item.id).toSet();
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
      h.setEnabled(_aimeeId, 'eye_cleaning', enabled: false);
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
      expect(
          h.notifications.scheduledIn, [catchUpIdBase + 1, catchUpIdBase + 2]);
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

      // The baby added mid-day arrives with her vitamin D row already present —
      // the state a 1.3.x install has after the v14 seed (D-R1), which is what
      // this harness models by default.
      h.setEnabled(_beaId, 'vitamine_d', enabled: true);
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

      h.setEnabled(_aimeeId, 'custom_1', enabled: false);
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

    // B6 (BACKLOG B6, PLAN-v1.4.0 D-R2): the enabled filter here must honour the
    // item's own default. This is the read site a `?? true` grep does not find
    // (`enabled[item.id] == false`), so no provider-level test can catch it:
    // with the old line, every test above still passes while the OS notification
    // of a new baby's vitamin D keeps firing behind a switch that shows OFF.
    test('a baby with no vitamin D row gets zero OS entries for it (B6)',
        () async {
      final h = _Harness(seedVitaminDOn: false);
      final count = await h.sync();

      // Three items per baby (vit K, eye, face): 5 scheduled + Béa's vit K nudge.
      expect(count, 6);
      for (final entry in h.notifications.entries.values) {
        expect(entry.$1.contains('reminderVitaminD'), isFalse,
            reason: 'a reminder that was never turned on must not notify, '
                'got "${entry.$1}"');
      }
      // The other presets are untouched by the new default.
      expect(h.notifications.entries.values.map((e) => e.$1),
          containsAll(['Aimée:reminderVitaminK', 'Béa:reminderEyeCleaning']));
    });

    test(
        'profileless fallback keeps vitamin K and drops the default-off vitamin D',
        () async {
      final h = _Harness(babies: const [], seedVitaminDOn: false);
      final count = await h.sync();

      // Only vitamin K is left, and the 30-day interval was never completed ⇒
      // due now ⇒ a catch-up nudge, not a plan entry (D3).
      expect(count, 1);
      expect(h.notifications.scheduledIn, [catchUpIdBase + 1]);
      expect(
          h.notifications.entries[catchUpIdBase + 1]!.$1, 'T:reminderVitaminK');
    });

    // BACKLOG B30: the hour is resolved per item inside the loop. `nextDueAt` is
    // unchanged — it receives this item's time of day — so these tests are about
    // the resolution, the re-submission and the catch-up window.
    test('an item with its own hour fires at that hour, not the global one',
        () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      h.repo.timesByScopeItem[_aimeeId] = {'eye_cleaning': '06:15'};
      await h.sync(); // 06:00 now, global hour 08:00

      final byTitle = {
        for (final entry in h.notifications.entries.values) entry.$1: entry.$3
      };
      expect(byTitle['Aimée:reminderEyeCleaning'], _at(2026, 7, 15, 6, 15),
          reason: 'its own hour wins, an hour and three quarters early');
      expect(byTitle['Aimée:reminderFaceCleaning'], _at(2026, 7, 15, 8),
          reason: 'a row without an hour keeps the global one');
      expect(byTitle['Aimée:reminderVitaminD'], _at(2026, 7, 15, 8));
    });

    test('an own hour that has passed opens the catch-up window early',
        () async {
      // The point of B30, as its ticket §6 puts it: a reminder at 08:00 on a
      // device whose global hour is 09:00 opens *its* catch-up an hour earlier
      // than the others. At 08:30, that item is overdue while the rest wait.
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      h.repo.timesByScopeItem[_aimeeId] = {'eye_cleaning': '08:00'};

      await h.sync(now: _at(2026, 7, 15, 8, 30), preferredHour: 9);

      expect(h.notifications.scheduledIn, [catchUpIdBase + 1]);
      expect(h.notifications.entries[catchUpIdBase + 1]!.$1,
          'Aimée:reminderEyeCleaning');
      final scheduled = {
        for (final entry in h.notifications.entries.values) entry.$1: entry.$3
      };
      expect(scheduled['Aimée:reminderFaceCleaning'], _at(2026, 7, 15, 9));
    });

    test('editing an hour re-submits the same plan id (B14 stale schedule)',
        () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      await h.sync();
      final callsBefore = h.notifications.scheduleAtCalls;
      // Aimée's items are ids 1-4 in the pinned slot order: eye cleaning is 3.
      expect(h.notifications.entries[3]!.$1, 'Aimée:reminderEyeCleaning');

      h.repo.timesByScopeItem[_aimeeId] = {'eye_cleaning': '21:45'};
      await h.sync();

      expect(h.notifications.entries[3]!.$3, _at(2026, 7, 15, 21, 45),
          reason: 'the entry moved to the new hour under the same id');
      expect(h.notifications.cancelled, isEmpty,
          reason: 'nothing left the plan, so nothing may be cancelled');
      expect(h.notifications.scheduleAtCalls, greaterThan(callsBefore),
          reason: 'a changed `at` is re-submitted, the plugin replaces the '
              'pending entry instead of stacking a duplicate');
    });

    test('an unusable stored hour inherits the global one', () async {
      // Read-lax: a value that is not a real HH:mm (hand-edited backup, junk
      // written by an older build) must not schedule a notification at a time
      // that does not exist, and must not fall back to 09:00 either — the global
      // hour is the promise the parent can still see.
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      h.repo.timesByScopeItem[_aimeeId] = {'eye_cleaning': '24:00'};
      await h.sync();

      expect(h.notifications.entries[3]!.$3, _at(2026, 7, 15, 8));
    });

    test('an explicit row still wins over the default: on for a new baby',
        () async {
      // The switch in Settings writes a row; from then on the row decides, in
      // both directions, whatever the item's default is.
      final h = _Harness(seedVitaminDOn: false);
      h.setEnabled(_beaId, 'vitamine_d', enabled: true);
      await h.sync();
      expect(
        h.notifications.entries.values.map((e) => e.$1),
        contains('Béa:reminderVitaminD'),
      );
    });
  });

  // B33 Part 1's actual work is the **removal** half (D-R7): an item that can no
  // longer be due has to leave the OS schedule, which happens by dropping out of
  // the plan and letting the existing diff cancel its id. A one-shot that stays
  // behind would re-ask for a dose already given; an ended series that stays
  // behind is a reminder the parent explicitly stopped.
  group('B33 — an item that can no longer be due leaves the OS schedule', () {
    test('a settled one-shot is cancelled, and nothing replaces it', () async {
      // Aimée: born 20 June ⇒ vitamin K on 20 July.
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      await h.sync();
      final vitKId = h.idOf('Aimée:reminderVitaminK');
      expect(vitKId, isNotNull, reason: 'the occurrence is scheduled first');
      final scheduledBefore = h.notifications.scheduleAtCalls;

      // The dose is recorded on the day ⇒ the one-shot is settled for good.
      h.repo.lastCompletedByScopeItem['$_aimeeId::vitamine_k'] =
          _at(2026, 7, 20, 9);
      final count = await h.sync();

      // Plan ids are positional and compact when an item drops out (the
      // existing disablement test asserts the same way), so the cancelled id is
      // the *tail*, not necessarily the dropped item's own id: the entry that
      // carried vitamin K is either cancelled or overwritten by whoever took its
      // id. What must be true in the OS is that nothing carries the title.
      expect(h.notifications.cancelled, isNotEmpty);
      expect(h.idOf('Aimée:reminderVitaminK'), isNull);
      expect(count, 3, reason: 'vitamin D, eye cleaning, face cleaning');
      expect(h.notifications.entries.length, 3);
      // And it never comes back. The next sync does re-submit two entries — the
      // plan compacted, so whoever took the vacated id is re-submitted by id
      // (R11, existing behaviour, not a B33 effect). Once the plan has settled,
      // a further tick must be silent: that is what "settled for good" means.
      await h.sync();
      final callsWhenSettled = h.notifications.scheduleAtCalls;
      expect(callsWhenSettled, greaterThan(scheduledBefore),
          reason: 'compaction re-submits the shifted entries by id');
      await h.sync();
      expect(h.notifications.scheduleAtCalls, callsWhenSettled,
          reason: 'a settled one-shot must not come back on a later sync');
      expect(h.idOf('Aimée:reminderVitaminK'), isNull);
    });

    test('an ended series is cancelled, not merely skipped', () async {
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      await h.sync();
      // Face cleaning is the last item, hence the last plan id: ending *it*
      // removes the tail, so the cancellation can be asserted on its own id
      // rather than on the compaction of the others.
      final faceId = h.idOf('Aimée:reminderFaceCleaning');
      expect(faceId, 4);

      // "Until 14 July", decided on the 15th: the series is already over. D-R5
      // accepts a past end at write time — the row simply stops being due.
      h.setEnd(_aimeeId, 'face_cleaning', endDate: '2026-07-14');
      await h.sync();

      expect(h.notifications.cancelled, [faceId],
          reason: 'the OS entry is cancelled, not left to fire on its own');
      expect(h.idOf('Aimée:reminderFaceCleaning'), isNull);
    });

    test('the end day itself still fires; the day after it does not', () async {
      // Inclusive end (D-R5): the boundary is tested at the scheduler level too,
      // because a whole-day off-by-one here is a reminder that dies early.
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      h.setEnd(_aimeeId, 'eye_cleaning', endDate: '2026-07-15');
      final countToday = await h.sync(); // now = 15 July 06:00
      expect(h.idOf('Aimée:reminderEyeCleaning'), isNotNull,
          reason: 'the end date is part of the series');

      h.setEnd(_aimeeId, 'eye_cleaning', endDate: '2026-07-14');
      final countTomorrow = await h.sync(now: _at(2026, 7, 15, 6));
      expect(countTomorrow, lessThan(countToday),
          reason: 'one day later the same row has no occurrence left');
      expect(h.idOf('Aimée:reminderEyeCleaning'), isNull);
    });

    test('a removed preset is cancelled from the OS schedule (D-R2, D-R4)',
        () async {
      // Removal is not a switch and not a deletion: the row stays (so D-R4's
      // restore has something to restore) but the reminder must stop producing
      // notifications, here and in every other baby's schedule it belongs to.
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      await h.sync();
      final faceId = h.idOf('Aimée:reminderFaceCleaning');
      expect(faceId, isNotNull);

      h.remove(_aimeeId, 'eye_cleaning');
      h.remove(_aimeeId, 'face_cleaning');
      await h.sync();

      expect(h.notifications.cancelled, contains(faceId),
          reason: 'the OS entry is cancelled, not left to fire once more');
      expect(h.idOf('Aimée:reminderFaceCleaning'), isNull);
      expect(h.idOf('Aimée:reminderEyeCleaning'), isNull);
      // The other presets are untouched: removal is per item, not per section.
      expect(h.idOf('Aimée:reminderVitaminK'), isNotNull);

      // And a restore puts it back, switch and all (D-R4): the row was never gone.
      h.remove(_aimeeId, 'face_cleaning', removed: false);
      await h.sync();
      expect(h.idOf('Aimée:reminderFaceCleaning'), isNotNull);
    });

    // B15: a tap must be able to say which reminder fired. The identity is decided
    // here, at schedule time, and nowhere else — the handler can only ever be as
    // precise as what the notification carries.
    group('the tap payload (B15)', () {
      test('every entry carries its scope and its stable item id', () async {
        final h = _Harness();
        await h.sync();

        // One entry per baby, with the *scope* of that baby — not the active one,
        // not the profileless sentinel: D6 schedules every baby, so a tap for Béa
        // must resolve to Béa even while Aimée is selected.
        final aimeeEye =
            h.notifications.payloads[h.idOf('Aimée:reminderEyeCleaning')];
        expect(ReminderNotificationPayload.tryParse(aimeeEye)?.scope, _aimeeId);
        expect(ReminderNotificationPayload.tryParse(aimeeEye)?.itemId,
            'eye_cleaning');
        final beaVitaminK =
            h.notifications.payloads[h.idOf('Béa:reminderVitaminK')];
        expect(
            ReminderNotificationPayload.tryParse(beaVitaminK)?.scope, _beaId);
        expect(ReminderNotificationPayload.tryParse(beaVitaminK)?.itemId,
            'vitamine_k');
      });

      test('the payload follows the reminder, not the plan position', () async {
        // B15's "Do not": never the OS id or the plan index. Aimée's eye cleaning
        // sits at one index while she is the only baby and at another once a second
        // baby sorts in front of her; the identity a tap resolves must not move.
        final alone = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
        await alone.sync();
        final idAlone = alone.idOf('Aimée:reminderEyeCleaning')!;
        expect(_identity(alone.notifications.payloads[idAlone]),
            (_aimeeId, 'eye_cleaning'));

        final two = _Harness(babies: [
          _baby('aaron-id', 'Aaron', 12),
          _baby(_aimeeId, 'Aimée', 20),
        ]);
        await two.sync();
        final idTwo = two.idOf('Aimée:reminderEyeCleaning')!;
        expect(idTwo, isNot(idAlone),
            reason:
                'a new baby in name order reshuffles the plan indices — that '
                'is exactly why an index is not an identity');
        expect(_identity(two.notifications.payloads[idTwo]),
            (_aimeeId, 'eye_cleaning'));
      });

      test('the catch-up nudge carries the same identity as the reminder',
          () async {
        // Tapping the nudge must do what tapping the notification would: it is the
        // same reminder, nudged because the due moment has already passed.
        final h = _Harness();
        await h.sync();
        final nudgeId = h.notifications.scheduledIn.single;
        expect(_identity(h.notifications.payloads[nudgeId]),
            (_beaId, 'vitamine_k'));
      });

      test('a re-submitted entry keeps its payload', () async {
        // Steady state skips plugin calls when nothing changed; the payload is part
        // of what "nothing changed" means, so an entry whose identity moved to a
        // different index cannot be skipped as unchanged.
        final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
        await h.sync();
        final callsAfterFirst = h.notifications.scheduleAtCalls;

        await h.sync(babies: [
          _baby('aaron-id', 'Aaron', 12),
          _baby(_aimeeId, 'Aimée', 20),
        ]);
        expect(h.notifications.scheduleAtCalls, greaterThan(callsAfterFirst),
            reason:
                'the plan reshuffled, so the entries are re-submitted by id');
        expect(
            ReminderNotificationPayload.tryParse(h.notifications
                    .payloads[h.idOf('Aimée:reminderEyeCleaning')])
                ?.itemId,
            'eye_cleaning');
      });
    });

    test('an age-based end moves when the birthdate is corrected', () async {
      // Read-time resolution: nothing about the end is stored as a date, so the
      // plan follows the birthdate with no invalidation step (D-R5).
      final h = _Harness(babies: [_baby(_aimeeId, 'Aimée', 20)]);
      h.setEnd(_aimeeId, 'eye_cleaning', endAgeMonths: 1);
      await h.sync();
      // Born 20 June, one month old on 20 July ⇒ still running on 15 July.
      expect(h.idOf('Aimée:reminderEyeCleaning'), isNotNull);

      // Correct the birthdate to 20 May ⇒ one month old on 20 June ⇒ ended.
      final h2 = _Harness(babies: [_babyMoved(_aimeeId, 'Aimée', 2026, 5, 20)]);
      h2.setEnd(_aimeeId, 'eye_cleaning', endAgeMonths: 1);
      await h2.sync();
      expect(h2.idOf('Aimée:reminderEyeCleaning'), isNull,
          reason:
              'the same stored row, a corrected birthdate, a finished series');
    });
  });

  // B31 was never "a reminder is missing". It was two consumers reading the same
  // settings row two different ways: the list on screen showed the declared preset
  // while the OS fired the overridden one, so a parent could read a reminder every
  // day and never meet the notification they had configured. M4 made
  // `effectiveItemsForScope` the single reading; this group is the seam between the
  // two consumers, which is where that bug lives — a unit test of the function
  // alone cannot see a caller that forgot to call it.
  group('B31 — the Home list and the OS plan read one row', () {
    test('baseline: both hold exactly the same items', () async {
      final baby = _baby(_aimeeId, 'Aimée', 20);
      final h = _Harness(babies: [baby]);
      await h.sync();

      expect(_scheduledIds(h, _aimeeId), await _homeIds(h.repo, baby));
    });

    test('a removed preset leaves both; an own hour changes no membership',
        () async {
      // The B31 shape exactly: removal applied in one consumer only would leave a
      // reminder on Home that the OS will never fire — or a notification behind a
      // row that says it is gone.
      final baby = _baby(_aimeeId, 'Aimée', 20);
      final h = _Harness(babies: [baby]);
      h.remove(_aimeeId, 'vitamine_d');
      h.repo.timesByScopeItem[_aimeeId] = {'nettoyage_yeux': '06:30'};
      await h.sync();

      final scheduled = _scheduledIds(h, _aimeeId);
      expect(scheduled, isNot(contains('vitamine_d')));
      expect(scheduled, await _homeIds(h.repo, baby));
    });

    test('a settled one-shot stays on Home and holds no OS entry', () async {
      // The one difference between the two lists that is allowed, stated rather
      // than assumed: the dose is taken, so nothing is left to schedule, while the
      // reminder remains something the parent configured.
      final baby = _baby(_aimeeId, 'Aimée', 20);
      final h = _Harness(babies: [baby]);
      h.repo.lastCompletedByScopeItem['$_aimeeId::vitamine_k'] =
          _at(2026, 7, 20, 9);
      await h.sync();

      expect(_scheduledIds(h, _aimeeId), isNot(contains('vitamine_k')));
      expect(
          (await _homeIds(h.repo, baby)).difference(_scheduledIds(h, _aimeeId)),
          {'vitamine_k'});
    });

    test('an ended series stays on Home and holds no OS entry', () async {
      final baby = _baby(_aimeeId, 'Aimée', 20);
      final h = _Harness(babies: [baby]);
      await h.sync();
      // Named by its preset id, and proven present first: an assertion about an id
      // that was never scheduled would pass for the wrong reason.
      expect(_scheduledIds(h, _aimeeId), contains('eye_cleaning'));

      h.setEnd(_aimeeId, 'eye_cleaning', endDate: '2026-07-14');
      await h.sync();

      expect(_scheduledIds(h, _aimeeId), isNot(contains('eye_cleaning')));
      expect(
          (await _homeIds(h.repo, baby)).difference(_scheduledIds(h, _aimeeId)),
          {'eye_cleaning'});
    });

    test('a never-touched vitamin D is absent from both consumers (B6)',
        () async {
      // The four-site default asserted on the two sites that matter together: a
      // provider-only assertion passed on the broken three-of-four version of M1.
      final baby = _baby(_aimeeId, 'Aimée', 20);
      final h = _Harness(babies: [baby], seedVitaminDOn: false);
      await h.sync();

      expect(_scheduledIds(h, _aimeeId), isNot(contains('vitamine_d')));
      expect(await _homeIds(h.repo, baby), isNot(contains('vitamine_d')));
    });
  });
}

/// A baby whose birthdate is given in full (the harness helper takes a day of
/// the current year only).
BabyProfile _babyMoved(String id, String name, int y, int m, int d) =>
    BabyProfile(
      id: id,
      name: name,
      birthDate: DateTime(y, m, d),
      isActive: id == _aimeeId,
    );
