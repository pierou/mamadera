import '../../../../data/local/db_constants.dart' show completionManual;
import '../../../../shared/domain/entities/baby_profile.dart';
import '../entities/custom_reminder.dart';
import '../entities/reminder_item.dart';
import '../entities/reminder_item_setting.dart';
import '../repositories/reminders_repository.dart';
import 'effective_reminders.dart';
import 'local_notification_service.dart';
import 'notification_payload.dart';
import 'notification_time.dart';
import 'reminder_scheduling.dart';
import 'reminders_service.dart' show defaultDismissalWindow;

/// The localized notification text for one item of one scope (`{baby}` / `{care}`
/// placeholders, plan §5). Injected into [ReminderScheduler.sync] so the domain
/// stays Flutter-free.
///
/// Named rather than spelled inline at both call sites: the same signature
/// appeared twice (here and in `_buildPlan`) and the inline form wraps ugly.
/// (Its other virtue is documentary — see the `ReminderScheduler` note in the
/// Makefile's `check-complexity` baseline about how little of this class the
/// complexity scanner can actually see.)
typedef NotificationContent = String Function(
    ReminderItem item, BabyProfile? scope);

/// D3: a due-at-sync item is nudged this many seconds after the sync that
/// sees it. One-shot; the ban is re-arming, not the 60 s delay itself.
const Duration catchUpDelay = Duration(seconds: 60);

/// Catch-up notifications live in their own id band, above every plan index
/// the sync notifier can produce. Sharing one id space with the plan
/// indices is what made the first draft unsound: a rename or a baby added
/// mid-day reshuffles the indices, so a fired catch-up nudge ended up either
/// cancelled out of the shade or replaced by another baby's schedule. In a
/// separate band a nudge is fire-and-forget: never re-armed (D3), never
/// displaced, cancelled only when its own due period closes.
const int catchUpIdBase = 10000;

/// The one-shot OS-notification orchestrator (plan §3.2/§3.5, D2 reconciliation).
///
/// The DB is the source of truth; the OS schedule is a derived cache.
/// [sync] rebuilds the whole per-baby plan (D6: every baby profile, the
/// profileless sentinel scope only when none exists) and diffs it against
/// what was submitted last time: unchanged entries are skipped (a steady-state
/// tick costs zero plugin calls), stale ids are cancelled, changed or new
/// entries are (re)submitted — by id, so the plugin replaces the pending
/// entry rather than stacking duplicates.
///
/// Notification ids are plan indices `1..N` over the kept entries in
/// enumeration order (D5). The content-aware diff (id + kind + at + title +
/// body) is what makes a baby rename safe: a surviving id whose title moved
/// is re-submitted with the new name (R11).
class ReminderScheduler {
  /// Creates the scheduler. [repository] is the same scope-aware repository
  /// the UI uses (`null` babyId ⇒ the profileless sentinel); [notifications]
  /// is the process-lived plugin wrapper (M4).
  ReminderScheduler({
    required RemindersRepository repository,
    required LocalNotificationService notifications,
    Duration? dismissalWindow,
  })  : _repository = repository,
        _notifications = notifications,
        _dismissalWindow = dismissalWindow ?? defaultDismissalWindow;

  final RemindersRepository _repository;
  final LocalNotificationService _notifications;

  /// Shared with the in-app pill (`RemindersService`) — a dismissed reminder
  /// must be silent in the OS for exactly as long as it is silent on screen.
  final Duration _dismissalWindow;

  /// The entries actually submitted at the last sync, by plan-index id
  /// (D2 diff baseline). Catch-up nudges are not here — see [_catchUpArmed].
  final Map<int, _PlanEntry> _plan = {};

  /// Catch-up nudges armed in this process, `scope::item::period → id`
  /// (D3): a key here is never re-armed, and its id survives plan-index
  /// reshuffles. Entries whose due period has closed are cancelled here.
  final Map<String, int> _catchUpArmed = {};

  /// Monotonic allocator for the catch-up id band; never reset within a
  /// process, so a live nudge's id is never recycled underneath the user.
  int _catchUpSeq = catchUpIdBase;

  /// Preset slot order, pinned to the item ids (plan §3.5 step 4) so a future
  /// reordering of [reminderItemsFor]'s list cannot move an id.
  static const List<String> _presetSlotOrder = [
    'vitamine_d',
    'vitamine_k',
    'eye_cleaning',
    'face_cleaning',
  ];

  /// Reconciles the OS schedule with the DB state (plan §3.5, exact steps).
  ///
  /// [babies] is the `BabyProfileRepository.getAllProfiles` list (name
  /// ascending); empty ⇒ the single profileless `''` scope. [title]/[body]
  /// resolve the localized notification text for an item + scope profile
  /// (`{baby}`/`{care}` placeholders, §5); they are injected so the domain
  /// stays Flutter-free. [now] is injectable for tests; defaults to
  /// [DateTime.now].
  ///
  /// Returns the number of entries currently pending in the OS.
  Future<int> sync({
    required List<BabyProfile> babies,
    required bool notificationsOptIn,
    required int preferredHour,
    required int preferredMinute,
    required NotificationContent title,
    required NotificationContent body,
    DateTime? now,
  }) async {
    // Step 0 (R13): init failed in this process ⇒ the OS holds no schedules
    // we know about; leave everything untouched and let the next tick retry
    // init before syncing.
    if (!_notifications.ready) return 0;

    // Step 1 (D8): opt-out ⇒ clear the OS and the local bookkeeping. The
    // de-opt path lands here too: the notifier persists '0' first.
    if (!notificationsOptIn) {
      await _notifications.cancelAll();
      _plan.clear();
      _catchUpArmed.clear();
      return 0;
    }

    final instant = now ?? DateTime.now();

    // Steps 3+4: build the new plan (scoping, item sets, the enabled filter,
    // nextDueAt). A flat list; the plan indices are assigned by the diff below.
    final fresh = await _buildPlan(
      babies: babies,
      preferredHour: preferredHour,
      preferredMinute: preferredMinute,
      instant: instant,
      title: title,
      body: body,
    );

    // Steps 5 and 6: diff against the last submitted plan, submit and cancel,
    // store the new baseline, and report what the OS holds.
    return _applyDiff(fresh);
  }

  /// The item set for a scope (plan §3.5 step 4): presets in the pinned slot
  /// order, then customs by `dbId` ascending (the repository's order).
  Future<List<ReminderItem>> _itemsForScope(BabyProfile? scope) async {
    final presets = reminderItemsFor(scope);
    final byId = {for (final item in presets) item.id: item};
    final ordered = [
      for (final slot in _presetSlotOrder)
        if (byId.containsKey(slot)) byId[slot]!,
    ];
    final customs = [
      for (final reminder
          in await _repository.getCustomReminders(babyId: scope?.id))
        CustomReminderPresets.forCustom(
          reminder,
          monthlyDay: scope?.birthDate.day,
        ),
    ];
    return [...ordered, ...customs];
  }

  /// The completion the pill and the scheduler must agree on: the event-driven
  /// lookup first, the manual journal only for detached (manual) items — the
  /// same split as `RemindersService._checkDue`.
  Future<DateTime?> _lastCompleted(
      ReminderItem item, BabyProfile? scope) async {
    final lastEventAt = await _repository.getLastCompleted(
      item,
      babyId: scope?.id,
    );
    if (lastEventAt == null && item.completionSource == completionManual) {
      return _repository.getLastManualCompletion(item.id, babyId: scope?.id);
    }
    return lastEventAt;
  }

  /// The new plan: one entry per scheduled or overdue item of every scope
  /// (plan §3.5 steps 3 and 4), in enumeration order and **without** plan indices
  /// — those belong to the diff, which assigns them to the scheduled subset only.
  ///
  /// Kept apart from [sync] on purpose: this half reads the DB and the clock, the
  /// other half talks to the OS. Each is testable and readable on its own.
  Future<List<_FreshEntry>> _buildPlan({
    required List<BabyProfile> babies,
    required int preferredHour,
    required int preferredMinute,
    required DateTime instant,
    required NotificationContent title,
    required NotificationContent body,
  }) async {
    final scopes = babies.isEmpty ? <BabyProfile?>[null] : babies;
    final fresh = <_FreshEntry>[];
    for (final scope in scopes) {
      final declared = await _itemsForScope(scope);
      // One query per scope for everything the row carries: the switch, the item's
      // own hour (B30), and from B33 the name, the rhythm, the end and the removal
      // — never one query per item.
      final settings = await _repository.getSettingsByItemId(babyId: scope?.id);
      // B33 (D-R2): the settings screen, Home and this plan all resolve the row
      // through `effectiveItemsForScope`, so a removed preset cannot be scheduled
      // while the list still shows it, or an overridden rhythm fire on the
      // preset's own. Removal reaches the OS the same way a settled one-shot does:
      // the item is absent from `fresh`, and the diff below cancels its id.
      final items = effectiveItemsForScope(
        items: declared,
        settings: settings,
        profile: scope,
      );
      for (final item in items) {
        final setting = settings[item.id];
        // B6 (D-R2): "no row" is not "on" — it is the item's own default. A
        // new baby has no `vitamine_d` row, so it must produce no OS entry;
        // honouring the default in the providers only would show the reminder
        // as off while its notification still fired. (M4 folds this line into
        // the shared effective-item function.)
        if (!(setting?.enabled ?? item.enabledByDefault)) continue;
        final lastCompleted = await _lastCompleted(item, scope);
        final lastDismissal = await _repository.getLastDismissal(
          item.id,
          babyId: scope?.id,
        );
        // B30: the hour is resolved **per item**, here, and `nextDueAt` itself is
        // unchanged — it simply receives this item's time of day. The plan diff
        // needs no new key for it: an edited hour moves `at`, and `at` is already
        // the first term of the `_PlanEntry` comparison, so the entry is
        // re-submitted by its id exactly like a renamed baby (B14's
        // stale-schedule concern is covered by the existing diff).
        final fireAt = _timeOfDayFor(
          setting,
          fallbackHour: preferredHour,
          fallbackMinute: preferredMinute,
        );
        final due = nextDueAt(
          item,
          now: instant,
          dismissalWindow: _dismissalWindow,
          preferredHour: fireAt.hour,
          preferredMinute: fireAt.minute,
          lastCompleted: lastCompleted,
          lastDismissal: lastDismissal,
        );
        // B33: this item can no longer be due (settled one-shot, D-R7; ended
        // series, D-R5). Dropping it from `fresh` is the whole mechanism — the
        // diff below finds the id in the old plan and in nothing else, and
        // cancels the OS notification. No second cancel path.
        if (due == null) continue;
        fresh.add(
          _FreshEntry(
            scopeKey: scope?.id ?? '',
            itemKey: item.id,
            periodKey: duePeriodStart(item,
                now: instant, lastCompleted: lastCompleted),
            isCatchUp: !due.isAfter(instant),
            at: due,
            title: title(item, scope),
            body: body(item, scope),
          ),
        );
      }
    }
    return fresh;
  }

  /// Step 5 and 6: reconcile the OS schedule with [fresh] — the plan just built.
  ///
  /// Unchanged entries are skipped (a steady tick costs zero plugin calls), stale
  /// ids are cancelled, changed or new ones are (re)submitted **by id** so the
  /// plugin replaces the pending entry instead of stacking a duplicate, and
  /// overdue items take a sticky catch-up nudge in their own id band (D3/D5).
  /// Returns the number of entries now pending in the OS.
  Future<int> _applyDiff(List<_FreshEntry> fresh) async {
    // Plan indices are assigned to *scheduled* entries only (D5); catch-up
    // nudges take a sticky id from [catchUpIdBase].
    // Period identity is a calendar day, not a month: a weekly item has a
    // distinct period per week, a monthly item one per month, a daily item
    // one per day — and a nudge is remembered against exactly one of them.
    var planIndex = 0;
    final next = <int, _PlanEntry>{};
    final armed = <String, int>{};
    for (final entry in fresh) {
      final key = '${entry.scopeKey}::${entry.itemKey}::'
          '${entry.periodKey.year}-'
          '${entry.periodKey.month}-'
          '${entry.periodKey.day}';

      if (entry.isCatchUp) {
        // D3: one nudge per item per due period, for the life of the process
        // (a restart inside the same window may nudge once more — R12,
        // accepted). The id is sticky and in its own band, so a rename or a
        // baby added/deleted can neither displace it nor re-arm it.
        final alreadyArmed = _catchUpArmed[key];
        if (alreadyArmed != null) {
          armed[key] = alreadyArmed;
          continue;
        }
        final id = ++_catchUpSeq;
        await _notifications.scheduleIn(
          id: id,
          title: entry.title,
          body: entry.body,
          delay: catchUpDelay,
          // The catch-up nudge is the same reminder, so it carries the same
          // identity: tapping it must do what tapping the notification would.
          payload: ReminderNotificationPayload(
            scope: entry.scopeKey,
            itemId: entry.itemKey,
          ).encode(),
        );
        armed[key] = id;
        continue;
      }

      final id = ++planIndex;
      final old = _plan[id];
      // B15: the reminder's stable identity rides the submission, so a tap can say
      // what fired. Derived from the entry's own keys — never from `id`, which is a
      // plan position (D2/D5).
      final payload = ReminderNotificationPayload(
        scope: entry.scopeKey,
        itemId: entry.itemKey,
      ).encode();

      // Steady state: same id + at + title + body ⇒ skip, so a 5-minute tick
      // costs zero plugin calls. A baby rename reshuffles ids and moves the
      // text: anything whose content changed is re-submitted by id, and the
      // plugin replaces the pending entry instead of stacking a duplicate
      // (R11 — no entry keeps a stale name).
      if (old != null &&
          old.at.isAtSameMomentAs(entry.at) &&
          old.title == entry.title &&
          old.body == entry.body &&
          old.payload == payload) {
        next[id] = old;
        continue;
      }

      await _notifications.scheduleAt(
        id: id,
        title: entry.title,
        body: entry.body,
        at: entry.at,
        payload: payload,
      );
      next[id] = (
        at: entry.at,
        title: entry.title,
        body: entry.body,
        payload: payload,
      );
    }

    // Stale ids: in the last plan, gone from the new one ⇒ cancel.
    for (final staleId in _plan.keys
        .where((candidate) => !next.containsKey(candidate))
        .toList(growable: false)) {
      await _notifications.cancel(staleId);
    }

    // Nudges whose due period has closed (completed, dismissed, disabled, or
    // gone with their baby) ⇒ cancel, and forget the key so that a *later*
    // period of the same item can nudge again. Without the forget, one
    // nudge would silence that item for the life of the process.
    for (final stale in _catchUpArmed.entries
        .where((candidate) => !armed.containsKey(candidate.key))
        .toList(growable: false)) {
      await _notifications.cancel(stale.value);
    }

    // Step 6: store the new baseline and report what is pending in the OS.
    _plan
      ..clear()
      ..addAll(next);
    _catchUpArmed
      ..clear()
      ..addAll(armed);
    return _plan.length + _catchUpArmed.length;
  }

  /// The time of day this item's notification fires at (B30).
  ///
  /// Its own stored hour when the row carries one that is a real `HH:mm`, the
  /// installation-wide pair otherwise — which is what `null` means: *inherit*,
  /// keeping the global row meaningful as "the default hour".
  ///
  /// Read-lax, with the fallback chosen deliberately: an unusable stored string
  /// is treated as "inherit", because the global hour is the promise the parent
  /// can still see and change, while the app's 09:00 default would be a third
  /// value nobody picked. The write side is strict (`isValidNotificationTime` at
  /// the picker and in the repository, and the importer refuses the value).
  ({int hour, int minute}) _timeOfDayFor(
    ReminderItemSetting? setting, {
    required int fallbackHour,
    required int fallbackMinute,
  }) {
    final stored = setting?.timeOfDay;
    if (stored == null || !isValidNotificationTime(stored)) {
      return (hour: fallbackHour, minute: fallbackMinute);
    }
    final parsed = parseNotificationTime(stored);
    return (hour: parsed.hour, minute: parsed.minute);
  }
}

/// The diff baseline (plan §3.2): what is pending in the OS at a plan id.
/// One submitted notification. The `payload` field is the reminder's stable identity
/// (`scope` + `item.id`) as the OS will hand it back on a tap (B15); it is part of
/// the entry so a reminder that moves to a different plan index is re-submitted
/// with the payload that now belongs to that index — which it already was, since
/// the ids are positional, but the payload must not lag behind the move.
typedef _PlanEntry = ({
  DateTime at,
  String title,
  String body,
  String payload,
});

/// One item of the freshly computed plan, before plan-index assignment.
class _FreshEntry {
  const _FreshEntry({
    required this.scopeKey,
    required this.itemKey,
    required this.periodKey,
    required this.isCatchUp,
    required this.at,
    required this.title,
    required this.body,
  });

  final String scopeKey;
  final String itemKey;

  /// The due period this entry belongs to, as a local calendar day — the
  /// identity a catch-up nudge is remembered against (D3: one nudge per
  /// period, every period its own).
  final DateTime periodKey;
  final bool isCatchUp;
  final DateTime at;
  final String title;
  final String body;
}
