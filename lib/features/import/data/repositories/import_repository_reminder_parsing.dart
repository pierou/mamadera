part of 'import_repository_impl.dart';

// The `reminderSettings` / `reminderDismissals` row parsers, split out of the
// importer's body. The honest reason is not the 800-line ratchet in
// `scripts/check_architecture.py` but what B33 did to this row: six more optional
// keys, each with a pairing rule of its own (an end on a one-shot, an occurrence
// date on a daily, both end forms at once), which reads better on its own page
// than as the tail of a file about the whole backup format.

ImportedReminderSetting _parseSetting(
    Map<String, dynamic> row, Set<Object> seenKeys) {
  const section = 'reminderSettings';
  // Absent (format 1): Setting shared by all babies.
  final babyId =
      _optionalString(row, 'babyId', section) ?? db_const.sharedBabyId;
  final itemId = _requiredString(row, 'itemId', section);
  _requireUnique((babyId, itemId), seenKeys, section);
  final enabled = row['enabled'];
  if (enabled is! bool) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  // Absent (every file before format 5) = inherit the global hour. Present but
  // not a real `HH:mm` is refused, not repaired: the app's read side is lax (it
  // falls back to the global hour), but a file is a one-shot restore and an hour
  // that does not exist would schedule a notification nobody asked for. The
  // importer applies the same rule to the global hour (`appSettings`).
  final timeOfDay = _optionalString(row, 'timeOfDay', section);
  if (timeOfDay != null && !isValidNotificationTime(timeOfDay)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  // B33 (format 5): the rest of the row. Optional keys, validated when present —
  // and the same pairing rules the picker enforces, because a file that carries
  // an end *and* a one-shot says two things about one reminder.
  final label = _optionalString(row, 'label', section);
  if (label != null && (label.isEmpty || label.length > _maxLabelLength)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final frequency = _optionalString(row, 'frequency', section);
  if (frequency != null && !db_const.allFrequencyValues.contains(frequency)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final frequencyDate = _optionalString(row, 'frequencyDate', section);
  final endDate = _optionalString(row, 'endDate', section);
  if (frequencyDate != null && parseCalendarDate(frequencyDate) == null ||
      endDate != null && parseCalendarDate(endDate) == null) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  if (frequency == db_const.freqOneTime && frequencyDate == null ||
      frequency != db_const.freqOneTime && frequencyDate != null) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final endAgeMonths = _optionalInt(row, 'endAgeMonths', section);
  if (endAgeMonths != null &&
          (endAgeMonths < 0 || endAgeMonths > maxReminderEndAgeMonths) ||
      // D-R5: at most one end form per row, here as at the write.
      endDate != null && endAgeMonths != null ||
      // A one-shot has an occurrence, never an end.
      frequency == db_const.freqOneTime &&
          (endDate != null || endAgeMonths != null)) {
    throw const ImportFormatException(ImportRejectionReason.invalidRow,
        section: section);
  }
  final removed = _optionalBool(row, 'removed', section);

  return ImportedReminderSetting(
    babyId: babyId,
    itemId: itemId,
    enabled: enabled,
    timeOfDay: timeOfDay,
    label: label,
    frequency: frequency,
    intervalDays: _optionalPositiveInt(row, 'intervalDays', section),
    frequencyDate: frequencyDate,
    endDate: endDate,
    endAgeMonths: endAgeMonths,
    removed: removed ?? false,
  );
}

ImportedReminderDismissal _parseDismissal(
    Map<String, dynamic> row, Set<Object> seenKeys) {
  const section = 'reminderDismissals';
  // Absent (format 1): Shared rejection among all the babies.
  final babyId =
      _optionalString(row, 'babyId', section) ?? db_const.sharedBabyId;
  final itemId = _requiredString(row, 'itemId', section);
  _requireUnique((babyId, itemId), seenKeys, section);
  return ImportedReminderDismissal(
    babyId: babyId,
    itemId: itemId,
    dismissedAt:
        _seconds(row, 'dismissedAtEpochSeconds', 'dismissedAtUtc', section),
  );
}
