import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import '../../../baby/data/repositories/baby_profile_repository_impl.dart';
import '../../../baby/domain/repositories/baby_profile_repository.dart';
import '../../../home/presentation/providers/repository_provider.dart';
import '../../data/repositories/reminders_repository_impl.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/entities/reminders_state.dart';
import '../../domain/services/reminders_service.dart';

/// Provider for the reminders repository implementation.
final remindersRepositoryProvider = FutureProvider((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return RemindersRepositoryImpl(database: database);
});

/// Provider for the baby profile repository (used to build dynamic reminders).
final babyProfileProvider = FutureProvider<BabyProfileRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return BabyProfileRepositoryImpl(database: database);
});

/// Dynamic list of reminder items built from the active baby profile.
/// Falls back to Vitamin D + daily Vitamin K when no profile exists yet.
final dynamicRemindersProvider = FutureProvider<List<ReminderItem>>((ref) async {
  final repo = await ref.watch(babyProfileProvider.future);
  final activeProfile = await repo.getActiveProfile();

  if (activeProfile == null) {
    // No baby profile yet — return default reminders with daily vitamin K fallback.
    return [ReminderItem.vitaminD(), ReminderItem.vitaminK()];
  }

  // Build dynamic reminders based on baby's birth date.
  return ReminderItem.buildForBaby(activeProfile);
});

/// Provider for the reminders service (pure business logic layer).
final remindersServiceProvider = FutureProvider((ref) async {
  final repository = await ref.watch(remindersRepositoryProvider.future);
  final items = await ref.watch(dynamicRemindersProvider.future);
  return RemindersService(items: items, repository: repository);
});

/// Provider that exposes due reminder statuses enriched with last tracked event times,
/// grouped by [TrackingType] for easy consumption on the home screen.
/// 
/// Each [ReminderStatus] includes [ReminderStatus.lastEventAt] populated from
/// the tracking repository, so UI can display "last cleaned X ago" etc.
final reminderStatusesProvider = FutureProvider<Map<TrackingType, List<ReminderStatus>>>((ref) async {
  final service = await ref.watch(remindersServiceProvider.future);
  final result = await service.checkDue();

  return switch (result) {
    RemindersAllCompleted() => {},
    RemindersDue(items: final List<ReminderStatus> items) => _enrichAndGroup(ref, List<ReminderStatus>.from(items)),
  };
});

/// Enrich [ReminderStatus] objects with last event timestamps from tracking repository,
/// then group by [TrackingType].
Future<Map<TrackingType, List<ReminderStatus>>> _enrichAndGroup(
  Ref ref,
  List<ReminderStatus> items,
) async {
  final trackingRepo = await ref.read(trackingRepositoryProvider.future);

  // Enrich each status with lastEventAt
  final enriched = <ReminderStatus>[];
  for (final status in items) {
    final lastEventAt = await trackingRepo.getLastEventByTypeAndSubtype(
      status.item.trackingType,
      subtypeValue: status.item.subtypeValue,
    );
    enriched.add(ReminderStatus(
      item: status.item,
      lastDismissedAt: status.lastDismissedAt,
      lastEventAt: lastEventAt,
    ));
  }

  // Group by TrackingType
  final grouped = <TrackingType, List<ReminderStatus>>{};
  for (final status in enriched) {
    final type = status.item.trackingType;
    grouped.putIfAbsent(type, () => []).add(status);
  }
  return grouped;
}
