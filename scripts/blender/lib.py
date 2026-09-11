"""Wspolne narzedzia dla modeli budowanych w Blenderze.

Modele opisujemy kodem, tak jak reszte projektu. Kazdy plik w scripts/blender/
buduje jedna rzecz i eksportuje .glb do assets/models/. Kolory materialow biora
sie z scripts/palette.gd - w Blenderze sluza tylko do podgladu, bo w grze i tak
podmienia je ToonMaterial (patrz scripts/model.gd).
"""

import os
import re
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(ROOT, "assets", "models")


def palette():
	"""Czyta stale z palette.gd jako {"BENCH": (r, g, b), ...}."""
	src = os.path.join(ROOT, "scripts", "palette.gd")
	colors = {}
	with open(src, encoding="utf-8") as fh:
		for line in fh:
			m = re.match(r'^const (\w+) := Color\("([0-9a-fA-F]{6})"\)', line)
			if m:
				h = m.group(2)
				colors[m.group(1)] = tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
	return colors


PALETTE = palette()


def reset():
	"""Pusta scena, bez kostki i lampy z domyslnego startu."""
	bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name):
	"""Material nazwany jak stala z Palette - po tej nazwie Godot dobiera kolor."""
	if name in bpy.data.materials:
		return bpy.data.materials[name]
	mat = bpy.data.materials.new(name=name)
	mat.use_nodes = True
	rgb = PALETTE.get(name, (0.8, 0.2, 0.8))  # magenta = literowka w nazwie
	bsdf = mat.node_tree.nodes.get("Principled BSDF")
	if bsdf:
		bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
		bsdf.inputs["Roughness"].default_value = 0.9
	return mat


def assign(obj, mat_name):
	obj.data.materials.clear()
	obj.data.materials.append(material(mat_name))
	return obj


def cube(size, location=(0, 0, 0), mat=None, name=None):
	"""Prostopadloscian o podanych wymiarach (x, y, z) w metrach, srodek w location."""
	bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
	obj = bpy.context.active_object
	obj.scale = size
	bpy.ops.object.transform_apply(scale=True)
	if name:
		obj.name = name
	if mat:
		assign(obj, mat)
	return obj


def cylinder(radius, depth, location=(0, 0, 0), segments=12, mat=None, rotation=(0, 0, 0)):
	bpy.ops.mesh.primitive_cylinder_add(
		radius=radius, depth=depth, vertices=segments, location=location, rotation=rotation
	)
	obj = bpy.context.active_object
	if mat:
		assign(obj, mat)
	return obj


def bevel(obj, width=0.01, segments=2):
	"""Zmiekcza krawedzie - glowny powod, dla ktorego w ogole idziemy przez Blendera."""
	mod = obj.modifiers.new(name="Bevel", type="BEVEL")
	mod.width = width
	mod.segments = segments
	mod.limit_method = "ANGLE"
	return obj


def mirror(obj, axis="X"):
	mod = obj.modifiers.new(name="Mirror", type="MIRROR")
	mod.use_axis = (axis == "X", axis == "Y", axis == "Z")
	return obj


def shade_flat(obj):
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.shade_flat()
	return obj


def export(model_name):
	"""Zapisuje cala scene do assets/models/<model_name>.glb."""
	os.makedirs(OUT_DIR, exist_ok=True)
	path = os.path.join(OUT_DIR, model_name + ".glb")
	bpy.ops.export_scene.gltf(
		filepath=path,
		export_format="GLB",
		export_apply=True,          # modyfikatory (bevel, mirror) wpieczone w siatke
		export_materials="EXPORT",  # nazwy materialow musza dojechac do Godota
		export_cameras=False,
		export_lights=False,
		export_yup=True,            # Blender Z-up -> Godot Y-up
	)
	print("zapisano: " + path)
	return path
