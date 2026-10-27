# Ajouter ou remplacer musiques, ambiances, bruitages et images

Tous les médias du jeu sont **déclarés dans des fichiers de données** : aucun
chemin de fichier n'est écrit dans le code. Pour ajouter ou changer un son ou
une image, il suffit de **déposer le fichier au bon endroit** (et, au besoin,
de modifier une ligne de JSON).

Règles communes :

- **Un fichier absent n'est jamais une erreur** : le jeu se tait (son) ou garde
  son dessin / fond uni (image). On peut donc livrer les médias un par un.
- **Extension libre** : si `tampon_01.ogg` est déclaré mais que vous déposez
  `tampon_01.wav` ou `tampon_01.mp3`, il est utilisé. Idem pour les images
  (`.png`, `.webp`, `.jpg`).
- **Boucles automatiques** : musiques et ambiances bouclent toutes seules, pas
  besoin de cocher « Loop » à l'import.
- Après avoir déposé un fichier, **ouvrir le projet dans Godot** pour qu'il soit
  importé (sinon le jeu ne le voit pas).
- Noter l'origine et la licence dans `assets/LICENCES.md` (et la mention
  « généré par IA » le cas échéant, pour Steam).

## Vérifier d'un coup d'œil : l'écran « Médias »

Menu principal > **Visite des scènes** > **OUTILS > Médias**. Chaque musique,
ambiance, bruitage, image et décor de terrain y est listé avec son chemin,
**FOURNI** ou **MANQUANT**, un bouton **ÉCOUTER** pour les sons et une vignette
pour les images. C'est la liste de courses des médias à produire.

## Musique : `data/music.json`, fichiers dans `assets/music/`

Un morceau par moment du jeu (menu, bureau selon l'acte, soirée, terrain...),
choisi par des règles (acte, drapeaux, indicateurs). Voir `assets/music/README.md`.
Réglage du volume d'un morceau : `"volume_db"` (0 = normal, -6 = deux fois moins fort).
Un morceau qui ne doit pas boucler : `"loop": false`.

## Ambiances : `data/sounds.json` > `ambiances`, fichiers dans `assets/sounds/ambiances/`

Boucles de fond longues (pluie, néons du bureau, appartement, salle
d'interrogatoire...), jouées **sous** la musique avec leur propre volume.
`ambiance_rules` choisit l'ambiance selon le moment du jeu, exactement comme la
musique (mêmes conditions : `act`, `requires_flags`, `min_indicator`...).

Conseils : 1 à 3 minutes, sans début ni fin marqués (pour que la boucle ne
s'entende pas), mixées bas.

## Bruitages : `data/sounds.json` > `effects`, fichiers dans `assets/sounds/effets/`

Sons brefs déclenchés par le jeu. Chaque son peut avoir **plusieurs variantes**
(`files`) : une est tirée au hasard à chaque fois, et `pitch_variation` change
un peu la hauteur, pour que le tampon ne sonne pas deux fois pareil.

| Son | Quand |
|---|---|
| `ui_click` | tout bouton (automatique) |
| `ui_hover` | survol d'un bouton (facultatif) |
| `window_open`, `window_close` | ouverture / fermeture d'une fenêtre |
| `paper` | lecture d'une pièce |
| `note` | élément noté au carnet |
| `confront_success`, `confront_fail` | confrontation réussie / ratée |
| `stamp` | conclusion transmise (tampon) |
| `typewriter` | texte qui s'affiche au terminal |
| `notification` | notification brève du bureau |
| `mail` | nouvelle journée (courrier arrivé) |
| `day_end` | fin de service |
| `door` | changement de pièce en perquisition |

Format conseillé : `.wav` ou `.ogg`, mono, court (moins d'une seconde pour les
clics), sans silence au début.

**Ajouter un nouveau bruitage** : une entrée dans `effects`, puis dans le code de
la scène `Sound.play("mon_son")`. Pour donner un son particulier à **un bouton**,
sans code : dans Godot, sélectionner le bouton > Inspecteur > *Metadata* >
ajouter `sound` (texte) = `"stamp"` ; une valeur vide le rend muet.
**Son lié à un événement du jeu** : `game_events` associe un signal de
`GameState` (`decision_applied`, `day_started`...) à un bruitage.

## Images : `data/images.json`, fichiers dans `assets/images/`

Chaque écran demande son image par un nom d'emplacement stable :

| Emplacement | Où | Sans image |
|---|---|---|
| `menu_background` | fond du menu principal | fond uni |
| `desk_wallpaper` | fond d'écran du bureau | trame et emblème dessinés |
| `intro_city` … `intro_signature` | pages de l'introduction | dessin |
| `evening_background` | fond des soirées (assombri) | fond uni |
| `act_review_background` | fin d'acte (assombri) | fond uni |

Remplacer une image : écraser le fichier (même nom), ou changer le chemin dans
`data/images.json`. La taille conseillée est indiquée dans le fichier (`size`).
Les fonds s'affichent en « couverture » (recadrés au centre), l'introduction
en entier.

## Décors des scènes de terrain : `data/field/*.json`, fichiers dans `assets/field/`

Clé `image` (ou `video`, en `.ogv`) de chaque scène ou pièce. Voir
`assets/field/README.md` (format 16:9, zones cliquables, éditeur F2).

## Réglages du joueur

Paramètres > **SON** : volume de la musique, des ambiances et des bruitages,
séparément. Le bouton haut-parleur de la barre des tâches coupe tout le son.
Techniquement : trois bus audio `Music`, `Ambience`, `Sfx` (créés au lancement).
