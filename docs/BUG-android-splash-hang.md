# BUG — Android ne dépasse jamais le splash ( Small_Phone, 360×640 dp )

**Statut:** **REGRESSIF CONFIRMÉ — bloquant pour la release** · **Ouvert:** 2026-10-04 · **Plateforme:** Android ( deux émulateurs )
**Build:** app-debug.apk de la branche `feat/v1.2.0-growth-and-baby-scoped-reminders` (95 835 048 octets), installé avec `install -r -g` → Success.

## Fait établi, pas supposé
- `am start -W -n com.pvjio.mamadera/.MainActivity` → **`Status: timeout`** : l'activité ne signale
  jamais son premier rendu. Ce n'est pas une écran lent, c'est un premier rendu qui n'arrive pas.
- Le processus **vit** (pid 6346), le moteur Flutter démarre, la surface est créée en 720x1280, les
  viewport metrics sont envoyés — puis plus rien que des **"Skipped N frames"** (64, 116, 34, 57).
  Aucune exception, aucun FATAL, aucun crash dans le buffer `crash`.
- `FlutterRenderer: Width is zero. 0,0` apparaît deux fois au démarrage, avant la création de surface.
- Les mêmes écrans **réussissent** sous `flutter test integration_test` sur ce même émulateur
  (rendering_validation_test.dart + feeding_tracking_flow_test.dart → tous passés). Donc le widget
  tree sait rendre sur cet appareil : la différence est le lanceur, pas le rendu.
- `FlutterSecureStorage` a complété sa migration sans erreur lors d'une exécution précédente
  (pid 4902, 17:52) — "Data migration completed successfully". Le keystroke n'est donc pas
  prouvé coupable ; c'est un suspect, pas un verdict.
- iOS (iPhone 17, même build) : aucunsplash hang, tous les écrans rendus et vérifiés visuellement.

## Ce que la passe a manqué
Le parcours manuel (biberon en ml, solide en g, poids, export JSON inspecté) et l'écran de
consentement tapé pour de vrai n'ont **pas** été faits : l'app ne quitte pas le splash.

## Prochain diagnostic, dans cet ordre
1. `am start -W` sur `Pixel_10_Pro` (même build) : si ça démarre, le problème est lié à la
   configuration de Small_Phone (résolution/densité/API), pas au code applicatif.
2. `logcat` filtré sur le pid courant, en cherchant la **dernière** ligne avant le silence — pour
   savoir si le blocage est avant `runApp`, dans un canal plugin, ou dans la main de Dart.
3. `flutter run --verbose -d emulator-5554` : le handshake engine↔app est visible, contrairement
   a `am start`.
4. Ne pas masquer le symptome (pas de splash timeout, pas de `postFrameCallback\) de contournement)
   avant d'avoir la cause : un splash qui ne finit jamais sur un device Android livré est un
   utilisateur perdu, pas un détail cosmetique.

## Preuves conservées
`/tmp/sp.png` `/tmp/sp2.png` `/tmp/sp3.png` `/tmp/small_home.png` `/tmp/clean.png` (splash)
`/tmp/name.jpg` (iOS, domicile avec le prénom) · journal: `/tmp/integ.log` `/tmp/emu.log`

## A/B décisif — c'est notre branche, pas l'émulateur
Même émulateur (emulator-5556, Pixel_10_Pro), même appareil de build, deux APK :

| build | \`am start -W\` | premier rendu | écran vu |
|---|---|---|---|
| **v1.1.1 (main)** | **\`Status: ok\`** | **TotalTime 4021 ms** | Conditions affichées, bouton « I Accept » rendu |
| **v1.2.0 (cette branche)** | **\`Status: timeout\`** | jamais | splash natif, écran clair, aucun contenu Flutter |

Reproduit sur \`Small_Phone\` (360×640 dp) **et** \`Pixel_10_Pro\` : ce n'est pas une configuration
d'écran. Et la version publiée fonctionne sur le même appareil : **c'est une régression introduite
par cette branche.**

## Ce que cela implique pour la vérification iOS (honnêteté, pas une note en bas de page)
La passe iOS a été faite avec **une base v10 plantée puis migrée** : elle prouve la montée
v10 → v11 et le rendu, elle ne prouve **pas** un \`onCreate\` v11 depuis une installation vraiment
fraîche. Le tout premier lancement iOS de v1.2.0 a bien affiché les conditions — mais la base est
en \`LazyDatabase\` : elle n'est créée qu'au premier accès, donc après consentement. **Aucune
plateforme n'a encore exercé \`onCreate\` v11 jusqu'au bout.** Le suspect n°1 est donc un chemin
d'initialisation bloquant avant le premier rendu Android — la piste principale étant l'init du
stockage sécurisé / du service de chiffrement invoqué au démarrage, que les tests d'intégration
court-circuitent.

## Prochain diagnostic, dans cet ordre
1. \`flutter run --verbose -d emulator-5556\` sur la branche : le handshake engine↔app est visible,
   contrairement a \`am start\` — on verra où ça bloque.
2. \`logcat\` filtré sur le pid courant, chasser la **dernière** ligne avant le silence, en cherchant
   \`FlutterSecureStorage\`, \`EncryptionService\`, \`drift\`, \`SQLite\`.
3. Bisecter la branche : \`git revert\` provisoire de M5 (module croissance) puis M1 (schéma v11)
   sur une branche jetable, pour encadrer la régression par commit.
4. Vérifier un \`onCreate\` v11 depuis une installation réellement fraîche, sur **les deux**
   plateformes, avant toute ouverture de PR.

Ne pas masquer le symptôme (pas de timeout de splash, pas de \`postFrameCallback\` de contournement)
avant d'avoir la cause.
