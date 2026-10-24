# Roadmap

## Fait : prototype 0.1 (2026-10-24)

- [x] Projet Godot 4, thème visuel rétro, filtre CRT désactivable
- [x] Menu principal : nouvelle partie, continuer (si sauvegarde), paramètres, quitter
- [x] Paramètres : plein écran, effet CRT, taille de l'interface (enregistrés)
- [x] Bureau : en-tête (ministère, agent, grade, date), terminal, raccourcis, sauvegarde
- [x] Terminal : commandes au clavier et en boutons (AIDE, DOSSIERS, MESSAGES, ARCHIVES, IDENT, DATE, SAUVER, EFFACER, MENU)
- [x] Fenêtre Dossiers : liste, onglets de pièces, rendu « papier », suivi des pièces lues
- [x] Messagerie interne (2 messages), Archives provisoires
- [x] Dossier 40921 complet en données (4 pièces, contradiction, décisions, vérité)
- [x] État de partie + sauvegarde JSON versionnée + 3 indicateurs internes
- [x] Tests automatiques (logique, sauvegarde, scènes, parcours complet)

## Fait : MVP 0.2 (2026-10-24)

- [x] Éléments notables dans chaque pièce, carnet d'enquête, confrontation de deux éléments
- [x] Formulaire de conclusion (arrestation, classement, enquête complémentaire) et signature
- [x] Règles de décision pilotées par les données : effets selon que la contradiction a été établie ou non
- [x] 6 réponses différentes du supérieur, affichées dès la transmission
- [x] Historique des décisions, conséquences persistantes (drapeaux), archives mises à jour
- [x] Sauvegarde v2 avec migration automatique des sauvegardes v1
- [x] Commande de développement ETAT (indicateurs, versions debug uniquement)

## Fait : 0.3 (2026-10-24)

- [x] Fin de service : passage au jour suivant (avec confirmation si un dossier attend), transition, sauvegarde automatique
- [x] Événements différés en données (`data/events/events.json`) : conséquences du dossier 40921, rappel, bulletin
- [x] VERITAS déterministe : remarque sur chaque pièce, recommandation chiffrée dans le formulaire, réponses au terminal
- [x] Accord ou désaccord avec VERITAS mémorisé dans l'historique des décisions
- [x] Sauvegarde v3 (migration des v1 et v2)

## Fait : 0.4 (2026-10-24)

- [x] Dossiers attribués par événement (`assign_cases`), dossiers de départ dans `index.json`
- [x] Pièces conditionnelles : le contenu d'un dossier dépend des choix passés
- [x] Dossier 51307 (B. ORLIK) : 4 pièces de base + 3 pièces selon le dossier 40921, 2 contradictions possibles
- [x] Pression de la Milice (capitaine L. ORLIK) et voie de la corruption (classement = faveur due)
- [x] Suites du 51307 : Milice hostile, Milice alliée, rétrogradation, rappel
- [x] VERITAS recommande le classement (71 %) : il protège les informateurs
- [x] Dossier personnel : évaluation de l'agent en mots, sans chiffres (choix de fen, 2026-10-24)

## Fait : 0.5 (2026-10-24)

- [x] Barre OBJECTIF : étape suivante calculée par `Guidance`, bouton visé mis en évidence
- [x] Éléments notables toujours visibles sous la pièce, boutons « + élément » / « NOTÉ »
- [x] Notifications brèves (élément noté, contradiction, sauvegarde, rapport transmis)
- [x] Info-bulles sur les boutons du bureau, compteurs sur les boutons latéraux
- [x] Déconnexion confirmée si la journée n'est pas sauvegardée
- [x] Menu : accroche, date de la sauvegarde sur CONTINUER ; option « Aide à l'enquête »

## Conception V2 (proposition du 2026-10-24, en attente de validation)

Directive de game design V2 de fen : audit, game design V2, carrière, factions,
VERITAS, dépendances, acte 5, roadmap hiérarchisée dans `docs/design/`
(voir `docs/design/README.md`). Priorité : un acte 1 complet et stable.

## Prochaine itération

- [ ] Effets observables des indicateurs (ton des messages, dossiers confiés)
- [ ] Utiliser les drapeaux `milice.ally` / `milice.enemy` dans un troisième dossier
- [ ] Sons d'ambiance (terminal, tampon de signature)

## Ensuite

- [ ] Troisième dossier, personnages récurrents (ORLIK, MAZUR)
- [ ] Chronologie et association de preuves
- [ ] Polices libres embarquées
- [ ] Preset d'export Windows, premiers tests sur machine cible

## Plus tard

- [ ] Réseaux d'informateurs, fiabilité des sources, interrogatoires
- [ ] Promotions et carrière, factions, simulation politique
- [ ] Interface LLM optionnelle pour VERITAS (formulation seulement, via serveur)
- [ ] Adaptation mobile complète
