// Toon shading with quantized light steps. Ambient fill comes from WorldEnvironment.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0) = 0.0;
uniform int steps : hint_range(1, 6) = 3;
uniform float ramp : hint_range(1.0, 3.0) = 1.6;

void fragment() {
	ALBEDO = albedo.rgb;
	EMISSION = emission_color.rgb * emission_strength;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float lit = clamp(ndl * ramp, 0.0, 1.0) * ATTENUATION;
	float q = floor(lit * float(steps) + 0.5) / float(steps);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * q / PI;
}
