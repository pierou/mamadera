import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Callback type for resolving the data directory.
typedef DirectoryResolver = FutureOr<Directory> Function();

/// Lightweight persistence layer for theme preference.
/// Stores the selected theme mode as a small JSON file.
class ThemeService {
  final String _fileName = '.mamadera_theme.json';

  /// Optional directory resolver for testing (defaults to [getApplicationDocumentsDirectory]).
  final DirectoryResolver? _directoryResolver;

  /// Cached data directory — resolved on first access.
  Directory? _cacheDir;

  // ignore: sort_constructors_first
  ThemeService({DirectoryResolver? directoryResolver})
      : _directoryResolver = directoryResolver;

  Future<Directory> _getCacheDir() async {
    if (_cacheDir case final dir?) return dir;
    final dir = await (_directoryResolver?.call() ?? getApplicationDocumentsDirectory());
    _cacheDir = dir;
    return dir;
  }

  File _getThemeFile(Directory dir) => File('${dir.path}/$_fileName');

  /// Loads persisted theme preference, or `null` if none saved.
  Future<ThemePreference?> load() async {
    try {
      final file = _getThemeFile(await _getCacheDir());
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ThemePreference(
        mode: map['themeMode'] as String? ?? 'system',
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves theme preference to disk.
  Future<void> save(ThemePreference preference) async {
    final file = _getThemeFile(await _getCacheDir());
    await file.writeAsString(jsonEncode({'themeMode': preference.mode}));
  }

  /// Clears persisted theme data (useful for testing).
  Future<void> clear() async {
    final file = _getThemeFile(await _getCacheDir());
    if (await file.exists()) await file.delete();
  }
}

/// Persisted user theme preference.
class ThemePreference {
  const ThemePreference({required this.mode});

  /// One of `'system'`, `'light'`, or `'dark'`.
  final String mode;

  ThemePreference copyWith({String? mode}) =>
      ThemePreference(mode: mode ?? this.mode);

  Map<String, dynamic> toMap() => {'themeMode': mode};

  @override
  String toString() => 'ThemePreference($mode)';
}
