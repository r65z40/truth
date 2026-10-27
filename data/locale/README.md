# Localisation

Le **français est la langue source**. Les clés de traduction sont les textes
français eux-mêmes ; une chaîne sans traduction s'affiche en français. On peut
donc traduire progressivement, sans jamais casser l'affichage.

Langues livrées : français (source) et anglais (`en`), interface et contenu complets.

## Interface

`data/locale/<langue>.json` : un objet `{ "texte français": "translated text" }`.
Les textes des scènes (Label, Button…) sont traduits automatiquement par Godot.
Les chaînes construites en code passent par `tr("…")` ; dans une fonction
statique (règles, mises en forme), par `UiText.of("…")`.

Pour un texte qui contient un nombre, on traduit le **format** avant de le
remplir : `tr("%d h restantes") % heures`. Clé et traduction gardent les mêmes
`%d` / `%s`, dans le même ordre.

```json
{ "NOUVELLE PARTIE": "NEW GAME", "%d h restantes": "%d h left" }
```

## Contenu (dossiers, courrier, soirées, journal, terrain, fins…)

`data/locale/<langue>/**/*.json` : des tables `{ "texte français": "translated text" }`,
une par fichier de données (`cases/case_40921.json`, `evenings.json`, `news.json`…).
Toutes les tables d'une langue sont fusionnées ; les clés qui commencent par `_`
sont des notes. `DataLoader.load_json()` remplace chaque texte connu au moment
où les données sont lues, à n'importe quelle profondeur. Les clés des objets
(identifiants, drapeaux, conditions) ne sont jamais traduites ; un texte absent
de la table reste en français.

Un texte qui apparaît plusieurs fois (même phrase dans deux dossiers) n'a besoin
que d'une seule traduction. Un texte identique dans les deux langues (nom propre,
« District 7 ») n'a pas besoin d'entrée.

Règle à respecter : la `quote` d'un élément de dossier doit rester un **extrait
exact** du texte traduit de sa pièce (sinon le passage ne peut plus être
souligné). Le test `test_english_version` le vérifie pour tous les dossiers.

Les messages déjà reçus (sauvegardés en français) sont traduits à l'affichage
par `Localization.text()`.

## Modifier un texte français

Si on change une phrase française dans `data/`, son ancienne traduction ne
s'applique plus (la clé a changé) : le texte s'affiche en français en anglais
tant qu'on n'a pas mis à jour la clé dans la table anglaise correspondante.

## Conventions de l'anglais

Anglais britannique. Lieux : Power Station No. 3, Militia, Tanners' Quay, Mill
Street, Weavers' Street, Saint Agatha, Halvek-South. Opérations : THE TRUE HOUR
(L'HEURE JUSTE), MIRROR (MIROIR), "CAULDRON" (CHAUDRON). Vocabulaire : pièce =
document, dossier = file, carnet = notebook, perquisition = home search, audition
= interrogation, classer = dismiss, raccordement = linkage. Grades : Inspector,
3rd class ; Deputy Director ; Internal Review. Heures au format 06h05,
guillemets droits "…".
