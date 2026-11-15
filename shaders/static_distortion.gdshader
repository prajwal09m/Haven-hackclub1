shader_type canvas_item;
// Full-screen static + horizontal tearing + colour split. Drive "intensity" from 0 to 1.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float noise_mix : hint_range(0.0, 1.0) = 0.6;
uniform float tear_chance : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 24.0);
	float band = floor(uv.y * 40.0);
	float tear = step(1.0 - tear_chance, hash(vec2(band + 7.0, t)));
	uv.x += (hash(vec2(band, t)) - 0.5) * intensity * 0.3 * tear;
	float split = 0.012 * intensity;
	float r = texture(screen_tex, uv + vec2(split, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(split, 0.0)).b;
	vec3 col = vec3(r, g, b);
	float n = hash(floor(SCREEN_UV * vec2(320.0, 240.0)) + t);
	col = mix(col, vec3(n), clamp(intensity * noise_mix, 0.0, 1.0));
	COLOR = vec4(col, 1.0);
}
