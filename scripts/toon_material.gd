class_name ToonMaterial
## Helper for placeholder art: toon shader material with an inverted-hull outline as next_pass.

const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")


static func make(color: Color, emission: Color = Color.BLACK, emission_strength: float = 0.0, outline: bool = true) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = TOON
	mat.set_shader_parameter("albedo", color)
	mat.set_shader_parameter("emission_color", emission)
	mat.set_shader_parameter("emission_strength", emission_strength)
	mat.set_shader_parameter("steps", 3)
	if outline:
		var out := ShaderMaterial.new()
		out.shader = OUTLINE
		out.set_shader_parameter("outline_color", Color(0.05, 0.05, 0.07))
		out.set_shader_parameter("grow", 1.06)
		mat.next_pass = out
	return mat
