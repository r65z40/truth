# Le terrain : interrogatoires, perquisitions, lieux (validé par fen le 2026-10-25)

fen : « Il faudrait rajouter des phases de dialogues, interrogatoires, lui dans
sa vie de tous les jours, avec des environnements à la première personne, et
une partie d'enquête : se rendre au domicile, faire une fouille. »
Validé : des **scènes fixes, dessinées, cliquables**, vues à la première
personne. Pas de 3D. Tout est écrit d'avance et décidé par le moteur.

Ce document complète le canon (`SCENARIO_V1.md` + `GAME_DESIGN_V2.md`) sans en
changer les vérités : le terrain donne d'autres chemins vers les mêmes faits,
et des indices pour les actes suivants.

## 1. Les règles communes

- Une scène de terrain coûte **2 heures** de service et se fait **une fois par
  dossier**. Elle s'ouvre depuis le dossier (bouton INTERROGER ou PERQUISITION),
  à partir du deuxième jour.
- Dans la scène, le joueur dispose d'un nombre limité de **tours** (5 questions,
  ou 4 endroits fouillés) : il faut choisir. On peut partir avant la fin.
- Ce qu'on obtient devient un **procès-verbal** dans le dossier, dont les
  éléments s'ajoutent au carnet : ils servent aux confrontations comme les autres.
- **Présenter un élément** (interrogatoire) : on pose sur la table un élément du
  carnet. S'il touche juste, le sujet change de version ; sinon il nie, et le
  tour est perdu.
- Les conséquences suivent les cinq catégories du design V2 : un indice, un
  drapeau lu plus tard, la Milice qui apprend la convocation, une famille qui
  voit sa maison retournée, ADLER ou les voisins qui en parlent.

## 2. Acte 1, scène par scène

### 40921 SEDLAR : perquisition rue de l'Unité (bloc 14, app. 61)

Possible si le dossier est ouvert, ou après l'arrestation (perquisition
d'usage). Vera SEDLAR est là, l'enfant aussi. Six endroits, quatre fouilles :

| Endroit | Ce qu'on trouve | Usage |
| --- | --- | --- |
| Tiroir de la commode | Ordonnance du docteur de Halvek-Sud pour Irena SEDLAR | Confirme le motif (la mère malade), comme la pièce médicale demandée |
| Sous le matelas | Formulaire de demande de soins, signature du médecin imitée au crayon | Le vrai délit : des papiers falsifiés (vérité du dossier) |
| Le poêle | Papier à moitié brûlé : une horloge sans aiguilles, « 06h05 » | **Indice L'HEURE JUSTE** (le même dessin que dans l'escalier de Vosk, soirée 1). Lu en acte 2 |
| La photo de famille | Au dos : « ORLIK, samedi, la chaudière » | Relie au 51307 : ORLIK couvre contre des réparations chez lui |
| Le cartable de Vera | Cahiers d'élèves corrigés. Rien | Vera vous regarde faire ; la famille s'en souviendra |
| Le lit de l'enfant | Un dessin : « papa dans le train » | Rien de prouvé, tout de compris |

Conséquences : `40921.home_searched` (zèle noté, loyauté +1) ; fouiller les
affaires de Vera ou de l'enfant pose `40921.family_humiliated` (lu par la lettre
de Vera et, plus tard, par la fin « Les familles »).

### 51307 ORLIK : audition, salle n° 3, sous-sol du ministère

Possible tant que le dossier est ouvert. Cinq tours.

Questions : les certificats d'octobre ; ses rapports avec SEDLAR ; son frère ;
PETRAS (si l'on a noté un élément sur PETRAS). Ses premières réponses tiennent
la version officielle (« l'horloge tombe en panne »), ce qui donne un élément
contredit par le relevé d'entretien.

Éléments à présenter :

| Élément présenté | Réaction | Gain |
| --- | --- | --- |
| Relevé d'entretien : horloge en marche | Il cède : « un paquet de café, de temps en temps » | Aveu : `orlik.motive = Contre des denrées` ; `51307.orlik_admitted` |
| Certificats ou pointage de PETRAS | « PETRAS paie en bouteilles. Ça vous va ? » | Élément sur PETRAS |
| Nom de code CHAUDRON (note de KREMER) | Il blêmit et exige son frère : l'audition s'arrête | `51307.chaudron_confronted`, suspicion +2 |
| Autre chose | « Je ne vois pas le rapport, inspecteur. » | Tour perdu |

Conséquence : convoquer ORLIK, c'est prévenir la Milice (`milice.orlik_questioned`) :
le capitaine Lev ORLIK appelle le lendemain.

### 52044 KOVAC et 52310 VARGA : prévus, à écrire après l'avis de fen

- 52044 : visite de la boulangerie n° 14 (le registre caché sous le comptoir,
  la file d'attente qui regarde) ou audition de l'agent DRAZEK.
- 52310 : perquisition au quai des Tanneurs, app. 40, chez Karel BENES : rien
  de VARGA n'y est resté, sauf une étagère vide et des épreuves corrigées de la
  main de BENES (l'écriture du correcteur, pas celle du poète).

## 3. La vie de tous les jours : les lieux

Les soirées (`data/evenings.json`) restent une action par soir. Elles gagnent
un décor dessiné : la cuisine du bloc 7, l'escalier et la loge d'ADLER, la
cabine du hall, plus tard l'hôpital n° 2 de Lena (acte 3). Même moteur que le
terrain, sans coût en heures.

## 4. Le fil des indices (L'HEURE JUSTE)

1. Soirée 1 : une horloge sans aiguilles gravée dans l'escalier de Vosk.
2. 40921, perquisition : le même dessin, avec « 06h05 », dans le poêle de SEDLAR.
3. Acte 2 (53402, LE CHEMINOT) : le train de 06h05 accumule les retards.
4. Acte 3 : le joueur qui a relevé les trois signes peut reconnaître un contact.

Chaque indice pose un drapeau (`heure_juste.sign_*`) ; aucun n'est obligatoire.
