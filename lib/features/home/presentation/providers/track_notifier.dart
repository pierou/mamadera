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
  /// [feedingSubtype] est requis pour FeedingEvent (natural/artificial).
  /// [healthSubtype] est requis pour HealthEvent (nettoyageYeux, etc.).
  /// [timestamp] est le moment où l'événement s'est produit ; il permet de
  /// saisir a posteriori (sieste terminée, change fait dans l'autre pièce).
  /// `null` = maintenant, comportement historique.
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
    DateTime? timestamp,
  }) async {
    // Get active baby ID
    final activeBaby = ref.read(activeBabyProvider).value;
    final babyId = activeBaby?.id;
    final eventDate = timestamp ?? DateTime.now();

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(trackingRepositoryProvider.future);
      final event = switch (type) {
        TrackingType.miam => TrackingEvent.feeding(
            timestamp: eventDate,
            babyId: babyId,
            subtype: feedingSubtype ?? FeedingSubtype.natural,
            quantity: quantity,
            notes: notes,
          ),
        TrackingType.dodo => TrackingEvent.sleep(
            timestamp: eventDate,
            babyId: babyId,
            duration: duration?.toDouble() ?? 0.0,
            quantity: quantity,
            notes: notes,
          ),
        TrackingType.caca => TrackingEvent.diaper(
            timestamp: eventDate,
            babyId: babyId,
            wasteType: wasteType,
            pipiColor: pipiColor,
            cacaColor: cacaColor,
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


