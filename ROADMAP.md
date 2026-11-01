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
- [x] Localisation complète en anglais (2026-10-27) : interface (`data/locale/en.json`,
      `tr()` / `UiText.of()`), tout le contenu (dossiers, courrier, soirées, journal,
      terrain, fins : `data/locale/en/**`, table texte français -> anglais appliquée
      par `DataLoader`), dates, grades, commandes anglaises du terminal ; test
      `test_english_version` (citations retrouvées dans le texte anglais)
- [x] Horloge de service (8 h + 2 h), demander une pièce (livrée le lendemain), consulter Mazur
- [x] Le prix de la vérité : certaines contradictions (secondaires) ne s'établissent qu'en PROUVANT — payer une heure, un risque (suspicion) ou une faveur (appui requis). Repérer reste gratuit ; données par dossier (`contradiction_prices`). Démonstration sur 51307 (mobile et passé d'informateur d'ORLIK) ; extensible à d'autres dossiers au choix de fen
- [x] Soirées : 5 soirées de l'acte 1 (Lena, radio d'Aldria, M. ADLER, visites), perdues en heures supplémentaires
- [x] Soirées prolongées aux actes 2-4 (jours 5-19) : les fissures, la nuit de la Centrale, la voisine BRANDT, les papiers du père ; réactives au sort d'ADLER/Lena, sans jamais décider d'une fin (données pures)
- [x] Calendrier en 20 journées de service, ellipses entre les actes
- [x] Profil du joueur dans `data/campaign.json` (préparation des extensions)
- [x] Écran de fin d'acte (archive des sujets), commission d'avancement, promotion en 2e classe acceptée ou déclinée
- [ ] Acte 2 : action « demander une archive confidentielle » débloquée par la 2e classe

## En cours : accueil du joueur (demande de fen du 25.10)

- [x] Introduction illustrée en 4 pages
- [x] Bulle d'aide de MAZUR qui montre où cliquer, conseils propres au premier dossier
- [x] Bandeau « À FAIRE » permanent en haut du bureau (prochaine étape en clair, même
      si la bulle est fermée) pendant l'apprentissage ; message d'accueil rassurant ;
      libellés alignés sur les icônes réelles (COURRIER, à gauche)
- [x] Première journée allégée, fonctions débloquées le lendemain
- [x] En-tête du dossier épuré pendant le tutoriel : seuls l'objet de l'enquête et
      les pièces restent ; le rappel « Vous pouvez… » et le compteur d'avancement
      (doublons du bandeau « À FAIRE ») sont masqués, puis réapparaissent une fois
      le joueur rodé (retour de fen du 26.10 : « trop d'info à l'écran »)
- [x] Bandeau « À FAIRE » plus contrasté : bande vert foncé (style « OBJET DE
      L'ENQUÊTE »), texte clair bien lisible (retour de fen : « pas assez contrasté »)
- [x] Dossier zéro (n° 40000, Ida NOVAK) : tutoriel sur rails, deux pièces, une seule
      contradiction évidente (l'adresse déclarée ≠ le registre), enjeu nul. Guidé en
      premier, avant le 40921 ; apprend la boucle lire → noter → confronter → conclure
- [x] Indice « où chercher » : pendant le tutoriel, quand deux notes portent sur le
      même point (même clé), le carnet invite à les confronter, sans dire le verdict
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
- [x] Varier le ressenti par acte — frise chronologique (acte 2) : `TimelineRules` + écran `TimelineScreen`, on remet des repères datés dans l'ordre pour révéler une anomalie et l'établir au carnet (comme la comparaison de pièces). Pilote : dossier 53402 (les retards du train couvraient les passages à la frontière). Données par dossier (bloc `timeline`).
- [x] Varier le ressenti par acte — interrogatoire sous tension (acte 3) : sang-froid du sujet (`FieldRules.composure`) qui baisse quand on le pousse ; un aveu ne s'ouvre que dans une fenêtre de sang-froid (`requires_composure`), trop pousser le referme. Additif, pas de sauvegarde en plus. Pilote : audition de VRABEC (53402), aveu sur les passages à la frontière. Readout du sang-froid dans l'écran de terrain
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
- [x] Décision de fen (27.10) : on reste en 2D / 2.5D, pas de 3D (le réglage 3D existant reste en place, désactivé)
- [x] La lampe (clé `darkness`) : pièce plongée dans le noir, on promène une lampe (souris ou doigt) ; un endroit n'apparaît sur l'image et dans la liste qu'une fois éclairé (`FieldRules.is_lit`, `FieldLamp` + `ui/shaders/lamp.gdshader`)
- [x] 2.5D légère sur toutes les scènes (clé `ambience`) : dérive lente de l'image, poussière, grain, lumière qui vacille (`FieldAmbience`, `ui/shaders/field_ambience.gdshader`) ; réglage « Scènes de terrain animées » pour la couper
- [x] Sous-sol B des archives (53760, acte 2), à la lampe : bordereaux contresignés « B. », carnet de permanence, chemise vide « VOSK, A. — 1971 », carton d'encre verte
- [x] Chaufferie de la Centrale (54001, acte 3) : bouchon à la place de la soupape, pièces visées L. O., arrêt ligaturé, alerte de RUDA, carnet de Mira
- [x] Chevet de REIS (54012, acte 3) : interrogatoire sous tension, l'aveu sur les visiteurs de la nuit ne vient que s'il est ébranlé ; le menacer fait intervenir l'infirmière
- [x] Atelier d'ADLER (54030, acte 3), deux pièces : radio sans ondes courtes, clientèle d'État, pendule bloquée à 06h05, notes du père (« Demander à K. »), cahier de L'HEURE JUSTE versé au dossier
- [x] Traces sur le bureau des nouvelles scènes (chemise du père, encre verte, carnet de Mira, notes du père, cahier « exploité »)
- [ ] Images de l'atelier d'ADLER à livrer (`search_54030_atelier.webp`, `search_54030_arriere.webp`) ; décors dessinés en attendant
- [ ] Suites du cahier de L'HEURE JUSTE versé au dossier (`heure_juste.list_in_file`) : arrestations à l'acte 4, fin ?
- [ ] Autres idées gardées (doc du 27.10) : BRANDT qui vous interroge dans le couloir, la salle d'audition vide (MIROIR), l'escalier de l'immeuble, la filature, la table d'écoute
- [ ] Repositionner finement les zones des autres scènes (51307, 52044, 52310, 53517) avec l'éditeur
- [ ] Modèles et images fournis par fen (ChatGPT, Blender, CC0) : cahier des charges `docs/design/ASSETS_3D.md`
- [ ] Décors 3D de la boulangerie n° 12 et de l'appartement 40

## Impact et profondeur (demande de fen du 26.10, doc de synthèse)

- [x] Levier n°1 : carte d'archive du destin du sujet après chaque signature
      (photo d'identité réutilisée, tampon TRANSFÉRÉ/RELAXÉ/MUTÉ…, ligne de
      conséquence = archive de la décision, parfois une phrase d'un proche ;
      `FateRules` + `ArchiveCard`, tampons dans les 7 dossiers)
- [x] Levier n°4 (journal) : chaque décision des 7 dossiers a sa une du lendemain
      dans « La Voix de Velmira » (version officielle, euphémismes qui contrastent
      avec la carte de destin)
- [x] Journal étendu aux actes 3 et 4 : l'explosion de la Centrale (sabotage →
      bouc émissaire, accident → « incident technique »), le témoin, l'horloger,
      et surtout les réécritures MIROIR qui paraissent comme la vérité établie
      (SEDLAR, la Centrale, le père « parti refaire sa vie à l'étranger »). La
      résistance, elle, ne se publie pas. Données pures, test `test_news_acts3_4`.
- [x] Ton plus dur (demande de fen du 26.10) : camps (Dolenz), exécutions, morts,
      déportations sur les dénouements graves (tampons DÉPORTÉ/EXÉCUTÉ/CONDAMNÉ +
      `fate_line` crue sur la carte, archive officielle conservée plus pudique)
- [x] Levier n°4 (suite) : conséquences aussi dans les soirées et sur le bureau —
      traces posées sur le fond d'écran (`data/desk_traces.json`, `DeskTraces`, 3 au
      plus, selon jours et drapeaux) et échos du soir (`echoes` dans `data/evenings.json`)
- [x] Levier n°3 (début) : semer le père dès l'acte 1 — extrait d'état civil scellé dans
      le dossier personnel (« Père : A. VOSK, horloger… ████ 1971 », mention SCELLÉE),
      visible dès le 2e jour, pour sentir vite que quelque chose autour du père est caché
      (s'ajoute aux traces existantes : intro, horloge sans aiguilles, soirées Lena/ADLER)
- [x] Levier n°3 (suite) : motif de l'horloge relié au père (pendule du couloir « révisée
      par l'atelier VOSK — 1969 », photocopie « réglage des horloges de la gare,
      1969-1971 », atelier VOSK saisi en mars 1971, marelle « 1971 », écho du soir 2)
- [x] Levier n°2 (acte 2) : les gens reviennent selon ce qu'on a signé — KOLB récidive
      (on devient son outil), la mère de la chorale attend en bas, ou KOLB dénonce
      l'inspecteur si on a classé ; retours PETRAS/informateur déjà en place
- [x] Levier n°2 (actes 3-4) : les gens jugés reviennent — Vera SEDLAR réécrit
      quand sa fille Mira est condamnée (après le père), le témoin coaché REIS est
      « versé à la liste des témoins fiables » (ou, discrédité, l'accusé rentre et
      REIS remercie), l'atelier d'ADLER scellé rend la pendule VOSK de 1971 (ou,
      relâché, ADLER laisse une montre « à l'heure juste »). Données pures
      (events.json), test `test_act3_returns`.
- [x] Pression de la hiérarchie selon le profil de l'agent (demande de fen du 26.10
      « amplifier les conséquences ») : les conditions d'événements acceptent des
      seuils d'indicateurs (`min_indicators`/`max_indicators`). La hiérarchie réagit
      au cumul des choix — relecture des classements (suspicion ≥ 50), contrôle
      interne (suspicion ≥ 70), agent courtisé par la Direction (loyauté ≥ 75 +
      poids ≥ 35, sans surveillance), réserve sur la fiabilité (loyauté ≤ 24). Chaque
      pression se lit aussi dans le dossier personnel (notes de drapeau). Déterministe.
- Mini-jeux (demande de fen du 26.10) — facultatifs, déterministes, avec avantage :
  - [x] Comparer deux pièces — VARGA : le joueur juge chaque trait (concorde/diffère)
        sur les mentions exactes des deux fiches ; pièges (nom/adresse identiques) ;
        bien juger établit `varga.mark` et verse les faits au carnet
        (ComparisonRules + ComparisonScreen + bouton COMPARER, photos facultatives)
  - [x] Comparer deux pièces — chorale 53118 (acte 2) : signalement vs archives
        paroissiales, sans photo ; établit `choir.curfew` (veillée autorisée) et
        débloque la relaxe prouvée
  - [x] Authentifier les papiers (« traquer les faussaires ») — cheminot 53402 :
        cachets dessinés en code (OfficialMark), le joueur confronte un permis en
        règle au permis présenté ; sceau authentique (ne pas crier au faux),
        validité échue ; établit `halvek.movements` (vraies familles, permis réels)
  - [x] Démasquer un vrai faux — signature imitée (SEDLAR, 40921) : signature
        authentique du Dr MARKO vs copie au crayon (tracé tremblé, encre « crayon »
        dans OfficialMark) ; le nom concorde (piège : ne pas accuser un nom exact),
        la graphie trahit la copie ; confrontable seulement après la perquisition
        (matelas) ; établit `sedlar.papers.forged` → l'arrestation devient appuyée
  - [x] Authentifier un carnet de rationnement — carnets du cimetière (KOVAC, 52044) :
        carnet VRAI (tampon District 4 dessiné, OfficialMark) au nom d'un homme mort
        sept semaines plus tôt ; piège « faussaire » inversé (ne pas accuser le vrai
        carnet, la fraude est au Bureau) ; établit `horvat.status` → disculpe la
        gérante et débloque la mise en cause prouvée du Bureau (DRAZEK)
  - [x] Loupe d'inspection : bouton AGRANDIR sous chaque pièce (portrait, cachet,
        signature) ; la pièce s'affiche agrandie et centrée, fermeture au toucher.
        On peut compter les branches d'une étoile, lire un numéro de série, voir le
        tremblé d'une signature — « faut que le joueur se prenne au jeu »
  - [x] Le coach (MAZUR) met en avant COMPARER + la loupe : quand un dossier propose
        une confrontation de pièces accessible, l'aide y oriente le joueur avant la
        confrontation classique (découvrabilité du mini-jeu)
  - [ ] Amplifier encore : un vrai sceau truqué (étoile à 4 branches) dans un dossier
        avec un faussaire au tampon ; billets de transport ; signatures côte à côte
  - [x] Comparer avec l'archive — registre modifié de SEDLAR (révélation d'acte 2) :
        dossier 53761, original du sous-sol B vs copie transmise ; la ligne du 21.10
        vers Halvek est un ajout postérieur (tampon coiffé) ; établit `register.altered`
  - [ ] Caviarder / réécrire ; pointeuse / l'heure juste ; radio étrangère ; tri du courrier

## Fait : acte 2 — L'Archive et le registre truqué (2026-10-26)

- [x] Dossier 53760 L'ARCHIVE : l'archiviste H. KREMER (ex-inspecteur Section 2 relégué
      au sous-sol B, l'allié de l'acte 1) est signalé par le contrôle interne pour
      « vol de papier » ; le registre de prêt dément le vol (contradiction `kremer.theft`).
      Trois voies : le protéger (classer) ouvre l'accès aux originaux (`kremer.originals`),
      le transmettre le fait révoquer et scelle les archives, le requalifier le met sous
      surveillance. VERITAS tient le signalement du contrôle interne pour fiable.
- [x] Révélation de fin d'acte — dossier 53761 : qui a protégé KREMER reçoit l'original
      du registre de déplacements du dossier 40921. La comparaison « avec l'archive »
      prouve que le trajet du 21 octobre vers Halvek a été ajouté le 24, après la
      clôture : la première contradiction du joueur était fabriquée, et le bordereau
      révèle que c'est MAZUR qui avait transmis le dossier. VERITAS retourne la charge
      et continue de couvrir la copie truquée même une fois l'altération prouvée.
- [x] Câblage déterministe : `assign_53760` (acte 2, après la note de KREMER),
      `assign_53761_reveal` (si `kremer.protected`), `kremer_archive_sealed` (si
      `kremer.arrested`) ; notes de dossier personnel pour les nouveaux drapeaux
      (`kremer.*`, `act2.*`, `player.flagged`, `mazur.confronted`). Tests ajoutés.

## Fait : acte 3 — La peur (début) (2026-10-27)

- [x] Dossier 54001 L'EXPLOSION : la Centrale thermique n° 3 saute, trois morts. La
      Direction veut un saboteur avant le bulletin de 20 h ; le registre d'entretien et
      l'expertise établissent la défaillance (soupape jamais livrée, réquisitions visées
      et détournées par le capitaine L. ORLIK). Trois voies : désigner Mira SEDLAR (la
      fille du 40921, couvre ORLIK, `54001.scapegoat`), établir la défaillance (accuse
      ORLIK, `milice.hostile`, `orlik.captain_hostile`), ou refuser de nommer avant le
      bulletin. Levier n°2 : condamner la fille après avoir arrêté le père brise la
      famille SEDLAR (`54001_sedlar_line_broken`).
- [x] Dossier 54012 LE TÉMOIN : le seul survivant posté près de la chaudière a « signé »
      une déposition de sabotage à 04 h, alors que la fiche médicale le dit inconscient
      jusqu'à 10 h. Registre des visites (brigade ORLIK entrée avant tout réveil) et
      rétractation sur demande. Retenir la déposition = faux témoin ; l'écarter établit
      `temoin.coached`.
- [x] Câblage : `assign_54001` (jour 10, priorité absolue), `assign_54012` (jour 11),
      `54001_orlik_reprisal` (si ORLIK accusé). Notes de dossier personnel ajoutées, tests.
- [x] Dossier 54030 L'HORLOGER (fil du père, levier n°3) : Viktor ADLER, le voisin
      horloger du bloc 7 (celui des soirées, « je vous mets toujours à l'heure »),
      arrêté dans la rafle des horlogers. L'inventaire (cahier de voisinage, radio de
      musique, et la pendule d'A. VOSK père déposée en mars 1971, jamais réclamée)
      dément le réseau de sabotage. Il révèle que le père enquêtait en 1971 sur les
      horloges du ministère et a disparu après. Si le joueur avait dénoncé la radio
      d'ADLER (soirées), le dossier le lui renvoie. Relâcher / transférer (il disparaît
      comme le père) / rouvrir 1971 (`vosk.father_1971_opened`, amorce acte 4).
- [x] Dossier 54100 VOSK, A. : un dossier au nom du joueur, en lecture seule (une seule
      issue, « refermer »). Indice de méfiance en toutes lettres, filiation scellée de
      1971, et révélation : I. BRANDT, l'inspectrice affable du poste voisin, est la
      contrôleuse (le « B. » du 53760). Annexe de procédure si le joueur est déjà sous
      contrôle interne.
- [x] Révélation de fin d'acte 3 : `brandt_revealed` (après lecture du 54100),
      et le sort de MAZUR — il s'enfuit avec un dernier message (« 05 h 05. Quai 2.
      Juste. ») si KREMER a été protégé, il est arrêté sinon.
- [ ] Note mécanique : 54100 « consultable seulement » rendu en données (issue inerte) ;
      l'indice de suspicion live en mots et l'interdiction d'ouvrir dans la liste
      demanderaient un petit ajout moteur — à proposer à fen.
## Fait : acte 4 — MIROIR (réécriture des archives) (2026-10-27)

Le joueur ne vérifie plus les documents, il les rédige. Mécanique de réécriture
modélisée par le choix de version (signer le mensonge / rétablir la vérité /
caviarder) via le système de décisions existant — données pures, sans moteur neuf.

- [x] Dossier 60001 MIROIR : SEDLAR — réécrire le premier dossier (40921) pour faire
      de la visite à la mère une « liaison » de réseau. Signer la falsification
      (`act4.sedlar_falsified`), rétablir la vérité (`act4.sedlar_restored`, résistance
      tracée), ou caviarder. Qui avait gardé la preuve d'acte 2 voit qu'il efface sa
      propre preuve.
- [x] Dossier 60002 MIROIR : CENTRALE — rédiger le rapport officiel de l'explosion.
      Nommer le mort RUDA en saboteur (96 % VERITAS), écrire la défaillance et ORLIK
      (`act4.centrale_truth`), ou caviarder. Qui a gardé les originaux de KREMER peut
      faire imprimer à VERITAS « 0 % de sabotage » (`veritas.zero`) — la preuve de la
      fin La Fuite des originaux.
- [x] Dossier 60003 MIROIR : VOSK — le choix final. Le dossier scellé de 1971 révèle
      que le père avait découvert le trucage des horloges et a disparu après. Effacer
      (émigration, `act4.father_erased` + `act4.mirror_signed_clean`, promotion, vers
      Le Miroir parfait), rétablir sa vérité (`act4.father_truth`, vers La Correction),
      ou refuser d'écrire (`act4.mirror_refused`, vers Le Silence).
- [x] Câblage : `assign_miroir_intro` + `assign_60001` (jour 15), `assign_60002`
      (jour 16), `assign_60003` (jour 18). Notes de dossier personnel. Tests ajoutés.
- [x] Moteur des 7 fins (`EndingRules.resolve`, logique pure) + `data/endings.json`
      (7 fins, règles en OR-de-ET sur les drapeaux/indicateurs, « spared » = innocents
      épargnés, Le Silence par défaut) + écran de fin `scenes/act_end/ending_screen`
      (texte de la fin, puis dernière page d'archive via `FateRules`, « ligne vraie »
      pour La Correction). Branché au terme du jour 20 (`GameState.is_final_day()` /
      `get_ending()` / `finish_game()`, `desk._end_game()` → menu). Tests `test_endings`
      et `test_end_of_game_in_desk`. Ordre et seuils validés par fen le 27.10.
      Conception : `docs/design/FINS_PROPOSITION.md`.
- [ ] Facultatif (proposé à fen) : compteur « fins découvertes X/7 » au menu principal,
      pour inciter à rejouer. À faire si fen le valide.

## Fait : audit de cohérence du scénario (demande de fen du 28.10)

Rapport complet : document « Audit du scénario » (lien dans la pull request).
- [x] La Fuite des originaux redevient atteignable : l'événement `veritas_zero_kept`
      (jour 17, original du 40921 gardé) pose `veritas.zero`
- [x] `vosk.subject` posé à l'attribution du dossier 54100 ; `53118.truth_known` posé
      quand on arrête les onze en connaissant le permis ou la liste
- [x] L'Allié de la Milice exclu si l'on s'est brouillé avec elle (`milice.hostile`)
- [x] Le père est partout horloger (agréé, il réglait les horloges de l'État) ; KREMER
      est l'inspecteur de la Section 2 qui a reçu son rapport de 1971 (« Demander à K. »)
- [x] Famille SEDLAR : deux enfants, Mira 19 ans, la sœur de Halvek renommée Hana DOLAN ;
      atelier d'ADLER situé au District 2 ; lettre BENES sans jour impossible ;
      fin de la Fuite : le registre n'est plus « truqué par MAZUR »
- [x] Test `test_scenario_flags_reachable` : tout drapeau lu par une fin, le dossier
      personnel ou une vérité d'archive est posé quelque part
- [x] Recommandations validées par fen : Miroir parfait évalué avant la Milice ; notes de
      KREMER sans « lundi » ; la veillée du 9 novembre fête la dédicace de l'église
      (plus la Sainte-Agathe, qui tombe en février) ; le Bureau du ravitaillement relève
      du ministère de la Sécurité nationale
- [ ] ~120 drapeaux posés jamais lus : suites proposées dans le rapport d'audit

## Retours du test complet de fen (28.10)

- [x] Introduction : la phrase sur le père est réécrite (horloger agréé, agrément retiré
      en 1971, disparu ; le ministère a quand même pris son fils, sans dire pourquoi) ;
      la Milice est nommée dès la première page ; FIN DE SERVICE annoncé
- [x] Mémento de l'agent dans le courrier du premier jour (ministère, Section 4,
      Section 7, Milice, Parti, VERITAS, Direction du personnel, Halvek, fiabilité,
      fin de journée), conseillé par le guide juste après le message de MAZUR
- [x] FIN DE SERVICE mis en avant : style rouge propre (`EndDayButton`), guidé toute
      la première journée, clignote et rappel à 16h00, étape « heures épuisées »
- [x] Classer les dossiers conclus (CLASSER / DOSSIERS CLASSÉS / RESSORTIR) et mettre
      les plis lus à la corbeille (SUPPRIMER / CORBEILLE / RESTAURER) ; sauvegarde v7

## Prochaine itération

- [ ] Effets observables des indicateurs (ton des messages, dossiers confiés)
- [ ] Utiliser les drapeaux `milice.ally` / `milice.enemy` dans un troisième dossier
- [x] Lecteur de musique (demande de fen du 25.10) : autoload `Music`, fondus enchaînés,
      volume dans Paramètres, morceau choisi par `data/music.json` (moment, acte, drapeaux, indicateurs)
- [ ] Morceaux fournis par fen (.ogg dans `assets/music/`, liste dans son README)
- [x] Socle des médias (demande de fen du 27.10, `docs/MEDIAS.md`) : autoload `Sound`
      (bruitages à variantes, ambiances par moment du jeu, clic de tous les boutons,
      sons liés aux signaux du jeu) piloté par `data/sounds.json` ; images d'écran
      remplaçables par emplacement (`data/images.json`) ; extension libre, fichiers
      absents sans erreur ; écran « Médias » (fourni / manquant, écouter, voir)
- [x] Paramètres en sections (affichage, son, jeu), volumes séparés musique /
      ambiances / bruitages, bouton du son dans la barre des tâches, fenêtres
      qui apparaissent en fondu, image de fond des soirées
- [ ] Bruitages et ambiances fournis par fen (liste dans l'écran « Médias » et `docs/MEDIAS.md`)
- [x] Portraits des citoyens remplaçables par un vrai fichier image (clé `image`
      du bloc `photo`, dossier `assets/portraits/`), repli automatique sur le
      visage dessiné ; noms de fichiers dans le document des besoins d'assets

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
