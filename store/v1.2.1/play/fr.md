# Google Play Console — fiche FR (fr-FR)

Version **1.2.1** (build 11 → `versionCode` 11). Limites Play : titre 30, description
courte 80, description complète 4 000, notes de version 500.

## Titre — deux options

| option | valeur | |
|---|---|---|
| **garder** | `Mamadera Suivi Bébé` | 19/30 |
| candidat | `Mamadera : poids & tétées` | 24/30 |

Le titre est le signal ASO le plus fort sur Play : le changer sur une fiche en place se
justifie par une stratégie, pas par une release. Décision propriétaire.

## Description courte — deux options

| option | valeur | |
|---|---|---|
| **garder** | `Suivi bébé 100% privé : tétées, sommeil, couches — hors-ligne & chiffré` | 71/80 |
| candidat | `Suivi bébé privé : tétées, poids, sommeil, couches — hors-ligne et chiffré` | 74/80 |

Le candidat nomme le poids, absent des textes depuis v1.1.0 alors que la mesure est en
production depuis v1.2.0.

## Description complète (4 000)

```
Suivez les tétées, le sommeil, les changements de couche et la santé de votre nouveau-né avec une confidentialité totale. Toutes les données restent sur votre appareil — pas de cloud, pas de suivi, pas de télémétrie.

Fonctionnalités :
• Historique des tétées (seins/biberons) et de l'alimentation solide, en grammes
• Suivi du poids, de la taille et de la température — valeurs chiffrées sur l'appareil
• Les mesures s'affichent dans l'historique, à côté des autres événements, et se modifient ou se suppriment depuis cet écran
• Journal des couches, avec texture des selles
• Rappels santé (Vitamine D/K) — et rappels personnalisés liés à un soin
• Rappels indépendants pour chaque enfant
• Saisie rétroactive d'un événement avec date et heure exactes
• Profils multiples pour bébé
• Sauvegarde et restauration JSON, 100 % sur l'appareil
• Notes chiffrées au repos

Mamadera est open source sous licence MIT. Les données de votre bébé ne quittent jamais votre téléphone, sauf si vous lancez vous-même l'export JSON puis le panneau de partage de votre appareil.
```

## Notes de version (500)

Coller [`../release-notes/play-fr.txt`](../release-notes/play-fr.txt) — 460/500.

## Sécurité des données (à ne pas toucher sauf changement réel)

« Je ne collecte, ne partage et n'autorise l'accès à aucune donnée » — inchangé : v1.2.1
ajoute une colonne `unit` à la base locale, aucun réseau, aucune nouvelle autorisation.
Note libre à garder :

> Toutes les données de suivi du bébé sont stockées localement sur l'appareil dans une
> base SQLite ; les notes textuelles sensibles sont chiffrées champ par champ en
> AES-256-GCM (le fichier de base lui-même n'est pas chiffré). Aucune donnée ne quitte
> le téléphone sauf export JSON volontaire. Nous ne collectons, partageons ni transmettons
> aucune donnée utilisateur.

Catégorie : **Santé et forme** (recommandation — la catégorie actuellement en place sur la
fiche n'est pas consignée dans `docs/`, à vérifier dans la Console avant de la modifier).
Public cible : parents de nouveau-nés, déclaré « Enfants » (l'app est utilisée par
l'adulte pour le compte du nourrisson) — réponse déjà en place, inchangée.
