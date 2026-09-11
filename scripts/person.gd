class_name Person
## Generator parafian z brył. Jedno miejsce dla mszy, spowiedzi, tłumu na festynie
## i późniejszych postaci z rutyną. Wygląd zależy od ziarna, więc ta sama osoba
## wygląda tak samo za każdym razem.

const COATS := [Color("3a3a44"), Color("4a3a30"), Color("2f3a4a"), Color("5a5048"),
	Color("3a2e3a"), Color("4a4a3a"), Color("6a5a4a"), Color("52414a"), Color("39463f")]
const HAIRS := [Color("2e1c14"), Color("6a6a6a"), Color("1a1a1a"), Color("8a7a5a"), Color("b0a090")]
const SKINS := [Color("c9a58a"), Color("d9b8a0"), Color("b89478")]
const SCARVES := [Color("7a3a4a"), Color("3a4a6a"), Color("6a5a2a"), Color("4a4a52")]

## Archetypy różnią się wzrostem, tuszą i dodatkami.
const KINDS := ["dorosly", "babcia", "dziadek", "dziecko", "nastolatek"]


static func make(seed_value: int) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var kind: String = KINDS[rng.randi() % KINDS.size()]
	var height := 1.0
	var girth := 1.0
	match kind:
		"dziecko":
			height = 0.62
			girth = 0.85
		"nastolatek":
			height = 0.86
		"babcia":
			height = 0.88
			girth = 1.12
		"dziadek":
			height = 0.93
			girth = 1.05
		_:
			height = rng.randf_range(0.96, 1.06)
			girth = rng.randf_range(0.92, 1.1)

	var root := Node3D.new()
	var body := _part(root, _body_mesh(girth), COATS[rng.randi() % COATS.size()], Vector3(0, 0.65 * height, 0))
	body.scale = Vector3(1, height, 1)
	var head_mesh := _head_mesh()
	_part(root, head_mesh, SKINS[rng.randi() % SKINS.size()], Vector3(0, 1.55 * height, 0))
	var hair := _part(root, head_mesh, HAIRS[rng.randi() % HAIRS.size()], Vector3(0, 1.62 * height, 0))
	hair.scale = Vector3(1.05, 0.55, 1.05)
	match kind:
		"babcia":
			# chustka zawiązana pod brodą
			var scarf := _part(root, head_mesh, SCARVES[rng.randi() % SCARVES.size()], Vector3(0, 1.6 * height, 0))
			scarf.scale = Vector3(1.12, 0.8, 1.12)
		"dziadek":
			# kaszkiet
			var cap := _part(root, _cap_mesh(), Color("3a3a3a"), Vector3(0, 1.78 * height, 0))
			cap.scale = Vector3(1.0, 0.6, 1.0)
		"dziecko":
			pass
	return root


static func _body_mesh(girth: float) -> Mesh:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28 * girth
	cyl.bottom_radius = 0.36 * girth
	cyl.height = 1.3
	cyl.radial_segments = 8
	cyl.rings = 1
	return cyl


static func _head_mesh() -> Mesh:
	var sph := SphereMesh.new()
	sph.radius = 0.24
	sph.height = 0.48
	sph.radial_segments = 8
	sph.rings = 5
	return sph


static func _cap_mesh() -> Mesh:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.26
	cyl.bottom_radius = 0.28
	cyl.height = 0.3
	cyl.radial_segments = 8
	return cyl


static func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterial.make(color)
	mi.position = pos
	parent.add_child(mi)
	return mi
