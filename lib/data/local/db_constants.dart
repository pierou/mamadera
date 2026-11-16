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

// ── The v14 vitamin D seed (BACKLOG B6, PLAN-v1.4.0 D-R1) ───────────────────

/// The statement that gives every **pre-existing scope** an explicit
/// `enabled = 1` vitamin D row when it has none.
///
/// Lives here, next to the other permanently engraved values, because two
/// different code paths need the *identical* statement:
///
/// * the schema v13 → v14 migration, where it is what keeps an existing parent's
///   reminder on while the app's default flips to off (B6);
/// * the backup restore, for documents written **before export format 5**: in
///   those files an absent vitamin D row still meant "on", and the restore
///   deletes every row before inserting, so replaying such a file without this
///   statement would silently switch the reminder off on a parent who never
///   turned it off.
///
/// INSERT-only and guarded by `NOT EXISTS`: it writes `enabled = 1` or nothing,
/// never 0, and never touches a row that exists — a parent who turned the
/// reminder off keeps it off. Idempotent by construction.
const String vitaminDSeedInsert = '''
  INSERT INTO reminder_settings (baby_id, item_id, enabled)
  SELECT s.baby_id, 'vitamine_d', 1
  FROM (SELECT '' AS baby_id UNION ALL SELECT id FROM baby_profiles) s
  WHERE NOT EXISTS (
    SELECT 1 FROM reminder_settings r
    WHERE r.baby_id = s.baby_id AND r.item_id = 'vitamine_d'
  )
''';

// ── Custom reminder frequency codes (match `custom_reminders.frequency`,
//    and from v14 `reminder_settings.frequency`) ───

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

/// Single occurrence on a date (B33 Part 1, D-R5 form 1) — the date itself is
/// the occurrence, stored in `frequency_date`. Never a rhythm: once settled the
/// reminder is done (D-R7), which is why this code needs its companion column
/// and nothing else.
const String freqOneTime = 'one_time';

/// All valid frequency codes. The importer validates against this set.
const Set<String> allFrequencyValues = {
  freqDaily,
  freqWeekly,
  freqMonthly,
  freqEveryNDays,
  freqOneTime,
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
