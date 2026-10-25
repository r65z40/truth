# Localisation

Le **français est la langue source**. Les clés de traduction sont les textes
français eux-mêmes ; une chaîne sans traduction s'affiche en français. On peut
donc traduire progressivement, sans jamais casser l'affichage.

## Interface

`data/locale/<langue>.json` : un objet `{ "texte français": "translated text" }`.
Les textes des scènes (Label, Button…) sont traduits automatiquement par Godot.
Les chaînes construites en code passent par `tr("…")`.

Exemple (`en.json`) :

```json
{ "NOUVELLE PARTIE": "NEW GAME" }
```

## Contenu des dossiers

`data/locale/<langue>/case_<id>.json` : une surcouche qui reprend la structure du
dossier français (`data/cases/case_<id>.json`) mais ne contient que les champs de
texte à traduire. `Localization.localize_case()` la fusionne sur le dossier
français. Les tableaux (`documents`, `facts`, `decisions`) sont appariés par `id`.
Un champ absent reste en français.

Exemple partiel (`en/case_40921.json`) :

```json
{
  "id": "40921",
  "title": "Citizen no. 40921",
  "documents": [
    { "id": "identity", "title": "Civil identity record" }
  ]
}
```

Aucune surcouche de dossier n'est encore livrée : en anglais, l'interface est
traduite et le contenu des dossiers reste en français (repli). La traduction des
dossiers de l'acte 1 est l'étape suivante.
