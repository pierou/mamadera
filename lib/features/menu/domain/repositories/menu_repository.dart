/// Repository interface pour le module menu (paramètres : langue + thème)
abstract class MenuRepository {
  /// Retourne le code de langue actuel (ex: 'fr', 'en').
  Future<String> getCurrentLanguage();

  /// Définit la langue et persiste le choix sur disque.
  Future<void> setLanguage(String languageCode);

  /// Retourne le mode de thème actuel (ex: 'system', 'light', 'dark').
  Future<String> getCurrentThemeMode();

  /// Définit le mode de thème et persiste le choix sur disque.
  Future<void> setThemeMode(String mode);

  /// Retourne la liste des langues supportées.
  List<String> getSupportedLanguages();

  /// Réinitialise la base de données (supprime le fichier SQLite physique).
  Future<void> resetDatabase();
}
