// Obscurité d'une scène de terrain : tout est noir, sauf le halo de la lampe.
// Posé au-dessus de l'image par FieldLamp ; ne capte pas la souris.
shader_type canvas_item;

uniform vec2 rect_size = vec2(1.0);
// Centre du halo et rayon, en pixels du contrôle.
uniform vec2 lamp = vec2(0.0);
uniform float radius = 80.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.9;
uniform float flicker : hint_range(0.0, 0.2) = 0.04;

void fragment() {
	vec2 p = UV * rect_size;
	// Léger vacillement de la pile, pour que le halo vive.
	float r = radius * (1.0 + flicker * sin(TIME * 7.0) * sin(TIME * 2.3));
	float a = smoothstep(r * 0.55, r * 1.15, distance(p, lamp));
	// Lueur chaude au cœur du halo.
	float glow = (1.0 - smoothstep(0.0, r * 0.9, distance(p, lamp))) * 0.10;
	COLOR = mix(vec4(1.0, 0.85, 0.55, glow), vec4(0.0, 0.0, 0.0, darkness), a);
}
