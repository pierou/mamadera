import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/encryption_provider.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) {
    final encryption = ref.watch(encryptionServiceProvider);
    return HistoryRepositoryImpl(encryption: encryption);
  },
);
