import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../data/local/database.dart' as db_reset;
import '../../domain/repositories/menu_repository.dart';

/// Concrete implementation of [MenuRepository] that delegates to the core services via Riverpod providers.
class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  String getCurrentLanguage() {
    return _ref
        .read(localeProvider)
        .maybeWhen(
          data: (pref) => pref.languageCode,
          loading: () => 'fr',
          error: (_, __) => 'fr',
          orElse: () => 'fr',
        );
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    if (!getSupportedLanguages().contains(languageCode)) return;
    final notifier = _ref.read(localeProvider.notifier);
    await notifier.setLocale(languageCode);
  }

  @override
  String getCurrentThemeMode() {
    return _ref
        .read(themeProvider)
        .maybeWhen(
          data: (pref) => pref.mode,
          loading: () => 'system',
          error: (_, __) => 'system',
          orElse: () => 'system',
        );
  }

  @override
  Future<void> setThemeMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) return;
    final notifier = _ref.read(themeProvider.notifier);
    await notifier.setMode(mode);
  }

  @override
  List<String> getSupportedLanguages() => List.unmodifiable(['fr', 'en']);

  @override
  Future<void> resetDatabase() async {
    // Fermer la base de données si elle est déjà initialisée
    final db = await _ref.read(databaseProvider.future);
    await db.close();
    // Supprimer le fichier physique SQLite
    await db_reset.resetDatabase();
    // Invalider le provider pour forcer une reconstruction fraîche au prochain accès
    _ref.invalidate(databaseProvider);
  }
}
