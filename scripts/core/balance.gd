class_name Balance
extends RefCounted
## Réglage d'équilibre des indicateurs (data/rules/balance.json). Logique pure.
##
## Les hausses d'un indicateur sont ramenées à gain_percent % de la valeur écrite
## dans les données (arrondi à l'entier le plus proche, au moins 1) ; les baisses
## restent entières. Permet de régler l'équilibre de toute la campagne en un seul
## chiffre, sans réécrire les dossiers.

const RULES_PATH := "res://data/rules/balance.json"

## Outil de mesure seulement (robot de partie) : remplace gain_percent de la
## suspicion si >= 0. Le jeu ne le modifie jamais.
static var override_percent := -1
static var _rules: Dictionary = {}


## Réglages lus une fois (aucun texte traduit : pas de cache à vider).
static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = DataLoader.load_json(RULES_PATH)
	return _rules


## Pourcentage appliqué aux hausses de l'indicateur (100 si non réglé).
static func gain_percent(indicator: String) -> int:
	if indicator == "suspicion" and override_percent >= 0:
		return override_percent
	return int(rules().get("gain_percent", {}).get(indicator, 100))


## Écart réellement appliqué pour un écart écrit dans les données.
static func scaled(indicator: String, delta: int) -> int:
	if delta <= 0:
		return delta
	var percent := gain_percent(indicator)
	if percent == 100:
		return delta
	return maxi(1, roundi(delta * percent / 100.0)) if percent > 0 else 0
