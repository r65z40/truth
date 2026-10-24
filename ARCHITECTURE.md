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
  cases/index.json            liste ordonnée des dossiers
  cases/case_<id>.json        un dossier = un fichier
  messages/initial_messages.json
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
  ui/ministry_window.gd       cadre commun des fenêtres
scenes/
  main_menu/                  menu principal
  desk/                       bureau de l'inspecteur (scène principale de jeu)
  ui/terminal/                terminal + interprète de commandes
  ui/windows/                 Dossiers, Messages, Archives, Paramètres
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
    "facts": [{"key": "sujet.lieu.date", "value": "..."}]  // pour les contradictions
  }],
  "decisions": [{"id": "arrest", "label": "...", "effects": {"loyalty": 10}, "superior_message": "arrest"}],
  "truth": { ... }                             // vérité objective, jamais affichée
}
```

Deux pièces qui donnent une valeur différente pour la même clé de `facts` se
contredisent (`CaseLibrary.find_contradictions`).

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
