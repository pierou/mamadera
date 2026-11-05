import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/encryption_provider.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../reminders/presentation/providers/reminder_notifier.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../domain/repositories/tracking_repository.dart';

/// The repository relies on asynchronous database operations and asynchronous encryption, utilizing the `FutureProvider`.
final trackingRepositoryProvider = FutureProvider<TrackingRepository>(
  (ref) async {
    final encryption = await ref.read(encryptionServiceProvider.future);
    final database = await ref.watch(databaseProvider.future);
    return TrackingRepositoryImpl(
      encryption: encryption,
      database: database,
    );
  },
);

/// Timestamp of the most recent tracked event of each home [TrackingType]
/// for the active baby (all four types; measurements live in their own table
/// and keep showing their last value on the growth buttons).
///
/// The home buttons' « last tracked » line reads from here: activity, not
/// reminder configuration — before this provider a type without any
/// configured reminder never showed the line, so in practice only Santé
/// (whose health routines are reminder-driven) had one.
///
/// Freshness piggybacks on [reminderNotifierProvider], which is the app-wide
/// « something was tracked or edited » signal: five-minute poll, refresh
/// after every tracking flow (home) and history edit/delete, rebuild on
/// baby switch. No new refresh mechanism.
// Keep-alive, like [reminderNotifierProvider] itself: the watch below is
// what carries the refresh cycle.
final lastTrackedTimestampsProvider =
    FutureProvider<Map<TrackingType, DateTime?>>((ref) async {
  // Recompute whenever the reminder state moves (see above). The watch is
  // for the cycle, not the value: the timestamps come from the events table.
  ref.watch(reminderNotifierProvider);

  // The baby read is watched, not read: the provider must re-query when the
  // active baby loads or switches. While the profile is still loading, `value`
  // is null and the query falls back to the unscoped column (always right for
  // a single-baby app); the following rebuild picks up the scoped one.
  final babyId = ref.watch(activeBabyProvider).value?.id;

  final repository = await ref.watch(trackingRepositoryProvider.future);
  if (!ref.mounted) return const {};

  final map = <TrackingType, DateTime?>{};
  for (final type in const [
    TrackingType.miam,
    TrackingType.sante,
    TrackingType.caca,
    TrackingType.dodo
  ]) {
    map[type] = await repository.getLatestEventTimestamp(type, babyId: babyId);
    if (!ref.mounted) return const {};
  }
  return map;
});
