# PLAN — show the active baby's name on home (v1.2.0, small)

Companion to [`PLAN-v1.2.0.md`](PLAN-v1.2.0.md). Branch `feat/v1.2.0-growth-and-baby-scoped-reminders`.
Do not branch, do not commit.

## Why
Home currently shows the tracking buttons, the measurement buttons and "Rappels à faire" with no
indication of **which baby is active**. Confirmed on iPhone 17 with two profiles conceptually in play:
a parent who has two children cannot tell, on the screen where they dismiss reminders, whose reminder
they are dismissing. The owner decided on 2026-10-03 that the active baby's name goes on screen.

## What to build
1. **Active baby's name in the home header.** Read it from the existing active-baby provider
   (`lib/core/providers/active_baby_provider.dart` — the plumbing already exists: `track_notifier.dart`,
   `measurement_providers.dart` and `reminder_notifier.dart` all consume it; reuse it, do not add a new
   provider or a new query).
   > **Correction, same day.** This plan first claimed the provider was "already used by
   > `feeding_tracking_dialog.dart`". It is not — that file has no reference to it. The implementer
   > caught and reported the error rather than quietly working around it. The requirement stood because
   > three other consumers prove the provider is the right seam; the citation did not.
   - Rendered prominently but subordinate to the buttons: it identifies the context, it is not a title
     competing with the app name.
   - It must **update when the active baby changes** — if the provider is an `AsyncNotifier`/`Notifier`,
     watching it is enough; do not cache the name into a field.
2. **Name in the reminders section header.** "Rappels à faire" becomes "Rappels de {prénom} à faire"
   (fr) / "{name}'s reminders" (en) / "Recordatorios de {name}" (es), via an l10n message with a
   placeholder — never string concatenation, because concatenation breaks in other languages.
3. **No active baby:** render nothing for the name (no "null", no empty placeholder, no "?" chip). The
   app's first-run flow handles profile creation; home must not show a fake identity.
4. **Long names:** a 24+ character given name must not overflow — use `Ellipsis.overflow` (or
   `Flexible` in the row), and verify by screenshot, not by assumption.

## Privacy
The name is already stored locally and already displayed elsewhere (history tiles, dialogs). This adds
no new data, no new storage, no transport. **No network, no analytics, no new dependency.** The name
must not be added to any log line (`_logger.d('...')`) — names in logs leave the device via support
bundles.

## Out of scope
Reminder semantics (D1/D2/D3 unchanged), the `''` shared-baby sentinel and its scoping logic, schema,
`MeasureKind`, the ±steppers widget, `TrackButton`, `HistoryFilter`, the v1.2.1 unit column
([`PLAN-v1.2.1-unit-column.md`](PLAN-v1.2.1-unit-column.md)).

## Required tests (English names, French comments)
1. The active baby's name appears on home.
2. Switching the active baby changes the name shown — this is the test that proves it is live, not a
   value captured at first build.
3. No active baby → no name widget, and no `'null'` text anywhere (`find.text('null')` must be nothing).
4. The reminders header contains the name through the l10n placeholder (assert on the rendered message,
   not on a hardcoded French string).
5. A long name does not throw overflow — pump with a 30-character name and expect no exception.
6. Existing home tests stay green **without being edited**. If one must be edited, say so explicitly
   in the report and explain why — an edited-to-pass test is a regression signal.

## Gates — paste final output verbatim
1. `flutter analyze --fatal-infos --fatal-warnings`
2. `flutter test test/features/home/ test/core/`
3. `flutter test`

Report: files changed, tests added, exact l10n keys added per locale, and anywhere this plan was wrong
or impossible. Do not commit.
