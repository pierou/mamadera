import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/reminder_frequency.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminder_item_setting.dart';
import '../../domain/services/notification_time.dart';
import '../../domain/services/reminder_frequency_codec.dart';
import 'reminder_providers.dart';
import 'reminder_sync_notifier.dart';

/// What the parent stored for each reminder of the active scope, as
/// `item_id → row` (the switch and the per-reminder hour, B30).
///
/// Only rows that exist are in the map. A missing key means "never touched",
/// which resolves to the item's own `ReminderItem.enabledByDefault` (B6): eye
/// and face care and vitamin K are on from the first launch, vitamin D is off
/// for a baby created on 1.4.0 or later and on for one carried over from
/// 1.3.x (the v14 seed, PLAN-v1.4.0 D-R1). Off-by-default is still **visible**
/// in the list — the switch shows it, which is the point of the decision.
///
/// This is the single read of `reminder_settings`: the switches, the hour
/// subtitles and the due list all project from here, so two surfaces of the same
/// reminder can never disagree (the B31 defect class).
final reminderSettingsProvider = AsyncNotifierProvider<ReminderSettingsNotifier,
    Map<String, ReminderItemSetting>>(
  ReminderSettingsNotifier.new,
);

class ReminderSettingsNotifier
    extends AsyncNotifier<Map<String, ReminderItemSetting>> {
  @override
  Future<Map<String, ReminderItemSetting>> build() async {
    // ref.watch: a system reset from the menu rebuilds this provider against the
    // now-empty `reminder_settings` table, and switching babies must re-read the
    // other baby's row (or the profileless `''` scope until a profile exists) —
    // so the switches and the hours always reflect the current scope.
    final profile = await ref.watch(activeBabyProvider.future);
    final repository = await ref.watch(remindersRepositoryProvider.future);
    return repository.getSettingsByItemId(babyId: profile?.id);
  }

  /// Persist the toggle and update local state — the switch does not flicker
  /// waiting for a round trip to re-read the data.
  ///
  /// The home pills update on their own: the reminders service reactively
  /// depends on this provider through the settings → enabled-reminders → service
  /// chain (see [RemindersNotifier.build]), so a disabled reminder disappears
  /// from the pills without this method invalidating anything. The OS schedule is
  /// re-reconciled too: a disabled item must stop producing notifications (D2).
  Future<void> setEnabled(String itemId, {required bool enabled}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setEnabled(itemId, enabled: enabled, babyId: profile?.id);

    _put(itemId, (current) => current.copyWith(enabled: enabled),
        whenAbsent: () => ReminderItemSetting(enabled: enabled));
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Give one reminder its **own** notification hour (B30), then re-reconcile the
  /// OS schedule — the plan entry moves to the new hour on the next diff, by id
  /// (the hour changes `at`, and `at` is already compared).
  ///
  /// Takes the [item] rather than an id because creating a row needs the item's
  /// own default: picking an hour for vitamin D is not consent to switch it on
  /// (B6).
  Future<void> setTime(ReminderItem item,
          {required int hour, required int minute}) =>
      setTimeById(
        item.id,
        timeOfDay: formatNotificationTime(hour: hour, minute: minute),
        enabledIfNew: item.enabledByDefault,
      );

  /// Give one reminder addressed by id its **own** hour (B30), or `null` to
  /// inherit again.
  ///
  /// For a reminder whose [ReminderItem] the caller does not hold: a custom
  /// reminder has just been written by the form sheet and its item is not in
  /// the provider yet — the same reason [setEndById] exists, and the hour the
  /// sheet's panel offered is written here, after the reminder itself, as the
  /// second column-write of the same row (B35).
  /// `enabledIfNew` is the caller's B6 answer: for a custom reminder it is
  /// `true`, because creating one *was* the consent.
  Future<void> setTimeById(
    String itemId, {
    required bool enabledIfNew,
    String? timeOfDay,
  }) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    if (timeOfDay == null) {
      // Back to the global hour: the stored hour becomes NULL, the switch and
      // the rest of the row are untouched (`useGlobalTime`'s contract, and a
      // missing row has nothing to clear).
      await repository.clearItemTime(itemId, babyId: profile?.id);
      final current =
          (state.value ?? const <String, ReminderItemSetting>{})[itemId];
      if (current != null) {
        _put(itemId, (row) => row.copyWith(timeOfDay: null));
      }
    } else {
      await repository.setItemTime(
        itemId,
        timeOfDay: timeOfDay,
        enabledIfNew: enabledIfNew,
        babyId: profile?.id,
      );
      _put(
        itemId,
        (row) => row.copyWith(timeOfDay: timeOfDay),
        whenAbsent: () => ReminderItemSetting(
          enabled: enabledIfNew,
          timeOfDay: timeOfDay,
        ),
      );
    }
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Back to the global hour for one reminder (B30's "inherit"): the stored hour
  /// becomes NULL, the switch and the rest of the row are untouched.
  Future<void> useGlobalTime(ReminderItem item) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.clearItemTime(item.id, babyId: profile?.id);

    final current =
        (state.value ?? const <String, ReminderItemSetting>{})[item.id];
    if (current != null) {
      _put(item.id, (row) => row.copyWith(timeOfDay: null));
    }
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  // ── The other columns of the same row (B33, D-R2) ──────────────────────
  //
  // Same three steps as [setEnabled] / [setTime], always: write the column, update
  // the cached row so the screen does not flicker on a re-read, then re-reconcile
  // the OS schedule. Each owns its columns only — the rule M2 learned when
  // `setEnabled`'s delete-and-reinsert erased a stored hour.
  //
  // All of them take the [item] rather than an id: creating a row has to answer
  // `enabled`, and that answer is the item's own default. Renaming, re-pacing or
  // ending vitamin D is not consent to switch it on (B6).

  /// Rename a preset for this scope (D-R6); `null` = back to the app's name.
  Future<void> setLabel(ReminderItem item, {String? label}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    final stored = label?.trim();
    await repository.setItemLabel(
      item.id,
      label: (stored == null || stored.isEmpty) ? null : stored,
      enabledIfNew: item.enabledByDefault,
      babyId: profile?.id,
    );
    _put(
      item.id,
      (row) => row.copyWith(label: stored),
      whenAbsent: () =>
          ReminderItemSetting(enabled: item.enabledByDefault, label: stored),
    );
    // A rename changes the notification text, so the pending entry has to be
    // re-submitted — the diff already re-submits on a changed title (R11).
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Give a preset a rhythm of its own (B33); `null` = the preset's own.
  ///
  /// A one-shot through the same door: the sheet that calls this is the thing that
  /// must supply the day (D-R5), and the repository refuses the call without one.
  Future<void> setFrequency(ReminderItem item,
      {ReminderFrequency? frequency}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setItemFrequency(
      item.id,
      frequency: frequency,
      enabledIfNew: item.enabledByDefault,
      babyId: profile?.id,
    );
    final stored = frequency == null ? null : encodeFrequency(frequency);
    _put(
      item.id,
      (row) => row.copyWith(
        frequency: stored?.code,
        intervalDays: stored?.intervalDays,
        frequencyDate: stored?.occurrenceDate,
        // D-R5's exclusivity: choosing a one-shot drops the stored end, and the
        // cached row has to say the same thing the columns now say.
        endDate: frequency is OneTime ? null : row.endDate,
        endAgeMonths: frequency is OneTime ? null : row.endAgeMonths,
      ),
      whenAbsent: () => ReminderItemSetting(
        enabled: item.enabledByDefault,
        frequency: stored?.code,
        intervalDays: stored?.intervalDays,
        frequencyDate: stored?.occurrenceDate,
      ),
    );
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// The end of a reminder addressed by id.
  ///
  /// For a reminder whose [ReminderItem] the caller does not hold: a custom
  /// reminder has just been written and its item is not in the provider yet.
  /// `enabledIfNew` is then the caller's answer to the same B6 question — for a
  /// custom reminder it is `true`, because creating one *was* the consent.
  Future<void> setEndById(
    String itemId, {
    required bool enabledIfNew,
    DateTime? endDate,
    int? endAgeMonths,
  }) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setItemEnd(
      itemId,
      endDate: endDate,
      endAgeMonths: endAgeMonths,
      enabledIfNew: enabledIfNew,
      babyId: profile?.id,
    );
    // The cached row mirrors the column, so the day goes back to its `'yyyy-MM-dd'`
    // text here and is parsed again by `effectiveItemsForScope` — one spelling on
    // disk, one resolution point (D-R5).
    final storedEnd = endDate == null ? null : formatCalendarDate(endDate);
    _put(
      itemId,
      (row) => row.copyWith(
        endDate: storedEnd,
        endAgeMonths: endAgeMonths,
      ),
      whenAbsent: () => ReminderItemSetting(
        enabled: enabledIfNew,
        endDate: storedEnd,
        endAgeMonths: endAgeMonths,
      ),
    );
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Program an end (D-R5 forms 2 and 3); both `null` = no end any more.
  Future<void> setEnd(
    ReminderItem item, {
    DateTime? endDate,
    int? endAgeMonths,
  }) =>
      setEndById(
        item.id,
        endDate: endDate,
        endAgeMonths: endAgeMonths,
        enabledIfNew: item.enabledByDefault,
      );

  /// Remove a preset for this scope (D-R2's third state): it leaves Home, this
  /// list and the OS schedule, and appears in the Removed section, from where one
  /// tap brings it back with everything it had (D-R4).
  Future<void> remove(ReminderItem item) => _setRemoved(item, removed: true);

  /// Restore a removed preset.
  Future<void> restore(ReminderItem item) => _setRemoved(item, removed: false);

  Future<void> _setRemoved(ReminderItem item, {required bool removed}) async {
    final profile = await ref.read(activeBabyProvider.future);
    final repository = await ref.read(remindersRepositoryProvider.future);
    await repository.setItemRemoved(
      item.id,
      removed: removed,
      enabledIfNew: item.enabledByDefault,
      babyId: profile?.id,
    );
    _put(
      item.id,
      (row) => row.copyWith(removed: removed),
      whenAbsent: () => ReminderItemSetting(
        enabled: item.enabledByDefault,
        removed: removed,
      ),
    );
    // Removal is the third caller of the "can no longer be due" path: the item
    // drops out of the plan and the existing diff cancels its notification.
    unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
  }

  /// Update one entry of the cached map without a re-read, keeping the columns
  /// this method does not own exactly as they are.
  void _put(
    String itemId,
    ReminderItemSetting Function(ReminderItemSetting current) update, {
    ReminderItemSetting Function()? whenAbsent,
  }) {
    final current = state.value ?? const <String, ReminderItemSetting>{};
    final row = current[itemId];
    if (row == null && whenAbsent == null) return;
    state = AsyncData({
      ...current,
      itemId: row == null ? whenAbsent!() : update(row),
    });
  }
}
