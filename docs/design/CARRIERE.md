# Système de carrière (proposition)

Principe : la carrière ouvre des **actions**, jamais un simple chiffre. Les
promotions ne sont pas garanties ; on peut aussi refuser de monter.

## Grades jouables dans la campagne

`career.gd` nomme aujourd'hui 6 grades, de l'inspecteur au haut dirigeant. En
4 heures, on propose de jouer les 5 premiers échelons ci-dessous ; ministre et
haut dirigeant relèvent de l'acte 5 (extension).

| Grade | Moment possible | Actions débloquées |
| --- | --- | --- |
| Inspecteur de 3e classe | Départ | Lire, confronter, conclure, demander une pièce, consulter Mazur |
| Inspecteur de 2e classe | Fin d'acte 1 | Demander une archive confidentielle (1 par jour) |
| Inspecteur principal | Fin d'acte 2 | Déléguer un dossier de routine à un inspecteur ; obtenir une information d'un autre service |
| Chef de section adjoint | Milieu d'acte 3 | Retarder une procédure ; protéger ou dénoncer un agent ; gérer 2 informateurs |
| Directeur adjoint par intérim | Début d'acte 4 | Diriger MIROIR ; influencer une nomination ; fixer les priorités des enquêtes |

## Ce qui décide d'une promotion

Évaluée à la fin de chaque acte, par une règle déterministe et testable :

| Critère | Source dans le jeu |
| --- | --- |
| Performance | Part des conclusions appuyées par une contradiction établie |
| Loyauté | Indicateur `loyalty` (palier « conforme » minimum) |
| Suspicion | Doit rester sous « surveillance renforcée » |
| Relations | Recommandation de Mazur, attention du directeur HALM (`player.noticed_by_halm`) |
| Compromissions | Une faveur de la Milice peut acheter une promotion, et laisse une trace |
| Événements | La purge après l'explosion libère des postes |

## Trajectoires alternatives

- **L'inspecteur honnête** : refuse une promotion (choix proposé par message).
  Moins d'actions de pouvoir, mais moins surveillé, et KREMER lui fait davantage
  confiance.
- **L'ambitieux** : suit VERITAS, accepte les faveurs, monte vite ; chaque grade
  coûte un renoncement visible (un sujet sacrifié, Lena compromise).
- **Le muté** : sanctionné en acte 2 ou 3, il part aux archives. Il perd du
  pouvoir mais gagne l'accès aux originaux : une autre voie vers les mêmes vérités.
- **Le suspendu** : il vit l'acte 4 de l'extérieur.

## Faveurs : le pouvoir rendu concret

Les faveurs sont des jetons nominatifs, au plus 3 par partie et par faction, que
le joueur dépense pour une action précise.

| Faveur | Obtenue par | Permet |
| --- | --- | --- |
| Milice (capitaine ORLIK) | Classer le 51307, rendre service en acte 3 | Faire disparaître ou apparaître un témoin ; éviter une perquisition |
| Ministère (Mazur, puis HALM) | Conclusions solides, concordance VERITAS | Une archive sans formulaire ; une promotion accélérée |
| L'HEURE JUSTE | Protéger un passeur, cacher un horaire | Un faux alibi ; une place dans le train de 06h05 |
| Les familles | Épargner un innocent | Un témoignage ; un refuge pour Lena |

Version minimale : 4 grades, 6 actions, faveurs Milice et ministère seulement.
Coût : moyen. Risque principal : glisser vers un jeu de gestion ; d'où le plafond
de 3 faveurs et l'absence de budget.
