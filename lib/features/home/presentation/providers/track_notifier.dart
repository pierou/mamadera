import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
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

  /// Enregistre un événement de suivi (tétée, sommeil, couche, santé).
  /// [duration] est en minutes pour dodo/sommeil.
  /// [quantity] est le volume en ml (feeding) ou minutes (sleep).
  /// [wasteType], [pipiColor] et [cacaColor] sont utilisés uniquement pour les selles.
  /// [feedingSubtype] est requis pour FeedingEvent (sein/bib).
  /// [healthSubtype] est requis pour HealthEvent (nettoyageYeux, etc.).
  Future<void> track({
    required TrackingType type,
    String? notes,
    double? duration,
    double? quantity,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
    FeedingSubtype? feedingSubtype,
    HealthSubtype? healthSubtype,
  }) async {
    // Get active baby ID
    final activeBaby = ref.read(activeBabyProvider).value;
    final babyId = activeBaby?.id;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(trackingRepositoryProvider.future);
      final event = switch (type) {
        TrackingType.miam => TrackingEvent.feeding(
            timestamp: DateTime.now(),
            babyId: babyId,
            subtype: feedingSubtype ?? FeedingSubtype.sein,
            duration: duration?.toDouble() ?? 0.0,
            quantity: quantity,
            notes: notes,
          ),
        TrackingType.dodo => TrackingEvent.sleep(
            timestamp: DateTime.now(),
            babyId: babyId,
            duration: duration?.toDouble() ?? 0.0,
            quantity: quantity,
            notes: notes,
          ),
        TrackingType.caca => TrackingEvent.diaper(
            timestamp: DateTime.now(),
            babyId: babyId,
            wasteType: wasteType,
            pipiColor: pipiColor,
            cacaColor: cacaColor,
            notes: notes,
          ),
        TrackingType.sante => HealthEvent(
            timestamp: DateTime.now(),
            babyId: babyId,
            subtype: healthSubtype ?? HealthSubtype.nettoyageYeux,
            notes: notes,
          ),
      };
      await repository.insertEvent(event);
    });
  }
}


