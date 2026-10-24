# Spécification de VERITAS (proposition)

VERITAS est un système d'analyse institutionnel. Il n'est pas méchant : il
applique des pondérations qui servent le régime. Il a souvent raison sur les
faits et tort sur ce qu'il en conclut.

## 1. Ce qui change par rapport au code actuel

Aujourd'hui (`scripts/core/veritas.gd`), les remarques et les pourcentages sont
écrits à la main dans chaque dossier. Proposition : garder les remarques écrites,
mais **calculer** le chiffre à partir de facteurs déclarés dans les données. Le
chiffre affiché s'appelle désormais **« indice de conformité »** : c'est un score
institutionnel, pas une probabilité, et le jeu le dit.

## 2. Le modèle

Pour chaque décision possible d'un dossier, VERITAS additionne des facteurs :

```
indice(décision) = base + somme(poids du facteur × multiplicateur de sa catégorie)
                   borné entre 1 et 99
```

- Chaque facteur est écrit dans le dossier : identifiant, libellé, catégorie,
  poids, et la pièce dont il vient.
- Les **multiplicateurs de catégorie** sont les paramètres cachés de VERITAS :

| Catégorie | Multiplicateur | Ce qu'il révèle |
| --- | --- | --- |
| Source d'un service de l'État | × 3 | « conformité de la source : x3 » (canon, acte 2) |
| Zone frontalière, famille à l'étranger | × 2 | Le régime craint la frontière |
| Appartenance au Parti | × 2 (en faveur du sujet) | Protection des cadres |
| Source anonyme | × 0,5 | Sauf si elle accuse un non-membre |
| Fait établi par l'inspecteur (contradiction) | × 1 | VERITAS lit bien les faits |
| Directive confidentielle de la hiérarchie | ajout fixe | Acte 3 : conclusions écrites d'avance |

Exemple (51307) : base 40 ; « membre du Parti depuis 1961 » +8 × 2 ;
« dénonciation anonyme » −6 × 0,5 ; « réseau d'informateurs utile » +9 × 2 ;
total 71 pour le classement, le chiffre actuel. Les valeurs déjà publiées
(87, 71, 83, 91) peuvent être retrouvées exactement.

## 3. Expliquer une recommandation

La commande `VERITAS POURQUOI` (et un bouton dans la conclusion) affiche les trois
facteurs qui pèsent le plus, avec la pièce d'origine. En acte 1, seuls les poids
sont visibles ; les multiplicateurs n'apparaissent qu'avec `VERITAS PARAMETRES`
(acte 2). Le joueur découvre le biais en voyant qu'un même fait pèse trois fois
plus quand il vient d'un service de l'État.

## 4. VERITAS doit parfois avoir raison

| Dossier | VERITAS | Qui a raison |
| --- | --- | --- |
| 40921 | Arrestation 87 % | Les faits oui (SEDLAR était dans le train), la conclusion se discute |
| 52044 | Arrêter la gérante 83 % | Faux : il ne croise pas les registres entre services ; mais juste sur l'authenticité des tickets |
| 52310 | Arrestation 91 % | Faux : il n'a lu que l'édition de 1986 |
| 53517 (proposé) | Croire l'informateur | **Juste** : le voisin cache bien quelque chose, même si l'informateur ment sur le reste |
| 54012 (proposé) | Écarter la déposition du témoin | **Juste** : la déposition a été dictée par la Milice |

Un joueur prudent a donc de bonnes raisons de le suivre de temps en temps.

## 5. Réactions aux décisions répétées

Le taux d'accord (`veritas_agreed`, déjà enregistré) produit des réactions :

| Taux d'accord | Réaction |
| --- | --- |
| 80 % et plus | « Concordance exemplaire » : bonus de réputation, mention au bulletin |
| 50 à 80 % | Rien |
| Moins de 50 % | VERITAS ajoute une remarque à chaque conclusion : « écart signalé » |
| Moins de 30 % (acte 2 et plus) | Signalement automatique à la Direction du personnel (BRANDT) : suspicion |

## 6. Évolution par acte (canon conservé)

1. Assistant fiable ; remarques utiles.
2. Biais détectable ; `VERITAS PARAMETRES`.
3. Instrument : des **directives confidentielles** apparaissent dans ses facteurs
   (« instruction HALM 11/86 : conclusion sabotage ») ; il cite des pièces que le
   joueur n'a pas encore.
4. Rédacteur de MIROIR ; s'il analyse les originaux de KREMER, ses propres
   multiplicateurs donnent « 0 % de sabotage » : la phrase devient une preuve.

## 7. Règles techniques

- La vérité d'un dossier reste dans le champ `truth`, jamais lu par VERITAS.
- VERITAS ne lit que les pièces visibles par le joueur, plus ses directives.
- Tout est déterministe et testable : mêmes pièces, même indice.
- Une IA conversationnelle future ne pourrait que **reformuler** les facteurs et
  remarques existants, côté serveur, sans clé dans le client.

Coût : faible (un calcul pur dans `veritas.gd`, des facteurs dans les données).
Risque : rendre le biais lisible trop tôt ; d'où les multiplicateurs cachés
jusqu'à l'acte 2. Version minimale : facteurs + `VERITAS POURQUOI`.
