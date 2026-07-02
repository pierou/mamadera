import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/baby_profile_repository_impl.dart';
import '../../domain/repositories/baby_profile_repository.dart';

/// Provider for the baby profile repository implementation.
final babyProfileRepositoryProvider = FutureProvider<BabyProfileRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return BabyProfileRepositoryImpl(database: database);
});
