# Google Play Console — fiche FR (fr-FR)

Version **1.2.1** (`versionCode` 11). Play publie **par langue** : chaque localisation a son
titre, sa description courte, sa description complète et **ses notes de version**.

## Titre — deux options

| option | valeur | limite |
|---|---|---|
| **garder** | `Mamadera Suivi Bébé` | 19/30 |
| candidat | `Mamadera : poids & tétées` | 24/30 |

Le titre est le signal ASO le plus fort d'une fiche en place : il se change par stratégie,
pas par release. Le candidat contient « tétées » — mot que l'app n'affiche jamais (son bouton
dit **Nourriture**) : `make store-check` le signale, à trancher à la revue.

## Coller depuis `../fields/`

| champ Play | fichier | limite | origine |
|---|---|---|---|
| Description courte | `../fields/play-fr-short.txt` | 80 | TranslateGemma, aligné |
| Description complète | `../fields/play-fr-description.txt` | 4 000 | TranslateGemma, aligné |
| Notes de version | `../release-notes/play-fr.txt` | 500 | TranslateGemma, aligné |

Sortie brute du modèle sous [`../machine/fr/`](../machine/fr/). Le plafond de 500 caractères
des notes est celui de Play, et le français s'allonge de 20 à 50 % : si ça déborde, on
raccourcit `store/source/en/play-release-notes.txt` et on relance
`python3 scripts/build_store_package.py --translate` — jamais en rognant le français.

## Sécurité des données — inchangée par 1.2.1

« Je ne collecte, ne partage et n'autorise l'accès à aucune donnée ». 1.2.1 ajoute une
colonne `unit` à la base locale : aucun réseau, aucune nouvelle autorisation, donc rien à
déclarer de nouveau. Note libre à maintenir :

> Toutes les données de suivi du bébé sont stockées localement sur l'appareil dans une base
> SQLite ; les notes textuelles sensibles sont chiffrées champ par champ en AES-256-GCM (le
> fichier de base lui-même n'est pas chiffré). Aucune donnée ne quitte le téléphone sauf
> export JSON volontaire. Nous ne collectons, partageons ni transmettons aucune donnée.

Catégorie : **Santé et forme** (recommandation — la catégorie réellement publiée n'est pas
consignée dans `docs/`, à vérifier dans la Console avant d'y toucher). Public : parents de
nouveau-nés, déclaré « Enfants » — déjà en place.

## Notes de version — où les coller

Dans la **release** (boîte « Notes de version », par langue), pas seulement dans la fiche :
c'est ce que le parent lit en mettant à jour. `../release-notes/play-fr.txt`, 427/500.
