# Portraits des citoyens (photos d'identité)

Images facultatives qui remplacent la photo d'identité **dessinée** par le jeu.
Chaque dossier déclare le fichier attendu dans la clé `image` de son bloc
`photo` (voir `data/cases/case_<dossier>.json` et `scripts/ui/id_photo.gd`).

## Repli automatique

Si le fichier référencé n'existe pas, le jeu garde la photo dessinée à partir
des traits (`face`, `hair`, `mark`, etc.). On peut donc livrer les portraits un
par un sans jamais casser un dossier. L'extension est libre (`.webp`, `.png`
ou `.jpg`, même nom de base) : voir `MediaLibrary`.

## Format

- Portrait d'identité judiciaire **vertical**, buste de face, fond uni
  gris-vert, expression neutre, noir et blanc argentique viré.
- Proportions proches de 4:5 (l'image est ajustée dans le cadre sans être
  déformée ; un portrait vertical remplit bien le cadre).
- Respecter les traits du personnage (cicatrice, moustache, lunettes…)
  décrits dans le document des besoins d'assets, pour rester cohérent.

## Fichiers attendus

| Dossier | Citoyen | Fichier |
| --- | --- | --- |
| 40921 | SEDLAR, Anton Pavel | `visage_40921.webp` |
| 51307 | ORLIK, Bohdan | `visage_51307.webp` |
| 52044 | KOVAC, Zora | `visage_52044.webp` |
| 52310 | VARGA, Teodor (fiche 1986) | `visage_52310.webp` |
| 52310 | VARGA, Teodor (fiche lecteur 1979) | `visage_52310_1979.webp` |
| 53118 | TILL, Ewa | `visage_53118.webp` |
| 53402 | VRABEC, Marek | `visage_53402.webp` |
| 53517 | PETRAS, Vaclav | `visage_53517.webp` |
| 53760 | KREMER, Henrik | `visage_53760.webp` |

Les deux fiches du dossier 52310 doivent paraître deux hommes **différents** :
c'est la contradiction centrale du dossier.
