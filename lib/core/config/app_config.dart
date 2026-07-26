/// Application configuration constants.
class AppConfig {
  AppConfig._();

  /// The app's display version (e.g. '1.0.0').
  ///
  /// This is the canonical source of truth. At runtime, the version is also
  /// read from `package_info_plus` and compared against this value to detect
  /// updates for patch notes.
  static const String version = '1.0.0';
}
