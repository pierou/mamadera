# BUG — le prénom du bébé est sous la barre d'état (Android), invisible

**Statut:** **CORRIGÉ** (manifeste + prénom déplacé dans le `AppBar`) · **Plateforme:** Android
**Cause racine :** `android:theme="@style/LaunchTheme"` absent sur `MainActivity`. `LaunchTheme` est
`Theme.Light.NoTitleBar` ; sans lui, Android dresse une ActionBar native « Mamadera » ET laisse le
thème clair par défaut. Ce sont bien cette barre native et ce fond clair vus dans les captures — je
les avais pris pour l'app bar Flutter et pour un splash bloqué.

**Provenance — vérifiée :** `main` n'a pas non plus ce thème (`git show main:android/app/src/main/AndroidManifest.xml`).
Donc **pas une régression de cette branche** : un défaut **déjà présent dans la version publiée**,
latent depuis `892ff41` (2026-07-26), que la branche a seulement rendu visible en plaçant du contenu
dans cette bande. En production, la barre ActionBar fantôme existe donc aussi aujourd'hui.

## Constat, vérifié à l'œil et par le dump
- Capture Android (`/tmp/mamadera-path/step8-home-lea.png`) : barre supérieure « Mamadera », aucune
  trace de « Lea » au-dessus de la grille.
- `uiautomator` : le nœud « Lea / 4 months old » est à **[337,32][383,72]** — donc dans la bande de
  la barre d'état système, en haut à droite.
- Sur iOS la même place retombe juste à côté de l'horloge (« 16:18 Léa ») et reste lisible : le
  défaut est Android, mais le *placement* est déjà suspect sur les deux plateformes.

## Mécanisme, établi (et non « probable »)
Sans `LaunchTheme`, l'activité reçoit un thème par défaut **avec** ActionBar : cette barre occupe la
bande système et pousse le contenu Flutter vers le bas, alors que le prénom était posé en haut du
corps scrollable → `y=32`, sous la barre. iOS n'a pas d'ActionBar native, donc le même placement y
retombeait juste à côté de l'horloge et restait lisible. Le « splash qui ne finit jamais » de
`BUG-android-splash-hang.md` n'était donc **pas** une famine mémoire : c'était ce même défaut de thème.

## Ce qui n'est PAS un bug (noté pour éviter une fausse piste)
La troisième rangée (Poids / Taille / Température) coupée à mi-hauteur est **normale** : le domicile
est un `SingleChildScrollView` et le contenu au pli se termine à l'écran. Vérifié dans le parent de
scroll avant de conclure.

## À faire
1. Placer le prénom **dans** la `SafeArea` du `Scaffold` — idéalement comme `title` du `AppBar`
   (ou à l'intérieur du corps, sous la barre), jamais dans la bande système.
2. Re-vérifier sur Android ET iOS, capture regardée, `dumpsys` confirmant l'activity au premier plan.
3. Tester un prénom long (30+ caractères) après repositionnement — l'ellipsize actuel est validé en
   test, pas à l'œil sur le nouveau placement.

## Contexte
Découverte pendant la passe manuelle du 2026-10-04, qui a par ailleurs validé : biberon 90 ml,
solide **40 g** (unité correcte à l'écran), poids 3500 → **+10 = 3510 g**, température **37,4 °C**
exact (virgule française acceptée en locale fr, refusée en en — comportement à confirmer comme voulu),
historique avec la bonne unité par ligne, export format 2 complet (7 sections, ids uniques, notes et
valeur de poids chiffrées au repos, déchiffrées à l'export par conception).
