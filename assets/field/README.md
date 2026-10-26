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

## Zones cliquables (`spot`) et placement

- Une `spot` est `[x, y, largeur, hauteur]` en **fractions de l'image**, chaque
  valeur entre 0 et 1 (`0,0` = coin haut-gauche, `1,1` = coin bas-droite). Ainsi
  la zone reste calée sur l'objet quelle que soit la taille de l'écran.
- **Éditeur de zones** : dans une scène de terrain, touche `F2` pour activer le
  mode placement, puis glisser un rectangle sur l'objet. Les coordonnées sont
  imprimées dans la console et copiées dans le presse-papiers, prêtes à coller
  dans le `spot` de la scène. `F2` de nouveau pour quitter le mode.
- L'ancien repère en pixels (640 × 300) reste accepté pour les décors dessinés.

## Nommage

- Perquisitions : `search_<dossier>_<pièce>.webp` (ex. `search_40921_salon.webp`).
- Interrogatoires : `interrogatoire_<dossier>.webp` (ex. `interrogatoire_51307.webp`).
- Lieux (soirées, scènes d'ambiance) : `lieu_<dossier ou thème>_<lieu>.webp`.

Les prompts de génération et la convention complète sont dans le doc
« Scénario & prompts images ».
