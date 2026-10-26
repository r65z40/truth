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
- [x] Écran principal plus visuel : remplacé par la refonte « bureau à fenêtres » ci-dessous

## En cours : interface « bureau à fenêtres » (validée par fen le 25.10, proposition `interface_v2.md` du projet)

- [x] Étape 1 : fond à l'emblème, icônes (pastilles), fenêtres déplaçables, superposables,
      réductibles et agrandissables, barre des tâches, menu MINISTÈRE, terminal en fenêtre,
      plein écran sur petit écran, icônes en pixels par type de pièce
- [x] Étape 2 : le dossier en classeur (pièces en liste à gauche, lues ou « à lire »,
      avancement en quatre étapes, éléments à noter en bas de la pièce, source rappelée
      dans le carnet) ; chaque pièce peut s'ouvrir dans sa propre fenêtre, pour comparer
- [x] Étape 3 : passages soulignés dans le texte (`quote`), cliqués pour être notés puis
      surlignés ; fiches du carnet à glisser l'une sur l'autre pour les confronter.
      Le carnet reste dans la fenêtre du dossier (une fenêtre à part masquerait les pièces)
- [x] Étape 4 : VERITAS devient un programme qu'on lance (plus affiché d'office dans la
      conclusion) ; Courrier en plis et lettres à en-tête ; Archives en chemises qui
      rouvrent le dossier, fonds historique verrouillé ; fiche d'évaluation du personnel.
      Les info-bulles et la bulle de R. MAZUR existaient déjà ; pas d'ancien bureau à supprimer
- [x] Journal du matin « La Voix de Velmira » : 3 titres par jour, la version officielle,
      dont les décisions de l'agent racontées à la manière du régime (data/news.json, NewsRules).
      Première des pistes « un 1986 qui parle d'aujourd'hui » (GAME_DESIGN_V2 section 14)
- [ ] Son à l'arrivée du courrier (quand fen fournira des sons)

## En cours : le terrain (validé par fen le 25.10, `docs/design/TERRAIN.md`)

- [x] Moteur des scènes de terrain (`FieldRules`, `data/field/`), 2 h, une fois par dossier, tours limités
- [x] Audition d'ORLIK (51307) : questions, éléments du carnet à présenter, procès-verbal versé au dossier
- [x] Perquisition chez SEDLAR (40921) : endroits cliquables sur le dessin, rapport versé au dossier
- [x] Indice L'HEURE JUSTE : l'horloge sans aiguilles (escalier, soirée 1, puis poêle de SEDLAR)
- [x] Visite de la boulangerie n° 12 (52044) et perquisition chez Karel BENES (52310)
- [ ] Soirées dans des lieux dessinés (cuisine, loge d'ADLER, cabine du hall)
- [x] Décors 3D (demande de fen du 25.10) : moteur `FieldStage3D`, audition d'ORLIK et appartement des SEDLAR en formes simples, réglage 2D/3D
- [x] Images de terrain livrées par fen : clé `image` par scène, affichées en fond (cadrage « cover »), prioritaires sur la 3D (réglage `field_3d` désormais optionnel, désactivé par défaut)
- [x] Perquisition en plusieurs pièces : clé `rooms` + `doors`, on clique une porte pour changer de pièce (gratuit), budget de fouilles commun. Pilote : 40921 (salon + chambre)
- [x] Zones cliquables en fractions de l'image (calées sur l'objet), image affichée en entier (cadre 16:9) + éditeur de zones (F2 : glisser un rectangle → coordonnées copiées)
- [x] Fond vidéo en boucle (clé `video`, .ogv) pour animer la scène : priorité vidéo > image > 3D > dessin, zones calées pareil
- [x] Visite de la salle de la chorale Sainte-Agathe (53118, acte 2) : 5 endroits, compte rendu de visite, second chemin vers le permis, les sept émargements et le mobile de l'informateur
- [x] Interface terrain immersive (demande de fen du 26.10) : l'image occupe tout l'écran, texte (bandeau bas) et choix (panneau droit) en surimpression translucide, zones cliquables au centre
- [ ] Repositionner finement les zones des autres scènes (51307, 52044, 52310, 53517) avec l'éditeur
- [ ] Modèles et images fournis par fen (ChatGPT, Blender, CC0) : cahier des charges `docs/design/ASSETS_3D.md`
- [ ] Décors 3D de la boulangerie n° 12 et de l'appartement 40

## Impact et profondeur (demande de fen du 26.10, doc de synthèse)

- [x] Levier n°1 : carte d'archive du destin du sujet après chaque signature
      (photo d'identité réutilisée, tampon TRANSFÉRÉ/RELAXÉ/MUTÉ…, ligne de
      conséquence = archive de la décision, parfois une phrase d'un proche ;
      `FateRules` + `ArchiveCard`, tampons dans les 7 dossiers)
- [ ] Levier n°2 : faire revenir les gens (épargnés/condamnés) sur 2-3 figures
- [ ] Levier n°3 : semer le père dès l'acte 1 (horloge, nom, date 1971)
- [ ] Levier n°4 : rendre les conséquences visibles (journal, soirées, bureau)

## Prochaine itération

- [ ] Effets observables des indicateurs (ton des messages, dossiers confiés)
- [ ] Utiliser les drapeaux `milice.ally` / `milice.enemy` dans un troisième dossier
- [x] Lecteur de musique (demande de fen du 25.10) : autoload `Music`, fondus enchaînés,
      volume dans Paramètres, morceau choisi par `data/music.json` (moment, acte, drapeaux, indicateurs)
- [ ] Morceaux fournis par fen (.ogg dans `assets/music/`, liste dans son README)
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
