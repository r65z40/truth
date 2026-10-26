# Images des scènes de terrain

Images de fond facultatives des interrogatoires et perquisitions. Si le fichier
référencé par la clé `image` d'une scène (`data/field/<scène>.json`) existe, il
s'affiche à la place du décor dessiné ; s'il manque, la scène retombe
automatiquement sur le dessin (`FieldArt`). On peut donc livrer les images une
par une sans jamais casser une scène.

## Format

- Paysage, haute résolution ; `.webp` de préférence (ou `.png`).
- L'image est dessinée dans le repère des zones cliquables (640 × 300) : cadre un
  décor lisible, avec les objets examinables bien visibles, sans interface ni
  texte. Les zones cliquables (`spot`) sont posées par-dessus dans le moteur.

## Nommage

- Perquisitions : `search_<dossier>_<pièce>.webp` (ex. `search_40921_salon.webp`).
- Interrogatoires : `interrogatoire_<dossier>.webp` (ex. `interrogatoire_51307.webp`).

Les prompts de génération et la convention complète sont dans le doc
« Scénario & prompts images ».
