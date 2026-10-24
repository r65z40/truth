class_name Career
extends RefCounted
## Échelons de carrière du joueur. La logique de promotion viendra plus tard ;
## pour l'instant ce module ne fait que nommer les grades.

enum Rank { INSPECTOR, ANALYST, SECTION_CHIEF, INTELLIGENCE_DIRECTOR, MINISTER, LEADER }

const RANK_TITLES := {
	Rank.INSPECTOR: "Inspecteur de 3e classe",
	Rank.ANALYST: "Analyste du renseignement",
	Rank.SECTION_CHIEF: "Chef de section",
	Rank.INTELLIGENCE_DIRECTOR: "Directeur du renseignement",
	Rank.MINISTER: "Ministre de la Sécurité",
	Rank.LEADER: "Haut dirigeant du régime",
}


static func rank_title(rank: int) -> String:
	return RANK_TITLES.get(rank, "Grade inconnu")
