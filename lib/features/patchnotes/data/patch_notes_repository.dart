import 'dart:convert';

import 'package:flutter/services.dart';

/// Repository that loads patch notes from locale-specific JSON assets.
class PatchNotesRepository {
  /// Loads patch notes JSON for the given locale.
  Future<Map<String, dynamic>> loadPatchNotes(String locale) async {
    String assetPath;
    switch (locale) {
      case 'en':
        assetPath = 'assets/patch_notes/en.json';
      case 'es':
        assetPath = 'assets/patch_notes/es.json';
      default:
        assetPath = 'assets/patch_notes/fr.json';
    }

    final raw = await rootBundle.loadString(assetPath);
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }
}
