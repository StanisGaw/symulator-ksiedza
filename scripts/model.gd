class_name Model
## Ładuje modele wyeksportowane z Blendera (assets/models/*.glb) i podmienia
## materiały z importu na toonowe, żeby pasowały do brył budowanych w kodzie.
## Nazwa materiału w .glb musi odpowiadać stałej z Palette, np. "BENCH".

const DIR := "res://assets/models/"

static var _colors: Dictionary = {}


static func make(model_name: String) -> Node3D:
	var path := DIR + model_name + ".glb"
	if not ResourceLoader.exists(path):
		push_warning("brak modelu: " + path)
		return Node3D.new()
	var root: Node3D = (load(path) as PackedScene).instantiate()
	_toonify(root)
	return root


static func _toonify(node: Node) -> void:
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			mi.set_surface_override_material(i, ToonMaterial.make(_color(src.resource_name if src else "")))
	for child in node.get_children():
		_toonify(child)


static func _color(key: String) -> Color:
	if _colors.is_empty():
		var palette_script: Script = load("res://scripts/palette.gd")
		_colors = palette_script.get_script_constant_map()
	var c: Variant = _colors.get(key)
	if c is Color:
		return c
	push_warning("materiał spoza Palette: '" + key + "'")
	return Color.MAGENTA
