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
| **B5** | une saisie hors plage est avalée sans message (feeding) | résolu v1.2.1 |

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
solved twice over: `MeasureKind.step` was documented as *« le slider amène à proximité ; le champ de
saisie et les boutons +/- fixent la valeur exacte »*, and the ±steppers were kept in the decision above.
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

## B5 — une saisie hors plage est avalée sans message (feeding) — résolu

**Statut:** **résolu en v1.2.1** — les deux chemins sont câblés : mesures (`a101429`,
avant rc) et feeding (`6133af9`, avec le toggle ml/min de B1 — même fichier, « À faire »
point 4 honoré) · **Priorité:** haute (santé) · **Coût:** trivial —
un callback à câbler, le mécanisme existe

### Résolu (v1.2.1, vérifié dans le code 2026-10-18)
`feeding_tracking_dialog.dart` câble `onValueOutOfRange` : la valeur saisie reste à
l'écran, le message `feedingValueOutOfRange` (nouvelle clé arb, sur le modèle de
`growthValueOutOfRange`) affiche la plage attendue, et `onConfirmPressed` est `null`
tant que la valeur est hors plage. Pas de `clamp`. Le reste de la fiche ci-dessous
est l'historique du défaut (état du 2026-10-06) — conservé tel quel.
**Trouvé:** 2026-10-04, en vérifiant une conséquence signalée par un worker
**Vérifié à nouveau:** 2026-10-06 — le commit `a101429` (« fix(growth,reminders): out-of-range
   feedback, comma in all locales, per-baby reminder isolation ») a corrigé le chemin **mesures** ;
le chemin **feeding** est toujours ouvert.
**Fichiers:** `lib/features/home/presentation/widgets/quantity_picker_inline.dart:186-193`
(le callback `onValueOutOfRange`, ajouté par `a101429`),
`lib/features/growth/presentation/widgets/measurement_sheet.dart:122,129,156` (**référend** :
onValueOutOfRange câblé, libellé `growthValueOutOfRange` affiché, `onConfirmPressed: _inRange ?
_save : null`), `lib/features/home/presentation/widgets/feeding_tracking_dialog.dart:156` (**ouvert** :
`QuantityPickerInline` utilisé **sans** `onValueOutOfRange` — la saisie hors plage y est encore
avalée en silence).

### Le fait (état du 2026-10-06)
Le widget `QuantityPickerInline` ne se tait plus : hors plage, il appelle `onValueOutOfRange` si
l'hôte le câble, sinon il se tait (callback optionnel, `quantity_picker_inline.dart:42`). Le sheet
des mesures est le seul hôte câblé : « 99999 » g en poids affiche « Valeur hors plage : entre X et
Y » et désactive Enregistrer — corrigé et testé. Le dialogue de feeding n'est **pas** câblé :
« 99999 » ml ou g n'y produit toujours ni valeur ni message. Même péché que le point-virgule de
température, moitié payé.

### Pourquoi le test ne l'avait pas attrapé
Un test affirmait que le sheet « s'ouvre hors plage » — ce qui n'était pas le comportement de la
saisie, mais l'effet de bug `_value = 0`. Le vrai chemin (la frappe hors plage) n'a **jamais** été
testé, et l'assertion est morte avec le défaut qu'elle masquait. Le test du chemin mesures existe
aujourd'hui (à étendre, pas à réinventer).

### À faire
1. `feeding_tracking_dialog.dart:156` : câbler `onValueOutOfRange` → state local + libellé d'erreur
   (nouvelle clé arb `feedingValueOutOfRange` sur le modèle de `growthValueOutOfRange`) + confirm
   désactivé tant que la valeur est hors plage. Ne rien appeler d'autre.
2. Ne pas borner silencieusement (`clamp`) : corriger le nombre du parent sans le lui dire est
   exactement ce qu'on refuse de faire.
3. Tester : taper 99999 en ml → erreur visible + confirm désactivé ; taper 9999 en g (solid) →
   idem ; revenir dans la plage → erreur effacée. Le référend mesures (`measurement_sheet`)
   démontre la suite attendue.
4. Rattacher à **v1.2.1** : le dialogue de feeding est touché de toute façon par le toggle ml/min
   de B1 — même fichier, même PR de revue, un callback de plus.

---

