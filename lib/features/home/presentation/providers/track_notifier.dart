import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../data/local/db_constants.dart' as db_const;
import '../../../../shared/domain/entities/quantity_unit.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_type.dart';
import 'repository_provider.dart';

final trackNotifierProvider = AsyncNotifierProvider<TrackNotifier, void>(
  TrackNotifier.new,
);

class TrackNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Records a tracking event (feeding, sleep, diaper change, health).
  /// [duration] is measured in minutes for sleep/nap time.
  /// [unit] is the unit of measurement for [quantity] – specified in the line, and never inferred.
  /// reading (v12). Provided by the feeding dialogue (`ml`, `min`, or...
  /// `g`) ; `null` is assigned to the unit that the subtype previously held before version 12.
  /// That is to say, what the parent saw on the screen ([defaultUnitFor]).
  /// [wasteType], [pipiColor], and [cacaColor] are used exclusively for stool samples.
  /// The `[feedingSubtype]` is required for a `FeedingEvent` (natural/artificial).
  /// The [healthSubtype] field is required for HealthEvent records (e.g., eye cleaning).
  /// [timestamp] is the moment the event happened; it lets you record
  /// afterwards (nap finished, diaper changed in the other room).
  /// `null` = maintenant, comportement historique.
  /// [stoolTexture]: consistency of the stool; ignored for urination.
  Future<void> track({
    required TrackingType type,
    String? notes,
    double? duration,
    double? quantity,
    QuantityUnit? unit,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
    StoolTexture? stoolTexture,
    FeedingSubtype? feedingSubtype,
    HealthSubtype? healthSubtype,
    DateTime? timestamp,
  }) async {
    // Get active baby ID
    final activeBaby = ref.read(activeBabyProvider).value;
    final babyId = activeBaby?.id;
    final eventDate = timestamp ?? DateTime.now();

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(trackingRepositoryProvider.future);
      final feedingSubtypeOrNull = feedingSubtype ?? FeedingSubtype.natural;
      final event = switch (type) {
        TrackingType.miam => TrackingEvent.feeding(
            timestamp: eventDate,
            babyId: babyId,
            subtype: feedingSubtypeOrNull,
            // The parent chooses "ml" or "min" within the context; the dialogue proceeds accordingly.
            // Otherwise: the consistency of the subtype is not a matter of guesswork.
            unit: unit ??
                defaultUnitFor(
                  typeValue: db_const.typeMiam,
                  subtypeValue: feedingSubtypeOrNull.dbValue,
                ),
            quantity: quantity,
            notes: notes,
          ),
        TrackingType.dodo => TrackingEvent.sleep(
            timestamp: eventDate,
            babyId: babyId,
            duration: duration?.toDouble() ?? 0.0,
            unit: unit ?? QuantityUnit.min,
            quantity: quantity,
            notes: notes,
          ),
        TrackingType.caca => TrackingEvent.diaper(
            timestamp: eventDate,
            babyId: babyId,
            wasteType: wasteType,
            pipiColor: pipiColor,
            cacaColor: cacaColor,
            stoolTexture: stoolTexture,
            notes: notes,
          ),
        TrackingType.sante => HealthEvent(
            timestamp: eventDate,
            babyId: babyId,
            subtype: healthSubtype ?? HealthSubtype.nettoyageYeux,
            notes: notes,
          ),
      };
      await repository.insertEvent(event);
    });
  }
}
