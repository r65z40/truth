# Images des scènes de terrain

Images de fond facultatives des interrogatoires et perquisitions. Si le fichier
référencé par la clé `image` d'une scène (`data/field/<scène>.json`) existe, il
s'affiche à la place du décor dessiné ; s'il manque, la scène retombe
automatiquement sur le dessin (`FieldArt`). On peut donc livrer les images une
par une sans jamais casser une scène.

## Format

- **16:9**, haute résolution ; `.webp` de préférence (ou `.png`).
- L'image est affichée en entier (jamais déformée ni rognée), dans un cadre 16:9.
  Cadre un décor lisible, objets examinables bien visibles, sans interface ni texte.

## Fond vidéo (animation)

- Pour animer une scène, une clé `video` (`res://assets/field/<nom>.ogv`) joue une
  vidéo **en boucle** derrière les zones cliquables, à la place de l'image.
- Format **Ogg Theora (.ogv)**, le seul lu nativement par Godot (pas de .mp4/.webm
  sans greffon). La vidéo doit être **16:9**. Priorité : vidéo > image > décor.
- Les zones (`spot`) restent en fractions, calées pareil sur la vidéo.

## Zones cliquables (`spot`) et placement

- Une `spot` est `[x, y, largeur, hauteur]` en **fractions de l'image**, chaque
  valeur entre 0 et 1 (`0,0` = coin haut-gauche, `1,1` = coin bas-droite). Ainsi
  la zone reste calée sur l'objet quelle que soit la taille de l'écran.
- **Éditeur de zones** : dans une scène de terrain, touche `F2` pour activer le
  mode placement, puis glisser un rectangle sur l'objet. Les coordonnées sont
  imprimées dans la console et copiées dans le presse-papiers, prêtes à coller
  dans le `spot` de la scène. `F2` de nouveau pour quitter le mode.
- L'ancien repère en pixels (640 × 300) reste accepté pour les décors dessinés.

## Obscurité et ambiance

- `darkness` : la scène est dans le noir, on promène une lampe. Une image assez
  lumineuse convient : c'est le jeu qui l'assombrit.
- `ambience` : grain, poussière, lumière qui vacille, dérive lente de l'image.
  Rien à prévoir dans l'image ; garder une marge de quelques pour cent sur les
  bords (l'image est très légèrement agrandie quand elle dérive).

## Images attendues

- `search_54030_atelier.webp` : atelier d'horloger, mur de pendules arrêtées,
  établi avec loupe, carton de radio sur une étagère basse, porte de
  l'arrière-boutique à droite.
- `search_54030_arriere.webp` : arrière-boutique, pendule de voyage sous un drap
  sur une étagère à gauche, lit de camp au centre, armoire à droite.
  En attendant, ces deux pièces sont dessinées par le jeu.

## Nommage

- Perquisitions : `search_<dossier>_<pièce>.webp` (ex. `search_40921_salon.webp`).
- Interrogatoires : `interrogatoire_<dossier>.webp` (ex. `interrogatoire_51307.webp`).
- Lieux (soirées, scènes d'ambiance) : `lieu_<dossier ou thème>_<lieu>.webp`.

Les prompts de génération et la convention complète sont dans le doc
« Scénario & prompts images ».
