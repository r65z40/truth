# MINISTRY OF TRUTH : game design V2

Statut : **validé par fen le 2026-10-24** (les dix changements et la gestion du
temps). Le canon est désormais `SCENARIO_V1.md` complété par les changements
marqués **[CHANGEMENT]**, listés à la fin. Références : `REFERENCES.md`.

> « Dans un État où chaque citoyen possède un dossier, tu commences par
> inspecter la vérité. Tu finis par décider de ce qu'elle doit être. »

## 1. Ce qu'on garde, ce qu'on ajoute

On garde les quatre actes, les sept fins, les personnages, VERITAS et le cœur du
jeu : lire des pièces, relever des contradictions, signer. On ajoute une seconde
boucle (le pouvoir), une gestion du temps dans la journée, une vie hors du bureau
et un monde extérieur. Tout ajout doit servir l'enquête sur documents : si une
mécanique ne produit pas de pièces à lire ou de décisions à signer, elle sort.

Garde-fous de périmètre : une partie de 4 heures, 20 journées d'environ
12 minutes, 15 dossiers écrits plus quelques dossiers courts de routine. Pas de
carte, pas de gestion de budget, pas de génération procédurale des révélations.

## 2. Les deux boucles

**Boucle A, enquête (chaque journée)** : recevoir un dossier, examiner les pièces,
établir des contradictions, conclure, observer les conséquences le lendemain.

**Boucle B, influence (chaque acte)** : les résultats de la boucle A produisent de
la **réputation** et des **faveurs** ; la réputation ouvre des **grades** ; les
grades et les faveurs ouvrent des **actions concrètes** qui changent les enquêtes
suivantes (pièce supplémentaire, témoin protégé, procédure retardée).

Comment elles se nourrissent :

| De A vers B | De B vers A |
| --- | --- |
| Une contradiction établie rend une conclusion « solide » : réputation | Demander une archive ajoute une pièce au dossier |
| Une conclusion qui embarrasse un service crée un ennemi, ou une dette | Affecter un inspecteur traite un dossier de routine à votre place (temps gagné) |
| Suivre VERITAS augmente le taux de concordance, que la hiérarchie récompense | Une faveur de la Milice retire un témoin gênant, ou en fait apparaître un |
| Protéger un sujet crée une source future | Un grade plus haut donne accès aux instructions confidentielles de VERITAS |

Le pouvoir n'est jamais un chiffre à faire monter : c'est une liste d'actions
débloquées, chacune avec un coût en temps, en faveurs ou en suspicion. Détail
dans `CARRIERE.md`.

## 3. Gestion du temps (validée le 2026-10-24, à implémenter)

Fen a répondu oui à une limite de temps dans la journée ; la directive demande un
système d'unités et pas de compte à rebours permanent. Proposition : **l'horloge
du bureau avance avec les actions, pas avec le temps réel**.

### 3.1 Règles

- Une journée de service = **8 heures** (08h00 à 16h00), affichées sur l'horloge
  du bureau. Chaque action importante avance l'horloge.
- Lire les pièces d'un dossier, noter et confronter sont **gratuits** : on ne
  pénalise jamais la lecture attentive, qui est le cœur du jeu.
- Les actions qui **cherchent hors du dossier** coûtent du temps.
- À 16h00, plus d'action payante ; on peut encore lire et signer.
- **Heures supplémentaires** : jusqu'à 2 heures en plus, une fois par jour, au
  prix d'une soirée perdue (voir la vie hors du bureau) et d'une mention au
  registre de présence (légère suspicion si répété).
- Un dossier non conclu reste ouvert ; ses conséquences de retard sont écrites
  (rappel de Mazur, puis réattribution, puis note au dossier).

### 3.2 Coûts proposés

| Action | Coût | Disponible |
| --- | --- | --- |
| Lire, noter, confronter | 0 | Toujours |
| Rédiger et signer une conclusion | 1 h | Toujours |
| Demander une pièce complémentaire à un service | 1 h, pièce reçue le lendemain | Acte 1 |
| Consulter Mazur | 1 h | Acte 1 |
| Vérifier une archive (comparer avec l'original) | 2 h | Acte 2 |
| Interroger un suspect ou un témoin (3 questions) | 2 h | Acte 3 |
| Rencontrer un informateur | 2 h, le soir de préférence | Acte 3, selon le grade |
| Déléguer un dossier de routine à un inspecteur | 0 h, mais résultat moins fiable | Grade inspecteur principal |

### 3.3 Équilibrage par acte

| Acte | Heures disponibles | Coût pour « tout faire » | Ressenti visé |
| --- | --- | --- | --- |
| 1 | 8 h | 3 à 5 h | Calme : on apprend, on a le temps |
| 2 | 8 h | 9 à 11 h | Premiers arbitrages : une archive ou un rendez-vous |
| 3 | 8 h | 12 h et plus | Manque de temps permanent ; jour de l'explosion chronométré |
| 4 | 8 h | 6 à 8 h | Le temps n'est plus le problème : le choix l'est |

**Seule exception en temps réel** : le jour de l'explosion (acte 3), le bulletin du
soir doit annoncer un coupable ; une horloge visible avance réellement pendant
environ 10 minutes. C'est la seule scène sous pression réelle, annoncée au joueur.

**Gagner du temps** : déléguer (grade), une faveur (« le service d'archives vous
envoie la pièce sans formulaire »), une journée calme sans nouveau dossier.

Version minimale : l'horloge, 3 actions payantes, les heures supplémentaires.
Coût technique : faible (un compteur dans `GameState`, des coûts dans les
données). Risque : rendre la lecture frustrante ; d'où la gratuité de la lecture.

## 4. La vie hors du bureau [CHANGEMENT]

Fen veut une vie privée sur laquelle Vosk peut influer. Proposition : chaque soir,
un court **écran de soirée** dans l'appartement de Vosk (bloc 7, District 2),
avec **une** action au choix parmi 2 ou 3.

- **LENA VOSK**, sœur cadette, 24 ans, étudiante en médecine. Elle a besoin d'une
  autorisation de stage ; le ministère peut l'accorder ou la refuser. Levier de la
  hiérarchie, et premier lieu où la violence touche Vosk de près (acte 3 : Lena
  soigne des blessés de l'explosion et raconte ce que les bulletins taisent).
- **La radio** : la nuit, on capte la radio du pays voisin. Écouter donne des
  informations (et parfois la vérité) ; être dénoncé par un voisin coûte cher.
- **Le voisin**, M. ADLER, gardien d'immeuble et informateur ordinaire : il
  remarque les heures de retour de Vosk.
- **Les visites** : une famille de sujet sonne à la porte (Vera SEDLAR, Mme BENES).

Les soirées produisent des pièces (une lettre, une note de radio) et des drapeaux
lus par les dossiers. Une soirée perdue en heures supplémentaires est un vrai
coût. Version minimale : 1 action par soir, 3 types d'action.

## 5. Le monde extérieur [CHANGEMENT]

Fen veut des éléments extérieurs qui influent sur le pays. Proposition :

- **La République d'Aldria**, voisine, de l'autre côté de Halvek. Plus riche,
  ni paradis ni ennemie : elle vend du charbon et des pièces détachées à Velmira.
- **Radio Aldria, service en langue velmirienne** : écoutée en cachette. Ses
  émissions donnent parfois une version des faits qui contredit les bulletins.
- **Les négociations sur le crédit énergétique** : Velmira a besoin du crédit
  d'Aldria pour l'hiver. Une **commission d'inspection** doit visiter la centrale
  n° 3 le **8 décembre**. Après l'explosion, le régime doit présenter des archives
  cohérentes : **c'est le motif de MIROIR** (constat 3.3 de l'audit).
- **Effets sur les dossiers** : la frontière se ferme ou s'ouvre selon les
  négociations (contrôles sur la ligne de Halvek), les rations baissent si le
  crédit est retardé (lien avec le 52044), un journaliste d'Aldria peut recevoir
  les originaux (fin « La Fuite des originaux »).

Le monde extérieur reste en arrière-plan : bulletins, radio, quelques pièces. Il
ne devient jamais une carte ni une diplomatie jouable (c'est l'acte 5, voir
`ACTE5_FAISABILITE.md`).

## 6. Violence montrée, en crescendo [CHANGEMENT de ton validé par fen]

La violence passe par les documents, jamais par une mise en scène gratuite.

| Acte | Ce que les documents montrent |
| --- | --- |
| 1 | Des mots administratifs (« interpellé », « transféré »), une durée d'interrogatoire (14 heures), une lettre de famille |
| 2 | Des procès-verbaux d'interrogatoire avec des mentions médicales, un rapport de décès en détention |
| 3 | Le rapport médical des victimes de l'explosion, des photos de pièces, le récit de Lena, un passage à tabac raconté par un témoin |
| 4 | Un ordre d'exécution à contresigner dans MIROIR ; ce que le joueur efface |

Une option dans les paramètres atténue les descriptions (avertissement de contenu
au lancement). Coût faible : variantes de textes sur quelques pièces.

## 7. Conséquences en cinq catégories

Chaque décision majeure doit produire au moins trois des cinq catégories :
**narrative** (messages, relations), **mécanique** (accès, outils, actions),
**institutionnelle** (réputation, grade, surveillance), **temporelle**
(événement différé), **humaine** (destin d'une personne). La matrice complète est
dans `MATRICE_DECISIONS.md`. Exemple, protéger KREMER au 53760 : il reste en poste
(humaine), les originaux restent accessibles (mécanique), suspicion en hausse
(institutionnelle), il apparaît dans MIROIR comme allié (temporelle), la fin
« La Correction » reste possible (narrative).

## 8. Fins : priorités proposées

Évaluées dans cet ordre ; la première vraie l'emporte.

| Ordre | Fin | Conditions proposées |
| --- | --- | --- |
| 1 | Le Dossier 54100 | Suspicion au palier « enquête interne » à deux soirs d'affilée après les deux avertissements ; vérifié chaque soir à partir de l'acte 2 |
| 2 | La Correction (cachée) | Dossier du père réécrit avec la vérité + KREMER protégé + au moins 3 innocents épargnés |
| 3 | La Fuite des originaux | Originaux copiés + phrase « 0 % » de VERITAS + un contact extérieur (journaliste d'Aldria ou réseau) |
| 4 | L'Heure juste | Confiance du réseau + un contact vivant (Mazur ou son remplaçant) + suspicion sous « surveillance renforcée » |
| 5 | L'Allié de la Milice | Relation Milice « alliée » + au moins une faveur utilisée en acte 3 ou 4 |
| 6 | Le Miroir parfait | MIROIR signé sans réserve + loyauté « affirmée » ou plus |
| 7 | Le Silence (par défaut) | Toute autre combinaison : Vosk refuse ou bâcle MIROIR sans preuves |

## 9. Rejouabilité sans abîmer l'histoire

Le noyau (15 dossiers, révélations, fins) est écrit à la main. Ce qui varie :
témoins présents ou absents, pièces accessibles, ton des supérieurs, fiabilité des
informateurs, moyens d'enquête selon le grade, relations, sanctions. Ajout limité :
**2 ou 3 dossiers de routine par partie**, tirés dans une réserve d'environ 10
dossiers courts écrits à la main (aucune génération de texte). Ils ne touchent
jamais une révélation centrale. Une **archive finale** récapitule le destin de
chaque sujet et les choix qui l'ont décidé.

## 10. Localisation français et anglais

- Interface : chaînes passées par `tr()`, fichiers `.po` (outil standard de Godot).
- Dossiers et événements : le JSON français reste la source canonique. Les
  traductions vivent dans `data/locale/en/` sous forme de surcouches qui ne
  contiennent que les textes, repérés par les identifiants existants (dossier,
  pièce, élément). Une pièce sans traduction s'affiche en français.
- Énigmes linguistiques (acrostiche du 52310) : champ `loc_note` dans la pièce ;
  le traducteur réécrit l'énigme et les éléments notables correspondants.
- Dates, mois et jours : tables par langue, plus de chaînes dans le code.
Coût : moyen, surtout de la rigueur. À poser avant d'écrire les 11 dossiers
restants, pour ne pas tout reprendre.

## 11. Direction artistique

Bureaux brutalistes, terminal monochrome vert, imprimante matricielle pour les
réponses officielles, papier jauni, tampons, photos d'identité dessinées (déjà
codé), notes au crayon, archives trouées, propagande. Sons : ventilation,
imprimante, téléphone qui ne sonne pas, silence. À éviter : surnaturel,
jumpscares, clichés de pirates, hologrammes, action militaire, caricature.

## 12. Fiches d'amélioration

| Amélioration | Intérêt pour le joueur | Systèmes | Coût | Risques | Version minimale |
| --- | --- | --- | --- | --- | --- |
| Horloge de service | Arbitrer, sentir la pression montante | Compteur, coûts dans les données | Faible | Frustration si la lecture coûte | 3 actions payantes |
| Demander une pièce | Plusieurs façons de résoudre | Pièces « sur demande » livrées le lendemain | Faible | Doublon avec les pièces conditionnelles | 1 par dossier en acte 1 |
| Comparer avec l'archive | Découvrir la falsification soi-même | Pièce originale liée à une pièce officielle, diff ligne à ligne | Moyen | Lourd à écrire | 1 comparaison par dossier d'acte 2 |
| Chronologie | Déduction visuelle | Frise d'une journée, éléments à placer | Moyen | Interface tactile à soigner | 1 dossier (53402) |
| Interrogatoire | Choix et risque | 8 questions, 3 posées, réponses = pièces | Moyen | Volume de texte | 1 interrogatoire en acte 3 |
| Caviardage et réécriture | Le cœur de l'acte 4 | Lignes de document éditables parmi des variantes écrites | Élevé | Combinatoire des variantes | 3 documents, 2 ou 3 variantes par ligne |
| Grades et actions | Sentiment d'ascension | Grades, actions débloquées | Moyen | Dérive vers la gestion | 4 grades, 6 actions |
| Faveurs | Le pouvoir rendu concret | Jetons par faction | Faible | Monnaie trop abondante | Au plus 3 faveurs par partie |
| Soirées | Vie privée, enjeu humain | Écran de soirée, 1 action | Moyen | Diluer le rythme | 3 actions, 5 soirées écrites |
| Monde extérieur | Logique de MIROIR, radio | Bulletins, radio, drapeaux | Faible | Surcharge de lore | Radio + commission du 8 décembre |
| VERITAS explicable | Comprendre, contester | Modèle de score par facteurs | Faible | Rendre le biais trop visible trop tôt | Les 3 facteurs principaux affichés |
| Archive finale | Récompense, rejouer | Récapitulatif depuis les drapeaux | Faible | Aucun | 1 ligne par sujet |
| Sauvegarde par acte | Rejouer sans tout refaire | Points de reprise, format v4 | Faible | Migration | 1 point par acte |
| Localisation | Marché Steam | `tr()`, surcouches | Moyen | Énigmes intraduisibles | Interface + acte 1 |

## 13. Changements du canon (validés par fen le 2026-10-24)

1. 15 dossiers dont 14 enquêtes, au lieu de « 16 » (audit 2.1).
2. 20 journées de service avec ellipses, au lieu de 24 (audit 2.2).
3. KREMER : ancien inspecteur de la Section 2 relégué aux archives (audit 3.1).
4. Motivation unique du capitaine ORLIK : protéger son réseau d'argent et
   d'informateurs (audit 2.3).
5. Ordre des fins et « Le Silence » comme fin par défaut (section 8).
6. Trois variantes de MIROIR selon le statut (audit 2.5).
7. La sœur LENA et les soirées (section 4).
8. La République d'Aldria, sa radio et la commission du 8 décembre comme motif de
   MIROIR (section 5).
9. Violence montrée en crescendo, avec option d'atténuation (section 6).
10. Pourcentages de VERITAS remplacés par un « indice de conformité » calculé
    (`VERITAS.md`).
