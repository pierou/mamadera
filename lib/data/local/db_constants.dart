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

// Permanently engraved: renaming them would change the meaning of each installation.
// existing, and they are read again as is in a backup JSON file.
// They live here, and not in the repository for reminders, because the importer...
// The backup system must be able to validate these codes without relying on the data layer of a specific system.
// autre feature.

/// Rythme quotidien.
const String freqDaily = 'daily';

/// Rythme hebdomadaire.
const String freqWeekly = 'weekly';

/// Monthly cycle (based on the baby's date of birth).
const String freqMonthly = 'monthly';

/// Rythme glissant de `interval_days` jours.
const String freqEveryNDays = 'every_n_days';

/// All rhythm codes are written in the base game and are also saved.
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

/// "Sentinelle" is a "profile-less" key system for composite keys (baby_id, item_id).
/// NULL is **not** used: SQLite allows it in a composite PRIMARY KEY.
/// et l'autorise en double.
///
/// The lines marked with `''` represent the state of the app **without an active baby profile**.
/// (Installation is performed before any profile is created, or it can be switched on during the loading process.)
/// These principles do not apply to any real baby; a baby only inherits traits from its...
/// distinct lines — and a baby born later cannot "inherit" from them.
/// (The "all babies" sharing feature in version 10 caused settings to leak, which were then ignored.)
/// and manual adjustments for a baby on the following setting).
const String sharedBabyId = '';
