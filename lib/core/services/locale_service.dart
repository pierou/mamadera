import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Callback type for resolving the data directory.
typedef DirectoryResolver = FutureOr<Directory> Function();

/// Lightweight persistence layer for locale preference.
/// Stores language code and manual override flag as a small JSON file.
class LocaleService {
  final String _fileName = '.mamadera_locale.json';

  /// Optional directory resolver for testing (defaults to [getApplicationDocumentsDirectory]).
  final DirectoryResolver? _directoryResolver;

  /// Cached data directory — resolved on first access.
  Directory? _cacheDir;

  // ignore: sort_constructors_first
  LocaleService({DirectoryResolver? directoryResolver})
      : _directoryResolver = directoryResolver;

  Future<Directory> _getCacheDir() async {
    if (_cacheDir case final dir?) return dir;
    final dir = await (_directoryResolver?.call() ?? getApplicationDocumentsDirectory());
    _cacheDir = dir;
    return dir;
  }

  File _getLocaleFile(Directory dir) => File('${dir.path}/$_fileName');

  /// Loads persisted locale preference, or `null` if none saved.
  Future<LocalePreference?> load() async {
    try {
      final file = _getLocaleFile(await _getCacheDir());
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LocalePreference(
        languageCode: map['languageCode'] as String? ?? 'fr',
        isManualOverride: map['isManualOverride'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves locale preference to disk.
  Future<void> save(LocalePreference preference) async {
    final file = _getLocaleFile(await _getCacheDir());
    await file.writeAsString(
      jsonEncode({
        'languageCode': preference.languageCode,
        'isManualOverride': preference.isManualOverride,
      }),
    );
  }

  /// Clears persisted locale data (useful for testing).
  Future<void> clear() async {
    final file = _getLocaleFile(await _getCacheDir());
    if (await file.exists()) await file.delete();
  }
}

/// Persisted user language preference.
class LocalePreference {
  const LocalePreference({
    required this.languageCode,
    required this.isManualOverride,
  });

  /// BCP 47 language code (e.g. 'fr', 'en').
  final String languageCode;

  /// `true` if the user explicitly selected this locale, falling back to
  /// device auto-detection otherwise.
  final bool isManualOverride;

  LocalePreference copyWith({
    String? languageCode,
    bool? isManualOverride,
  }) {
    return LocalePreference(
      languageCode: languageCode ?? this.languageCode,
      isManualOverride: isManualOverride ?? this.isManualOverride,
    );
  }

  Map<String, dynamic> toMap() => {
        'languageCode': languageCode,
        'isManualOverride': isManualOverride,
      };

  @override
  String toString() => 'LocalePreference($languageCode, override: $isManualOverride)';
}
