# Architecture

Godot 4 (GDScript), rendu **Compatibility** (OpenGL, le plus portable : PC, mobile,
web). Résolution de base 1280x720, mise à l'échelle `canvas_items` + `expand`.

## Principe

```
data/ (JSON)  ──>  scripts/core (lecture, règles pures)  ──>  autoloads (état)  ──>  scenes/ (UI)
                                                               │
                                                   SaveManager (JSON versionné, user://)
```

- L'**interface** lit l'état et émet des actions ; elle ne contient pas de règle de jeu.
- L'**état** (GameState) est la seule chose sauvegardée.
- Le **contenu** (dossiers, messages) est en JSON : ajouter un dossier ne demande
  pas de code.
- La vérité des affaires et les conséquences sont décidées par le moteur.
  Un futur LLM pour VERITAS ne pourra que **formuler** des réponses à partir des
  données accessibles, jamais modifier l'état. Aucune clé d'API dans le client.

## Arborescence

```
project.godot
data/
  cases/index.json            tous les dossiers + "starting_cases" (attribués au départ)
  cases/case_<id>.json        un dossier = un fichier
  messages/initial_messages.json
  events/events.json          événements différés (conséquences, rappels, bulletins)
  field/<scène>.json          scènes de terrain (audition, perquisition)
  field/stages/<décor>.json   décors 3D des scènes de terrain (caméra, lumières, objets)
assets/
  models/field/, textures/field/  modèles .glb et images des décors 3D (facultatifs)
  LICENCES.md                 origine et licence de chaque fichier
  assessment.json             paliers d'appréciation des indicateurs, observations
scripts/
  autoload/
    game_state.gd             état de la partie + signal state_changed
    save_manager.gd           sauvegarde/chargement versionnés
    settings.gd               préférences (user://settings.cfg)
  core/                       logique sans interface (classes statiques)
    data_loader.gd            lecture JSON
    case_library.gd           accès aux dossiers, validation, contradictions
    fictional_calendar.gd     date du jeu
    career.gd                 grades
    decision_rules.gd         résolution d'une décision (issue, effets, réponse)
    event_rules.gd            événements dus au début d'une journée
    veritas.gd                VERITAS déterministe (remarques, recommandation)
    assessment.gd             évaluation de l'agent en mots (data/assessment.json)
    guidance.gd               objectif du jour affiché au bureau (étape suivante)
    field_rules.gd            scènes de terrain (interrogatoires, perquisitions)
  ui/ministry_window.gd       cadre commun des fenêtres (titre, réduire, agrandir, fermer, déplacer)
  ui/window_manager.gd        zone de travail : ordre des fenêtres, premier plan, petit écran
  ui/pixel_icons.gd           icônes en pixels (grilles 16 x 16 aux couleurs du thème)
  ui/bevel_style_box.gd       style en relief des fenêtres et boutons (utilisé par le thème)
scenes/
  main_menu/                  menu principal
  desk/                       bureau de l'inspecteur : fond, icônes, fenêtres, barre des tâches
  ui/terminal/                terminal + interprète de commandes
  ui/windows/                 Dossiers, Messages, Archives, Dossier personnel, Paramètres
  ui/crt_overlay/             filtre écran cathodique (autoload)
ui/theme/ministry_theme.tres  thème global (couleurs, polices, styles)
ui/shaders/crt.gdshader
tests/                        tests automatiques et captures d'écran
```

## Autoloads (ordre de chargement)

| Nom | Rôle |
|---|---|
| `Settings` | Préférences d'affichage, appliquées au démarrage |
| `GameState` | État de la partie ; toute modification émet `state_changed` |
| `SaveManager` | `save_game()`, `load_game()`, `has_save()` ; format versionné |
| `CrtOverlay` | Filtre visuel global (CanvasLayer 100) |

## Flux principaux

- **Menu > Nouvelle partie** : `GameState.new_game()` puis scène `desk`.
- **Menu > Continuer** : `SaveManager.load_game()` puis scène `desk`.
- **Bureau** : icône, menu MINISTÈRE ou commande du terminal > `Desk.open_app()` >
  `MinistryWindow.open()` > `WindowManager` la place (première fois) et la passe
  au premier plan. Plusieurs fenêtres restent ouvertes ; `Desk.get_open_app()`
  renvoie celle du premier plan. La barre des tâches a un bouton par fenêtre
  ouverte (ressortir, passer devant, réduire). Sous 900 px de large, chaque
  fenêtre occupe toute la zone de travail.
- **Terminal** (fenêtre facultative) : saisie ou bouton > `TerminalCommands.parse()`
  > signal `app_requested` > `Desk.open_app()`.
- **Lecture d'une pièce** : `DossiersWindow.select_document()` > affichage BBCode >
  `GameState.mark_document_viewed()`.
- **Carnet d'enquête** : « + NOTER » > `GameState.note_fact()` ; deux éléments
  sélectionnés > `GameState.confront_facts()` > `CaseLibrary.confront()`.
- **Conclusion** : `ConclusionPanel.submitted` > `GameState.apply_decision()` >
  `DecisionRules.resolve()` > effets, statut, drapeaux, message du supérieur >
  signal `decision_applied` > le bureau ouvre la messagerie sur la réponse.
- **Fin de service** : `FIN` (deux fois si un dossier attend) > `Desk.end_day()` >
  `GameState.end_day()` > `EventRules.due_events()` > effets, drapeaux, messages >
  sauvegarde automatique > nouvelle session au terminal.

## Événements différés (`data/events/events.json`)

```jsonc
{"id": "40921_orlik_hearing",
 "conditions": {"min_day": 1, "requires_flags": ["40921.orlik_hearing_requested"],
                "forbidden_flags": [], "undecided_cases": []},
 "effects": {"influence": 2}, "set_flags": {"40921.orlik_confessed": true},
 "message": {"from": "...", "subject": "...", "body": "..."},
 "assign_cases": ["51307"],                    // attribue un nouveau dossier
 "repeatable": false}
```

Évalués à chaque nouvelle journée, dans l'ordre du fichier. Les drapeaux posés par
les décisions (`flags` des issues) sont le lien entre un dossier et ses suites.

## Accompagnement du joueur

`scripts/core/guidance.gd` calcule, à partir de l'état seul, la prochaine étape
utile (`{text, hint, target}`) : lire les messages, ouvrir un dossier, noter et
confronter des éléments, rédiger la conclusion, finir la journée. Le bureau
la montre dans la bulle d'aide et fait pulser l'icône visée. Désactivable dans
Paramètres (`gameplay/guidance`). Les fenêtres émettent `notify(text)` ; le bureau
affiche ces notifications brèves (toast). Les sauvegardes contiennent un résumé
(`summary` : date, grade) lu par le menu sans charger la partie.

## Accueil du joueur

- **Introduction** (`scenes/intro/`, `data/intro.json`) : quatre pages illustrées
  entre « Nouvelle partie » et le bureau ; dessins en code (`IntroArt`).
- **Bulle d'aide** (`scenes/ui/coach/`) : `Guidance.next_step()` renvoie aussi
  `part` (endroit dans la fenêtre : `case`, `tab:<pièce>`, `facts`, `notebook`,
  `conclusion`), `case_id` et `coach` (texte). Le bureau résout le contrôle
  visé (`coach_target()`, `MinistryWindow.get_guide_target()`) ; la bulle le
  suit à chaque image et ne bloque jamais les clics. Un dossier peut préciser
  ses conseils dans un bloc `"guide"` (le 40921 sert de tutoriel).
- **Fonctions débloquées** (`data/rules/features.json`, `Features`) : le premier
  jour n'affiche ni DEMANDER, ni CONSULTER, ni Archives, ni Dossier personnel ;
  MAZUR les annonce le lendemain. Les règles de `GameState` vérifient aussi ces
  conditions.

## VERITAS

`scripts/core/veritas.gd` ne lit que les données et les pièces visibles par
l'agent. Chaque pièce porte une `veritas_remark` écrite. La recommandation est
calculée : pour chaque décision, **indice de conformité** = `base` + somme des
`weight` x multiplicateur de la `category` des facteurs du bloc `veritas.factors`
(paramètres cachés dans `data/veritas.json`), borné entre 1 et 99. C'est un score
institutionnel, pas une probabilité. Un facteur ne compte que si sa pièce est
visible et, s'il a `requires_contradiction`, si l'agent a établi cette
contradiction. `VERITAS POURQUOI` (terminal) et le formulaire de conclusion
montrent les 3 facteurs principaux ; les multiplicateurs n'apparaissent qu'avec le
drapeau `veritas.params_known`. `veritas.note` est une note de scénario jamais
affichée. Un futur modèle de langage ne ferait que reformuler ces résultats,
côté serveur.

## Format d'un dossier (`data/cases/case_<id>.json`)

```jsonc
{
  "id": "40921", "title": "...", "subject_name": "...", "summary": "...",
  "documents": [{
    "id": "travel_log", "type": "identity|report|intercept|travel_log|...",
    "title": "...", "source": "...", "reliability": "A|B|C|D", "date": "AAAA-MM-JJ",
    "fields": [["Libellé", "Valeur"]],        // optionnel : fiche
    "columns": [...], "rows": [[...]],         // optionnel : registre
    "author": "...", "body": "texte",          // optionnel
    "facts": [{"id": "f_log_trip", "key": "sujet.lieu.date", "value": "...",
               "label": "texte montré au joueur"}]   // éléments notables
  }],
  "decisions": [{
    "id": "arrest", "label": "...", "description": "...",
    "status_after": "closed|under_investigation",
    "outcomes": [                               // testées dans l'ordre
      {"when": "contradiction_found", "effects": {"loyalty": 10}, "response": "arrest_found", "flags": {}},
      {"when": "default", ...}                  // obligatoire, en dernier
    ]
  }],
  "responses": {"arrest_found": {"from": "...", "subject": "...", "body": "..."}},
  "veritas": {"recommendation": "arrest", "confidence": 87, "rationale": "..."},
  "truth": { ... }                             // vérité objective, jamais affichée
}
```

Une pièce peut porter `"conditions"` (même format que les événements) : elle
n'apparaît que si elles sont remplies, par exemple
`{"requires_flags": ["40921.orlik_confessed"]}`. L'interface passe toujours par
`GameState.get_case_view(id)`, qui filtre les pièces ; les règles utilisent le
dossier complet.

Deux éléments qui portent sur la même `key` avec des `value` différentes se
contredisent (`CaseLibrary.confront`). La clé et la valeur ne sont jamais
affichées : le joueur ne voit que `label`. Nouvelle condition `when` : l'ajouter
dans `DecisionRules.is_condition_met()`. `CaseLibrary.validate_case()` vérifie
la structure (testée pour chaque dossier).

Une pièce peut porter `"request": {"label": "...", "flags": {}, "effects": {}}` :
elle n'est visible qu'après une demande (`GameState.request_document`, 1 h de
service) faite un jour précédent, donc livrée le lendemain. Un dossier peut
porter `"consultation"` : le conseil du supérieur (`GameState.consult_superior`,
1 h, une fois par dossier non conclu).

## Temps de service (`data/rules/work_time.json`)

Une journée compte 8 h, plus 2 h supplémentaires ; lire est gratuit. Le coût de
chaque action est dans le JSON, la logique dans `WorkTime` (pur), l'état dans
`GameState.hours_used` / `overtime_days`. Signer une conclusion ne bloque
jamais, même à court d'heures. Le calendrier (`data/calendar.json`) liste les
20 journées de service et les actes ; `FictionalCalendar.days_since_previous`
sert aux ellipses (« N jours plus tard »).

## Soirées (`data/evenings.json`)

Une soirée par jour (champ `day`), avec `intro`, `set_flags` et 2 ou 3
`actions` {id, kind, label, description, conditions, results, effects,
set_flags, followups}. `results` est une liste de variantes : la première dont
les conditions sont remplies est affichée (la dernière, sans condition, sert de
défaut). Les conditions sont celles des événements, plus `min_count`
(`{"radio": 2}` : nombre de soirées passées à ce `kind`). Logique dans
`EveningRules`, état dans `GameState.evenings`, écran
`scenes/evening/evening_screen.tscn` ouvert par le bureau avant le jour suivant.

## Terrain (`data/field/<scène>.json`)

Un dossier rattache une scène par `"field_scene"`. Une scène a un `type`
(`interrogation` ou `search`), `turns`, `time_action` (coût dans
`work_time.json`), `available_when` (liste de conditions, une suffit),
`start_flags`/`start_effects`, `options` {id, label, conditions, text, note,
set_flags, effects, ends, spot [x, y, l, h] pour une perquisition} et, pour un
interrogatoire, `presentations` {id, facts, text, note, ...} et
`present_default`. Textes d'interface facultatifs : `verb` (« Vous examinez : »),
`hint`, `turns_label`. Décors : `art` (`sedlar_flat`, `bakery`, `benes_flat`). Chaque choix pose `field.<scène>.<choix>`. Le procès-verbal
est une pièce ordinaire du dossier dont les éléments portent des `conditions`
sur ces drapeaux : `CaseLibrary.filter_case` filtre aussi les éléments. Logique
dans `FieldRules`, état dans `GameState.field_scenes`, écran
`scenes/field/field_screen.tscn`, décors dessinés par `FieldArt`.

Décor 3D (`FieldStage3D`, réglage `Settings.field_3d`) : si
`data/field/stages/<décor>.json` existe, l'écran l'affiche à la place du dessin.
Chaque objet charge son `model` (.glb) s'il existe, sinon ses `parts` (boîte,
cylindre, sphère, capsule ; couleurs du thème `IntroArt`, `texture` facultative).
Un objet avec `option` est cliquable (rayon contre sa boîte englobante, sans
physique) et émet `spot_pressed` ; `present` ouvre la liste du carnet.
Le sujet d'un interrogatoire (`role: subject`) prend `subject.model` de la scène.
Cahier des charges des modèles : `docs/design/ASSETS_3D.md`.

## Campagne (`data/campaign.json`)

Profil du personnage joué (nom, matricule, supérieur). Rien n'est écrit en dur
dans le code, pour pouvoir ajouter plus tard des campagnes jouant un autre
personnage (`docs/design/EXTENSIONS_PERSONNAGES.md`).

## Sauvegarde

Fichier `user://savegame.json` :
`{save_version, game_version, saved_at, state}`. Pour changer le format :
incrémenter `SAVE_VERSION` et ajouter une étape dans `SaveManager._migrate()`.
Un chargement en échec ne modifie pas l'état courant. Version actuelle : 4
(heures de service, pièces demandées, consultation, soirées, scènes de terrain).
Emplacement de `user://` sous Windows : `%APPDATA%\Godot\app_userdata\Ministry of Truth\`.

## Compatibilité mobile

Zones tactiles de 44 px minimum, boutons pour toutes les commandes du terminal
(le clavier n'est jamais obligatoire), barres de boutons en `HFlowContainer`,
option d'agrandissement de l'interface, bouton Quitter masqué sur mobile/web.

## Direction visuelle (thème)

Fond `#0b0d0c`, anthracite `#1b1f1e`, phosphore `#3ce07a`, beige document
`#d8ccad`, encre `#2a241c`, rouge alerte `#8e1f1f`, blanc cassé `#e8e4d8`.
Police : monospace système (SystemFont avec repli). Variations de thème :
`TerminalPanel`, `TerminalText`, `DocumentPanel`, `DocumentLabel`, `DocumentText`,
`DocumentTab`, `WindowFrame`, `TitleBar`, `TopBar`, `HeaderLabel`, `MutedLabel`,
`StampLabel`, `AlertButton`.

## Export

Les fichiers `.json` de `data/` doivent être inclus dans l'export : à vérifier
lors de la création du premier preset (filtre « fichiers non-ressources » : `*.json`).
