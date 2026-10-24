# MINISTRY OF TRUTH (titre provisoire)

Simulation de renseignement et d'inspection administrative dans une dictature
rétrofuturiste des années 1980. Le joueur incarne un jeune inspecteur du
ministère de la Sécurité nationale : il examine des dossiers, recoupe des pièces
contradictoires et transmet des conclusions qui pèsent sur sa carrière, sur la
vie des citoyens et sur le régime.

Statut : **0.4** (deux dossiers liés, journées, conséquences différées, VERITAS).
Cible : Windows via Steam en priorité, puis Linux/macOS, mobile plus tard.

## Prérequis

- [Godot 4](https://godotengine.org/download), version standard (pas .NET).
  Projet créé et testé avec **Godot 4.7.2 stable**. Une version 4.x plus ancienne
  affichera un avertissement à l'ouverture ; 4.4 minimum est conseillé.
- Aucune dépendance externe, aucun plugin.

## Lancer le jeu

1. Ouvrir Godot, cliquer sur **Importer**, choisir le fichier `project.godot`.
2. Appuyer sur **F5** (ou le bouton ▶ en haut à droite).

En ligne de commande :

```bash
godot --path .
```

## Lancer les tests

```bash
# Tests automatiques (logique + scènes), sans fenêtre. Code de sortie 0 = OK.
godot --headless --path . res://tests/test_runner.tscn

# Captures d'écran des écrans principaux (nécessite un affichage)
godot --path . res://tests/capture_screens.tscn -- /chemin/vers/dossier
```

Depuis l'éditeur, on peut aussi ouvrir `tests/test_runner.tscn` et appuyer sur
**F6** (lancer la scène courante) : les résultats s'affichent dans la console.

## Documentation

- [GAME_DESIGN.md](GAME_DESIGN.md) : univers, mécaniques, progression.
- [ARCHITECTURE.md](ARCHITECTURE.md) : organisation du code et des données.
- [ROADMAP.md](ROADMAP.md) : fait, en cours, à venir.
- [CLAUDE.md](CLAUDE.md) : règles pour les sessions de développement assistées.

## Captures

Voir [docs/captures](docs/captures) (régénérées avec `tests/capture_screens.tscn`).
