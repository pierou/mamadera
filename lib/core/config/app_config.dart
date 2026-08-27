/// Application configuration constants.
class AppConfig {
  AppConfig._();

  /// The app's display version (e.g. '1.0.1').
  ///
  /// Must stay in sync with `version:` in `pubspec.yaml` (enforced in CI).
  /// Used to detect app updates for the patch-notes dialog and displayed
  /// on the About and feedback screens.
  static const String version = '1.0.1';

  /// Contact email for bug reports and feature requests.
  static const String contactEmail = 'support@pvj.io';

  /// GitHub repository URL for issue tracking.
  static const String githubIssuesUrl = 'https://github.com/pierou/mamadera/issues/new';
}
