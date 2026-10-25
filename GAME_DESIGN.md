# Game design : MINISTRY OF TRUTH

Document évolutif. Les décisions de design sont datées dans la section finale.

## Intention

Un jeu sérieux et inquiétant sur la bureaucratie du renseignement. Le plaisir
vient de l'examen minutieux de pièces concrètes, du recoupement et du poids des
conclusions, pas de l'accumulation de statistiques.

Principes :
- Chaque décision a des conséquences compréhensibles, parfois différées.
- Pas de choix évident : la « bonne » réponse dépend de ce que le joueur valorise.
- Les interactions sont visuelles et manipulables (pièces, tampons, registres),
  pas seulement des dialogues ou des QCM.

## Les cinq vérités

Toute affaire distingue :
1. **Vérité objective** : ce qui s'est réellement passé (champ `truth` du dossier,
   jamais affiché tel quel).
2. **Informations accessibles** : les pièces du dossier, parfois incomplètes,
   fausses ou manipulées, chacune avec une source et une fiabilité (A à D).
3. **Conclusions du joueur** : ce qu'il déduit et transmet.
4. **Recommandations de VERITAS** : l'avis du système, qui peut se tromper ou
   avoir ses propres objectifs.
5. **Vérité officielle** : ce que le régime retient et publie.

## Univers

- Pays fictif, régime à parti unique. Capitale **Velmira** ; ville frontalière
  **Halvek**. Calendrier de jeu à partir du lundi 3 novembre 1986.
- Le joueur : **A. VOSK**, matricule INS-7734, Section 4 (Inspection des dossiers
  civils) du ministère de la Sécurité nationale.
- Supérieur direct : **R. MAZUR**, directeur adjoint de la Section 4.
- **VERITAS** : système d'analyse du régime, raccordé aux terminaux. Pour l'instant
  présence d'ambiance ; deviendra conseiller puis acteur politique.

## Boucle de jeu (cible du MVP)

1. Le joueur arrive au bureau, lit ses messages.
2. Il ouvre un dossier, consulte les pièces, repère les incohérences.
3. Il choisit une conclusion : arrestation, classement, enquête complémentaire.
4. Les indicateurs internes évoluent ; le supérieur réagit par message.
5. La partie est sauvegardée ; le jour suivant apporte de nouvelles affaires
   et les conséquences des précédentes.

## Indicateurs internes (0 à 100, non affichés en chiffres)

| Indicateur | Sens | Départ |
|---|---|---|
| Loyauté (`loyalty`) | Loyauté perçue envers le régime | 50 |
| Suspicion (`suspicion`) | Méfiance de la hiérarchie envers le joueur | 20 |
| Influence (`influence`) | Poids institutionnel du joueur | 10 |

Le joueur ne voit jamais les chiffres. La fenêtre **Dossier personnel** (commande
`PROFIL`) traduit chaque indicateur en appréciation administrative (« loyauté :
conforme », « attention de la hiérarchie : surveillance renforcée ») et ajoute des
observations selon les drapeaux (note au dossier, relations avec la Milice).
Paliers et textes : `data/assessment.json`. Décision de fen du 2026-10-24.

Chaque indicateur doit produire des effets observables (ton des messages,
dossiers confiés, promotions, enquêtes internes). Pas de variable décorative.

## Dossier n° 40921 : SEDLAR, Anton Pavel

Premier dossier, tutoriel implicite.
- **Fiche d'identité** (fiabilité A) : technicien à la Centrale thermique n° 3,
  famille à Halvek, un avertissement pour absentéisme.
- **Rapport de présence** (B), signé par le chef d'équipe B. ORLIK : SEDLAR était
  à son poste le 21 octobre 1986.
- **Communication interceptée** (B) : un homme annonce venir « mardi » à Halvek,
  dit que son chef « s'en occupe » et parle des « papiers de maman ».
- **Registre de déplacements** (A) : la carte de travail de SEDLAR est contrôlée
  dans le train Velmira > Halvek le mardi 21 octobre.

**Contradiction vérifiable** : rapport de présence contre registre ferroviaire
pour le 21 octobre. L'interception suggère que le chef d'équipe a couvert l'absence.
**Ambiguïtés volontaires** : la voix n'est pas formellement identifiée ; la photo
de la carte n'est pas toujours contrôlée (quelqu'un d'autre a pu l'utiliser).

Vérité objective : SEDLAR est allé à Halvek apporter les papiers de sa mère malade,
en partie falsifiés, pour des soins de l'autre côté de la frontière ; ORLIK l'a
couvert en échange de services. Arrêter est « correct » pour le régime mais
brise une famille ; classer expose le joueur ; enquêter ouvre la piste ORLIK.

## Instruction et conclusion (MVP 0.2)

- Chaque pièce présente des **éléments notables** que le joueur peut noter dans
  son **carnet d'enquête**. Il en sélectionne deux et les **confronte** : le jeu
  dit seulement s'il y a contradiction, jamais qui ment.
- Le **formulaire de conclusion** rappelle les pièces lues et les contradictions
  établies, puis le joueur signe une recommandation (irréversible).
- Les effets dépendent de la décision **et** de la qualité de l'instruction :

| Décision | Contradiction établie | Sans contradiction établie |
|---|---|---|
| Arrestation | loyauté +10, suspicion -5, influence +5 ; ORLIK sera entendu | +6 / +3 / +1 ; Mazur reproche une arrestation sans faits |
| Classement | -8 / +15 / -3 ; convocation, note au dossier | -4 / +8 / -2 ; reproche de négligence |
| Enquête complémentaire | +3 / 0 / +3 ; audition d'ORLIK demandée, dossier ouvert | 0 / +4 / -2 ; accordée « cette fois » |

Intention : aucune option n'est gratuite. Arrêter est le plus rentable pour la
carrière mais brise une famille ; enquêter est prudent et ouvre la piste ORLIK ;
classer protège SEDLAR au prix de la confiance de la hiérarchie.

## Journées et conséquences différées (0.3)

Le joueur termine sa journée (« FIN DE SERVICE »). Le lendemain apporte :
- **Arrestation** : requête de Vera SEDLAR, l'épouse, classée sans suite par
  l'administration. Le coût humain devient visible.
- **Classement malgré la contradiction** : note versée au dossier personnel.
- **Classement sans instruction** : dossier réattribué à l'inspecteur KREMER.
- **Enquête complémentaire fondée** : ORLIK avoue avoir couvert SEDLAR, et parle
  d'une mère malade. Drapeau `40921.orlik_confessed` pour la suite.
- **Aucune décision** : rappel de MAZUR, suspicion +3.
- Bulletin du jour : contrôle renforcé sur la ligne de Halvek (conséquence
  systémique) et taux de concordance VERITAS de 91 % (pression implicite).

## VERITAS (0.3)

VERITAS commente chaque pièce et recommande l'arrestation à 87 %. Son raisonnement
est plausible mais aveugle aux motifs humains, et il surestime l'interception.
Son objectif caché : maximiser le taux de concordance publié. Le jeu mémorise si
le joueur a suivi VERITAS (`veritas_agreed`), pour de futures réactions.

## Dossier n° 51307 : ORLIK, Bohdan (0.4)

Attribué le mardi 4 novembre. Chef d'équipe, membre du Parti, frère d'un capitaine
de la Milice. Le même jour, le capitaine écrit : « La Milice sait se souvenir de
ceux qui font preuve de discernement. »

- Pièces de base : fiche d'identité, registre des certificats (4 en octobre,
  0 en septembre), relevé d'entretien de l'horloge (aucune panne), lettre anonyme (D).
- Contradiction toujours disponible : « panne de l'horloge » contre relevé technique.
- Selon le dossier 40921 :
  - enquête complémentaire fondée > audition d'ORLIK (« je n'ai jamais rien vendu »),
    qui contredit la lettre anonyme ;
  - arrestation de SEDLAR > son interrogatoire (14 heures, fiabilité C), qui confirme
    la lettre ;
  - classement sans instruction > note de KREMER : ORLIK est un informateur de la
    Milice (« CHAUDRON »).
- Décisions : arrestation (Milice hostile), sanction administrative (équilibre),
  classement (influence +, faveur due à la Milice : voie de la corruption).
- VERITAS recommande le classement à 71 % : il protège les réseaux d'informateurs.
- Vérité : ORLIK vend des certificats contre du café et de l'alcool ; pour SEDLAR
  seulement, c'était un échange de services.

## Dossier n° 52044 : KOVAC, Zora (0.6)

Attribué le mercredi 5 novembre. La Boulangerie d'État n° 12 encaisse 1 412 carnets
pour 1 080 attendus. Trois contradictions : l'écart entre recensement et carnets
délivrés, et deux carnets délivrés en octobre à des personnes mortes en août et
septembre. Mettre en cause le Bureau du ravitaillement n'aboutit que si l'agent a
établi la mort d'un titulaire (condition `contradiction:<clé>`) ; l'écart seul ne
fait que muter le préposé DRAZEK. VERITAS (83) accuse la gérante : il donne une
conformité maximale aux registres des services de l'État. Pièces selon le 51307 :
déposition de PETRAS (« carnets du cimetière ») ou note de la Milice.

## Dossier n° 52310 : VARGA, Teodor (0.6)

Attribué le jeudi 6 novembre par la Section 7. Le poème « Novembre » de l'édition
revue de 1986 forme l'acrostiche HALVEK ; l'édition de 1979 forme HALINA (la femme
morte du poète). La fiche d'identité, refaite par la Section 7, ne porte pas la
cicatrice de la fiche de lecteur de 1979. Vérité : le vrai VARGA est mort en
détention en 1983 ; l'homme de la photo est Karel BENES, l'occupant actuel de
l'appartement. VERITAS (91) ignore les documents « hors période ». Dans tous les
cas, KREMER, relégué aux archives, écrit à Vosk : c'est la fin de l'acte 1.

## Temps de service et soirées (0.6)

Une journée de service compte 8 heures (plus 2 heures supplémentaires). Lire
est gratuit ; demander une pièce, consulter MAZUR et signer coûtent 1 h. Une
pièce demandée arrive le lendemain.

Après la fin de service vient la **soirée**, dans l'appartement du bloc 7 : une
seule action parmi 2 ou 3 (`data/evenings.json`). Une journée finie en heures
supplémentaires fait perdre la soirée. Fils de l'acte 1 :
- **Lena** demande une autorisation de stage, bloquée par le dossier du père.
  Le joueur peut répondre, appeler le ministère de la Santé avec son matricule
  (elle obtient le stage, mais la recommandation est notée au dossier et devient
  un levier de la hiérarchie) ou refuser par principe.
- **La radio d'Aldria** annonce l'accord d'électricité, parle de Halvek, lit un
  poème de VARGA, puis annonce la commission du 8 décembre. Deux écoutes sans
  avoir ménagé M. ADLER : signalement, suspicion +3, note de MAZUR.
- **M. ADLER**, gardien et informateur ordinaire : le ménager protège, mais il
  montre qu'il pourrait aussi dénoncer ses voisins.
- **Visites** selon les décisions : Vera SEDLAR après l'arrestation de son
  mari, Irena BENES après celle de « VARGA ».

## Le terrain (0.6)

Depuis le dossier, à partir du deuxième jour, l'inspecteur peut sortir du
bureau une fois par dossier (2 h) : **audition** ou **perquisition**, en scènes
dessinées à la première personne, avec un nombre de tours limité. L'audition
d'ORLIK (51307) se joue en questions et en éléments du carnet posés sur la
table : le bon élément fait changer sa version. La perquisition chez SEDLAR
(40921) se joue en endroits cliquables : fouiller les affaires de Vera ou de
l'enfant humilie la famille. Ce qui est obtenu devient un procès-verbal au
dossier. Le poêle de SEDLAR cache le premier vrai indice de L'HEURE JUSTE.
La visite de la boulangerie n° 12 (52044) et la perquisition chez Karel BENES
(52310) donnent d'autres chemins vers les mêmes vérités (un ticket de mort
encaissé, un bail au nom d'un autre homme) mais préviennent ceux qu'on
soupçonne : DRAZEK écrit, la Section 7 pose les scellés.
Détails : `docs/design/TERRAIN.md`.

## Carrière

Inspecteur de 3e classe > 2e classe > Inspecteur principal > Chef de section
adjoint > Directeur adjoint par intérim (puis ministre et haut dirigeant, hors
campagne). Le dernier soir d'un acte, un écran archive le sort de chaque sujet
et la commission d'avancement statue (`data/rules/promotion.json`) : tous les
dossiers conclus, au moins 2 conclusions appuyées par une contradiction,
loyauté conforme, pas de surveillance renforcée. Une faveur de la Milice peut
remplacer la qualité des conclusions (et MAZUR le dit). Le joueur peut décliner :
le refus est mémorisé (`career.refused_promotion`).

## Journal des décisions de design

- 2026-10-24 : indicateurs cachés, mais évaluation en mots dans le Dossier
  personnel (choix de fen).
- 2026-10-24 : les conséquences récompensent l'instruction (contradiction établie)
  plus que la décision elle-même ; le joueur confronte des éléments par paires.
- 2026-10-24 : conception V2 validée par fen (`docs/design/`).
- 2026-10-25 : soirées, une action par soir, perdue en heures supplémentaires.
- 2026-10-25 : terrain en scènes 2D fixes et cliquables (pas de 3D), validé par fen.
- 2026-10-24 : contenu des enquêtes en JSON ; contradictions détectées par
  comparaison de « faits » déclarés dans chaque pièce ; indicateurs masqués.
