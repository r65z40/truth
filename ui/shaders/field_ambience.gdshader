// Ambiance 2.5D d'une scène de terrain : grain de pellicule et lumière qui
// vacille. Posé sur l'image par FieldAmbience ; ne capte pas la souris.
shader_type canvas_item;

uniform float grain : hint_range(0.0, 1.0) = 0.5;
uniform float flicker : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// Grain : un point sur deux pixels, renouvelé douze fois par seconde.
	float g = (hash(floor(FRAGCOORD.xy / 2.0) + floor(TIME * 12.0)) - 0.5) * 0.12 * grain;
	vec3 col = g > 0.0 ? vec3(1.0) : vec3(0.0);
	float a = abs(g);
	// Vacillement : la lumière baisse par à-coups irréguliers, jamais au noir.
	float f = flicker * 0.22 * max(0.0, sin(TIME * 3.1) * sin(TIME * 7.3) + sin(TIME * 13.0) * 0.3);
	col = mix(col, vec3(0.0), f / (a + f + 0.0001));
	COLOR = vec4(col, clamp(a + f, 0.0, 0.6));
}
