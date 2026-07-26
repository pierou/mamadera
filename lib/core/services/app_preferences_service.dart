import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'locale_service.dart' show LocaleService;
import 'theme_service.dart' show ThemeService;

/// Callback type for resolving the data directory.
typedef DirectoryResolver = FutureOr<Directory> Function();

/// Lightweight persistence layer for app-wide preferences (T&C acceptance,
/// patch notes opt-out, last seen version).
///
/// Stores data as a small JSON file in the application documents directory,
/// following the same pattern as [LocaleService] and [ThemeService].
class AppPreferencesService {
  AppPreferencesService({DirectoryResolver? directoryResolver})
      : _directoryResolver = directoryResolver;

  static const _fileName = '.mamadera_prefs.json';
  final DirectoryResolver? _directoryResolver;
  Directory? _cacheDir;

  Future<Directory> _getCacheDir() async {
    if (_cacheDir case final dir?) return dir;
    final dir = await (_directoryResolver?.call() ?? getApplicationDocumentsDirectory());
    _cacheDir = dir;
    return dir;
  }

  File _getPrefsFile(Directory dir) => File('${dir.path}/$_fileName');

  /// Loads persisted preferences, or `null` if none saved.
  Future<AppPreferences?> load() async {
    try {
      final file = _getPrefsFile(await _getCacheDir());
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppPreferences(
        appVersion: map['appVersion'] as String? ?? '',
        termsAccepted: map['termsAccepted'] as bool? ?? false,
        patchNotesOptOut: map['patchNotesOptOut'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves preferences to disk.
  Future<void> save(AppPreferences preferences) async {
    final file = _getPrefsFile(await _getCacheDir());
    await file.writeAsString(
      jsonEncode({
        'appVersion': preferences.appVersion,
        'termsAccepted': preferences.termsAccepted,
        'patchNotesOptOut': preferences.patchNotesOptOut,
      }),
    );
  }

  /// Clears persisted preferences (useful for testing).
  Future<void> clear() async {
    final file = _getPrefsFile(await _getCacheDir());
    if (await file.exists()) await file.delete();
  }
}

/// Persisted app preferences.
class AppPreferences {
  const AppPreferences({
    required this.appVersion,
    required this.termsAccepted,
    required this.patchNotesOptOut,
  });

  /// Last app version that showed patch notes (from pubspec).
  final String appVersion;

  /// Whether the user has accepted the Terms & Conditions.
  final bool termsAccepted;

  /// Whether the user opted out of seeing patch notes forever.
  final bool patchNotesOptOut;

  AppPreferences copyWith({
    String? appVersion,
    bool? termsAccepted,
    bool? patchNotesOptOut,
  }) =>
      AppPreferences(
        appVersion: appVersion ?? this.appVersion,
        termsAccepted: termsAccepted ?? this.termsAccepted,
        patchNotesOptOut: patchNotesOptOut ?? this.patchNotesOptOut,
      );

  Map<String, dynamic> toMap() => {
        'appVersion': appVersion,
        'termsAccepted': termsAccepted,
        'patchNotesOptOut': patchNotesOptOut,
      };

  @override
  String toString() => 'AppPreferences($appVersion, termsAccepted: $termsAccepted, patchNotesOptOut: $patchNotesOptOut)';
}
