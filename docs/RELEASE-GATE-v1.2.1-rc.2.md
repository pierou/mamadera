# Release gate pass — v1.2.1-rc.2 (2026-10-13/14)

Emulator release-gate per `AGENTS.md`, run on branch `develop` above `v1.2.1-rc.1` (`d100305`),
pubspec `1.2.1+10`. Debug builds both sides (release signing lives in CI).

## Contents of this rc versus rc.1

- **Retrait de la paire de curseurs B2 (grossier/précis)** : un seul curseur pleine amplitude
  (min→max, pas fin conservé) sur les 5 surfaces de saisie ; les boutons ± et le champ clavier
  gardent l'entrée exacte. Pas de colonne ni de schéma touché.
- **`HistoryTile` : date et heure sur deux lignes** — la date anglaise avec minutes
  (« 10/13/2026 9:32 PM ») débordait de 360 dp sur Small_Phone.
- **`HistoryTile` : la sieste se lit en « Durée » seule** — la demi-affichage de B13 ; le modèle
  écrit toujours les deux colonnes (demi-modèle = **B13**, post-v1.2.1).
- **Porte intégrée** : `integration_test/pickers_gate_rc2.dart` — 8 cas, preuves programmatiques
  imprimées dans la log + captures écrites dans le Documents de l'app.

## 1. Migration path v11 → v12, on a device that had old data

**Small_Phone (emulator-5554, Android 17 / API 37, 720×1280):**

1. `adb install` fraîche de **v1.2.0** (worktree de la tag, debug) → onboarding, bébé **Léa**,
   locale EN (`migration/01-v120-home-seeded.png`).
2. Seeded via the v1.2.0 UI : prise au sein **120 ml**, prise biberon **100 ml**, purée/solide
   **40 g**, sieste — base v11 authentique (`PRAGMA user_version = 11`, pas de colonne `unit`).
3. `adb install -r` de **rc.2** (`1.2.1+10` debug) par-dessus. Lancement : dialogue
   « What's New in Mamadera 1.2.1 » (`migration/02-rc2-patch-notes.png`).
4. Base extraite via `run-as` + `sqlite3` hôte : `user_version = **12**` ; `unit` backfillée
   conformément au code (`app_db.dart` v11→v12, `6133af9`) : `miam`/`natural` et `miam`/
   `artificial` → `ml` (défaut de colonne), `miam`/`solid` → `g`, `dodo` → `min`,
   `caca`/`sante` → NULL (quantity y est NULL) ; lignes de rappels `''` (sentinelle v1.2.0)
   ré-attribuées au bébé unique.
5. Historique après migration (`migration/03-v12-history-migre.png`) : tous les événements
   visibles avec les bonnes unités (120 ml / 100 ml / 40 g).

**Note d'honnêteté** : la vérification base est faite sur le build du point v12 (couche données) ;
les deux corrections d'affichage (`history_tile.dart`) sont tombées après, sur une couche qui ne
touche ni schéma ni migrations — `app_db.dart` (schemaVersion 12 + backfill) est byte-identique à
celui vérifié (dernier commit le touchant : `6133af9`). Le build final rend bien des données de
schéma v12 : cas 8 de la porte, sur les deux plateformes (`08_historique.png`).

## 2. Porte — 8 cas, les deux plateformes

Commandes :

```
flutter test integration_test/pickers_gate_rc2.dart --no-uninstall -d emulator-5554
flutter test integration_test/pickers_gate_rc2.dart --no-uninstall -d <udid iPhone 17 Pro>
```

Les logs brutes (`gate-*.log`, dans `docs/release-evidence/v1.2.1-rc.2/` sur la machine de
passage) ne sont pas commitées (`*.log` est gitignorée) — toutes les lignes `[GATE]` et
`[CAPTURE]` utiles sont reprises dans le tableau ci-dessous.

Les captures sont écrites **dans** le sandbox de l'app (`Documents/gate/`) puis extraites
(`adb exec-out run-as … cat` / copie du conteneur simulateur) — d'où `--no-uninstall` : un
`flutter test` ordinaire déinstalle l'app en teardown et emporte les captures.

| # | Cas | Preuve `[GATE]` (identique sur les 2 plateformes) |
|---|-----|---------------------------------------------------|
| 1 | prise · nouvelle | 1 slider, min=0 max=120, divisions=120 |
| 2 | prise · édition (110 ml) | 1 slider, min=0 max=300, divisions=30, value=110 |
| 3 | sieste · édition (95 min) | 1 slider, min=0 max=480, divisions=96, value=95 |
| 4 | poids · nouvelle | 1 slider, min=200 max=20000, divisions=1980, value=3500 |
| 5 | poids · édition (6,12 kg) | 1 slider, min=200 max=20000, divisions=1980, value=6120 |
| 6 | température · édition (37,2 °C) | 1 slider, min=33 max=42, divisions=90 (pas 0,1), value=37.2 |
| 7 | saisie manuelle + export | 22 min au stepper → `miam/min/22.0` en base ET dans l'export ; export **format 3, schéma 12, 5 événements, 3 mesures** |
| 8 | frise d'historique | la sieste se lit en « Durée: 95 min » seule — pas de « Quantité », pas d'exception, date/heure sur deux lignes |

**8/8 sur Small_Phone** et **8/8 sur iPhone 17 Pro** (locale FR dans la porte ; le cas EN
débordant est couvert par le test de régression widget §5). Chaque cas 1–6 assert en plus
l'absence des libellés de la paire B2 et `takeException() isNull`. Documents d'export sortis du
sandbox : `export-small_phone.json`, `export-iphone17pro.json`.

## 3. Screenshots

- `screenshots/gate/android/` — 8 PNG, Small_Phone 720×1280.
- `screenshots/gate/ios/` — 8 PNG, iPhone 17 Pro 1206×2622.
- `migration/01..03` ci-dessus.

## 4. Suite de tests

- `flutter analyze --fatal-infos --fatal-warnings` : **no issues**.
- `flutter test` : **1382 passing**.
- Le test de régression d'overflow (`history_tile_test.dart`) charge la **Roboto réelle** du cache
  SDK : en widget test, la police par défaut (Ahem) est carrée et ~2× plus large que Roboto, ce qui
  fausse tout raisonnement en dp. À 360×640 dp, locale EN, il attend `takeException() isNull`
  (le RenderFlex overflow est un exception debug). Garde-fou prouvé : repasser la date en une
  ligne fait échouer le test (overflow 9,5 px) ; restaurée, il passe.

## 5. Lacunes connues

- Pas de passe iOS sur petit écran : le plus petit iOS (iPhone SE, 375 dp) est déjà plus large que
  Small_Phone (360 dp) ; le débordement observé n'existait qu'à 360 dp.
- B13 (écriture double `quantity`/`duration` du sommeil) : affichage payé ici, modèle différé.
