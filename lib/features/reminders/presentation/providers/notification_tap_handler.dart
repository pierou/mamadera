import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/router.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../domain/entities/custom_reminder.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/services/effective_reminders.dart';
import '../../domain/services/notification_payload.dart';
import 'pending_care_sheet.dart';
import 'reminder_providers.dart';

/// What a notification tap does (PLAN-v1.4.0 **M5**: B22 + B15, D-R9).
///
/// Two decisions, in this order:
///
/// 1. **The app lands on Home, always** (B22). Owner-reported: with no Dart tap
///    handler the tap fell through to the OS default, which restores whatever
///    screen was last open — reminder settings, in their case, on both platforms.
///    Home is a fixed destination, and it is applied *before* the payload means
///    anything, so a junk or absent payload still produces the documented
///    behaviour rather than an inert notification.
/// 2. **Then the tap does what the reminder allows** (B15, D-R9): a detached
///    reminder (whose completion is by definition a manual act) is settled for the
///    scope that fired; a treatment-linked one opens the matching care sheet
///    **pre-filled** and lets the parent confirm. It never writes a health event on
///    its own — a mistap on a 3 a.m. banner must not become a row in the
///    paediatrician's export (B15 "Do not" 1).
///
void _goRouter(String path) => router.go(path);

/// 3. **The child the notification is about becomes the selected baby** (owner
///    decision 2026-11-17), so the Home it lands on is that child's Home and the care
///    sheet below records for them. The profileless `''` scope cannot be selected and
///    is the one case that still stops at Home.
///
/// Injected into `FlutterLocalNotificationService` at
/// `localNotificationServiceProvider`, because the data layer must not import
/// `core/router.dart` (B22's seam note).
final notificationTapHandlerProvider =
    Provider<NotificationTapHandler>(NotificationTapHandler.new);

class NotificationTapHandler {
  /// [navigate] is `router.go` in the app. Injectable so a test can assert the
  /// destination — the alternative is pumping the whole route tree (splash, terms
  /// gate, shell) to learn that one string was passed.
  NotificationTapHandler(this._ref, {void Function(String path)? navigate})
      : _navigate = navigate ?? _goRouter;

  final Ref _ref;
  final void Function(String path) _navigate;
  final Logger _logger = appLogger();

  /// Entry point: the payload the OS delivered, `null` when the tap carried none.
  ///
  /// Synchronous by contract — the plugin's callback is `void` — so the database
  /// half runs in a detached future. Every failure inside it is logged and
  /// swallowed: a tap that cannot resolve its reminder has still taken the parent
  /// Home, which is the half of the promise that cannot fail.
  void handle(String? payload) {
    _navigate(AppRoute.home.path);
    final parsed = ReminderNotificationPayload.tryParse(payload);
    if (parsed == null) return;
    unawaited(_act(parsed));
  }

  Future<void> _act(ReminderNotificationPayload payload) async {
    try {
      final scope = payload.scopeOrNull;
      final repository = await _ref.read(remindersRepositoryProvider.future);
      // Riverpod 3 disposes a provider nothing watches, and a tap's work continues
      // after the plugin callback returned. `ReminderLifecycleSyncWidget` watches
      // this handler for exactly that reason; these guards are the belt to that
      // brace — an app torn down mid-tap must not write through a dead Ref.
      if (!_ref.mounted) return;
      final babies = await _ref.read(babyProfileListProvider.future);
      final profile =
          scope == null ? null : babies.where((b) => b.id == scope).firstOrNull;
      // The scope must still exist. A baby deleted between the firing and the tap
      // has no reminders to settle, and writing a completion against a dead scope
      // would create a row nothing can show or delete.
      if (scope != null && profile == null) return;

      // Resolved the way every other consumer resolves it — the same scope's
      // presets, customs and overrides, through `effectiveItemsForScope`. A
      // reminder the parent removed or re-paced after the notification fired is
      // read as it is *now*, not as it was when the plan was built.
      final settings = await repository.getSettingsByItemId(babyId: scope);
      final customs = await repository.getCustomReminders(babyId: scope);
      final items = effectiveItemsForScope(
        items: [
          ...reminderItemsFor(profile),
          for (final custom in customs)
            CustomReminderPresets.forCustom(
              custom,
              monthlyDay: profile?.birthDate.day,
            ),
        ],
        settings: settings,
        profile: profile,
      );
      final item = items
          .where((candidate) => candidate.id == payload.itemId)
          .firstOrNull;
      if (item == null) return;

      // **A tap selects the child it is about** (owner decision 2026-11-17, D-R9's
      // open point). D6 schedules every baby, so the banner may belong to the one
      // who is not selected — and landing on the other child's Home is the same
      // complaint B22 was, one level deeper: right screen, wrong baby. It is also
      // the only version under which the care sheet below is safe: the sheet belongs
      // to Home, and Home shows the selected baby.
      //
      // The profileless (`''`) scope cannot be selected — there is no profile to
      // select — so it is left as it is, and its care sheet stays gated on the
      // selected baby being absent too (below).
      final active = await _ref.read(activeBabyProvider.future);
      if (!_ref.mounted) return;
      if (scope != null && active?.id != scope) {
        await _ref.read(activeBabyProvider.notifier).switchProfile(scope);
        if (!_ref.mounted) return;
      }

      if (item.isDetached) {
        // Detached: the tap *is* the act of completion the app already accepts from
        // the Home pill, so it settles the same way — same `reminder_completions`
        // row, same re-plan, and the next due date moves out of tonight (D3).
        // Scoped to the payload's baby explicitly rather than to whoever is now
        // selected: the write must be right even if the selection above is a no-op.
        await _ref
            .read(reminderNotifierProvider.notifier)
            .markDone(item, scope: payload.scope);
        return;
      }

      // Treatment-linked: deep-link, never auto-create (D-R9). The tap asks Home for
      // the matching care sheet, pre-selected; the parent confirms, and that confirm
      // is the only thing that writes (D2). A mistap on a 3 a.m. banner must not
      // become a line in the paediatrician's export.
      final subtype = item.subtypeValue == null
          ? null
          : HealthSubtype.byValue(item.subtypeValue!);
      if (subtype == null) return;
      if ((await _ref.read(activeBabyProvider.future))?.id != scope) {
        // Only reachable for the profileless scope: a tap cannot select a baby that
        // does not exist, and opening the sheet would record against whoever *is*
        // selected. Home only, then — and said out loud in the log rather than
        // silently dropped.
        _logger.d(
          'Notification tap for the profileless scope while "${active?.id}" is '
          'selected: opened Home, care sheet withheld (it would record for the '
          'wrong baby)',
        );
        return;
      }
      _ref
          .read(pendingCareSheetProvider.notifier)
          .request(PendingCareSheet(subtype: subtype, itemId: item.id));
    } on Object catch (error, stackTrace) {
      // Never rethrow into the plugin's callback.
      _logger.e(
        'Notification tap could not be resolved to a reminder',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
