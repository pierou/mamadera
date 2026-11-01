import '../../../../data/local/db_constants.dart' show completionManual;
import '../../../../shared/domain/entities/baby_profile.dart';
import '../entities/custom_reminder.dart';
import '../entities/reminder_item.dart';
import '../repositories/reminders_repository.dart';
import 'local_notification_service.dart';
import 'reminder_scheduling.dart';
import 'reminders_service.dart' show defaultDismissalWindow;

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
    required String Function(ReminderItem, BabyProfile?) title,
    required String Function(ReminderItem, BabyProfile?) body,
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

    // Steps 3+4: build the new plan (scoping, item sets, enabled filter,
    // nextDueAt). Kept as a flat list; plan indices are assigned below.
    final scopes = babies.isEmpty ? <BabyProfile?>[null] : babies;
    final fresh = <_FreshEntry>[];
    for (final scope in scopes) {
      final items = await _itemsForScope(scope);
      final enabled = await _repository.getEnabledByItemId(babyId: scope?.id);
      for (final item in items) {
        if (enabled[item.id] == false) continue;
        final lastCompleted = await _lastCompleted(item, scope);
        final lastDismissal = await _repository.getLastDismissal(
          item.id,
          babyId: scope?.id,
        );
        final due = nextDueAt(
          item,
          now: instant,
          dismissalWindow: _dismissalWindow,
          preferredHour: preferredHour,
          preferredMinute: preferredMinute,
          lastCompleted: lastCompleted,
          lastDismissal: lastDismissal,
        );
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

    // Step 5: diff against the last submitted plan and submit/cancel.
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
        );
        armed[key] = id;
        continue;
      }

      final id = ++planIndex;
      final old = _plan[id];

      // Steady state: same id + at + title + body ⇒ skip, so a 5-minute tick
      // costs zero plugin calls. A baby rename reshuffles ids and moves the
      // text: anything whose content changed is re-submitted by id, and the
      // plugin replaces the pending entry instead of stacking a duplicate
      // (R11 — no entry keeps a stale name).
      if (old != null &&
          old.at.isAtSameMomentAs(entry.at) &&
          old.title == entry.title &&
          old.body == entry.body) {
        next[id] = old;
        continue;
      }

      await _notifications.scheduleAt(
        id: id,
        title: entry.title,
        body: entry.body,
        at: entry.at,
      );
      next[id] = (at: entry.at, title: entry.title, body: entry.body);
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
}

/// The diff baseline (plan §3.2): what is pending in the OS at a plan id.
typedef _PlanEntry = ({DateTime at, String title, String body});

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
