# CLAUDE.md : règles du projet MINISTRY OF TRUTH

Jeu Godot 4 (GDScript). Le propriétaire (fen) parle français et a des bases en
programmation : expliquer clairement les décisions importantes, en français.

## Avant de modifier

- Lire ARCHITECTURE.md (structure, flux, format des données) et ROADMAP.md.
- Demander validation avant : changement d'architecture majeur, suppression de
  fichiers, nouvelle dépendance ou plugin, API externe ou service payant,
  publication, changement important de périmètre.

## Règles de code

- Séparer UI (`scenes/`), logique pure (`scripts/core/`), état (`scripts/autoload/`)
  et contenu (`data/`). Pas de règle de jeu dans les scripts d'interface.
- Toute donnée sauvegardée vit dans `GameState` et passe par `to_dict()/from_dict()`.
  Changer le format de sauvegarde = incrémenter `SAVE_VERSION` + migration.
- Nouveau dossier = nouveau JSON + entrée dans `data/cases/index.json`, sans code.
- Commentaires et textes du jeu en français ; noms de code en anglais.
- Indentation par tabulations ; typage statique quand c'est simple.
- Styles via le thème (`ui/theme/ministry_theme.tres`) et ses variations,
  pas de couleurs codées en dur dans les scènes sauf exception justifiée.
- Mobile : zones tactiles >= 44 px, aucune action accessible uniquement au clavier.
- VERITAS : déterministe d'abord. Un LLM ne décide jamais de la vérité ni de l'état.
  Jamais de clé d'API dans le client.
- Pas de graphismes, interfaces ou textes copiés d'autres jeux.

## Vérifier

```bash
godot --headless --path . --import                     # après ajout de classes/scripts
godot --headless --path . res://tests/test_runner.tscn # doit finir par 0 échec
```

- Ajouter des tests pour toute règle de décision ou changement d'état.
- Les tests redirigent la sauvegarde vers `user://test_savegame.json`.
- Pour vérifier le rendu : `tests/capture_screens.tscn` (sous Linux sans écran :
  `xvfb-run -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 res://tests/capture_screens.tscn -- <dossier>`).
- Ne jamais affirmer qu'une fonctionnalité marche sans l'avoir testée ; distinguer
  validation syntaxique, tests automatiques et test manuel du ressenti.

## Git

Dépôt : github.com/r65z40/truth. Travailler sur une branche, ouvrir une pull
request ; fen teste dans Godot et fusionne lui-même. Un commit par étape
fonctionnelle, message en français, tests au vert.
Mettre à jour ROADMAP.md (et GAME_DESIGN.md si le design change).
