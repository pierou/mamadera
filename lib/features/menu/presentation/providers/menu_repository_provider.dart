import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/repositories/menu_repository.dart';

/// Riverpod provider that exposes a [MenuRepository] instance.
/// Uses constructor injection of LocaleService, ThemeService, and AppDatabase
/// instead of passing Ref to the data layer.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final localeService = ref.watch(localeServiceProvider);
  final themeService = ref.watch(themeServiceProvider);
  return MenuRepositoryImpl(
    localeService: localeService,
    themeService: themeService,
    databaseFuture: ref.watch(databaseProvider.future),
  );
});
