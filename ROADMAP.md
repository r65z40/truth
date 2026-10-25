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

## Conception V2 (validée par fen le 2026-10-24)

Directive de game design V2 de fen : audit, game design V2, carrière, factions,
VERITAS, dépendances, acte 5, roadmap hiérarchisée dans `docs/design/`
(voir `docs/design/README.md`). Priorité : un acte 1 complet et stable.

## En cours : 0.6, acte 1 complet

- [x] Dossier 52044 : carnets du cimetière (3 contradictions, issues selon la contradiction établie)
- [x] Dossier 52310 : le poète T. VARGA (deux éditions, deux photos, Section 7)
- [x] Note de KREMER, fin de l'acte 1 (deux variantes), lettre de Mme BENES, bulletins des 5, 6 et 7 novembre
- [x] Photos d'identité dessinées à partir des données (`IdPhoto`)
- [x] VERITAS : indice de conformité calculé, `VERITAS POURQUOI`
- [x] Onglets des pièces sur une ligne défilante (dossiers de 8 pièces)
- [ ] Fondations de la localisation (français, anglais)
- [x] Horloge de service (8 h + 2 h), demander une pièce (livrée le lendemain), consulter Mazur
- [x] Soirées : 5 soirées de l'acte 1 (Lena, radio d'Aldria, M. ADLER, visites), perdues en heures supplémentaires
- [x] Calendrier en 20 journées de service, ellipses entre les actes
- [x] Profil du joueur dans `data/campaign.json` (préparation des extensions)
- [x] Écran de fin d'acte (archive des sujets), commission d'avancement, promotion en 2e classe acceptée ou déclinée
- [ ] Acte 2 : action « demander une archive confidentielle » débloquée par la 2e classe

## En cours : accueil du joueur (demande de fen du 25.10)

- [x] Introduction illustrée en 4 pages
- [x] Bulle d'aide de MAZUR qui montre où cliquer, conseils propres au premier dossier
- [x] Première journée allégée, fonctions débloquées le lendemain
- [ ] Écran principal plus visuel (bureau dessiné ou terminal allégé : choix de fen)

## En cours : le terrain (validé par fen le 25.10, `docs/design/TERRAIN.md`)

- [x] Moteur des scènes de terrain (`FieldRules`, `data/field/`), 2 h, une fois par dossier, tours limités
- [x] Audition d'ORLIK (51307) : questions, éléments du carnet à présenter, procès-verbal versé au dossier
- [x] Perquisition chez SEDLAR (40921) : endroits cliquables sur le dessin, rapport versé au dossier
- [x] Indice L'HEURE JUSTE : l'horloge sans aiguilles (escalier, soirée 1, puis poêle de SEDLAR)
- [ ] Scènes de 52044 (boulangerie ou agent DRAZEK) et 52310 (chez Karel BENES), après l'avis de fen
- [ ] Soirées dans des lieux dessinés (cuisine, loge d'ADLER, cabine du hall)

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
