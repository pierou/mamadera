part of 'import_repository_impl.dart';

// ── Field extraction ─────────────────────────────────────────────────────
//
// Explicit helpers rather than `as` casts everywhere: the analyzer runs with
// strict-casts/strict-raw-types, and every rejection must name its section so
// the parent gets "the file is malformed" and not a Dart type message.

String _requiredString(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value is! String || value.isEmpty) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

String? _optionalString(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

int _requiredInt(Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value is! int) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

int? _optionalPositiveInt(
    Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! int || value < 1) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

double? _optionalFiniteDouble(
    Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return null;
  if (value is! num) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final converted = value.toDouble();
  if (!converted.isFinite) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return converted;
}

bool _boolWithTrueDefault(
    Map<String, dynamic> row, String key, String section) {
  final value = row[key];
  if (value == null) return true;
  if (value is! bool) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return value;
}

/// Instant stored as epoch SECONDS, with the ISO twin as fallback.
DateTime _seconds(
    Map<String, dynamic> row, String epochKey, String isoKey, String section) {
  final epoch = row[epochKey];
  if (epoch is int) {
    return _checkRange(
        DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true),
        section);
  }
  if (epoch == null) {
    final iso = row[isoKey];
    if (iso is String) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) return _checkRange(parsed, section);
    }
  }
  throw ImportFormatException(ImportRejectionReason.invalidRow,
      section: section);
}

/// Instant stored as epoch MILLISECONDS (`baby_profiles.birth_date`), with the
/// ISO twin as fallback.
int _milliseconds(
    Map<String, dynamic> row, String epochKey, String isoKey, String section) {
  final epoch = row[epochKey];
  if (epoch is int) {
    _checkRange(
        DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true), section);
    return epoch;
  }
  if (epoch == null) {
    final iso = row[isoKey];
    if (iso is String) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) {
        _checkRange(parsed, section);
        return parsed.millisecondsSinceEpoch;
      }
    }
  }
  throw ImportFormatException(ImportRejectionReason.invalidRow,
      section: section);
}

/// Rejects instants outside 1990-2100: a wrong unit (milliseconds where seconds
/// were expected, a hand-edited value) lands there, and restoring it would put
/// a baby event in 1970 with nothing raised to notice.
DateTime _checkRange(DateTime moment, String section) {
  final utc = moment.toUtc();
  if (utc.isBefore(_plausibleMin) || !utc.isBefore(_plausibleMax)) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  return moment;
}

void _requireUnique(Object id, Set<Object> seen, String section) {
  if (!seen.add(id)) {
    throw ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
}

/// Deterministic `(birthDate, id)` ordering, the same one
/// `AppDatabase.getActiveBabyProfile` uses to pick the active profile.
ImportedBabyProfile _firstByBirthDateThenId(
    List<ImportedBabyProfile> profiles) {
  var first = profiles.first;
  for (final candidate in profiles) {
    final earlier = candidate.birthDateEpochMs < first.birthDateEpochMs ||
        (candidate.birthDateEpochMs == first.birthDateEpochMs &&
            candidate.id.compareTo(first.id) < 0);
    if (earlier) first = candidate;
  }
  return first;
}
