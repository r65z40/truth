# Audit du scénario et du projet (2026-10-24)

Base auditée : `docs/design/SCENARIO_V1.md` (canon), `GAME_DESIGN.md`,
`ARCHITECTURE.md`, `ROADMAP.md`, `CLAUDE.md`, les données `data/` et les scripts
`scripts/` de la branche `main` (version 0.5), plus la branche de travail
`claude/acte-1` (non fusionnée).

Chaque point est classé :
**[INCOHÉRENCE]** avérée · **[AMBIGUÏTÉ]** · **[ABSENT]** information absente ·
**[PRÉFÉRENCE]** choix de design à trancher. Rien n'a été réécrit dans le canon :
les corrections proposées attendent la validation de fen.

## 1. Ce qui existe vraiment dans le code

Vérifié dans le code et par les tests automatiques (284 vérifications sur `main`,
345 sur `claude/acte-1`). La documentation ne décrit rien qui ne soit pas codé,
sauf les points marqués « non implémenté ».

| Élément | État | Où |
| --- | --- | --- |
| Dossiers 40921 et 51307 (pièces, contradictions, 3 décisions, réponses) | Implémenté, testé | `data/cases/`, `main` |
| Dossier 52044 (carnets du cimetière, 7 pièces, 3 contradictions) | Implémenté, testé, non fusionné | branche `claude/acte-1` |
| Dossier 52310 (le poète) | Brouillon de données, non branché | branche `claude/acte-1` |
| Photos d'identité dessinées depuis les données | Implémenté, testé, non fusionné | `scripts/ui/id_photo.gd`, branche `claude/acte-1` |
| Condition de décision `contradiction:<clé>` | Implémenté, testé, non fusionné | `scripts/core/decision_rules.gd`, branche `claude/acte-1` |
| Journées, événements différés, drapeaux | Implémenté, testé | `event_rules.gd`, `events.json` |
| Pièces conditionnelles selon les drapeaux | Implémenté, testé | `CaseLibrary.filter_case` |
| VERITAS : remarques et recommandation | Implémenté, mais **textes et pourcentages écrits à la main** | `veritas.gd`, bloc `veritas` des dossiers |
| Indicateurs loyauté, suspicion, influence + évaluation en mots | Implémenté, testé | `game_state.gd`, `assessment.json` |
| Carrière | **Non implémenté** : `career.gd` ne fait que nommer 6 grades, aucune promotion | `scripts/core/career.gd` |
| Factions | **Seulement des drapeaux** (`milice.ally`, `milice.enemy`…), aucun état de faction | données |
| Comparaison avec l'archive, chronologie, interrogatoire, caviardage | **Non implémenté** | — |
| Gestion du temps dans la journée | **Non implémenté** | — |
| Fins, écran récapitulatif | **Non implémenté** | — |
| Vie hors du bureau, monde extérieur | **Non implémenté**, absent du canon | — |
| Localisation | **Non implémenté** : textes français dans les JSON et dans le code (jours, mois, interface) | partout |
| Sauvegarde | Un seul emplacement, sauvegarde automatique en fin de journée, format v3 avec migrations | `save_manager.gd` |

## 2. Points demandés par la directive (section X)

### 2.1 Nombre de dossiers principaux — [INCOHÉRENCE]

Le canon annonce « 16 dossiers principaux » mais en liste **15** (4 + 4 + 4 + 3).
De plus, 54100 (le dossier de Vosk) ne s'instruit pas : c'est une scène, pas une
enquête. Il y a donc **14 enquêtes jouables**.
Proposition : écrire « 15 dossiers, dont 14 enquêtes » ; pas de 16e dossier
inventé sans accord.

### 2.2 Journées et calendrier — [INCOHÉRENCE]

- Le calendrier du code avance d'un jour par journée, dimanches compris
  (`FictionalCalendar`). 24 journées vont donc du lundi 3 au **mercredi
  26 novembre**, pas au 6 décembre. Du 3 novembre au 6 décembre, il y a 34 jours.
- Le découpage du canon (1 à 6, 7 à 13, 14 à 19, 20 à 24) couvre bien 24 journées.
- Nouvelle contrainte de fen : une partie de **4 heures** et des journées de
  **12 minutes**, soit **20 journées**. Avec 24 journées, on arrive à 4 h 48.

Proposition (à valider) : **20 journées de service**, du lundi 3 novembre au
samedi 6 décembre, avec des **ellipses** entre les actes (dimanches et jours sans
dossier sautés, annoncés par un écran « 3 jours plus tard »). Découpage :
acte 1 = 5 journées, acte 2 = 5, acte 3 = 5, acte 4 = 5. Le calendrier du code
devra alors stocker la date de chaque journée, et pas seulement leur nombre.

### 2.3 Le capitaine L. ORLIK — [AMBIGUÏTÉ]

Ses rôles actuels : frère protecteur (51307), patron d'un informateur
(« CHAUDRON »), receleur des « carnets du cimetière » (52044, branche de travail),
détourneur des réquisitions de la centrale (acte 3), puis allié possible (fin
« L'Allié de la Milice »). Ces rôles sont compatibles si on fixe une seule
motivation : **il protège un réseau d'argent et d'informateurs**, et l'explosion
de l'acte 3 le menace directement (ses détournements ont privé la centrale de
pièces). Il a donc intérêt à trouver un saboteur. À valider : c'est le point qui
rend l'acte 3 logique.
Ambiguïté restante : les états `milice.ally` et `milice.enemy` sont exclusifs
dans les données, mais rien n'empêche aujourd'hui un joueur neutre (sanction
administrative au 51307) d'arriver en acte 3 sans relation. Il faut un état
« neutre » explicite.

### 2.4 Conditions et priorités des sept fins — [AMBIGUÏTÉ] et [ABSENT]

- Plusieurs fins peuvent être vraies en même temps (par exemple « L'Heure juste »
  et « La Fuite des originaux »). **Aucun ordre de priorité n'est défini.**
- « Le Silence » : « démission refusée de MIROIR sans preuves » se lit de deux
  façons (Vosk refuse MIROIR, ou sa démission est refusée).
- Aucune fin par défaut si aucune condition n'est remplie.
- « Le Dossier 54100 » peut survenir avant l'acte 4 (fen accepte une arrestation
  anticipée), alors que le canon le classe parmi les fins de l'acte 4.

Proposition d'ordre d'évaluation (à valider), de la plus contraignante à la plus
large : 1) Le Dossier 54100 (vérifié chaque soir, à partir de l'acte 2, après
deux avertissements) ; 2) La Correction ; 3) La Fuite des originaux ;
4) L'Heure juste ; 5) L'Allié de la Milice ; 6) Le Miroir parfait ;
7) Le Silence, **fin par défaut**. Détail dans `GAME_DESIGN_V2.md`.

### 2.5 Accès de Vosk à MIROIR selon son statut — [ABSENT]

Le canon dit « promu, muté ou suspendu » sans dire ce que chaque statut permet.
Proposition : trois variantes d'un même acte 4.

| Statut à la fin de l'acte 3 | Rôle dans MIROIR | Pouvoir sur les documents |
| --- | --- | --- |
| Promu (directeur adjoint par intérim) | Il dirige MIROIR | Réécrit, caviarde, choisit le coupable |
| Maintenu ou muté aux archives | Il exécute les corrections d'un autre | Peut seulement caviarder, ou « oublier » une correction |
| Suspendu | Il assiste de l'extérieur (BRANDT dirige) | Aucun ; il ne garde que ses copies et ses contacts |

### 2.6 Dépendances entre enquêtes et drapeaux — [INCOHÉRENCE] mineure

Vérification automatique des données (`main` + branche de travail) :
aucun drapeau n'est lu sans être posé. En revanche **17 drapeaux sont posés sans
être lus** (par exemple `40921.orlik_exposed`, `milice.enemy`, `player.bribed`).
Ce n'est pas une erreur aujourd'hui (ils serviront plus tard), mais il faut un
outil qui liste les drapeaux orphelins avant la 1.0. Le schéma est dans
`DEPENDANCES_DOSSIERS.md`.

### 2.7 Personnages indisponibles — [ABSENT]

| Personnage | Peut disparaître | Scènes qui en dépendent | Proposition |
| --- | --- | --- | --- |
| R. MAZUR | Arrêté ou en fuite fin d'acte 3 | Tous les messages de la hiérarchie, fin « L'Heure juste » (« Mazur vivant ») | Remplaçant écrit d'avance : directeur adjoint par intérim (BRANDT ou un nouveau nom) ; la fin « L'Heure juste » passe par un autre contact du réseau |
| H. KREMER | Arrêté au 53760 | Note de fin d'acte 1, originaux de l'acte 2, fins « Correction » et « Fuite des originaux » | Les originaux déjà copiés restent ; sans copie, ces deux fins se ferment, ce qui doit être annoncé |
| A. SEDLAR | Arrêté au 40921 | Sa fille en acte 3 | La fille existe dans tous les cas ; son attitude change (hostile si le père a été arrêté) |
| B. ORLIK | Arrêté au 51307 | Témoin possible de l'acte 3 | Si arrêté, son interrogatoire devient une pièce ; sinon, il témoigne |
| T. VARGA / K. BENES | Arrêté au 52310 | Suites de l'acte 1 | Lettre de l'épouse de BENES ; si non arrêté, BENES peut devenir témoin |

### 2.8 Sauvegardes et reprises entre actes — [ABSENT]

Un seul emplacement, sauvegarde automatique chaque soir. Un joueur arrêté à
l'acte 3 perd toute sa partie, et un joueur qui veut rejouer l'acte 4 doit tout
recommencer. Proposition : 3 emplacements manuels, plus une **sauvegarde
automatique au début de chaque acte**, conservée à part (« reprendre au début de
l'acte 3 »). Format v4 avec migration depuis la v3.

### 2.9 Localisation français et anglais — [ABSENT] et [INCOHÉRENCE] technique

- Tous les textes sont en français dans les JSON et dans le code (noms des jours
  et des mois dans `FictionalCalendar`, libellés de l'interface).
- **Des énigmes dépendent de la langue** : l'acrostiche HALINA / HALVEK du 52310
  doit être réécrit en anglais, pas traduit. Idem pour les jeux de mots
  éventuels et l'ordre alphabétique.
Proposition dans `GAME_DESIGN_V2.md` (section localisation) : textes de
l'interface via `tr()` et fichiers `.po` de Godot ; contenu des dossiers dans des
fichiers de surcouche par langue (`data/locale/en/…`), repérés par les
identifiants déjà présents ; les énigmes linguistiques signalées par un champ
`loc_note`.

## 3. Autres constats

| # | Constat | Type |
| --- | --- | --- |
| 3.1 | KREMER est **inspecteur de la Section 2** dans le code (message `40921_reassigned`) mais **archiviste** dans le canon. Proposition : ancien inspecteur, relégué aux archives après le 40921. Cela explique qu'il ait accès aux originaux. | INCOHÉRENCE |
| 3.2 | Les pourcentages de VERITAS (87, 71, 83, 91 %) sont écrits à la main, sans modèle. La directive demande un modèle explicite ou un score institutionnel nommé. Voir `VERITAS.md`. | INCOHÉRENCE avec la directive |
| 3.3 | Le canon ne dit pas **pourquoi MIROIR existe maintenant**. Proposition : une commission internationale (pays voisin, crédits énergétiques) doit visiter la centrale le 8 décembre ; le régime veut des archives propres avant. Cela relie MIROIR au monde extérieur demandé par fen. | ABSENT |
| 3.4 | La vie privée de Vosk (souhaitée par fen) n'existe pas dans le canon. La sœur LENA n'est qu'une proposition. | ABSENT |
| 3.5 | Le canon prévoyait la violence par allusion ; fen demande une violence **montrée, en crescendo**. Les dossiers d'acte 1 restent à revoir dans ce sens (procès-verbaux, rapports médicaux). | PRÉFÉRENCE tranchée par fen |
| 3.6 | Le père de Vosk est horloger, et le réseau s'appelle L'HEURE JUSTE : c'est cohérent, mais le canon ne dit pas si le père en faisait partie. C'est la clé de la fin « La Correction ». | AMBIGUÏTÉ |
| 3.7 | « Mazur a transmis le dossier 40921 » (rebondissement de l'acte 2) suppose que Mazur savait le registre falsifié. Pourquoi l'aurait-il donné au joueur ? Proposition : il voulait tester Vosk, ou espérait que Vosk enquête au lieu d'arrêter. À trancher. | AMBIGUÏTÉ |
| 3.8 | La fin « L'Heure juste » prévoit une fuite par le train de 06h05 alors que l'acte 1 annonce un contrôle renforcé avec photo sur cette ligne (bulletin du 4 novembre). Ce n'est pas bloquant si le réseau a un cheminot (53402) : il faut l'écrire. | AMBIGUÏTÉ |
| 3.9 | Le canon parle d'« indicateurs vagues » ; fen veut que la suspicion soit perceptible sans jauge omnisciente. L'évaluation en mots existe déjà ; il manque des signes indirects (ton des messages, dossiers retirés, collègue qui ne parle plus). | ABSENT |
| 3.10 | Le grade le plus haut de `career.gd` est « Haut dirigeant du régime » : inatteignable en 4 heures. Les grades au-delà de directeur adjoint relèvent de l'acte 5. | PRÉFÉRENCE |
