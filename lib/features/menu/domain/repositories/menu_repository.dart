/// Repository interface pour le module menu (paramètres : langue + thème)
abstract class MenuRepository {
  /// Retourne le code de langue actuel (ex: 'fr', 'en').
  String getCurrentLanguage();

  /// Définit la langue.
  Future<void> setLanguage(String languageCode);

  /// Retourne le mode de thème actuel (ex: 'system', 'light', 'dark').
  String getCurrentThemeMode();

  /// Définit le mode de thème.
  Future<void> setThemeMode(String mode);

  /// Retourne la liste des langues supportées.
  List<String> getSupportedLanguages();
}
