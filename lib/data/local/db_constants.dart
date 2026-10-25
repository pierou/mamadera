/// Shared constants for DB column values (type strings, etc.).
/// Single source of truth — used by the event mapper and repository impls.
library;

// ── Type value constants (match TrackingType enum names) ────────────────

const String typeMiam = 'miam';
const String typeSante = 'sante';
const String typeCaca = 'caca';
const String typeDodo = 'dodo';

/// All valid type values for the `type` column.
const Set<String> allTypeValues = {
  typeMiam,
  typeSante,
  typeCaca,
  typeDodo,
};

// ── Custom reminder frequency codes (match `custom_reminders.frequency`) ───

// Permanently engraved in existing databases and read back verbatim from
// backup JSON files: renaming one would silently change the meaning of every
// installation. They live here, not in the reminders repository, because the
// backup importer must be able to validate these codes without depending on
// the reminders data layer.

/// Daily rhythm (due every calendar day).
const String freqDaily = 'daily';

/// Weekly rhythm (due in the ISO week after the last completed week).
const String freqWeekly = 'weekly';

/// Monthly cycle (based on the baby's date of birth).
const String freqMonthly = 'monthly';

/// Sliding rhythm: due every `interval_days` days after the last completion.
const String freqEveryNDays = 'every_n_days';

/// All valid frequency codes. The importer validates against this set.
const Set<String> allFrequencyValues = {
  freqDaily,
  freqWeekly,
  freqMonthly,
  freqEveryNDays,
};

// ── Growth measurement kinds (`measurements.kind`) ─────────────────────
const String kindPoids = 'poids';
const String kindTaille = 'taille';
const String kindTemperature = 'temperature';
const Set<String> allMeasureKindValues = {
  kindPoids,
  kindTaille,
  kindTemperature
};

// Units — metric only in v1.2.0, no °F.
const String unitG = 'g';
const String unitCm = 'cm';
const String unitDegC = 'degC';

// Units of `tracking_events.unit` — v12. `g` is shared with measurements:
// one vocabulary for both tables, so a backup never carries two spellings of
// the same unit.
const String unitMl = 'ml';
const String unitMin = 'min';

/// Every unit an event row may carry. The importer validates against this set.
const Set<String> allEventUnitValues = {unitMl, unitMin, unitG};

/// Feeding subtypes (`tracking_events.subtype` where `type = 'miam'`).
const String subtypeNatural = 'natural';
const String subtypeArtificial = 'artificial';
const String subtypeSolid = 'solid';

// ── Reminder completion source (`custom_reminders.completion_source`) ──
const String completionFromEvents =
    'from_events'; // a `sante` event of subtype settles it
const String completionManual =
    'manual'; // a tap on reminder_completions settles it
const Set<String> allCompletionSourceValues = {
  completionFromEvents,
  completionManual
};

/// The "profileless" sentinel for the composite keys `(baby_id, item_id)`.
/// NULL is **not** used: SQLite allows NULL in a table-level composite
/// PRIMARY KEY and lets it repeat — an empty string cannot.
///
/// Rows under `''` hold the app's state **without any baby profile** (the
/// installation before the first profile is created, or the state visible
/// while no profile is active). They belong to no real baby: switching to a
/// profile never reads them, and a baby born later cannot "inherit" them
/// (the v10 "all babies" sharing that leaked settings and dismissals across
/// babies is what the isolation of v11/v12 fixed).
const String sharedBabyId = '';

// ── App settings keys (`app_settings.key`, schema v13) ──────────────────

/// Opt-in flag for system notifications: `'1'` = enabled, `'0'` (or a
/// missing row) = disabled. A missing row always reads as disabled.
const String settingsKeyNotificationsOptIn = 'notifications_opt_in';

/// Preferred time of day for reminder notifications, `'HH:mm'` (24-hour,
/// device-local). A missing row reads as [defaultNotificationTime].
const String settingsKeyNotificationTime = 'notification_time_of_day';

/// Default value of [settingsKeyNotificationTime] when no row exists.
const String defaultNotificationTime = '09:00';
