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
