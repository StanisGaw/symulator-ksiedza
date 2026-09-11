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

## Chód: długość kroku, uniesienie buta, podskok sylwetki i kołysanie na boki (radiany).
## Postacie nie mają nóg, więc krok pokazują buty wystające spod płaszcza plus kołysanie -
## bez tego parafianie suną po placu, zamiast iść.
const WALK_STRIDE := 0.16
const WALK_LIFT := 0.035
const WALK_BOB := 0.012
const WALK_ROLL := 0.025
## Ile cykli kroku na metr drogi; to samo tempo co u księdza.
const WALK_CADENCE := 1.9
## Klęknięcie: o ile postać opada i jak mocno pochyla się w przód (radiany).
const KNEEL_DROP := 0.34
const KNEEL_LEAN := 0.12


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
	# płaszcz kończy się nad kostkami, żeby spod niego było widać buty w ruchu
	var body := _part(root, _body_mesh(girth), COATS[rng.randi() % COATS.size()], Vector3(0, 0.72 * height, 0))
	body.scale = Vector3(1, height, 1)
	var shoe := BoxMesh.new()
	shoe.size = Vector3(0.16, 0.09, 0.26)
	var shoe_color := Color("1a120c")
	var shoe_l := _part(root, shoe, shoe_color, Vector3(-0.12, 0.045, 0.03))
	var shoe_r := _part(root, shoe, shoe_color, Vector3(0.12, 0.045, 0.03))
	root.set_meta("walk", {"body": body, "shoe_l": shoe_l, "shoe_r": shoe_r, "height": height})
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


## Cykl chodu dla postaci z make(): buty idą na zmianę, sylwetka podskakuje i kołysze się.
## Fazę podaje ten, kto rusza postacią, więc tempo wynika z przebytej drogi.
static func walk(node: Node3D, phase: float) -> void:
	if not node.has_meta("walk"):
		return
	var parts: Dictionary = node.get_meta("walk")
	var step := sin(phase)
	var height: float = parts["height"]
	var shoe_l: Node3D = parts["shoe_l"]
	var shoe_r: Node3D = parts["shoe_r"]
	shoe_r.position = Vector3(0.12, 0.045 + maxf(0.0, step) * WALK_LIFT, 0.03 + step * WALK_STRIDE)
	shoe_l.position = Vector3(-0.12, 0.045 + maxf(0.0, -step) * WALK_LIFT, 0.03 - step * WALK_STRIDE)
	var body: Node3D = parts["body"]
	body.position.y = 0.72 * height + absf(sin(phase * 2.0)) * WALK_BOB
	body.rotation.z = step * WALK_ROLL


## Klęczenie: postać opada i pochyla się lekko w przód, a buty chowają się pod płaszczem.
## Wcześniej scena ściskała całą bryłę w pionie, przez co kurczyła się też głowa.
static func kneel(node: Node3D, on: bool) -> void:
	if not node.has_meta("walk"):
		return
	var parts: Dictionary = node.get_meta("walk")
	var height: float = parts["height"]
	var body: Node3D = parts["body"]
	stand(node)
	if on:
		node.position.y -= KNEEL_DROP * height
		body.rotation.x = KNEEL_LEAN
		parts["shoe_l"].position.z = -0.12
		parts["shoe_r"].position.z = -0.12
	else:
		body.rotation.x = 0.0


## Przesuwa fazę kroku o przebytą drogę i układa postać. Faza siedzi w metadanych węzła,
## więc ten, kto rusza postacią, nie musi jej u siebie trzymać.
static func advance(node: Node3D, distance: float) -> void:
	if not node.has_meta("walk"):
		return
	var phase := float(node.get_meta("walk_phase", 0.0)) + distance * WALK_CADENCE * PI
	node.set_meta("walk_phase", phase)
	walk(node, phase)


## Postać w spoczynku: buty równo, płaszcz bez przechyłu.
static func stand(node: Node3D) -> void:
	if not node.has_meta("walk"):
		return
	var parts: Dictionary = node.get_meta("walk")
	var height: float = parts["height"]
	parts["shoe_l"].position = Vector3(-0.12, 0.045, 0.03)
	parts["shoe_r"].position = Vector3(0.12, 0.045, 0.03)
	parts["body"].position.y = 0.72 * height
	parts["body"].rotation.z = 0.0


static func _body_mesh(girth: float) -> Mesh:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28 * girth
	cyl.bottom_radius = 0.36 * girth
	cyl.height = 1.22
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
