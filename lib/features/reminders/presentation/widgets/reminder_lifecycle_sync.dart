import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reminder_sync_notifier.dart';

/// The app's single [WidgetsBindingObserver] (verified 2026-10-26: no other
/// observer exists anywhere in `lib/`).
///
/// Runs the notification reconciliation (plan §3.1, M5) at the two moments
/// that can change the OS schedule without any user mutation: the first
/// frame after cold start, and every `AppLifecycleState.resumed` (the device
/// clock may have moved, the user may have revoked or granted the
/// permission in system settings while the app was away — D8 de-opt).
///
/// Lives in the reminders feature, not in `core/`: both of its triggers do
/// exactly one thing, and that thing is reminder scheduling. Mounting it
/// from `core/` would make the dependency arrows point the wrong way (the
/// architecture ratchet's `core_to_feature_presentation` rule).
class ReminderLifecycleSyncWidget extends ConsumerStatefulWidget {
  const ReminderLifecycleSyncWidget({required this.child, super.key});

  /// The normal app tree; this widget adds no UI of its own.
  final Widget child;

  @override
  ConsumerState<ReminderLifecycleSyncWidget> createState() =>
      _ReminderLifecycleSyncWidgetState();
}

class _ReminderLifecycleSyncWidgetState
    extends ConsumerState<ReminderLifecycleSyncWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First-frame sync: the tree is built, the schedule is not yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(reminderSyncNotifierProvider.notifier).syncNow());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
