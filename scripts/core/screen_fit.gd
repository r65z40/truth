class_name ScreenFit
extends RefCounted
## Mise à l'échelle de l'interface sur téléphone et tablette. Logique pure.
##
## Le jeu est dessiné pour un écran d'au moins 1280 × 720 points. Sur un
## téléphone, l'écran a beaucoup de pixels mais ils sont minuscules : sans
## agrandissement, un bouton de 44 px ferait 3 mm. On agrandit donc selon la
## densité de l'écran (160 ppp = 1, comme les « dp » d'Android), sans jamais
## descendre sous MIN_HEIGHT points de haut : en dessous, les fenêtres du
## bureau ne tiennent plus (mesuré avec tests/capture_screens.tscn).

## Hauteur logique minimale (points), écran tenu à l'horizontale.
const MIN_HEIGHT := 600.0
## Densité de référence : 160 ppp = facteur 1.
const BASE_DPI := 160.0
const MAX_FACTOR := 4.0


## Facteur d'agrandissement pour un écran de screen_px pixels à dpi points par
## pouce. Toujours >= 1, arrondi au vingtième. Le petit côté de l'écran compte
## comme hauteur (le jeu se joue à l'horizontale).
static func factor_for(screen_px: Vector2i, dpi: int) -> float:
	var short_side := float(mini(screen_px.x, screen_px.y))
	if short_side <= 0.0:
		return 1.0
	var by_density := float(maxi(dpi, 1)) / BASE_DPI
	var by_height := short_side / MIN_HEIGHT
	var factor := clampf(minf(by_density, by_height), 1.0, MAX_FACTOR)
	return floorf(factor * 20.0) / 20.0


## Taille logique obtenue (ce que voit la mise en page).
static func logical_size(screen_px: Vector2i, factor: float) -> Vector2:
	return Vector2(screen_px) / maxf(factor, 1.0)


## Écran court : la mise en page doit se resserrer (menu principal...).
static func is_short(viewport_size: Vector2) -> bool:
	return viewport_size.y < 680.0
