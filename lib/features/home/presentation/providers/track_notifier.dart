import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_provider.dart';

final trackNotifierProvider = AsyncNotifierProvider<TrackNotifier, void>(
  TrackNotifier.new,
);

class TrackNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async => null;

  Future<void> track({
    required String type,
    String? notes,
    double? duration,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trackingRepositoryProvider);
      await repository.insertEvent(
        type: type,
        notes: notes,
        duration: duration,
      );
    });
  }
}

