# Roadmap V2 (proposition hiérarchisée)

Priorité absolue : un **acte 1 complet, amusant, lisible et stable**. Rien de
l'acte 2 ne commence avant que l'acte 1 soit jouable de bout en bout et testé par
fen.

## MVP : acte 1 complet (versions 0.6 et 0.7)

| # | Élément | Statut | Dépend d'une validation |
| --- | --- | --- | --- |
| 1 | Dossier 52044 RATIONS | Codé, testé (branche `claude/acte-1`) | Non |
| 2 | Photos d'identité dessinées | Codé, testé (branche `claude/acte-1`) | Non |
| 3 | Dossier 52310 LE POÈTE | Données en brouillon | Rôle de KREMER (changement 3) |
| 4 | Note de KREMER et fin d'acte 1 | À faire | Rôle de KREMER |
| 5 | Calendrier en 20 journées avec ellipses | À faire | Changement 2 |
| 6 | VERITAS : indice de conformité calculé + `VERITAS POURQUOI` | À faire | Changement 10 |
| 7 | Horloge de service (prototype) | À faire | Gestion du temps (section 3 de GAME_DESIGN_V2) |
| 8 | Demander une pièce, consulter Mazur | À faire | Gestion du temps |
| 9 | Soirées minimales (Lena, radio) | À faire | Changements 7 et 8 |
| 10 | Bulletins quotidiens d'acte 1 | En partie fait (2 bulletins) | Non |
| 11 | Écran de fin d'acte 1 avec archive des sujets | À faire | Non |
| 12 | Fondations de la localisation (`tr()`, dates par langue, surcouches) | À faire | Format (section 10) |
| 13 | Points de reprise par acte (sauvegarde v4) | À faire | Non |
| 14 | Promotion de fin d'acte 1 (2e classe) | À faire | Système de carrière |

Ordre conseillé : 1-2 (fusion), puis 6 et 12 (fondations peu coûteuses), puis 3-4,
puis 7-8-9 si la gestion du temps est validée, puis 5, 10, 11, 13, 14.

## Version 1.0

- Actes 2, 3 et 4 (11 dossiers), comparaison avec l'archive, chronologie,
  interrogatoire, caviardage et réécriture.
- Carrière sur 5 grades, faveurs, états de faction.
- Monde extérieur (radio d'Aldria, commission du 8 décembre), violence en
  crescendo avec option d'atténuation.
- Sept fins avec ordre de priorité, archive finale personnalisée.
- 2 ou 3 dossiers de routine par partie (réserve d'environ 10).
- Traduction anglaise complète, sons, polices libres embarquées, export Windows,
  tests de tous les embranchements (outil de drapeaux orphelins).

## Acte 2 — en cours (RACCORDEMENT + décret 86-31)

Proposition de design validée par fen (voir le document partagé du 25/10). Ordre :

| # | Étape | Statut |
| --- | --- | --- |
| 1 | Socle VERITAS : catégorie « donnée raccordée » (`linked`), overrides du décret 86-31 (frontière x2→x3), facteurs `contestable` | Codé, testé |
| 2 | Mémoire institutionnelle (`ministry_record`, graine du 54100, +SAVE_VERSION) | Codé, testé |
| 3 | Pression hiérarchique (message + choix + drapeaux) | À faire |
| 4 | 4 dossiers (53118, 53402, 53517, 53760) + révélation du 40921 | À faire |
| 5 | Bonus : audit VERITAS contestable à l'écran, radio étrangère | À faire |

Tout reste déterministe : les facteurs (dont `linked`) sont écrits à la main dans
les dossiers ; le décret agit par un drapeau ; une contestation n'écarte un facteur
que s'il est marqué `contestable`.

## Extensions futures

- Acte 5 « Le pouvoir » ou suite (voir `ACTE5_FAISABILITE.md`).
- Extensions jouant un autre personnage : MAZUR, BRANDT, KREMER, ORLIK, LENA, le père
  de Vosk (voir `EXTENSIONS_PERSONNAGES.md`). Préparation dès le MVP : profil du
  joueur et campagne dans les données, pas dans le code.
- Adaptation mobile complète.
- Reformulation de VERITAS par un modèle de langage, côté serveur, limitée aux
  informations accessibles à VERITAS.
- Réserve de dossiers de routine élargie.

## Ce qu'on ne fera pas

Génération aléatoire des révélations, carte du pays, diplomatie jouable, budget
des services, compte à rebours en temps réel sur toutes les enquêtes.
