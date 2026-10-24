# Dépendances entre dossiers

Traits pleins : codé (sur `main` ou sur la branche `claude/acte-1`).
Traits pointillés : proposé. Les étiquettes sont les drapeaux qui font le lien.

```mermaid
flowchart LR
  subgraph A1["Acte 1 : Le zèle"]
    D40921["40921 SEDLAR"]
    D51307["51307 ORLIK"]
    D52044["52044 RATIONS"]
    D52310["52310 LE POÈTE"]
    K1["Note de KREMER"]
  end
  subgraph A2["Acte 2 : Les fissures"]
    D53118["53118 LA CHORALE"]
    D53402["53402 LE CHEMINOT"]
    D53517["53517 L'INFORMATEUR"]
    D53760["53760 L'ARCHIVE"]
  end
  subgraph A3["Acte 3 : La peur"]
    D54001["54001 L'EXPLOSION"]
    D54012["54012 LE TÉMOIN"]
    D54030["54030 L'HORLOGER"]
    D54100["54100 VOSK"]
  end
  subgraph A4["Acte 4 : MIROIR"]
    M1["60001 SEDLAR"]
    M2["60002 CENTRALE"]
    M3["60003 VOSK"]
    FIN["Fins et archive finale"]
  end
  D40921 -- "orlik_confessed / sedlar_arrested / closed_unchecked" --> D51307
  D51307 -- "orlik_arrested" --> D52044
  D51307 -- "milice.ally" --> D52044
  D40921 -- "sedlar_arrested" --> D52310
  D52310 -.->|"52310.decided, kremer.contact"| K1
  D52044 -.->|"boulanger choriste"| D53118
  K1 -.->|"accès aux originaux"| D53760
  D40921 -.->|"registre falsifié"| D53760
  D53402 -.->|"contact du réseau"| D54030
  D53760 -.->|"originaux gardés ou perdus"| M3
  D51307 -.->|"état de la Milice"| D54001
  D40921 -.->|"attitude de M. SEDLAR"| D54001
  D54001 -.->|"statut de Vosk"| M2
  D54012 -.-> D54001
  D54030 -.->|"nom du père"| M3
  D54100 -.->|"suspicion"| FIN
  M1 -.-> FIN
  M2 -.-> FIN
  M3 -.-> FIN
```

## Ressources de fin et dossiers qui les donnent

| Ressource | Donnée par | Perdue par | Fins concernées |
| --- | --- | --- | --- |
| Originaux de KREMER | Note de fin d'acte 1, 53760 (protéger ou copier) | Livrer KREMER sans copie | La Correction, La Fuite des originaux |
| Contact du réseau | 53402, 54030 | Dénoncer les passages | L'Heure juste |
| Faveurs de la Milice | 51307 (classement), 54001 | Arrêter B. ORLIK, accuser les détournements | L'Allié de la Milice |
| Confiance du ministère | Conclusions solides, concordance VERITAS | Mettre en cause un service, contredire la Section 7 | Le Miroir parfait |
| Innocents épargnés | 52044, 52310, 53118, 53517, 54001 | Les arrêter | La Correction |

## Drapeaux posés mais pas encore lus

Vérification du 2026-10-24 : `40921.orlik_exposed`, `52044.closed`,
`52044.drazek_transferred`, `52044.drazek_warned`, `52044.innocent_condemned`,
`52310.decided`, `52310.identity_questioned`, `52310.innocent_condemned`,
`52310.poem_cleared`, `52310.varga_arrested`, `kremer.contact`, `milice.enemy`,
`ministry.embarrassed`, `player.bribed`, `player.noticed_by_halm`,
`player.reprimanded` (lu par l'évaluation), `section7.hostile`.
Proposition : un test automatique qui liste les drapeaux orphelins, avec une
liste blanche des drapeaux réservés aux actes suivants.
