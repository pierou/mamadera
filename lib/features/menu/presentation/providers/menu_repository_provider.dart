import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/repositories/menu_repository.dart';

/// Riverpod provider that exposes a [MenuRepository] instance.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(ref);
});
