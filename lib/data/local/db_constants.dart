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
