# BUG — le prénom du bébé est sous la barre d'état (Android), invisible

**Statut:** ouvert · **Priorité:** bloquant pour la release (c'est la fonctionnalité demandée le
2026-10-03) · **Plateforme:** Android (iOS : visible, mais placement déjà douteux)

## Constat, vérifié à l'œil et par le dump
- Capture Android (`/tmp/mamadera-path/step8-home-lea.png`) : barre supérieure « Mamadera », aucune
  trace de « Lea » au-dessus de la grille.
- `uiautomator` : le nœud « Lea / 4 months old » est à **[337,32][383,72]** — donc dans la bande de
  la barre d'état système, en haut à droite.
- Sur iOS la même place retombe juste à côté de l'horloge (« 16:18 Léa ») et reste lisible : le
  défaut est Android, mais le *placement* est déjà suspect sur les deux plateformes.

## Mécanisme probable
Le prénom est posé dans la zone hors `SafeArea` : Android ne laisse pas la barre d'état transparente de
la même façon qu'iOS, donc ce qui passe en `y=32` est masqué par le système là où iOS le montre.

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
