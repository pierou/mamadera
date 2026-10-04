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

// Gravés en dur : les renommer changerait de sens chaque installation
// existante, et ils se relisent tels quels dans un JSON de sauvegarde. Ils
// vivent ici, et non dans le repository des rappels, parce que l'importateur
// de sauvegarde doit valider ces codes sans dépendre de la couche data d'une
// autre feature.

/// Rythme quotidien.
const String freqDaily = 'daily';

/// Rythme hebdomadaire.
const String freqWeekly = 'weekly';

/// Rythme mensuel (jour de naissance du bébé actif).
const String freqMonthly = 'monthly';

/// Rythme glissant de `interval_days` jours.
const String freqEveryNDays = 'every_n_days';

/// Tous les codes de rythme écrits en base et dans les sauvegardes.
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
const Set<String> allMeasureKindValues = {kindPoids, kindTaille, kindTemperature};

// Units — metric only in v1.2.0, no °F.
const String unitG = 'g';
const String unitCm = 'cm';
const String unitDegC = 'degC';

// ── Reminder completion source (`custom_reminders.completion_source`) ──
const String completionFromEvents = 'from_events'; // a `sante` event of subtype settles it
const String completionManual = 'manual';          // a tap on reminder_completions settles it
const Set<String> allCompletionSourceValues = {completionFromEvents, completionManual};

/// Sentinelle « installation sans profil » des clés composites (baby_id, item_id).
/// NULL n'est **pas** utilisé : SQLite l'autorise dans une PRIMARY KEY composite,
/// et l'autorise en double.
///
/// Les lignes portées par `''` sont l'état de l'app **sans bébé actif**
/// (installation avant tout profil, ou basculement pendant le chargement).
/// Elles ne s'appliquent à aucun bébé réel : un bébé n'hérite que de ses
/// propres lignes — et d'un bébé créé après coup, on ne peut pas « hériter »
/// (le partage « tous les bébés » de la v10 faisait fuiter réglages, ignorés
/// et réglages manuels d'un bébé sur le suivant).
const String sharedBabyId = '';
