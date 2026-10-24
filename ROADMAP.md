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

## Prochaine itération

- [ ] Passage au jour suivant (« fin de service »), conséquence différée du dossier 40921
- [ ] VERITAS déterministe : remarque sur les pièces et recommandation dans le formulaire
- [ ] Deuxième dossier, lié aux choix du premier (piste ORLIK)

## Ensuite

- [ ] Troisième dossier, personnages récurrents (ORLIK, MAZUR)
- [ ] Chronologie et association de preuves
- [ ] Sons d'ambiance (terminal, tampons), polices libres embarquées
- [ ] Preset d'export Windows, premiers tests sur machine cible

## Plus tard

- [ ] Réseaux d'informateurs, fiabilité des sources, interrogatoires
- [ ] Promotions et carrière, factions, simulation politique
- [ ] Interface LLM optionnelle pour VERITAS (formulation seulement, via serveur)
- [ ] Adaptation mobile complète
