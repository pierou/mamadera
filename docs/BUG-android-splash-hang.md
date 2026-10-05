# BUG — Android ne dépasse jamais le splash ( Small_Phone, 360×640 dp )

**Statut:** **CLOSED — cause trouvée : `android:theme="@style/LaunchTheme"` absent du manifeste.**
Ni une régression de la branche, ni une famine mémoire. Voir `BUG-baby-name-under-status-bar.md`. · **Ouvert:** 2026-10-04 · **Plateforme:** Android ( deux émulateurs )
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

## Clarification de la méthode (mes erreurs, notées pour qu'on ne les répète pas)
- Les captures de 708 Ko et 37 Ko étaient **le launcher Android**, pas l'app : le fond d'écran
  riche explique la taille. Une capture n'est un fait qu'après avoir été regardée ET identifiée.
- `am start -W` → `Status: timeout` ne prouve pas la mort du process : l'app était vivante et
  `topResumedActivity` était bien `com.pvjio.mamadera/.MainActivity`.
- Ce qui est établi, par convergence et non par un seul signal : process vivant, activity au
  premier plan, `crash` buffer vide, aucune ligne `AndroidRuntime`/`F DEBUG`/`MissingPlugin`,
  et l'écran reste le **splash natif** (fond clair, alors que l'app vérifiée est sombre) pendant
  des minutes. Donc : **le premier rendu Flutter ne remplace jamais le splash.**
- La règle manquante dès le départ : comparer la taille des captures ne dit rien. `dumpsys` pour
  savoir quelle activity est au premier plan, puis regarder l'image, puis conclure.

## Clôture — ma conclusion était fausse
Un autre poste (même dépôt, même HEAD `a112d5a`, même Flutter, images émulateur identiques) construit
l'APK de la branche et lance :

| lancement | résultat |
|---|---|
| `install -r` + prefs (consentement accepté) | \`Status: ok\`, TotalTime **1756 ms** → **écran « Nouveautés de Mamadera 1.2.0 » rendu** |
| `pm clear` (installation fraîche, sans consentement) | \`Status: ok\`, TotalTime **1920 ms** → **Conditions rendues, bouton « I Accept »** |
| tap « I Accept » | **domicile rendu** avec la dialogue d'ajout de bébé → **un \`onCreate\` v11 frais s'exécute sans blocage** |
| \`logcat -s flutter:* ActivityManager:*\` pendant 60 s | aucune erreur Flutter, aucun \`MissingPlugin\`, aucun crash |

Il n'y a **donc pas de régression de code.** La cause est l'hôte d'origine : le limiteur mémoire du
Mac affame ou redémarre qemu. Les symptômes collent exactement à un thread de rendu affamé plutôt
qu'à un Dart bloqué — rafales de « Skipped N frames » (un vrai blocage avant \`runApp\` ne produirait
pas de sauts d'images, il n'y aurait pas de boucle d'images du tout), \`FlutterRenderer: Width is
zero\`, moteur vivant sans premier rendu, et les tests d'intégration verts sur ce même émulateur.

**Ce que mon A/B n'était pas : un A/B.** Comparer 1.1.1 et 1.2.0 sur le même émulateur *après*
plusieurs builds lourds sur un poste déjà sous pression mémoire ne compare pas deux builds, ça
compare deux états de l'hôte. Leçon à garder : un A/B ne vaut que si l'environnement est tenu
constant, et « ça marche sur une autre machine » est une donnée qui doit venir avant une conclusion,
pas après.

## Ce que cette clôture valide au passage (et qui n'avait jamais été vérifié)
- **\`onCreate\` v11 depuis une installation réellement fraîche**, exécuté et rendu — le point que la
  passe iOS (base plantée et migrée) ne prouvait pas.
- **L'écran des notes de version 1.2.0 rendu pour de vrai** sur l'appareil.

## Reste ouvert
Le parcours manuel (biberon en ml, tétée en min, solide en g, poids) et l'inspection du JSON exporté.

## Cause réelle (trouvée, pas devinée)
`MainActivity` n'avait pas `android:theme="@style/LaunchTheme"` (`Theme.Light.NoTitleBar`). Sans lui,
Android monte une ActionBar native « Mamadera » et garde le thème clair par défaut : ce que j'ai pris
pour un splash bloqué était **l'app rendue derrière la barre native**, sur fond clair. Le splash
bouteille appartenait au thème par défaut. Le prénom, posé en haut du corps scrollable, tombait à
`y=32` — sous la barre système.

**Ce que j'ai affirmé à tort, dans l'ordre :** (1) « régression de la branche » — non, `main` a le
même manifeste ; (2) « le limiteur mémoire du Mac affame qemu » — non plus, c'était le thème ;
(3) des captures du launcher et une capture derrière l'ActionBar lues comme des preuves. Chaque
conclusion tenait sur un seul signal au lieu de la convergence. La règle qui manque : identifier
l'écran (dumpsys + regard) avant d'interpréter, et faire l'A/B sur **deux machines** avant de
conclure à une régression.
