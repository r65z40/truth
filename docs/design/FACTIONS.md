# Système de factions (proposition)

Quatre factions du canon, aucune entièrement bonne ou mauvaise. Chacune agit selon
ses intérêts, ce qu'elle sait et ce qu'elle peut. L'état d'une faction envers
Vosk tient en un mot (**hostile, méfiante, neutre, favorable, alliée**), plus
ses faveurs. On propose de remplacer les drapeaux épars (`milice.ally`,
`milice.enemy`) par cet état, en gardant les drapeaux pour l'historique.

## Le ministère de la Sécurité nationale

Pas un bloc : trois services aux intérêts différents.

| | Section 4 (MAZUR) | Section 7, censure (HALM, DUBEK) | Direction du personnel (BRANDT) |
| --- | --- | --- | --- |
| Objectif | Des dossiers bouclés sans scandale ; Mazur protège en secret | Une vérité officielle sans faille, des procès exemplaires | Des agents fiables ; trouver les traîtres |
| Ressources | Attribution des dossiers, rapports à l'étage | VERITAS, archives, presse | Dossiers personnels, contrôles, suspensions |
| Actions envers Vosk | Couvrir une erreur, retirer un dossier | Promouvoir, imposer une conclusion | Avertir, surveiller, suspendre (fin 54100) |

- Alliance : grades, archives, protection officielle. Prix : signer ce qu'on vous
  dicte, sacrifier des innocents.
- Opposition : suspicion, mutation, arrestation.
- Rôle dans les fins : Le Miroir parfait, Le Dossier 54100, Le Silence.

## La Milice du District 9 (capitaine L. ORLIK)

- Objectif : garder son réseau d'informateurs et son trafic (certificats, carnets
  du cimetière, réquisitions de la centrale) ; après l'explosion, détourner
  l'enquête de ses détournements.
- Ressources : hommes, interpellations, informateurs de quartier, marché noir.
- Relations : utile au ministère qui ferme les yeux ; ennemie de L'HEURE JUSTE,
  qui lui fait concurrence sur la frontière.
- Actions : pression par lettre, faveurs, témoin qui disparaît, perquisition chez
  Vosk ou chez Lena.
- Alliance : protection rapide et efficace, mais la dette s'alourdit ; en acte 3,
  elle demande un saboteur. Opposition : menaces, voisin informateur, Lena
  inquiétée.
- Rôle dans les fins : L'Allié de la Milice ; facteur aggravant du Dossier 54100.

## L'HEURE JUSTE (réseau clandestin)

- Objectif : faire passer des gens et des papiers vers Aldria, sauver qui peut ;
  pas une révolution, une évasion.
- Ressources : horlogers (horloges de pointage déréglées), cheminots (train de
  06h05), employés qui volent des formulaires. Mazur en fait partie.
- Relations : traque par la Milice ; le ministère ignore son ampleur.
- Actions : faux alibis, messages dans les dossiers, demande de cacher un horaire.
- Défauts : elle ment aussi, et elle a sacrifié des gens (le père de Vosk ?
  à trancher, audit 3.6). Elle peut utiliser Vosk sans le lui dire.
- Rôle dans les fins : L'Heure juste ; aide possible à La Fuite des originaux.

## Les familles et les citoyens

- Objectif : survivre, retrouver un proche.
- Ressources : témoignages, petites aides (la miche de KOVAC), pétitions.
- Actions : lettres, visites le soir, refuge pour Lena.
- Ni bonnes ni naïves : certaines dénoncent (l'informateur du 53517), d'autres
  mentent pour protéger.
- Rôle dans les fins : la condition « 3 innocents épargnés » de La Correction ;
  l'archive finale.

## Acteur extérieur (proposé, pas une faction jouable)

La République d'Aldria, sa radio et sa commission d'inspection du 8 décembre
pèsent sur le pays (crédit énergétique, frontière, rations) et donnent son motif
à MIROIR. Elle ne se gère pas : elle produit des bulletins, des pièces et des
contraintes.

## Influence sur les enquêtes

| État d'une faction | Effet sur les dossiers |
| --- | --- |
| Alliée | Pièce bonus (note de la faction), témoin coopératif, faveur disponible |
| Favorable | Ton plus doux, informations partielles |
| Neutre | Aucun effet |
| Méfiante | Pièce manquante (« non transmise »), rappel menaçant |
| Hostile | Témoin retiré, contre-rapport versé au dossier, action contre Vosk ou Lena |

Version minimale : états Milice et ministère, lus par les conditions des pièces
et des événements (une extension de `EventRules`). Coût : faible à moyen.
