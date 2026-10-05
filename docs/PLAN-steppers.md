# PLAN — +/- steppers on every numeric picker (v1.2.0)

Companion to [`PLAN-v1.2.0.md`](PLAN-v1.2.0.md). Read this file only; it is self-contained.
Branch: `feat/v1.2.0-growth-and-baby-scoped-reminders`. Work on the current tree, do not branch.

## Why
Numeric entry today is a slider + a text field. With the steps just set — weight **10 g**,
temperature **0,1 °C** — the slider has up to 1980 stops (~0,5 px each) and is no longer a way to
land an exact value. Users need `+` / `−` to nudge by one step. This is the missing half of the
precision change, not a decoration.

## Scope — ONE widget change, then wiring
`lib/features/home/presentation/widgets/quantity_picker_inline.dart` is the shared numeric picker
used by the feeding dialog, the edit-event dialog and `MeasurementSheet`. Add the stepper **there**,
once. Do not copy stepper code into each screen.

### QuantityPickerInline
Add an optional named param `step` (`double? step`) and render two icon buttons flanking the value
display (`Icons.remove_circle_outline` / `Icons.add_circle_outline`):

- Tap `+` → `value + step`, `−` → `value - step`, in that direction only.
- **Clamp to the widget's existing `min`/`max`.** At a bound the corresponding button is disabled
  (`onPressed: null`), not hidden — a control that vanishes makes the layout jump.
- When `step == null`, render no stepper: existing call sites that do not pass `step` must be
  pixel-identical to today. This is what protects the feeding dialog's existing tests.
- Round with the widget's existing `decimals` so `0.1 + 0.1 + 0.1` never displays `0.30000000000000004`.
  The arithmetic happens in `double`; the *display* uses `decimals`. Keep the text field authoritative:
  if the user typed `37,4`, `+` yields `37,5` — parse what is on screen, do not re-derive from the slider.
- Long-press to repeat (`LongPressRepeatIndicator` is not available; use `GestureDetector` with
  `onLongPressStart` + a `Timer.periodic` at ~120 ms, cancelled in `onLongPressEnd` / `dispose`).
  Cancel the timer in `dispose` or the widget leaks a running timer after the sheet closes.
- Buttons get `tooltip` from l10n (`increment` / `decrement`), and a `Semantics` label. Every control
  in this app is reachable by screen reader; an icon without a label is an inaccessible control.

### Wiring
- `lib/features/growth/presentation/widgets/measurement_sheet.dart` → pass `step: kind.step`.
- Existing feeding / edit-event call sites: pass the step that matches their unit, keeping today's
  default behaviour where a step is not meaningful. If a call site's step is unclear, **do not guess** —
  leave it `null` (no stepper) and report it as an open question.
- `lib/features/home/presentation/widgets/duration_picker_dialog.dart` (sleep) → its own `+` / `−`
  of **5 minutes**, clamped to its existing bounds, same disabled-at-bound and long-press rules.
  It does not use `QuantityPickerInline`; do not refactor it to use it — that is a bigger change than
  this task and it would put the sleep tracker at risk for a UI nicety.

### l10n
Add `increment` / `decrement` keys to `lib/l10n/app_fr.arb`, `app_en.arb`, `app_es.arb`:
FR `Incrémenter` / `Décrémenter`, EN `Increase` / `Decrease`, ES `Aumentar` / `Disminuir`.
Then run `flutter gen-l10n`.

## Out of scope (do not touch)
- `TrackButton` — must stay as is.
- `HistoryFilter` — no new values.
- Schema, `MeasureKind` ranges/steps (already final), export/import format, `ReminderRow`,
  the D2 rule that `Done` renders only for `completionSource == manual`.
- Do not add dependencies. This app has no network and no analytics; keep both true.

## Required tests (test/features/home/presentation/widgets/quantity_picker_inline_test.dart exists — extend it)
1. `+` increments by `step`; `−` decrements by `step`.
2. Clamped at `max` / `min`, and the button at the bound is disabled.
3. `decimals: 1` with `step: 0.1`: three taps up from `37,2` display `37,5` — **not** `37,500000000000004`.
   This is the float trap; assert the rendered string, not just the number.
4. Typed value is honoured: enter `37,4`, tap `+`, expect `37,5`.
5. `step == null` renders no stepper (guards the existing call sites).
6. Long-press repeats and the timer is cancelled on dispose — pump, long-press, `pump(1s)`, expect
   several increments; then unmount and expect no exception from a fired-after-dispose timer.
7. MeasurementSheet: weight `+` moves by 10 g.

## Definition of done
- `flutter analyze --fatal-infos --fatal-warnings` → clean.
- `flutter test test/features/growth/ test/features/home/` → all green, **0 skipped**.
- `flutter test` full suite → green.
- Report: files changed, tests added, any call site you left with `step: null` and why.
- Do not commit. The orchestrator reviews `git diff` and commits.
