import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/encryption_provider.dart';
import '../../data/repositories/measurement_repository_impl.dart';
import '../../domain/entities/growth_measurement.dart';
import '../../domain/repositories/measurement_repository.dart';

/// Provider for the measurements repository implementation.
///
/// Exposed through the [MeasurementRepository] interface so that...
/// The presentation depends on the level of abstraction, and the tests overload a fake implementation.
final measurementRepositoryProvider =
    FutureProvider<MeasurementRepository>((ref) async {
  final encryption = await ref.read(encryptionServiceProvider.future);
  final database = await ref.watch(databaseProvider.future);
  return MeasurementRepositoryImpl(database: database, encryption: encryption);
});

/// History of the baby's activity measurements, with the most recent measurement listed first.
///
/// Keep-alive, similar to the `reminderNotifierProvider`: watch.
/// [activeBabyProvider] to re-evaluate with each change in the baby's condition, and the...
/// Home screen buttons, such as the "growth" screen, always display those of...
/// Selected baby.
final measurementNotifierProvider =
    AsyncNotifierProvider<MeasurementNotifier, List<GrowthMeasurement>>(
  MeasurementNotifier.new,
);

class MeasurementNotifier extends AsyncNotifier<List<GrowthMeasurement>> {
  @override
  Future<List<GrowthMeasurement>> build() async {
    // Responsiveness to baby's changes (same functionality as the reminder notification).
    ref.watch(activeBabyProvider);
    return _load();
  }

  Future<List<GrowthMeasurement>> _load() async {
    final repository = await ref.read(measurementRepositoryProvider.future);
    if (!ref.mounted) return const [];
    // `null` (no baby selected) = all rows, like the...
    // events: Before a profile is created, all events are set to be "profile-based."
    // empty anyway.
    final babyId = ref.read(activeBabyProvider).value?.id;
    return repository.allForBaby(babyId);
  }

  /// Review the list after you've written it (save it to the sheet).
  Future<void> refresh() async {
    final result = await AsyncValue.guard(_load);
    if (ref.mounted) state = result;
  }
}
