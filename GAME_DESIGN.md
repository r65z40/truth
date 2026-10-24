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

## Carrière

Inspecteur > Analyste du renseignement > Chef de section > Directeur du
renseignement > Ministre de la Sécurité > Haut dirigeant. Progression non
automatique (réputation, relations, résultats, choix, événements).

## Journal des décisions de design

- 2026-10-24 : les conséquences récompensent l'instruction (contradiction établie)
  plus que la décision elle-même ; le joueur confronte des éléments par paires.
- 2026-10-24 : contenu des enquêtes en JSON ; contradictions détectées par
  comparaison de « faits » déclarés dans chaque pièce ; indicateurs masqués.
