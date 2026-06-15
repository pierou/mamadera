import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/tracking_enums.dart';
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
  Future<void> track({
    required TrackingType type,
    String? notes,
    double? duration,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // trackingRepositoryProvider est un FutureProvider → on attend l'instance.
      final repository = await ref.read(trackingRepositoryProvider.future);
      await repository.insertEvent(
        type: type,
        notes: notes,
        duration: duration,
        wasteType: wasteType,
        pipiColor: pipiColor,
        cacaColor: cacaColor,
      );
    });
  }
}


