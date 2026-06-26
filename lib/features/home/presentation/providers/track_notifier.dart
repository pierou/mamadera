import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  /// [wasteType], [pipiColor] et [cacaColor] sont utilisés uniquement pour les selles.
  /// [feedingSubtype] est requis pour FeedingEvent (sein/bib).
  /// [healthSubtype] est requis pour HealthEvent (nettoyageYeux, etc.).
  Future<void> track({
    required TrackingType type,
    String? notes,
    double? duration,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
    FeedingSubtype? feedingSubtype,
    HealthSubtype? healthSubtype,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(trackingRepositoryProvider.future);
      final event = switch (type) {
        TrackingType.miam => FeedingEvent(
            timestamp: DateTime.now(),
            subtype: feedingSubtype ?? FeedingSubtype.sein,
            duration: duration?.toDouble() ?? 0.0,
            notes: notes,
          ),
        TrackingType.dodo => SleepEvent(
            timestamp: DateTime.now(),
            duration: duration?.toDouble() ?? 0.0,
            notes: notes,
          ),
        TrackingType.caca => DiaperEvent(
            timestamp: DateTime.now(),
            wasteType: wasteType,
            pipiColor: pipiColor,
            cacaColor: cacaColor,
            notes: notes,
          ),
        TrackingType.sante => HealthEvent(
            timestamp: DateTime.now(),
            subtype: healthSubtype ?? HealthSubtype.nettoyageYeux,
            notes: notes,
          ),
      };
      await repository.insertEvent(event);
    });
  }
}


