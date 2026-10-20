# App Store Connect — fiche FR (fr-FR)

Version **1.2.1** (build 11). Chaque champ a **un seul fichier** dans
[`../fields/`](../fields/) : c'est lui qu'on colle, jamais une recopie. Ce guide ne
répète pas le texte — il dit ce qu'on garde, ce qu'on change, et pourquoi.

## Nom — garder `Mamadera Suivi Bébé`

Approuvé et en place depuis v1.1.0. Le renommer casse l'historique ASO et relance un
contrôle d'unicité côté Apple. Décision propriétaire, pas une tâche de release.

## Sous-titre — deux options

| option | valeur | limite |
|---|---|---|
| **garder** | `Suivi nouveau-né 100% privé` | 27/30 |
| candidat | `Tétées, sommeil, croissance` | 27/30 |

Le candidat nomme le troisième axe de mesure (poids/taille/température), absent de tous les
champs depuis v1.1.0. **Attention :** l'app n'écrit jamais « tétées » — son bouton
(`homeButtonMiam`) dit **Nourriture**. Un sous-titre qui nomme une chose que l'écran ne
montre pas est un écart entre la fiche et l'app, pas une amélioration. `make store-check`
le signale en WARN ; c'est une décision à prendre à la revue, pas à laisser passer.

## Les champs longs — coller depuis `../fields/`

| champ ASC | fichier | limite | origine |
|---|---|---|---|
| Mots-clés | `../fields/apple-fr-keywords.txt` | 100 | éditorial — jamais traduit par une machine |
| Texte promotionnel | `../fields/apple-fr-promo.txt` | 170 | TranslateGemma, aligné |
| Description | `../fields/apple-fr-description.txt` | 4 000 | TranslateGemma, aligné |
| Nouveautés | `../release-notes/apple-whatsnew-fr.txt` | 4 000 | `assets/patch_notes/fr.json` |

Le texte français est celui de TranslateGemma, aligné terme à terme sur
`lib/l10n/app_fr.arb` ; sa sortie brute est sous [`../machine/fr/`](../machine/fr/).
Si un mot ne convient pas, on corrige **`store/source/en/`** (ou on ajoute une règle
d'alignement citée dans `scripts/build_store_package.py`) et on relance
`python3 scripts/build_store_package.py --translate` — éditer `../fields/` localement fait
perdre la phrase au prochain build, et la fiche se retrouve avec du texte que personne n'a
relu.

## Notes pour l'équipe de revue

- Aucun compte de démonstration : l'app fonctionne dès le premier lancement, conditions
  acceptées, rien à connecter.
- Pour voir les mesures chiffrées : Accueil → bouton **Poids** → Enregistrer, puis onglet
  **Historique** — la ligne apparaît avec son unité (`6,18 kg`, virgule française).
- « Lait Maternel » propose un bascule ml / minutes ; les autres types d'alimentation ont
  une unité fixe.
- Pas de contenu médical, pas de diagnostic, pas de conseil : l'app enregistre ce que le
  parent saisit. L'allaitement y est parental, non sexuel.
