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
  ui/ministry_window.gd       cadre commun des fenêtres
scenes/
  main_menu/                  menu principal
  desk/                       bureau de l'inspecteur (scène principale de jeu)
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
- **Terminal** : saisie ou bouton > `TerminalCommands.parse()` > signal
  `app_requested` > `Desk.open_app()` > fenêtre `MinistryWindow.open()`.
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
l'affiche dans la barre OBJECTIF et fait pulser le bouton visé. Désactivable dans
Paramètres (`gameplay/guidance`). Les fenêtres émettent `notify(text)` ; le bureau
affiche ces notifications brèves (toast). Les sauvegardes contiennent un résumé
(`summary` : date, grade) lu par le menu sans charger la partie.

## VERITAS

`scripts/core/veritas.gd` ne lit que les données : `veritas_remark` sur chaque pièce,
bloc `veritas` du dossier (`recommendation`, `confidence`, `rationale`, `note` de
scénario non affichée). Ses avis sont écrits par le scénario et peuvent être faux.
Un futur modèle de langage ne ferait que reformuler ces résultats, côté serveur.

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

## Sauvegarde

Fichier `user://savegame.json` :
`{save_version, game_version, saved_at, state}`. Pour changer le format :
incrémenter `SAVE_VERSION` et ajouter une étape dans `SaveManager._migrate()`.
Un chargement en échec ne modifie pas l'état courant.
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
