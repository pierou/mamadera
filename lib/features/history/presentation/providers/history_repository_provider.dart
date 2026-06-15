import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/encryption_provider.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';

/// Le repository dépend de la DB asynchrone → FutureProvider.
final historyRepositoryProvider = FutureProvider<HistoryRepository>(
  (ref) async {
    final encryption = ref.watch(encryptionServiceProvider);
    final database = await ref.watch(databaseProvider.future);
    return HistoryRepositoryImpl(
      encryption: encryption,
      database: database,
    );
  },
);

