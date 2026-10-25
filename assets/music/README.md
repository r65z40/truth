# Musique

Déposer ici les morceaux au format **.ogg** (Ogg Vorbis, stéréo, 44,1 kHz).
Dans Godot : sélectionner le fichier > onglet **Import** > cocher **Loop** >
**Réimporter**. Noter la provenance et la licence dans `assets/LICENCES.md`
(et la mention « contenu généré par IA » si c'est le cas, pour Steam).

Le choix du morceau se fait dans `data/music.json` (règles par moment du jeu,
acte, drapeaux, indicateurs) ; aucun code à modifier. Un fichier absent donne
du silence, sans erreur.

| Fichier attendu | Moment |
|---|---|
| `menu.ogg` | menu principal |
| `intro.ogg` | introduction (nouvelle partie) |
| `acte1_bureau.ogg` … `acte4_bureau.ogg` | bureau, selon l'acte |
| `bureau_tension.ogg` | bureau quand la suspicion atteint 60 |
| `soiree.ogg` | soirées |
| `soiree_deuil.ogg` | soirées après l'arrestation de SEDLAR |
| `interrogatoire.ogg` | auditions sur le terrain |
| `perquisition.ogg` | perquisitions et visites |
| `fin_acte.ogg` | revue de fin d'acte |
