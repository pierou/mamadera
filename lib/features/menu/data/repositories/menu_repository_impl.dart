import '../../../../core/services/locale_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../data/local/app_db.dart';
import '../../../../data/local/database.dart' as db_reset;
import '../../domain/repositories/menu_repository.dart';

/// Concrete implementation of [MenuRepository] using constructor injection.
/// Decoupled from Riverpod — injects [LocaleService], [ThemeService], and resolves [AppDatabase] lazily.
class MenuRepositoryImpl implements MenuRepository {
  const MenuRepositoryImpl({
    required this.localeService,
    required this.themeService,
    required Future<AppDatabase> databaseFuture,
    String? directoryPath,
  }) : _databaseFuture = databaseFuture,
       _directoryPath = directoryPath;

  final LocaleService localeService;
  final ThemeService themeService;
  final Future<AppDatabase> _databaseFuture;

  /// Optional override for the database directory path (used in tests).
  final String? _directoryPath;

  @override
  Future<String> getCurrentLanguage() async {
    try {
      final pref = await localeService.load();
      return pref?.languageCode ?? 'fr';
    } catch (_) {
      return 'fr';
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    if (!getSupportedLanguages().contains(languageCode)) return;
    final current = (await localeService.load()) ?? const LocalePreference(
      languageCode: 'fr',
      isManualOverride: false,
    );
    final updated = current.copyWith(
      languageCode: languageCode,
      isManualOverride: true,
    );
    await localeService.save(updated);
  }

  @override
  Future<String> getCurrentThemeMode() async {
    try {
      final pref = await themeService.load();
      return pref?.mode ?? 'system';
    } catch (_) {
      return 'system';
    }
  }

  @override
  Future<void> setThemeMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) return;
    await themeService.save(ThemePreference(mode: mode));
  }

  @override
  List<String> getSupportedLanguages() => List.unmodifiable(['fr', 'en', 'es']);

  @override
  Future<void> resetDatabase() async {
    // Fermer la base de données si elle est déjà initialisée
    try {
      final db = await _databaseFuture;
      await db.close();
    } catch (_) {
      // Database may already be closed or not yet initialized — ignore.
    }
    // Supprimer le fichier physique SQLite
    await db_reset.resetDatabase(directoryPath: _directoryPath);
  }
}
