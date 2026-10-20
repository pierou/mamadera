# docs/archive/ — shipped plans, kept as implementation history

Nothing here is a to-do list. Every document in this directory describes work that **shipped**, and each
carries a status line at the top naming the version and the code evidence that closed it.

They are kept, not deleted, for three reasons:

1. **They record why, not just what.** The release notes say *what* changed; these plans carry the
   rejected alternatives and the constraints that survive the release — e.g. why the growth slider's
   step is 10 g for weight (`PLAN-v1.2.0.md`), or why `import` refuses a document whose
   `databaseSchemaVersion` exceeds the build's (`import-database-plan.md`).
2. **Schema and migration archaeology.** `PLAN-v1.2.1-unit-column.md` is the reasoning behind schema
   v12; six months from now, someone reading a `unit` column needs it.
3. **Deleting them would rewrite history.** A plan that says "ready to implement" next to a shipped
   feature is a lie you can audit; a deleted plan leaves no trace to reconcile.

## Contents

| File | Shipped in | Closed by |
|---|---|---|
| `PLAN-v1.2.0.md` | v1.2.0 | solid-food subtypes, unit column (schema v12), steppers, baby name on home |
| `PLAN-v1.2.1-unit-column.md` | v1.2.1 | schema v12 — `tracking_events.unit`; slider half reverted |
| `PLAN-solid-food.md` | v1.2.0 | `FeedingSubtype.solid` in `lib/shared/domain/entities/tracking_enums.dart` |
| `PLAN-steppers.md` | v1.2.0 | `lib/features/home/presentation/widgets/quantity_picker_inline.dart` |
| `PLAN-baby-name-on-home.md` | v1.2.0 | `activeBaby` reads in `lib/features/home/presentation/screens/home_screen.dart` |
| `import-database-plan.md` | v1.1.0 | `lib/features/import/` — restore path, transaction + validation |
| `RELEASE-PLAN-v1.1.0.md` | v1.1.0 | release closed; no `v1.1.0` tag exists, only `v1.1.0-rc.1/rc.2` |

## Rules

- **Do not add work items here.** A new plan belongs in `docs/`.
- **Do not edit the bodies.** Correct a factual error if you find one, and date the correction — but a
  plan is a record of a decision, not a living spec.
- **Open plans stay in `docs/`**: `PLAN-fr-comments-to-english.md` (stage 1 blocked on an owner
  decision), `PLAN-francophone-neonatal.md` (proposal awaiting owner decision) and
  `ROADMAP-reminders-and-sync.md` (§6 v1.3.0 sync is still a proposal).
- Resolved *backlog* items go to [`../BACKLOG-RESOLVED.md`](../BACKLOG-RESOLVED.md), not here.
