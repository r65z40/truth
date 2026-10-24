# Matrice des décisions et conséquences

Catégories : **N** narrative · **M** mécanique · **I** institutionnelle ·
**T** temporelle · **H** humaine. « Codé » = présent dans les données ;
« proposé » = à écrire, après validation.

## Acte 1 (codé, sauf mention)

| Dossier | Décision | N | M | I | T | H |
| --- | --- | --- | --- | --- | --- | --- |
| 40921 SEDLAR | Arrestation | Mazur approuve | Interrogatoire de SEDLAR visible au 51307 et au 52310 | Loyauté ++ | Requête de Vera SEDLAR le lendemain | SEDLAR détenu ; sa fille hostile en acte 3 (proposé) |
| | Enquête complémentaire | Méthode « remarquée à l'étage » | Audition d'ORLIK au 51307 | Influence + | Aveu d'ORLIK le lendemain | SEDLAR reste libre |
| | Classement | Reproche ou réattribution | Note de KREMER au 51307 (si sans instruction) | Suspicion ++, note au dossier | Réattribution à KREMER | SEDLAR libre, KREMER entre en scène |
| 51307 ORLIK | Arrestation | Le capitaine ORLIK appelle trois fois | PETRAS témoigne au 52044 (branche de travail) | Milice hostile | Message hostile de la Milice | B. ORLIK détenu, son atelier sans chef |
| | Sanction administrative | « Un équilibre » | Aucune pièce supplémentaire | Neutre | Suite au lendemain | B. ORLIK rétrogradé |
| | Classement | Le capitaine « de bonne humeur » | Note de la Milice au 52044 (branche de travail) | Faveur due, suspicion + | Milice alliée | Les certificats continuent |
| 52044 RATIONS (branche de travail) | Arrêter la gérante | Remerciements du Bureau | — | Loyauté + | Pétition des habitants | Z. KOVAC détenue, boutique fermée |
| | Mettre en cause le Bureau (preuve : un mort) | DRAZEK suspendu | `player.noticed_by_halm` : HALM connaît Vosk (proposé : lu en acte 2) | Influence ++, suspicion + | Lettre froide de la Direction, miche offerte par KOVAC | KOVAC rouvre |
| | Mettre en cause le Bureau (écart seul) | DRAZEK muté | — | Influence + | — | DRAZEK sévit ailleurs |
| | Classer en sachant | Ironie de Mazur | Carnet d'un mort reçu : `player.bribed` | Suspicion ++ | Pli anonyme | Le trafic continue |
| 52310 LE POÈTE (brouillon) | Arrestation | « Réseau des poètes » | Procès public en acte 2 (proposé) | Loyauté ++ | Lettre de l'épouse de BENES (proposé) | K. BENES arrêté à la place d'un mort |
| | Absence de code (preuve : HALINA) | DUBEK demande votre nom | Section 7 hostile | Suspicion ++, influence ++ | Note de KREMER renforcée (proposé) | VARGA « suspendu » |
| | Erreur d'identité (preuve : cicatrice) | Dossier retiré en 48 minutes | `kremer.contact` : accès aux originaux plus tôt | Suspicion +++ | Note de KREMER directe | BENES épargné |

## Actes 2 à 4 (proposé, décisions pivots)

| Dossier | Décision | N | M | I | T | H |
| --- | --- | --- | --- | --- | --- | --- |
| 53118 LA CHORALE | Livrer les 11 noms / livrer l'informateur / classer | Le boulanger du 52044 est choriste | Un informateur gagné ou perdu | Loyauté ou suspicion | Procès collectif en acte 3 | 11 familles |
| 53402 LE CHEMINOT | Dénoncer les passages / les cacher / les retarder | L'HEURE JUSTE se révèle | Contact du réseau (nécessaire à « L'Heure juste ») | Suspicion | Le train de 06h05 en acte 4 | Les passeurs |
| 53517 L'INFORMATEUR | Croire l'informateur / le dégrader | VERITAS a raison sur un point | Fiabilité d'une source changée | Concordance VERITAS | Le voisin dénoncé réapparaît | Un appartement, une famille |
| 53760 L'ARCHIVE | Protéger KREMER / le livrer / copier les originaux puis le livrer | KREMER allié ou perdu | Originaux accessibles ou non | Suspicion ++ si protégé | KREMER dans MIROIR | KREMER |
| 54001 L'EXPLOSION | Sabotage (désigner un suspect) / accident (accuser les détournements) | Le capitaine ORLIK menacé | Faveur de la Milice utilisée ou perdue | Grade (promotion ou suspension) | Statut pour MIROIR | M. SEDLAR et deux autres |
| 54030 L'HORLOGER | Le libérer / le garder | Le nom du père | Dossier du père ouvert en acte 4 | Suspicion | La fin « La Correction » | Le vieil horloger |
| 60001 à 60003 MIROIR | Corriger / caviarder / garder la vérité | Archive finale | Fins | Loyauté | Fin calculée | Tous les sujets |

## Règles de cohérence

- Chaque décision pivot ouvre ou ferme au moins une **ressource de fin**
  (originaux, contact du réseau, faveur, confiance du ministère).
- Une ressource perdue l'est de façon visible (message, pièce absente avec une
  mention « retirée du dossier »), jamais en silence.
- Aucune décision n'a une issue strictement meilleure sur les cinq colonnes.
