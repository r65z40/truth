# Extensions : incarner un autre personnage (idée de fen, 2026-10-24)

Statut : **piste pour après la 1.0**, rien n'est à implémenter maintenant, sauf
les précautions techniques listées à la fin.

## Principe

Chaque extension est une campagne courte (environ 1 h 30 à 2 h) qui fait vivre
une partie de l'histoire du point de vue d'un autre personnage. Elle garde la
boucle documentaire (lire, confronter, signer) avec une mécanique propre au
personnage. Règle de canon : une extension **révèle** ce que la campagne de Vosk
cache (les champs `truth`, les coulisses), elle ne le **contredit** jamais.

Bonus de cohérence : une extension peut lire l'archive finale d'une partie de
Vosk terminée, pour que ses choix existent dans l'autre récit (par exemple, BRANDT
rédige le dossier 54100 à partir de ce que le joueur a vraiment fait).

## Personnages candidats

| Personnage | Période | Ce que le joueur découvre | Mécanique propre | Intérêt |
| --- | --- | --- | --- | --- |
| R. MAZUR, le double jeu | Actes 1 à 3, en parallèle | Pourquoi les dossiers arrivent chez Vosk ; le registre falsifié du 40921 | Choisir quel inspecteur reçoit quel dossier ; protéger le réseau sans se trahir | Très fort : répond à la question laissée ouverte (audit 3.7) |
| I. BRANDT, la contrôleuse | Actes 2 à 4, en parallèle | Ce que la hiérarchie sait de Vosk | Surveiller un agent : écoutes, rapports, dossier 54100 à rédiger | Très fort : retourne le jeu, réutilise la partie du joueur |
| H. KREMER, l'archiviste | 1979 à 1986, puis acte 2 | Comment les originaux ont été sauvés ; la vraie fin de VARGA | Copier, cacher, falsifier les registres de prêt des archives | Fort, peu coûteux (archives déjà prévues en acte 2) |
| Capitaine L. ORLIK | Acte 3 | Les détournements et l'explosion vus de la Milice | Trafic, faveurs, choisir qui sera le saboteur | Moral et risqué : jouer le corrompu |
| LENA VOSK | Acte 3 | L'explosion vue de l'hôpital, les blessés, ce que taisent les bulletins | Rapports médicaux à signer, certificats de décès dictés | Forte charge humaine ; violence montrée |
| Le père de Vosk, 1971 | Prologue | L'origine de L'HEURE JUSTE et de la disparition | Réparer des horloges de pointage pour fabriquer des alibis | Ferme la boucle de « La Correction » |
| Un journaliste d'Aldria | Après la fin | Ce que deviennent les originaux | Vérifier l'authenticité de documents sortis du pays | Épilogue, rejouabilité des fins |

Recommandation : si une seule extension doit être faite, commencer par **MAZUR**
ou **BRANDT**, qui changent le plus le regard sur la campagne principale.

## Précautions techniques à prendre dès maintenant

Elles coûtent peu et évitent de tout reprendre plus tard :

1. Ne pas écrire « A. VOSK » ni son matricule en dur dans le code : le profil du
   personnage joué vient des données de la campagne (aujourd'hui dans
   `GameState.new_game`, à déplacer dans un fichier de campagne).
2. Regrouper ce qui définit une campagne (dossiers de départ, calendrier,
   événements, messages initiaux, profil du joueur) pour pouvoir en charger une
   autre : `data/campaigns/<id>/`, la campagne de Vosk étant la première.
3. Garder des identifiants stables pour les personnages et les drapeaux, et une
   archive finale exportable, lisible par une autre campagne.
4. Une sauvegarde par campagne (le format v4 prévu porte l'identifiant de
   campagne).
