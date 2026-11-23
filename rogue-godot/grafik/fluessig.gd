## NetHack (Peter 21.11.2026): Wasser, Lava und Eis als Bodenflächen. Selbst gebaut im Code (kein fremdes Bild):
## ein kleiner Shader mit bewegtem Rauschen. Wasser spiegelt dunkel, Lava glüht und leuchtet, Eis ist hell und glatt.
extends RefCounted

const SHADER := """
shader_type spatial;
uniform vec3 farbe : source_color = vec3(0.05, 0.12, 0.16);
uniform vec3 hell : source_color = vec3(0.15, 0.3, 0.35);
uniform float glut = 0.0;
uniform float tempo = 0.25;
uniform float rauheit = 0.08;
uniform float metall = 0.0;

float zufall(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float rauschen(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(zufall(i), zufall(i + vec2(1, 0)), f.x), mix(zufall(i + vec2(0, 1)), zufall(i + vec2(1, 1)), f.x), f.y);
}
float wolken(vec2 p) {
	float s = 0.0; float a = 0.5;
	for (int k = 0; k < 4; k++) { s += a * rauschen(p); p *= 2.03; a *= 0.5; }
	return s;
}
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = w.xz * 0.9;
	float t = TIME * tempo;
	float n = wolken(p + vec2(t, t * 0.7)) * 0.6 + wolken(p * 1.7 - vec2(t * 0.8, -t * 0.5)) * 0.4;
	ALBEDO = mix(farbe, hell, n);
	ROUGHNESS = rauheit;
	METALLIC = metall;
	EMISSION = mix(farbe, hell, n * n) * glut;
}
"""


static func materialien() -> Dictionary:
	var sh := Shader.new()
	sh.code = SHADER
	var wasser := ShaderMaterial.new()
	wasser.shader = sh
	var lava := ShaderMaterial.new()
	lava.shader = sh
	lava.set_shader_parameter("farbe", Color(0.35, 0.03, 0.0))
	lava.set_shader_parameter("hell", Color(1.0, 0.55, 0.08))
	lava.set_shader_parameter("glut", 3.0)
	lava.set_shader_parameter("tempo", 0.08)
	lava.set_shader_parameter("rauheit", 0.9)
	var eis := ShaderMaterial.new()
	eis.shader = sh
	eis.set_shader_parameter("farbe", Color(0.55, 0.68, 0.75))
	eis.set_shader_parameter("hell", Color(0.85, 0.93, 1.0))
	eis.set_shader_parameter("tempo", 0.0)
	eis.set_shader_parameter("rauheit", 0.15)
	return {"wasser": wasser, "lava": lava, "eis": eis}
