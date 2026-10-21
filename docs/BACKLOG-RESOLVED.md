# BACKLOG-RESOLVED — closed debt, kept as history

Append-only archive of items that were opened in [`BACKLOG.md`](BACKLOG.md) and have since been
**resolved, shipped or decided**. Bodies are moved here verbatim — the evidence, the owner
decisions and the "do not" sections stay intact, because the reason an item was closed is what
stops the next person from re-opening it or paying for it twice.

Rules for this file:

- **Append-only.** An entry arrives here only when its own `**Status:**` line already says
  resolved / shipped / reverted, naming the version that carried it. Nothing is edited into
  "done" here.
- **Nothing is deleted from this file.** A reverted decision is still a decision — B2 shipped
  in v1.2.1 and was taken back out the same week; the reversal is recorded inside the entry,
  not by removing it.
- Items keep their `B<n>` numbers from `BACKLOG.md`, so every `B<n>` citation written before
  the move still resolves.

| item | subject | state at archive time |
|---|---|---|
| **B2** | weight slider: 1980 stops → coarse + fine slider pair | shipped v1.2.1, reverted 2026-10-13 (owner) |
| **B5** | out-of-range input swallowed without a message (feeding) | resolved v1.2.1 |

Open items live in [`BACKLOG.md`](BACKLOG.md).

---

## B2 — Weight slider has 1980 stops → coarse + fine slider pair

**Status:** ~~approved for v1.2.1~~ **shipped in v1.2.1, reverted 2026-10-13** (owner) ·
**Severity:** low · **Cost:** UI, ~2 h
**Found:** 2026-10-03, when the step moved from 200 g to 10 g

Half a pixel per stop on a phone. The slider is an aiming device, not an input device; the text
field and the ±steppers set the real value. Accepted deliberately because 10 g of granularity is
what the parent is looking at, and a coarse slider is a lesser sin than a coarse measurement.

**Decision:** two sliders, not one. A **coarse** slider spanning the whole range for rapid finding
(50 g, or 100 g below 3 kg) and a **fine** slider spanning a narrow window around the current value
for the exact one (±50 g, step 10 g), the window re-centring as the coarse slider moves. Same pattern
resolves temperature (coarse 33–42 by 0,5, fine ±1 °C by 0,1) and height. The ±steppers stay — they
are the fastest way to nudge one quantum, and the fine slider is the fastest way to see the neighbours.
Reused across all measurement kinds and the feeding picker, so this is one widget change, not four.
Reverting the step to 200 g is **not** an option: coarse selection and fine value are both required.

### Reverted (owner, 2026-10-13)
Shipped in v1.2.1, taken out the same week: the owner opened an edit sheet, saw two sliders, and could
not tell which one to move or what the second was for. That is the whole verdict — a control whose
purpose has to be explained is not a control. And the diagnosis it was written for had already been
solved twice over: `MeasureKind.step` was documented as <!-- lang:fr: verbatim docstring, quoted below -->
*« le slider amène à proximité ; le champ de saisie et les boutons +/- fixent la valeur exacte »* <!-- lang:fr: verbatim docstring -->, and the ±steppers were kept in the decision above.
The fine slider therefore added no reach the ± and the keyboard did not already give (volume: coarse 50 /
fine 10 / stepper 10 — the fine slider was the stepper, drawn 300 px wide), while costing a legend per
slider and ~60 px of a bottom sheet that was already scrolling.

**Kept:** the 10 g / 1 cm / 0,1 °C steps (that half of the decision stands — `divisions` still spans the
full range at the fine step, the thumb just stops where the finger stops), the ±steppers, the text field.
**Removed:** the `SliderPair` typedef, the `sliderPair` parameter of `QuantityPickerInline`, the two
`Grossier`/`Précis` captions (`sliderCoarse`/`sliderFine` deleted from all three ARBs). One slider per
picker, everywhere — `QuantityPickerInline`, `measurement_sheet`, `edit_measurement_sheet`,
`edit_event_dialog`, `feeding_tracking_dialog`.

**What would re-open this:** a parent who cannot land a value with ± plus keyboard. Not a dense slider —
Flutter skips painting tick marks once they fall below ~12 px apart (`adjustedTrackWidth / divisions >=
3 * tickMarkWidth`, `material/slider.dart`), and at `trackHeight: 4` every range in this app is under
that threshold: the 1980 stops are not painted, they only snap. If the thumb lands on the wrong 10 g,
the fix is a narrower *range* per kind, not a second thumb.

---

## B5 — out-of-range input swallowed without a message (feeding) — resolved

**Status:** **resolved in v1.2.1** — both paths are wired: measurements (`a101429`,
before rc) and feeding (`6133af9`, with the ml/min toggle of B1 — same file, « To do »
point 4 honoured) · **Priority:** high (health) · **Cost:** trivial —
one callback to wire, the mechanism exists

### Resolved (v1.2.1, verified in the code 2026-10-18)
`feeding_tracking_dialog.dart` wires `onValueOutOfRange`: the entered value stays on
the screen, the `feedingValueOutOfRange` message (new arb key, on the model of
`growthValueOutOfRange`) displays the expected range, and `onConfirmPressed` is `null`
as long as the value is out of range. No `clamp`. The rest of the ticket below
is the history of the defect (state as of 2026-10-06) — kept as is.
**Found:** 2026-10-04, while checking a consequence reported by a worker
**Verified again:** 2026-10-06 — commit `a101429` (« fix(growth,reminders): out-of-range
   feedback, comma in all locales, per-baby reminder isolation ») fixed the **measurements** path;
the **feeding** path was still open.
**Files:** `lib/features/home/presentation/widgets/quantity_picker_inline.dart:186-193`
(the `onValueOutOfRange` callback, added by `a101429`),
`lib/features/growth/presentation/widgets/measurement_sheet.dart:122,129,156` (**reference**:
onValueOutOfRange wired, `growthValueOutOfRange` label displayed, `onConfirmPressed: _inRange ?
_save : null`), `lib/features/home/presentation/widgets/feeding_tracking_dialog.dart:156` (**open**:
`QuantityPickerInline` used **without** `onValueOutOfRange` — out-of-range input is still
swallowed there in silence).

### The fact (state as of 2026-10-06)
The `QuantityPickerInline` widget no longer stays silent: out of range, it calls `onValueOutOfRange` if
the host wires it, otherwise it stays silent (optional callback, `quantity_picker_inline.dart:42`). The measurements
sheet is the only wired host: « 99999 » g as weight displays « Valeur hors plage : entre X et
Y » and disables Enregistrer — fixed and tested. The feeding dialog is **not** wired:
« 99999 » ml or g still produces there neither a value nor a message. Same sin as the temperature
semicolon, half paid for.

### Why the test had not caught it
A test asserted that the sheet « s'ouvre hors plage » — which was not the behaviour of the
input, but the effect of the `_value = 0` bug. The real path (typing out of range) had **never** been
tested, and the assertion died with the defect it was masking. The test for the measurements path exists
today (to extend, not to reinvent).

### To do
1. `feeding_tracking_dialog.dart:156`: wire `onValueOutOfRange` → local state + error label
   (new arb key `feedingValueOutOfRange` on the model of `growthValueOutOfRange`) + confirm
   disabled as long as the value is out of range. Do not call anything else.
2. Do not bound silently (`clamp`): correcting the parent's number without telling them is
   exactly what we refuse to do.
3. Test: type 99999 in ml → visible error + confirm disabled; type 9999 in g (solid) →
   idem; back in range → error cleared. The measurements reference (`measurement_sheet`)
   demonstrates the expected behaviour.
4. Attach to **v1.2.1**: the feeding dialog is touched anyway by the ml/min toggle
   of B1 — same file, same review PR, one more callback.

---

