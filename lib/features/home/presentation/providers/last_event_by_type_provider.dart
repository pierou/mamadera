import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import 'repository_provider.dart';

/// When each tracking type was last recorded, for the home grid.
///
/// Deliberately **not** derived from the reminders (B28). `RemindersService
/// .checkDue` answers "what is overdue right now", so a line built from its
/// statuses disappears the moment a reminder is settled — and because
/// `miam`/`caca`/`dodo` reminders are settled by the events themselves
/// (`completion_source = from_events`), logging a feeding used to delete its
/// own « last tracked » line, leaving Health as the only button that showed
/// one. The pending reminders are listed below the grid
/// (`HomeRemindersSection`); this map is event history, and the two must not
/// share a query.
///
/// Keyed by type, and a type with no event is **absent** rather than mapped to
/// a sentinel: the button then renders no line instead of an invented date.
///
/// Nothing watches the event table, so freshness is by invalidation — every
/// write that can change an answer invalidates this provider
/// (`TrackNotifier.track`, `HistoryNotifier` edit/delete, the restore in
/// `import_providers`, the reset in `menu_screen`). A line that lies about when
/// something was last tracked is worse than a line that is one frame late.
class LastEventByTypeNotifier
    extends AsyncNotifier<Map<TrackingType, DateTime>> {
  @override
  Future<Map<TrackingType, DateTime>> build() async {
    final repository = await ref.watch(trackingRepositoryProvider.future);
    // Awaited, not `.value`: the notifier's id is the query's baby scope, and
    // reading it while it is still loading would silently ask for the
    // profile-less rows instead — and then need a second rebuild to correct.
    final baby = await ref.watch(activeBabyProvider.future);

    final result = <TrackingType, DateTime>{};
    for (final type in TrackingType.values) {
      final at = await repository.getLastEventAt(type, babyId: baby?.id);
      if (at != null) result[type] = at;
    }
    return result;
  }
}

/// Provider for [LastEventByTypeNotifier].
final lastEventByTypeProvider =
    AsyncNotifierProvider<LastEventByTypeNotifier, Map<TrackingType, DateTime>>(
        LastEventByTypeNotifier.new);
