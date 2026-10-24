// Effet d'écran cathodique discret : lignes de balayage + vignettage.
// Superposé à toute l'interface par CrtOverlay. N'altère pas la lisibilité du texte.
shader_type canvas_item;

uniform float scanline_strength : hint_range(0.0, 0.5) = 0.10;
uniform float scanline_spacing : hint_range(1.0, 8.0) = 3.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float flicker_strength : hint_range(0.0, 0.1) = 0.012;

void fragment() {
	float scanline = step(scanline_spacing - 1.0, mod(FRAGCOORD.y, scanline_spacing)) * scanline_strength;
	vec2 centered = SCREEN_UV - vec2(0.5);
	float vignette = smoothstep(0.35, 0.85, length(centered)) * vignette_strength;
	float flicker = (sin(TIME * 60.0) * 0.5 + 0.5) * flicker_strength;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(scanline + vignette + flicker, 0.0, 0.85));
}
