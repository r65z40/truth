# Scènes de terrain en 3D : cahier des charges des modèles et des images

Demande de fen (2026-10-25) : améliorer le visuel des fouilles et des
interrogatoires en 3D, avec des modèles faits (ou générés) par fen et des
ressources libres de droits (CC0).

## 1. Comment ça marche dans le jeu

- Chaque décor est décrit dans `data/field/stages/<décor>.json` : caméra,
  lumières et liste d'objets. Les règles (questions, endroits, carnet,
  procès-verbal) ne changent pas : elles restent dans `data/field/*.json` et
  `FieldRules`.
- Chaque objet indique un **fichier de modèle** (`"model"`). S'il existe, le jeu
  l'affiche ; sinon il construit l'objet en **formes simples** (`"parts"`).
  On peut donc livrer les modèles un par un : rien ne casse entre-temps.
- Certaines formes acceptent une **image** (`"texture"`) : papier peint, sol,
  photo de famille, vue par la fenêtre. Même principe : si le fichier manque,
  la couleur du thème est utilisée.
- Rendu en basse définition (`"pixel_size": 3`) : un pixel du jeu vaut 3 pixels
  d'écran. Ça donne l'aspect des premiers jeux 3D et cache le manque de détail :
  inutile de viser des modèles très fins.
- Réglage « Scènes de terrain en 3D » dans les Paramètres : désactivé, le jeu
  revient aux dessins 2D (petites machines, préférence du joueur).

## 2. Règles pour tous les modèles

| Point | Règle |
| --- | --- |
| Format | glTF binaire **`.glb`** (glTF 2.0). Godot l'importe tout seul. |
| Unités | **mètres**, 1 unité = 1 m. Respecter les dimensions ci-dessous (±10 %). |
| Axes | **Y vers le haut**, la face avant de l'objet tournée vers **+Z** (vers le joueur). |
| Origine | **au sol, au centre** de l'objet (sauf indication : lampe, cadres). |
| Poids | meubles et objets : 3 000 triangles au plus ; personnages : 8 000 au plus. |
| Textures | une seule image par modèle, **256 ou 512 px**, intégrée au `.glb`. Pas de transparence. |
| Contenu | ni caméra ni lumière dans le fichier, pas d'animation pour l'instant. |
| Style | années 80 d'un pays de l'Est imaginaire : formica, bois verni, métal peint, tissus usés. Couleurs ternes (vert-gris, brun, beige, bleu de travail), aucune couleur vive sauf un objet qui doit attirer l'œil. Pas de marques, pas de logos réels, rien de copié d'un autre jeu. |

Les fichiers se déposent **exactement** au chemin indiqué. Ensuite, ouvrir le
projet dans Godot une fois (il importe les nouveaux fichiers), puis lancer.

## 3. Audition d'ORLIK (salle n° 3, sous-sol) : `data/field/stages/interrogation.json`

| Fichier | Objet | Dimensions (l × h × p) | Remarques |
| --- | --- | --- | --- |
| `assets/models/field/characters/orlik.glb` | Bohdan ORLIK, assis | environ 0,6 × 1,4 × 0,8 | Homme de 48 ans, visage rond, front dégarni, cheveux gris, rasé de près, **une cicatrice sur la joue** (comme sur sa photo d'identité du dossier). Bleu de travail, médaille du Travail sur la poitrine, casquette gardée sur la tête. Assis, avant-bras posés sur la table (à 0,8 m du sol, 0,3 m devant lui). Origine au sol, entre ses pieds. Chaise incluse ou non (la chaise existe déjà à part). |
| `assets/models/field/interrogation/table.glb` | Table en formica | 1,6 × 0,75 × 0,9 | Plateau beige ou vert d'eau, pieds en tube métallique. |
| `assets/models/field/interrogation/chair.glb` | Chaise de bureau | 0,45 × 0,95 × 0,45 | Assise à 0,45 m. Bois et tube. |
| `assets/models/field/interrogation/lamp.glb` | Suspension | Ø 0,42 × 0,25 | Abat-jour en tôle émaillée. **Origine en haut de l'abat-jour** ; le fil monte de 0,7 m. |
| `assets/models/field/interrogation/door.glb` | Porte | 0,9 × 2,1 × 0,05 | Porte métallique avec un petit carreau dépoli à 1,55 m. |
| `assets/models/field/interrogation/folder.glb` | Chemise cartonnée | 0,34 × 0,03 × 0,25 | Dossier fermé, couleur kraft, étiquette blanche. C'est l'objet cliquable « présenter un élément ». |

Images (facultatives) : `assets/textures/field/interrogation_wall.png` (béton
peint vert-gris, se répète tous les 1 m), `assets/textures/field/interrogation_floor.png`
(carrelage ou linoléum usé, 1 m).

## 4. Appartement des SEDLAR (bloc 14, app. 61) : `data/field/stages/sedlar_flat.json`

| Fichier | Objet (endroit à fouiller) | Dimensions | Remarques |
| --- | --- | --- | --- |
| `assets/models/field/sedlar_flat/commode.glb` | Commode (tiroir) | 1,1 × 0,85 × 0,5 | Trois tiroirs, bois sombre, napperon dessus. |
| `assets/models/field/sedlar_flat/stove.glb` | Poêle | 0,55 × 0,9 × 0,55, tuyau jusqu'à 2,6 m | Poêle en fonte, petite porte vitrée rougeoyante. |
| `assets/models/field/sedlar_flat/photo.glb` | Photo de famille | 0,42 × 0,34 × 0,03 | Cadre en bois. **Origine au centre du cadre** (accroché au mur). |
| `assets/models/field/sedlar_flat/bed.glb` | Lit des parents (matelas) | 1,5 × 0,7 × 2,0 | Tête de lit contre le mur du fond (côté −Z). |
| `assets/models/field/sedlar_flat/child_bed.glb` | Lit de l'enfant | 0,8 × 1,1 × 1,4 | **Avec l'enfant (8 ans) assis dessus**, en pyjama. |
| `assets/models/field/sedlar_flat/satchel.glb` | Cartable de Vera | 0,38 × 0,3 × 0,12 | Cartable d'institutrice en cuir rouge sombre. |
| `assets/models/field/characters/vera.glb` | Vera SEDLAR, debout | 0,45 × 1,65 × 0,3 | Institutrice, 35 ans, blouse grise, cahier rouge à la main, bras croisés ou le long du corps. |

Images (facultatives) : `sedlar_wallpaper.png` (papier peint à rayures fanées,
0,8 m), `sedlar_floor.png` (parquet, 1 m), `sedlar_family_photo.png` (photo
noir et blanc 1979 : un homme, une femme, une vieille femme devant une maison
de campagne ; format 4:3), `sedlar_window_view.png` (toits et cheminées d'une
ville grise, le soir), toutes dans `assets/textures/field/`.

## 5. Avec ChatGPT : ce qui marche bien, ce qui marche moins

- **Images (textures, photo, vue par la fenêtre)** : ChatGPT les génère bien.
  Demander une image **carrée, sans perspective, sans ombre portée, qui se
  répète sans couture** pour les murs et les sols. Exemple de demande :
  « Texture carrée 512 px, vue de face, sans perspective, raccordable sans
  couture : papier peint d'appartement d'Europe de l'Est années 1980, rayures
  verticales beige et vert passé, usé, légèrement taché. »
- **Modèles 3D** : ChatGPT ne fabrique pas directement un bon `.glb`. Deux
  chemins réalistes :
  1. faire générer une **image de référence** (l'objet de face et de profil,
     fond neutre), puis la modéliser dans **Blender** (gratuit) et l'exporter en
     `.glb` (Fichier > Exporter > glTF 2.0, format « glTF Binary », +Y vers le haut) ;
  2. passer cette image dans un outil « image vers 3D ». Ces outils sont des
     **services externes, souvent payants** : à choisir par toi, et vérifier
     leurs conditions (droits d'usage commercial).
- Les personnages sont le plus difficile : commencer par les meubles, garder
  ORLIK et Vera pour la fin.

## 6. Ressources libres (CC0)

Je n'ai pas accès à ces sites depuis mon environnement : c'est toi qui
télécharges. CC0 = utilisable librement, même dans un jeu vendu, sans
attribution obligatoire.

- **Poly Haven** (polyhaven.com) : meubles et objets réalistes, textures de
  murs et de sols. Le plus proche du ton du jeu.
- **ambientCG** (ambientcg.com) : textures (béton, parquet, papier peint, métal).
- **Kenney** et **Quaternius** : très « jeu vidéo », souvent trop coloré pour
  le ministère ; à réserver aux petits objets.

Vérifier la licence sur la page de **chaque** fichier, puis le renommer au
chemin attendu (sections 3 et 4).

## 7. Droits et origine des fichiers

- Chaque fichier ajouté s'inscrit dans `assets/LICENCES.md` : chemin,
  auteur ou outil, licence, date. C'est ce qui permettra de répondre à Steam.
- **Steam demande de déclarer le contenu généré par IA** dans le questionnaire
  de la page du jeu. Garder la trace des images et modèles générés avec ChatGPT.
- Rien de copié d'un autre jeu, d'un film ou d'une photo existante (règle du projet).
