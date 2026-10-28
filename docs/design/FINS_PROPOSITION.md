# Proposition : moteur des 7 fins + écran d'archive final

> Proposition de conception à valider par fen avant implémentation.
> Les 7 fins sont canon (`SCENARIO_V1.md`, `GAME_DESIGN_V2.md` §8, « Le Silence »
> par défaut). Ce document propose **comment** les résoudre à partir des drapeaux
> et indicateurs déjà posés par les actes 1 à 4, sans rien inventer de narratif.

## Ce qui existe déjà

Les actes 1 à 4 posent tous les drapeaux nécessaires (déterministes, en données).
Rien à ajouter côté contenu ; il manque **le moteur qui lit ces drapeaux** et
**l'écran final**.

## Résolution proposée

Une fin, et une seule, à la fin du jour 20. On évalue dans l'ordre (du plus
spécifique au plus général) ; la première dont les conditions sont réunies gagne.
Même grammaire de conditions que les événements (`requires_flags`,
`forbidden_flags`, seuils d'indicateurs), dans un nouveau `data/endings.json`.

| Ordre | Fin | Conditions proposées (drapeaux déjà posés) |
| --- | --- | --- |
| 1 | **La Correction** (cachée) | `act4.father_truth` + `kremer.protected` + au moins 3 « innocents épargnés » (voir plus bas) |
| 2 | **La Fuite des originaux** | `act2.original_kept` + `veritas.zero` |
| 3 | **L'Heure juste** | `mazur.fled` + (`kremer.protected` ou contact réseau) + suspicion moyenne (p. ex. 35–70) |
| 4 | **Le Miroir parfait** | `act4.mirror_signed_clean` + loyauté haute (p. ex. ≥ 70) |
| 5 | **L'Allié de la Milice** | `milice.ally` + une faveur utilisée (`54001.orlik_protected` ou `51307` faveur), sans `milice.hostile` |
| 6 | **Le Dossier 54100** | suspicion très haute avant l'acte 4 (p. ex. ≥ 80) ou `player.internal_review` |
| 7 | **Le Silence** (défaut) | aucune des précédentes (typiquement `act4.mirror_refused`, ou rien de marquant) |

Remarques :
- Audit du 28.10 (validé par fen) : le Miroir parfait passe avant la Milice, sinon
  un joueur qui a tout signé dans MIROIR mais classé ORLIK au jour 1 obtenait la
  fin de la Milice ; la Milice est exclue après une brouille (`milice.hostile`).
- L'ordre place les fins « rares/méritées » avant les fins « par excès »
  (54100) et la fin par défaut (Le Silence) en dernier, conforme
  à l'esprit du canon (« Le Silence » = défaut).
- **« Innocents épargnés »** : à compter sur un ensemble de drapeaux de clémence
  prouvée, à confirmer par fen. Candidats déjà posés : `52044` gérante disculpée,
  `53118.choir_cleared`, `53517.petras_cleared`, `53402` relaxe, `54001` sans bouc
  émissaire, `54030` `adler.freed`, `40921` non-arrestation. Seuil proposé : 3.

## Écran d'archive final (canon : « une dernière page d'archive »)

Après la fin, un écran récapitule le destin de chaque sujet rencontré (SEDLAR,
ORLIK, VARGA, la chorale, PETRAS, ADLER, KREMER, MAZUR, le père…), à partir des
drapeaux de destin déjà posés (`*_arrested`, `*_cleared`, `*.freed`, `fate_line`
des cartes de destin existantes). Réutilise `FateRules` + `ArchiveCard`, déjà en
place pour les cartes de destin par dossier.

Pour **La Correction**, le jeu affiche « la seule ligne vraie qui survit » : la
ligne rétablie du dossier du père (60003, `act4.father_truth`).

## Ce que je propose de construire (après ton accord)

1. `data/endings.json` : les 7 fins, conditions ci-dessus (ajustables), texte de
   la dernière image (déjà esquissé dans le canon).
2. `scripts/core/ending_rules.gd` : `resolve(flags, indicators) -> ending_id`
   (logique pure, testée), + comptage des « innocents épargnés ».
3. `scripts/core/final_archive.gd` (ou extension de `FateRules`) : récapitulatif
   des destins.
4. Écran de fin (scène) qui affiche la fin résolue puis l'archive finale.
5. Déclenchement au terme du jour 20 (fin de l'acte 4).
6. Tests : chaque fin atteinte par un jeu de drapeaux type ; Le Silence par défaut.

## Questions pour toi

1. D'accord avec l'ordre d'évaluation et les seuils (suspicion moyenne 35–70,
   loyauté ≥ 70, suspicion ≥ 80, 3 innocents) ? Ou tu veux ajuster ?
2. La liste des drapeaux « innocents épargnés » te convient-elle ?
3. Je construis le moteur en données + `EndingRules` (petit ajout moteur, testé),
   ou tu préfères qu'on en reparle d'abord ?
