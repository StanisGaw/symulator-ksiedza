// Inverted-hull outline, used as next_pass on toon materials.
shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.07, 1.0);
uniform float grow : hint_range(1.0, 1.2) = 1.06;

void vertex() {
	VERTEX *= grow;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
