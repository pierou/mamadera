# App Store Connect — listing FR (fr-FR)

Version **1.2.1** (build 11). Champs collés tels quels dans App Store Connect →
**Versions** → langue française. Limites ASC : nom 30, sous-titre 30, mots-clés 100,
texte promotionnel 170, description 4 000, Nouveautés 4 000.

## Nom de l'app — **garder** `Mamadera Suivi Bébé` (19/30)

Approuvé et en place depuis v1.1.0 : le renommer casse l'historique ASO et redéclenche
une revue du nom (unicité). Ne changer que sur décision du propriétaire.

## Sous-titre — deux options

| option | valeur | |
|---|---|---|
| **garder** | `Suivi nouveau-né 100% privé` | 27/30 |
| candidat | `Tétées, sommeil, croissance` | 27/30 |

Le candidat nomme la troisième mesure (poids/taille/température), absente de tous les
textes depuis v1.1.0. Décision propriétaire — le sous-titre est indexé par ASC.

## Mots-clés (100)

```
bebe,nouveau-ne,tetee,sommeil,couche,confidentialite,hors-ligne,allaitement,sauvegarde,croissance
```

97/100 — `croissance` s'ajoute, les 9 mots d'origine restent dans l'ordre. Sans accents
(ASC indexe mal) et **sans espace après les virgules** : la version espacée faisait
106/100 et dépassait la limite — compté, pas estimé.

## Texte promotionnel (170)

```
Poids, taille et température suivis et chiffrés sur l'appareil, visibles dans l'historique avec les prises, le sommeil et les couches. Aucune donnée ne quitte le téléphone.
```

## Description (4 000)

```
Suivez les tétées, le sommeil, les couches et la santé de votre bébé — tout stocké localement sur votre appareil avec chiffrement. Pas de cloud, pas de télémétrie, pas de suivi.

CE QUE VOUS POUVEZ FAIRE
• Noter les tétées et biberons, les sessions de sommeil et les changements de couche — y compris la texture des selles
• Enregistrer le poids, la taille et la température : les valeurs sont chiffrées sur l'appareil et se lisent dans l'historique, à côté des autres événements
• Modifier ou supprimer une mesure directement depuis l'historique
• Suivre les routines santé (vitamines D et K) avec leurs rappels, et créer vos propres rappels liés à un soin
• Saisir un événement avec sa date et son heure exactes, même à posteriori
• Tenir des profils séparés pour chaque enfant
• Exporter toutes vos données dans un fichier JSON et les restaurer quand vous voulez — entièrement sur l'appareil, sans compte ni cloud

CONFIDENTIALITÉ PAR CONCEPTION
Mamadera est conçu pour protéger la vie privée : les notes sensibles et les mesures sont chiffrées au repos, l'application ne demande aucune permission inutile et rien n'est jamais envoyé. Le seul chemin de sortie des données est l'export JSON que vous lancez vous-même, puis le panneau de partage de votre appareil. Gratuit, open source et sous licence MIT.

Idéal pour les parents qui valorisent leur vie privée — et pour les nouveau-nés qui méritent la leur.
```

## Nouveautés — fichier collé

[`../release-notes/apple-fr.txt`](../release-notes/apple-fr.txt) —édité depuis
`assets/patch_notes/fr.json` (la même copie que la fenêtre « Nouveautés » dans l'app,
pour qu'aucun parent ne lise deux choses différentes).

## Notes pour l'équipe de revue (App Review)

- Aucun compte de démonstration : l'app fonctionne dès le premier lancement, l'écran de
  conditions d'utilisation accepté, rien à connecter.
- Pour voir les mesures chiffrées : Accueil → bouton Poids → enregistrer, puis onglet
  Historique — la ligne apparaît avec son unité.
- L'allaitement « Lait maternel » propose un bascule ml / minutes ; les autres types
  d'alimentation ont une unité fixe.
- Pas de contenu médical, pas de diagnostic, pas de conseil : l'app enregistre ce que
  le parent saisit. Le contenu « allaitement » est parental et non sexuel.
