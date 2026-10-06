# BACKLOG — known debt, deliberately not paid

Things we know are wrong, cheap-ish to fix, and chose not to fix in the release at hand.
Each entry says **why it was deferred** and **what makes it urgent**, so the next person can
re-decide instead of re-discovering. Nothing here is hidden; nothing here is approved silently.

---

## B1 — `tracking_events.quantity` has no unit column

**Status:** open · **Severity:** medium · **Cost:** one migration (schema v12) + export format bump
**Found:** 2026-10-03, while adding the `solid` feeding subtype for v1.2.0
**Files:** `lib/data/local/app_db.dart:28`, `lib/features/history/presentation/widgets/history_tile.dart:134`,
`lib/features/home/presentation/widgets/feeding_tracking_dialog.dart:121`,
`lib/features/history/presentation/widgets/edit_event_dialog.dart:243`

### The debt
`tracking_events.quantity` is a `REAL` with no unit. Its meaning is **inferred from the row's
type and subtype**:

| type | subtype | quantity means |
|------|---------|----------------|
| `miam` | `natural` | millilitres (expressed milk) |
| `miam` | `artificial` | millilitres of formula |
| `miam` | `solid` ← new in v1.2.0 | **grams** |
| `dodo` | — | minutes |

`FeedingEvent` has **no duration field** — `quantity` is the only number, and it has always held
millilitres for both milk subtypes. Anyone tempted to relabel `natural` as "minutes at the breast"
is inventing a semantic the stored data never had, and would display every existing expressed-milk
record as a breastfeeding duration. `feeding_tracking_dialog_test.dart`'s *"natural keeps millilitres"*
test exists because a plan asserted minutes, an implementation obeyed, and nothing else checked.

Three call sites hardcode `'ml'` for feeding and derive nothing from the subtype
(`history_tile.dart:134` does `feeding: (_) => 'ml'`). The unit is a property of the *event*, but
it lives in the *code that renders the event*.

### Why it was accepted
This was already true before v1.2.0 — minutes vs ml was the same inference. Adding `solid` extends
existing debt rather than creating it, and the alternative was a schema migration landing days before
the v10→v11 re-key had been run on a single real device. Two irreversible migrations in one release,
both unverified on hardware, is how you lose a user's data.

### What makes it urgent
1. **The day a meal is logged in ml and g at once** — a bottle *and* a purée at one sitting — the
   model cannot express it. One row per event, one number, one inferred unit: the second food's
   quantity becomes ambiguous or the meal has to be split into two events with no link between them.
2. **Any future import of a foreign format** (another app's export, a spreadsheet restore) cannot be
   validated: an out-of-range value is only detectable if you know what unit you're checking against.
3. **Rendered output is wrong for `solid`** unless every display site was updated in lockstep. A missed
   site prints "40 ml" for 40 g of purée. That is a wrong health number on screen, in an app whose
   entire promise is correct health numbers. Four sites hardcoded `'ml'` for all feeding and had to be
   found and fixed in v1.2.0 — the fourth was not in the plan's list.
4. `measurements` (v1.2.0) *does* carry a `unit` column (`app_db.dart:102`). The schema now contradicts
   itself: one table states its unit, the other assumes it.

### Decision (owner, 2026-10-03): fix it in v1.2.1, and breastfeeding becomes MINUTES
Per-subtype units are now the product contract, not an accident of inference:

| subtype | unit | who chooses |
|---------|------|-------------|
| `natural` | **`ml` or `min` — sélectionné par le parent** | le parent, à la saisie (toggle) |
| `artificial` | `ml` | fixe |
| `solid` | `g` | fixe |
| `dodo` | `min` | fixe |

Amendment owner 2026-10-03 (second): le sein ne se fige **ni** en minutes **ni** en ml. Le parent
choisit. Téter se compte en minutes, tirer un biberon se compte en ml, et la même mère fait les deux
le même jour — figer le sous-type supprimait l'un des deux usages, ce qui n'est pas un détail pour
un parent qui tire. Le toggle n'apparaît que pour `natural` ; les autres sous-types restent figés,
parce qu'une seule unité y a un sens.

### Backfill à la migration v12 — règle explicite
**Toutes les lignes `natural` existantes passent à `'ml'`**, parce que c'est ce que l'interface
affichait : un parent qui a saisi 20 a vu « 20 ml », donc la donnée *veut* dire 20 ml. Aucune
conversion arithmétique, aucune déduction : on nomme l'unité que l'utilisateur a vue. Une ligne dont
l'unité devinerait la minute serait une invention.

Conséquence assumée : au sein, `ml` et `min` coexistent dans la même colonne et le même sous-type.
Tout agrégat doit filtrer sur `unit` — additionner des minutes à des millilitres n'est pas une
approximation, c'est un non-sens. Vérifié : rien ne somme le volume d'alimentation aujourd'hui.

That makes the `unit` column a **prerequisite**, not a cleanup: without it, `quantity` would hold
minutes and millilitres under one subtype name with nothing distinguishing them.

### The backfill trap, stated before anyone writes the migration
Rows written before v1.2.1 under `natural` contain **millilitres** — entered through an `ml` picker,
labelled `ml`, on builds already shipped. There is no way to recover whether a given historical
`natural` row of `20` meant 20 ml or 20 minutes, so **do not convert them**. They backfill to `'ml'`
and stay `'ml'`, truthfully. Consequences, all of them intended:

- `natural` rows carry two units across time, distinguished only by `unit`. Any query, chart or
  "last fed" logic that ignores `unit` will mix volumes and durations. Verify there is no such query
  before shipping — today there is none, nothing sums feeding volume (checked 2026-10-03).
- ~~Expressed milk loses its input field~~ — **résolu** par le toggle ml/min sur `natural`
  (amendement ci-dessus) : pas de quatrième sous-type, le sein accepte les deux unités.
- Duration of a feed becomes available per row, which is what a paediatrician asking "how long does
  she feed?" actually wants. That is the gain paying for all of the above.

### The fix
Schema v12: `ALTER TABLE tracking_events ADD COLUMN unit TEXT`. Backfill honestly, per row:
`sleep`→`min`; `miam`+`artificial`→`ml`; `miam`+`solid`→`g`; **`miam`+`natural`→`ml` for every row
that already exists** (that is what they mean), and `'min'` only for rows written by v1.2.1 and later.
Default for new rows comes from the subtype at insert time, so no code path can write a unit-less row.
Then make every read path render from `unit` and delete the hardcoded `'ml'` literals. Export format 3,
importer accepts 2 and 3, and a format-2 backup's feeding rows backfill to `'ml'` — never `'min'`.
Same discipline as v11: explicit column list in any `INSERT … SELECT`, export stability test extended
to cover `unit`, and an emulator migration pass with pre-existing v11 data before the PR (AGENTS.md).

**Ordering:** v1.2.0 (schema v11) ships and is verified on a device first. v1.2.1 carries v12. Two
unverified irreversible migrations in one release is how a re-key goes wrong with no rollback.

### Do not
Do not "fix" this by widening reminder matching to `type == miam`. Reminders match `subtype`
exactly (`reminders_repository_impl.dart:58`) — that is why a purée does **not** silence a milk
reminder. That exactness is behaviour, not oversight.

---

## B2 — Weight slider has 1980 stops → coarse + fine slider pair

**Status:** **approved for v1.2.1** (owner, 2026-10-03) · **Severity:** low · **Cost:** UI, ~2 h
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

---

## B3 — v1.3.0 sync requires a written change to the privacy mandate

**Status:** blocked on the owner · **Severity:** structural
**Files:** `docs/ROADMAP-reminders-and-sync.md` §7 decision 5, `README.md` privacy promises

The app's core promise is *no network transport exists anywhere*. LAN peer sync contradicts that
sentence, so it is not a feature decision but a promise decision, and only the owner can rewrite the
promise. No code, no dependency, no spike until that sentence changes — see `AGENTS.md`
"Privacy-First Mandates (NON NEGOTIABLE)".

---

## B4 — Contraste insuffisant : le jaune (jour) et le brun (nuit)

**Statut:** ouvert, candidate v1.2.1 · **Priorité:** accessibilité réelle · **Coût:** choix couleur + passe de vérification
**Trouvé:** 2026-10-04, à l'œil sur captures Android (clair) et iOS (sombre)

### Le problème, vu et non deviné
- **Mode clair :** le bouton « Feeding » est en jaune pâle sur fond jaune pâle — à peine lisible.
- **Mode sombre :** le bouton « Couche » est en brun sombre sur fond sombre — à peine lisible.
Les deux sont **déjà en production** (le thème n'a pas changé sur cette branche). Ce n'est pas un
goût, c'est un parent qui lit l'écran d'une main à moitié endormi, à 3 h, sur un écran réduit.

### Candidats, avec le ratio à mesurer — pas à deviner
Règle WCAG AA : **4,5:1** pour le texte normal, **3:1** pour le texte large (≥ 24 px / gras ≥ 18,7 px).
Les titres de bouton sont larges, mais les pilules (« Vit. D ») et les valeurs (« 3 510 g ») ne le
sont pas — c'est donc 4,5:1 qu'il faut viser sur les libellés de ces boutons.

| rôle | problème | candidat à tester |
|---|---|---|
| `miam` (jaune, clair) | trop pâle sur fond clair | ambre foncé `#B26A00`, ou jaune saturé `#E0A400` **avec texte brun foncé** par-dessus |
| `couche` (brun, sombre) | trop sombre sur fond sombre | terracotta `#C97B5A`, ou argile `#D08B6A` |
| alternative structurelle | — | garder les teintes, mais passer le **libellé** en couleur de texte à contraste garanti (foncé sur fond clair, clair sur fond sombre), et réserver la teinte au fond et à l'icône |

L'alternative structurelle est probablement la bonne : elle garde l'identité visuelle (les quatre
couleurs qui distinguent soin/nourriture/couche/sommeil) sans demander à une teinte pastel de porter
la lisibilité du texte.

### À faire avant de toucher aux couleurs
1. Mesurer le ratio réel des paires actuelles (extrait de capture + calculateur WCAG) et noter les
   chiffres — une fiche de couleurs sans ratios est une opinion.
2. Choisir une paire par thème, vérifier 4,5:1 sur les libellés et les pilules dans **les deux**
   thèmes, sur le plus petit appareil.
3. Ne pas changer une couleur d'identité à la légère : ces quatre teintes sont le système de
   repérage de l'app, et un đổi couleur non mesuré peut en casser deux autres.

---

## B5 — une saisie hors plage est avalée sans message (feeding) — résolu à moitié

**Statut:** ouvert (reste le chemin feeding) · **Priorité:** haute (santé) · **Coût:** trivial —
un callback à câbler, le mécanisme existe
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

## B6 — Le rappel Vitamine D est activé par défaut ; OMS 2022 (Rec 36) : recherche uniquement

**Statut :** ouvert, priorité haute (clinique) — **décision A tranchée** (propriétaire, 2026-10-06 : pas de
migration, nouveau défaut seulement) · **Coût :** petit — un champ + un fallback de filtre + tests
**Trouvé:** 2026-10-05, archive de recherche (`docs/research/2026-10-05-clinical-evidence.md`, Rec 36) ;
demande de retrait au backlog par le propriétaire, 2026-10-06.
**Fichiers:** `lib/features/reminders/domain/entities/reminder_item.dart:51` (preset `vitamine_d`),
`lib/features/reminders/presentation/providers/reminder_providers.dart:84` (`settings[item.id] ?? true`),
`lib/features/reminders/presentation/providers/reminder_settings_notifier.dart` (le doc comment
documente « clé absente = activé »), `lib/features/reminders/presentation/screens/reminder_settings_screen.dart`,
`lib/features/reminders/presentation/widgets/reminder_row.dart`.

### Le fait
La liste de rappels par défaut inclut une pastille Vit. D quotidienne (`ReminderItemPresets.vitaminD`,
`Daily()`, réglée par un événement santé de sous-type `vitamine_d`). Tous les préréglages sont **activés par
défaut** : le filtre est `settings[item.id] ?? true`, et le doc comment du notifieur le dit explicitement :
« Une clé absente signifie *jamais touché*, donc **activé** : l'extinction est une option de retrait, pas une
adhésion. Un parent qui n'ouvre jamais cet écran continue de recevoir Vit. D, Vit. K, Yeux et Visage. »

L'OMS 2022 *Caring for the newborn*, Rec 36 : la supplémentation en vitamine D du nouveau-né est
**recherche uniquement** — pas une recommandation (Rec 35 montre le modèle pour la vitamine A : des seuils de
contexte, jamais un complément systématique). L'app envoie donc, tous les jours, par défaut, un rappel pour une
pratique que le guideline de référence ne recommande pas — dans une app dont la raison d'être est les zones de
mortalité néonatale (`docs/PLAN-francophone-neonatal.md`). C'est la divergence clinique ouverte documentée dans
l'archive de recherche : « This is a live clinical discrepancy in the current build, in the app's own default
reminder list. »

### Le fix (mécanique)
1. Ajouter `enabledByDefault` (bool, défaut `true`) à `ReminderItem` ; le mettre à `false` sur `vitamine_d`.
2. Le filtre devient `settings[item.id] ?? item.enabledByDefault`. L'invariant « clé absente = activé » reste
   entier pour tous les autres items — le modèle d'opt-out est préservé, seule la Vit. D devient opt-in.
3. `reminder_settings_screen.dart` / `reminder_row.dart` doivent rendre l'état initial du switch depuis le même
   fallback — vérifier qu'aucun « activé par défaut » n'est recodé dans le widget.
4. Le suivi reste : `HealthSubtype.vitamineD` (`tracking_enums.dart:290`) demeure dans
   `health_subtype_dialog.dart`. Un parent avec prescription continue de loguer la vitamine D, et le rappel reste
   rallumable dans Réglages → Rappels. On change le **défaut**, pas la **fonction**.
5. l10n : ajouter une courte justification sur la ligne des réglages (« Non recommandé en routine — OMS 2022, Rec
   36 ») en fr/en/es, pour que l'état éteint par défaut ne ressemble pas à un bug.

### Point de décision (propriétaire) — les installations existantes
Un parent installé avant ce changement a « Vit. D = jamais touché » = **activé**. Deux options :
- **A. Nouveau défaut seulement** (pas de migration) : les existants continuent de recevoir le rappel jusqu'à
  extinction manuelle ; les nouveaux bébés/installations démarrent éteints.
- **B. Migration** seedant `reminder_settings(baby_id, 'vitamine_d', enabled: false)` pour tous les scopes
  existants (profils + portage `''`) : toutes les installations basculent à l'upgrade.

Recommandation : **A** + note de patch expliquant le changement. B retire silencieusement un rappel visible
sans consentement — exactement le péché que la règle de backfill de B1 refuse pour les données (« on nomme
l'unité que l'utilisateur a vue »).

**Décision (propriétaire, 2026-10-06) : A.** Nouveau défaut seulement, pas de migration. Les installations
existantes gardent le rappel jusqu'à extinction manuelle ; les nouveaux bébés/installations démarrent éteints.
Note de patch expliquant le changement (sans le marketer comme « l'app suit l'OMS » — voir « Ne pas »).

### Ne pas
- Ne pas **supprimer** le rappel vitamine D ni le sous-type santé `vitamine_d`. « Recherche uniquement » n'est
  pas « interdit » : dans une partie du marché cible (pratique US, AAP : 400 UI/jour) c'est le standard. La
  suppression est une décision différente, beaucoup plus bruyante.
- Ne pas inverser le **défaut global** « clé absente » en « désactivé » : l'opt-out porte les préréglages Vit. K
  (après le premier mois), Yeux, Visage — tous deviendraient opt-in et l'écran d'accueil d'un nouveau parent
  serait vide de rappels.
- Ne pas présenter ce changement en store/patch notes comme « l'app suit désormais l'OMS sur les
  suppléments » : le reste de la liste par défaut (yeux, visage, Vit. K) est une hygiène de soin,
  pas une liste dérivée de l'OMS. Une sur-généralisation est une promesse clinique que l'archive
  de recherche interdit de faire.

---

## B7 — L'onglet Historique n'a pas *tous* les types d'événements : les mesures en sont absentes

**Statut :** la frise unifiée est **déjà décidée pour v1.2.1** (PLAN-v1.2.1-unit-column.md, « Décision —
   les mesures doivent apparaître comme événements », owner 2026-10-04) ; reste dans ce ticket : le chip
   `HistoryFilter.measurements` dédié, explicitement **hors périmètre v1.2.1** (section « Out of scope »
   du plan : « no `HistoryFilter` value for growth ») → candidat v1.3.0 si le propriétaire veut encore le
   chip après l'arrivée de la frise. · **Coût de la partie restante:** petit
**Trouvé:** demande du propriétaire, 2026-10-06 (« l'onglet historique devrait avoir tous les types
   d'événements »), vérifié dans le code — et recoupé avec le plan v1.2.1 le 2026-10-06.
**Fichiers:** `lib/features/history/presentation/screens/history_screen.dart:20` (`_filters` :
all/miam/dodo/caca/sante), `lib/features/history/presentation/providers/history_notifier.dart:28-50` (ne
consulte que `tracking_events`), `lib/features/history/data/repositories/history_repository.dart`
(`getAllEventsOrdered`, `getEventsByType`), `lib/shared/domain/entities/tracking_enums.dart:320`
(`HistoryFilter`), `lib/data/local/app_db.dart:96` (table `measurements`, séparée, valeurs chiffrées),
`lib/features/history/presentation/widgets/history_tile.dart`.

### Le fait
« Historique » promet tous les événements ; il n'affiche que `tracking_events` (miam, dodo, caca, sante).
Depuis v1.2.0, poids/taille/température vivent dans la table **`measurements`** — une autre table, valeurs
chiffrées, unité en colonne, son propre repository (`MeasurementRepository.allForBaby`, borné au bébé, déjà
trié du plus récent au plus ancien). La vue « tous » du parent est donc muette sur une classe entière
d'événements : les mesures n'apparaissent que sur l'écran Croissance (lui-même caché dans le menu, voir B8).
Un parent qui veut « tout ce qui s'est passé aujourd'hui » ne voit pas le poids pris ce matin.

### À faire
**Partie v1.2.1 (ne pas redéfinir, c'est le contrat du plan)** : frise unifiée en **lecture seule** —
`history_notifier` fusionne `tracking_events` et `measurements` triés par horodatage, chaque ligne
rendant son unité depuis sa propre colonne `unit` ; modification/suppression adressées à la table
d'origine (jamais aux deux) ; **pas de duplication** dans `tracking_events` — le plan la refuse
explicitement : `quantity` y est **en clair** au repos, dupliquer y créerait une copie non chiffrée
de la donnée la plus sensible de l'app. Tuile « échec de déchiffrement → `growthValueUndecryptable`,
jamais un nombre inventé ». Voir le plan pour les détails d'édition (`measurement_sheet.dart` ou
`edit_event_dialog.dart`).

**Partie restante (v1.3.0 si toujours voulue)** :
1. `HistoryFilter.measurements` (valeur `'mesures'`, libellé l10n fr/en/es) en plus de l'inclusion dans
   `all` (celle-ci arrive avec la frise v1.2.1) ; `HistoryFilter.fromString` : `'mesures'` avant le
   fallback `all` (le fallback sûr déjà en place).
2. Le chip s'insère dans `_filters` de `history_screen.dart` — position et icône au plan (les mesures ne
   sont ni un type `TrackingType` ni une couleur existante).
3. Rien à bumper dans le format d'export : les mesures sont déjà exportées/importées, le chip est une
   pure question de lecture.

### Ne pas
- Ne pas migrer `measurements` **dans** `tracking_events` pour « unifier » l'historique. Les deux tables ont des
  contrats différents (colonne `unit`, valeur chiffrée, enum `kind`, pas de sous-type) ; la dette B1 montre
  précisément ce que fait une colonne numérique unique qui porte la sémantique. Une fusion **d'affichage**
  suffit ; une fusion de schéma est une migration irréversible sans gain.
- Ne pas ajouter les `reminder_completions` ou les `reminder_dismissals` à l'historique : ce sont des
  journaux de service, pas des événements du bébé.

---

## B8 — Mesures : pas d'onglet dédié, pas de visualisation

**Statut:** ouvert (demande du propriétaire, 2026-10-06 : « un onglet de visualisation pour les mesures ») ·
**Coût:** petit côté routeur, moyen côté graphique (dépendance ou `CustomPainter`)
**Fichiers:** `lib/core/router.dart:23` (`AppRoute` : home/history/menu), `:137` (route `/growth`
**hors** du shell), `lib/features/menu/presentation/screens/menu_screen.dart:111` (`context.push('/growth')`),
`lib/features/growth/presentation/screens/growth_screen.dart` (3 cartes dernière valeur + liste plate, aucun
graphique).

### Le fait
Croissance est aujourd'hui un push plein écran depuis le Menu — deux tapes de profondeur — et sa
« visualisation » est trois cartes de dernière valeur au-dessus d'une liste plate. Il n'existe **aucun**
graphique : pas de courbe de poids dans le temps, pas de tendance. Un parent qui suit le poids de son
nouveau-né regarde des tuiles, pas une trajectoire.

### À faire
1. Déplacer `GrowthScreen` dans le `ShellRoute` comme **quatrième onglet** de la navigation basse. Ordre :
   Home, History, Croissance, Menu (à valider au plan — le Menu reste le dernier, c'est l'onglet de
   service ; quatre onglets est la limite de confort de Material, on n'en ajoute pas un cinquième).
2. `AppRoute` enum + `routeIndex` + `_routeIndexForPath` + label/icône de nav (nouvelle clé l10n ou
   réutilisation de `growthScreenTitle`/`growthMenuTile` — vérifier les trois arb).
3. La tuile « Croissance » du Menu devient redondante : la supprimer ou la garder comme raccourci —
   décision au plan. Si on la garde, l'onglet et la tuile mènent au même endroit (le push disparaît,
   remplacé par une navigation d'onglet).
4. La visualisation elle-même : courbe **poids dans le temps** (et taille en option). Deux chemins :
   - (a) `CustomPainter` maison — zéro dépendance, fidèle à la charte de confidentialité, ~une journée ;
   - (b) paquet de graphiques pur Dart (ex. `fl_chart`) — **audit obligatoire** : `make audit-trivy` +
     revue de confidentialité des dépendances (AGENTS.md : aucune dépendance sans audit, zéro réseau,
     zéro télémétrie).
   Décision au plan ; (a) n'a aucune raison d'être refusée.
5. La **température** ne va pas dans le graphique : une température n'a pas de sens en tendance (c'est un
   état, pas une trajectoire). Elle reste carte + liste. Le graphique porte poids (et taille).

### Ne pas
- Ne pas superposer les **percentiles OMS** (courbes de croissance). C'est du contenu clinique : l'archive
  de recherche est explicite — aucune intervention numérique n'a démontré d'effet sur la mortalité néonatale,
  l'app ne doit pas se marketer comme un outil clinique, et l'archive refuse de reconstruire des couleurs
  de triage IMNCI d'après des sources de seconde main. Une superposition de percentiles sans revue
  clinique serait la première **interprétation** de données de santé de l'app. Si des percentiles sont un
  jour voulus, c'est d'abord une tâche de recherche (docs/research/), pas un paramètre de graphique.
- Ne pas créer un **cinquième** onglet « tous les événements » : B7 fusionne les mesures dans
  Historique. L'onglet Croissance et le filtre `measurements` de l'historique sont complémentaires —
  l'onglet pour la **visualisation**, l'historique pour le **registre chronologique** — et non rivaux.
- Ne pas toucher à l'export/import dans ce ticket : les mesures voyagent déjà (`docs/import-database-plan.md`,
  format d'export). L'onglet change la présentation, pas le contrat des données.

---

## B9 — Sélection du bébé en haut de l'app : le prénom de la barre d'app est inerte

**Statut:** ouvert (demande du propriétaire, 2026-10-06 : « baby selection in the top of app ») ·
**Coût:** petit — une feuille + un titre d'AppBar cliquable
**Trouvé:** vérification du 2026-10-06 — le nom du bébé actif est affiché en titre de la barre d'app de
   l'accueil (`home_screen.dart:316-335`, « contexte, pas titre ») et ne fait rien ; le changement de bébé
   exige Menu → Profil bébés.
**Fichiers:** `lib/features/home/presentation/screens/home_screen.dart:316-335` (AppBar, titre = nom,
   inerte), `lib/core/providers/active_baby_provider.dart:32` (`switchProfile(id)` existe déjà),
   `lib/features/menu/presentation/widgets/baby_profile_section.dart` (UI de liste existante, pour la
   cohérence visuelle), `lib/features/baby/presentation/providers/baby_profile_providers.dart`.

### À faire
1. Rendre le titre de l'AppBar de l'accueil cliquable (affordance `expand_more`), ouvrant une bottom sheet :
   liste des profils (avatar + nom + date de naissance), profil actif coché, tap →
   `ref.read(activeBabyProvider.notifier).switchProfile(id)`, la feuille se ferme.
2. Une ligne « Ajouter un bébé » en bas de la feuille → le flux de création de profil existant (celui que
   la section du Menu utilise), pour que l'entrée en haut soit complète : on bascule **et** on ajoute sans
   redescendre dans le Menu.
3. Cas d'un seul bébé : décision au plan — la feuille s'ouvre quand même (cohérent, c'est aussi là qu'on
   ajoute le deuxième) ou l'affordance disparaît (moins de bruit, incohérent). Recommandation : la feuille
   s'ouvre toujours, elle est le point d'entrée « famille ».

### Pourquoi c'est bon marché et sûr
La chaîne réactive existe déjà : le notifieur de rappels `watch`e `activeBabyProvider`, l'historique lit
`.value`, l'en-tête de l'accueil se re-rend au basculement (le commentaire de `home_screen.dart:316`
documente précisément pourquoi c'est un `watch` et non un `read`). Rien à invalider manuellement —
l'invalidation globale après reset de base (`menu_screen.dart:350-357`) couvre déjà les providers
concernés.

### Ne pas
- Ne pas déplacer la **gestion** des profils (édition nom/naissance, suppression) dans la feuille du haut.
  Le haut est un **commutateur** ; la gestion reste dans Menu → Profil bébés. Deux points d'entrée pour la
  suppression, c'est comme ça qu'un « supprimer ce profil » accidentel se fabrique.
- Ne pas écrire sous le portage `''` pendant un basculement transitoire : le même piège que
  `markDone`/`snooze` documentent dans `reminder_notifier.dart` — résolution par
  `activeBabyProvider.future`, jamais `.value` sur une lecture transitoire (les lignes `''` se lisaient
  pour **tous** les bébés avec le partage v10).
- Ne pas afficher le prénom du bébé **et** une icône de famille : l'un ou l'autre. Deux porteurs de
  contexte sur la même barre, c'est du double discours.

---

## B10 — Les commentaires de code sont français : ~1 750 lignes à angliciser

**Statut:** ouvert (demande du propriétaire, 2026-10-06 : « tous les commentaires de code en anglais ») ·
**Coût:** gros, mécanique (~5–8 h) · **Risque:** faible si la discipline est tenue
**Compté:** 2026-10-06 — 945 lignes de commentaires en `lib/` (56 fichiers), 800 en `test/` (71 fichiers),
   comptage sur lignes de commentaires contenant des caractères accentués, fichiers générés exclus.

### Le fait
Le code porte des commentaires `//` et `///` en français à travers `lib/` et `test/` (les chaînes
utilisateurs sont, elles, intentionnellement trilingues — `lib/l10n/*.arb` — mais les **commentaires**
sont unidiomes par convention de repo : anglais). Les commentaires français rendent le code plus dur à
chercher pour un second lecteur et pour le prochain agent : « trouver l'invariant » exige des mots
français, et la recherche d'agent (RAG inclus) est calibrée sur l'anglais.

### À faire
1. Traduire `lib/` (hors générés), puis `test/`, fichier par fichier. Tâche purement mécanique —
   **idéale pour un fan-out** `box-coder`/`fast-coder` (pas de décision de design), mais la revue du diff
   reste humaine : certains commentaires portent des invariants (D1/D2/D3, le portage `''`, la règle de
   backfill de B1, le « do not » de B5) qui doivent survivre **en tant que raisonnement**, pas en résumé.
   Une traduction qui efface un « pourquoi » est un échec, pas une simplification.
2. Les fichiers générés (`*.freezed.dart`, `.g.dart` de drift) **copient** les doc comments de la source —
   ne jamais les éditer à la main ; traduire la source, relancer `make codegen`, ils suivent.
3. Après la passe : `make lint` + `make test` (les tests doivent rester inchangés en comportement —
   seule la langue des commentaires bouge).
4. Optionnel, à trancher à la revue : une garde CI (grep des lignes de commentaires accentuées
   `é è ê à â ç ù û ô î ï` dans `lib/**/*.dart` et `test/**/*.dart`) pour empêcher la régression —
   à brancher sur le pipeline existant (`make ci`).

### Ne pas
- Ne pas traduire les **chaînes utilisateur** : `lib/l10n/*.arb` et les `app_localizations_*.dart` générés
  restent intacts. C'est le produit, pas du code.
- Ne pas **supprimer** de commentaires pour « simplifier » : la règle AGENTS.md — jamais de suppression
  sans justification et remplacement fonctionnel. Un « pourquoi » perdu (la trappe de backfill de B1 en
  est l'exemple) est une perte de données d'un autre type.
- Ne pas faire cette passe **dans le même PR** que B6–B9 : le diff noierait les changements fonctionnels et
  la revue des invariants. Un PR de balayage séparé, et de préférence **avant** tout autre travail — tout ce
  que l'on touche ensuite sera écrit en anglais et la dette cessera de grossir.
- Ne pas « traduire » en résumant : un commentaire de six lignes doit en rester six. La traduction qui
  perd une nuance de portage ou d'invariant est pire que le français original.

---

## B11 — La notification de changement de langue s'affiche dans l'ancienne langue

**Statut:** ouvert (demande du propriétaire, 2026-10-06 : « la notification de changement de langue doit
   être dans la langue cible ») · **Coût:** trivial
**Trouvé:** vérification du 2026-10-06 dans `menu_screen.dart:217-218`.
**Fichiers:** `lib/features/menu/presentation/screens/menu_screen.dart:211-220` (le tap de la tuile
   de langue), `lib/l10n/app_localizations.dart:1711` (`lookupAppLocalizations(Locale)` — le mécanisme de
   correction, déjà public), les clés `languageChanged` dans les trois arb (fr : « Langue changée », en :
   « Language changed », es : « Idioma cambiado »).

### Le fait
```dart
onTap: () async {
  await ref.read(localeProvider.notifier).setLocale(code);
  if (context.mounted) _showSnackBar(context, context.l.languageChanged);
},
```
Après le basculement, l'arbre de widgets est **encore** construit dans l'ancienne locale — la
reconstruction dans la nouvelle se fait à la frame suivante, après que le snackbar a lu la chaîne. Un
parent qui passe fr → en voit **« Langue changée »** : la confirmation arrive dans la langue qu'il vient
de quitter. La seule chaîne dont le métier est de dire « tu es maintenant en anglais » est elle-même
encore en français.

### Le fix
Résoudre la chaîne dans la **locale cible**, pas la locale courante — `lookupAppLocalizations` est public
et synchrone :
```dart
onTap: () async {
  await ref.read(localeProvider.notifier).setLocale(code);
  if (!context.mounted) return;
  final target = lookupAppLocalizations(Locale(code));
  _showSnackBar(context, target.languageChanged);
},
```
`Locale(code)` est toujours supportée (les trois codes de l'écran sont `fr`/`en`/`es` ; `lookupAppLocalizations`
les couvre tous, une langue ajoutée demain l'ajoute à `supportedLoces` et au switch — la correction suit
sans code supplémentaire).

### Tests
- fr → en : snackbar « Language changed » ; fr → es : « Idioma cambiado » ; en → fr : « Langue changée ».
  Les trois directions, pas seulement celle du rapporteur.
- Widget test existant du menu à étendre : surcharger `localeProvider`, taper la tuile, pump, attendre la
  chaîne de la **cible** (pas de l'ancienne). L'assertion sur l'ancienne chaîne est le bug — la ne jamais
  re-écrire.

### Ne pas
- Ne pas « corriger » en **différant** le snackbar jusqu'à la reconstruction (`addPostFrameCallback` puis
  lire `context.l`) : cela couple le message au timing d'une frame et affiche la mauvaise chaîne si la
  reconstruction est retardée. Lire la locale cible directement est le seul fix déterministe.
- Ne pas retirer la notification : c'est la seule confirmation du changement (l'écran entier, lui, se
  met à jour à la frame suivante et le parent n'y prête pas attention) — la corriger, pas la tuer.

---

## B12 — Les rappels dus sont en bas de l'accueil : ils doivent être en haut

**Statut:** ouvert (demande du propriétaire, 2026-10-06 : « les rappels devraient être en haut de
   l'écran d'accueil ») · **Coût:** trivial — un réordonnancement de `Column`
**Trouvé:** vérification du 2026-10-06 — la liste des rappels dus est le **troisième** enfant de la
   `Column` de l'accueil, sous la grille 2×2 de suivi **et** sous la rangée de boutons de croissance.
**Fichiers:** `lib/features/home/presentation/screens/home_screen.dart:344-396` (la `Column` :
   `GridView.count` → `MeasurementButtonRow` → `HomeRemindersSection`),
   `lib/features/reminders/presentation/widgets/home_reminders_section.dart:19` (le doc comment dit
   explicitement « sous les boutons de soin »).

### Le fait
Sur l'accueil, l'ordre actuel est : (1) la grille 2×2 des boutons de suivi (miam/santé/caca/dodo),
(2) les trois boutons de mesure (poids/taille/température), (3) la liste des rappels dus du bébé actif
(`HomeRemindersSection`). Les rappels — l'action du jour, « Vit. K à faire », « Yeux à nettoyer » —
sont donc le **dernier** bloc de l'écran : sur un petit téléphone, avec deux ou trois rappels dus,
il faut scroller pour les voir. Or c'est l'information la plus urgente : un parent qui ouvre l'app le
matin cherche d'abord « qu'est-ce qu'il reste à faire ? », pas « comment est-ce que j'enregistre ? ».
Le compteur « +N » sur les pastilles des boutons (`track_button.dart`) pointe vers cette liste en bas
tandis que le doigt est en haut — le regard fait un aller-retour inutile.

### À faire
1. Dans la `Column` de `home_screen.dart`, déplacer `HomeRemindersSection` **au premier** enfant :
   rappels dus → grille 2×2 → boutons de mesure. C'est un cut/paste de deux widgets, aucun changement
   de données, de provider ni de test de comportement.
2. Mettre à jour le doc comment de `home_reminders_section.dart` (« sous les boutons de soin » →
   « au-dessus de la grille ») et le commentaire inline de `home_screen.dart:393` (« remplace la
   lecture du « +N » des pastilles, sans toucher à la grille ») — les deux sont faux après le
   réordonnancement. (En anglais si B10 est passé d'abord ; sinon en français, B10 les traduira.)
3. L'état vide : `HomeRemindersSection` rend aujourd'hui la ligne centrée « Rien à faire pour
   l'instant. » (`reminderListEmpty`) quand aucun rappel n'est dû. En haut de l'écran, cette ligne
   occuperait la première place **la plupart du temps** (c'est l'état normal d'une journée calme).
   Décision au plan : **masquer la section quand elle est vide** (recommandé — le silence est
   l'information : rien à faire, on passe aux boutons) ou garder la ligne discrète. Si on masque,
   la liste apparaît/disparaît au fil de la journée : vérifier que le saut de mise en page ne
   dérange pas (le `SingleChildScrollView` absorbe, mais le confirmer sur `Small_Phone`).

### Pourquoi c'est trivial mais pas gratuit
- Le réordonnancement est sûr pour les tests : `home_screen_test.dart` et
  `home_baby_name_test.dart` assertent la **présence** des widgets (`findsOneWidget`,
  `findsNWidgets`), pas leur ordre — ils passent sans changement. `home_reminders_section_test.dart`
  teste le widget seul, pas sa position.
- L'AGENTS.md est clair : les tests unitaires ne rendent pas une layout sur un écran de 4,7 pouces.
  Le passage émulateur (gate de release) est **obligatoire** : screenshots `Small_Phone` + un
  appareil normal, avec et sans rappels dus, **et** avec le prénom en barre d'app (B9) pour vérifier
  que la partie haute de l'écran ne s'affole pas quand les deux tickets atterrissent.
- Pas de migration, pas de changement d'export, pas de provider : le `reminderNotifierProvider`
  est watché par le widget quel que soit sa position dans la `Column`.

### Ne pas
- Ne pas toucher aux **pastilles** « +N » des `TrackButton` : elles restent, c'est l'indicateur par
  type sur le bouton ; la liste en haut est la vue détaillée. Les retirer au prétexte que la liste est
  maintenant visible serait une suppression de fonctionnalité sans demande — et B4 documente que
  ces pastilles ont un problème de contraste à régler, pas de redondance.
- Ne pas réordonner la **grille** elle-même (miam/santé/caca/dodo) ni les boutons de mesure dans ce
  ticket : la demande est « les rappels en haut », pas « refaire l'accueil ». Un réordonnancement
  supplémentaire dans le même diff est du scope creep qui complique la revue et le passage
  émulateur.
- Ne pas masquer la section vide **et** déplacer la liste en haut dans le même PR sans la capture
  `Small_Phone` : le saut de mise en page au premier rappel réglé du jour (la liste disparaît, la
  grille remonte) est exactement le genre de chose invisible en test unitaire et agaçante en usage
  réel — à valider à l'œil, pas à deviner.
