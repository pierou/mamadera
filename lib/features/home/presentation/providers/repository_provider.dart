import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/encryption_provider.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../domain/repositories/tracking_repository.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) {
    final encryption = ref.watch(encryptionServiceProvider);
    return TrackingRepositoryImpl(encryption: encryption);
  },
);
