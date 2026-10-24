# MINISTRY OF TRUTH : scénario complet (V1, canon)

Copie de référence du document de scénario du 2026-10-24
([Claude Doc](https://claude.ai/artifact/KLQcMmT6CDQhUQVttANdhH)).
**Ce texte est le canon narratif.** Il n'est pas modifié ici : les changements
validés le 2026-10-24 sont dans `GAME_DESIGN_V2.md` (section 13) et priment sur
ce texte là où ils diffèrent.

## Intention

Le jeu raconte en 4 actes et environ 24 journées (3 novembre au 6 décembre 1986) comment un petit fonctionnaire découvre qu'il ne vérifie pas la vérité : il la fabrique. Chaque dossier reste une petite enquête autonome, mais tous tirent sur le même fil, et le joueur comprend trop tard qu'il en fait partie.

- **Thème** : la vérité administrative contre la vérité vécue. Un tampon vaut plus qu'un témoin.
- **Ton** : froid, bureaucratique, avec des éclats d'humanité dans les lettres, les notes manuscrites et les erreurs de frappe.
- **Ce que le joueur doit ressentir** : acte 1, la compétence (je trouve les contradictions) ; acte 2, le doute (mes conclusions servent à autre chose) ; acte 3, la peur (on m'observe) ; acte 4, la responsabilité (je dois choisir ce qui restera dans les archives).
- **Règle d'or** : aucun choix n'est "le bon". Dire la vérité peut tuer quelqu'un, mentir peut le sauver. Le moteur suit tout par drapeaux, et les dossiers suivants changent selon ce que le joueur a signé.

## Personnages et factions

| Personnage | Rôle visible | Secret | Révélé |
| --- | --- | --- | --- |
| A. VOSK (joueur) | Inspecteur de 3e classe, Section 4 | Son père, horloger, a disparu en 1971 après une inspection. Le ministère l'a recruté exprès. | Acte 3 |
| R. MAZUR | Supérieur direct, paternaliste, las | Membre du réseau L'HEURE JUSTE ; il protège des gens en orientant les dossiers vers Vosk | Acte 2 (indices), acte 3 |
| H. KREMER | Archiviste discret, laisse des notes | Garde les vrais originaux que le ministère a réécrits | Acte 2 |
| Capitaine L. ORLIK | Milice, menace ou alliée selon le 51307 | Trafique les réquisitions de la Centrale n° 3 | Acte 3 |
| I. BRANDT | Nouvelle inspectrice au poste voisin, sympathique | Contrôleuse interne chargée d'évaluer Vosk | Acte 3 |
| Directeur S. HALM | Voix lointaine du ministère, bulletins | Architecte de l'opération MIROIR | Acte 4 |
| A. SEDLAR et sa famille | Premier dossier | Sa fille M. SEDLAR revient en acte 3 comme suspecte ou témoin | Acte 3 |
| VERITAS | Module d'analyse, neutre en apparence | Voir son arc plus bas | Progressif |

**Factions** (suivies par drapeaux et par les indicateurs vagues déjà en place) :

- **Le ministère** : récompense l'efficacité et la conformité (loyauté).
- **La Milice** : veut des coupables, accorde des faveurs (drapeaux `milice.ally` / `milice.enemy`).
- **L'HEURE JUSTE** : réseau clandestin d'horlogers, de cheminots et d'employés. Ils fabriquent de faux alibis en déréglant les horloges de pointage. C'est l'explication cachée de la contradiction "horloge" du dossier 51307.
- **Les familles** : lettres, visites, suppliques. Elles ne donnent rien au joueur, sauf parfois la vérité.

## Structure en actes

Quatre actes, 16 dossiers principaux et quelques dossiers courts "de routine" pour respirer. Chaque acte se termine par un rebondissement qui change le sens des dossiers déjà traités.

### Acte 1 : Le zèle (jours 1 à 6)

Le joueur apprend le métier. Les dossiers sont simples, les contradictions honnêtes.

| Dossier | Sujet | Enjeu |
| --- | --- | --- |
| 40921 SEDLAR (fait) | Absence déguisée en présence | Première signature, première lettre de famille |
| 51307 ORLIK (fait) | Chef d'équipe qui couvre ses ouvriers | Première pression de la Milice |
| 52044 RATIONS | Carnets de rationnement doublés dans une boulangerie | Dossier court : le coupable est un employé du ministère |
| 52310 LE POÈTE (T. VARGA) | Recueil de poèmes saisi, faut-il y lire un code ? | Il n'y a aucun code. VERITAS en voit un (91 %). |

**Rebondissement de fin d'acte** : Kremer laisse une note dans le dossier 52310. La photo d'identité de Varga a été remplacée ; l'original, dans les archives, montre un autre homme. Le ministère a déjà condamné quelqu'un sous ce nom.

### Acte 2 : Les fissures (jours 7 à 13)

Les dossiers deviennent ambigus. Le joueur découvre les originaux de Kremer et une nouvelle action : **comparer une pièce avec l'archive**.

| Dossier | Sujet | Enjeu |
| --- | --- | --- |
| 53118 LA CHORALE | Une chorale paroissiale chante à l'heure du couvre-feu | Drame collectif : 11 noms, un seul informateur |
| 53402 LE CHEMINOT | Retards de trains répétés sur Velmira > Halvek | Les retards cachent des passages de personnes (L'HEURE JUSTE) |
| 53517 L'INFORMATEUR | Un informateur dénonce son voisin pour un appartement | Le dénoncé est innocent, l'informateur est utile au ministère |
| 53760 L'ARCHIVE | Kremer lui-même est signalé pour "vol de papier" | Protéger Kremer, c'est perdre la source des originaux ou se compromettre |

**Rebondissement de fin d'acte** : le registre de déplacements du dossier 40921, comparé à l'archive, a été modifié après coup. Sedlar était peut-être au travail. La première "vérité" du joueur était fabriquée, et c'est Mazur qui avait transmis le dossier.

### Acte 3 : La peur (jours 14 à 19)

La Centrale thermique n° 3 (celle de Sedlar et d'Orlik) explose. Le ministère veut un saboteur avant le bulletin du soir.

| Dossier | Sujet | Enjeu |
| --- | --- | --- |
| 54001 L'EXPLOSION | Trois suspects, dont M. SEDLAR, la fille | Accident par manque de pièces (réquisitions détournées par le capitaine Orlik) ou sabotage inventé |
| 54012 LE TÉMOIN | Seul survivant de l'équipe de nuit, à l'hôpital | Sa déposition change selon qui l'interroge avant vous |
| 54030 L'HORLOGER | Un vieux réparateur d'horloges arrêté | Il a connu le père de Vosk. Il reconnaît le nom. |
| 54100 VOSK, A. | Un dossier au nom du joueur apparaît dans la liste | On ne peut pas l'ouvrir, seulement le voir. Le compteur de suspicion devient visible en mots. |

**Rebondissement de fin d'acte** : Brandt n'est pas une collègue, c'est la contrôleuse. Mazur est arrêté (ou s'enfuit, selon les choix). Son dernier message : une heure, un quai, et le mot "juste".

### Acte 4 : MIROIR (jours 20 à 24)

Vosk est promu (ou muté, ou suspendu). Le directeur Halm lance l'opération MIROIR : réécrire les archives de l'explosion et des dossiers des actes 1 à 3 pour qu'ils racontent tous la même histoire. Le joueur ne vérifie plus les documents, **il les rédige**.

| Dossier | Sujet | Enjeu |
| --- | --- | --- |
| 60001 MIROIR : SEDLAR | Corriger la fiche de Sedlar pour qu'elle colle au sabotage | Chaque correction est enregistrée : le joueur choisit ce qu'il efface |
| 60002 MIROIR : CENTRALE | Rédiger le rapport officiel de l'explosion | Coupable à choisir parmi des noms déjà rencontrés |
| 60003 MIROIR : VOSK | Le dossier du père, à réécrire par son propre fils | Le choix final |

Le dernier jour, le joueur dispose de ce qu'il a gardé : originaux de Kremer, contacts de L'HEURE JUSTE, faveurs de la Milice, confiance du ministère. Ces ressources ouvrent ou ferment les fins.

## Arc de VERITAS

VERITAS n'est pas méchant : il est paramétré. Son arc se lit dans ses chiffres et ses phrases, toujours écrits dans les données (aucun LLM ne décide).

1. **Acte 1, l'assistant fiable** : ses remarques aident à trouver les contradictions. Seul indice, le 71 % du 51307 "protège les informateurs".
2. **Acte 2, le biais** : il voit un code dans des poèmes, recommande toujours la version de l'informateur. Une commande cachée (`VERITAS PARAMETRES`, trouvée dans une note de Kremer) affiche ses pondérations : "conformité de la source : x3".
3. **Acte 3, l'instrument** : ses avis arrivent avant que le joueur ait ouvert les pièces. Il cite des documents que le joueur n'a pas encore. Quelqu'un écrit les conclusions à l'avance.
4. **Acte 4, le complice ou l'outil** : pendant MIROIR, VERITAS propose les corrections. Le joueur peut l'utiliser tel quel, le contredire à chaque ligne, ou (avec les originaux de Kremer) lui faire analyser les vrais documents : il donne alors 0 % de probabilité de sabotage. Cette phrase, imprimée, devient une preuve.

Le taux d'accord avec VERITAS, déjà mémorisé, nourrit l'évaluation et une des fins.

## Fins

Sept fins, calculées par le moteur à partir des drapeaux et des indicateurs. Aucune n'est un "game over" brutal : chacune se termine par un dernier document d'archive.

| Fin | Conditions principales | Dernière image |
| --- | --- | --- |
| **Le Miroir parfait** | MIROIR signé sans réserve, loyauté haute | Vosk directeur adjoint. Son propre dossier est désormais vide, comme celui de son père. |
| **L'Heure juste** | Contacts du réseau, Mazur vivant, suspicion moyenne | Fuite par le train de 06h05 vers Halvek, celui du premier dossier. |
| **La Fuite des originaux** | Originaux de Kremer gardés + phrase "0 %" de VERITAS | Les documents sortent du pays. Vosk reste et attend qu'on frappe. |
| **L'Allié de la Milice** | `milice.ally`, faveurs utilisées | Vosk échappe au ministère mais doit tout au capitaine Orlik. |
| **Le Dossier 54100** | Suspicion très haute avant l'acte 4 | Vosk devient le sujet. Le joueur lit son dossier, rédigé par Brandt. |
| **Le Silence** | Démission refusée de MIROIR sans preuves | Mutation en province, archives au sous-sol, à la place de Kremer. |
| **La Correction** (fin cachée) | Réécrire le dossier du père avec la vérité + Kremer protégé + au moins 3 innocents épargnés | Une seule ligne vraie survit dans les archives officielles. Le jeu affiche laquelle. |

Un écran final récapitule le destin de chaque sujet rencontré (Sedlar, Orlik, Varga, la chorale…), comme une dernière page d'archive.

## Variété et nouvelles mécaniques

| Acte | Mécanique | Exemple |
| --- | --- | --- |
| 1 | Noter et confronter (existe déjà) | Présence contre registre |
| 1 | Pièces non textuelles : photo d'identité, plan, carnet de rations | La photo remplacée de Varga |
| 2 | Comparer avec l'archive (originaux de Kremer) | Registre 40921 modifié |
| 2 | Chronologie : placer les éléments sur une frise d'une journée | Retards de trains du cheminot |
| 3 | Interrogatoire : choisir 3 questions parmi 8, les réponses deviennent des pièces | Le témoin de la centrale |
| 3 | Fiabilité des sources : dégrader ou garder un informateur | L'informateur de l'appartement |
| 4 | Rédaction : caviarder ou réécrire des lignes d'un document | MIROIR |

**Variations de rythme** : un dossier court par journée de temps en temps (5 minutes), des journées sans dossier mais avec une visite ou un message important, un bulletin radio du ministère chaque matin qui ment de plus en plus visiblement.

**Immersion** : chaque dossier a au moins une pièce "humaine" (lettre, dessin d'enfant, note au crayon) qui n'est pas une preuve. Les personnages se croisent : le boulanger du 52044 chante dans la chorale du 53118, le cheminot conduit le train de 06h05.

## Plan de production (V1)

1. **0.6** : dossiers 52044 et 52310, pièces photo/plan, note de Kremer, bulletin radio quotidien. Acte 1 jouable de bout en bout.
2. **0.7** : mécanique "comparer avec l'archive", acte 2 (4 dossiers), commande `VERITAS PARAMETRES`.
3. **0.8** : chronologie et interrogatoire, acte 3, explosion de la centrale, dossier 54100.
4. **0.9** : rédaction MIROIR, calcul des 7 fins, écran récapitulatif.
5. **1.0** : réécriture des textes, sons, polices libres, test complet des embranchements.

## Réponses de fen aux questions de cadrage (2026-10-24)

1. Vosk a une vie hors du bureau, sur laquelle il peut influer.
2. Le lien avec le père disparu en 1971 est conservé.
3. Le joueur peut être arrêté avant la fin.
4. Velmira reste un pays inventé.
5. Violence montrée, qui monte crescendo.
6. Des éléments extérieurs influent sur le pays (politique, Vosk, etc.).
7. Durée d'une partie : 4 heures.
8. Durée d'une journée : 12 minutes.
9. Oui à une limite de temps dans la journée.
10. Compromis entre histoire écrite et rejouabilité ; l'histoire reste la priorité.
11. Prévoir le français et l'anglais dès maintenant.
12. Suivre la directive de game design V2.
