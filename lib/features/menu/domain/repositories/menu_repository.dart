/// Repository interface for the menu module (parameters: language + theme).
abstract class MenuRepository {
  /// Retourne le code de langue actuel (ex: 'fr', 'en').
  Future<String> getCurrentLanguage();

  /// Defines the language and saves the selection to the disk.
  Future<void> setLanguage(String languageCode);

  /// Returns the current theme mode (e.g., 'system', 'light', 'dark').
  Future<String> getCurrentThemeMode();

  /// Defines the theme mode and saves the selected option to disk.
  Future<void> setThemeMode(String mode);

  /// Returns a list of supported languages.
  List<String> getSupportedLanguages();

  /// Resets the database (deletes the physical SQLite file).
  Future<void> resetDatabase();
}
