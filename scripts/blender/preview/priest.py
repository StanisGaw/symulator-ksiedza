"""Podglad ksiedza i scen czynnosci w Blenderze, zbudowany z tego samego kodu, co gra.

Ksiadz nie jest modelem z pliku - powstaje z prymitywow w player.gd::_build_model(),
a rekwizyty w activity_scene.gd. Zeby dalo sie obejrzec poze i animacje bez odpalania
gry, ten skrypt odtwarza te sama hierarchie w Blenderze: wezly Player -> Model -> Body
-> ramie -> dlon jak w Godocie, eulery skladane w kolejnosci YXZ (tak jak Godot),
a caly rig wisi pod empty obroconym o +90 wokol X, wiec Y-up Godota wyglada jak Z-up
Blendera.

Stale animacji, ulozenie miotly i poza rak czytamy z .gd, zeby podglad nie rozjechal
sie z gra. Bryly ciala trzymamy tutaj w tabelach PARTS - przy zmianie _build_model()
trzeba je poprawic recznie (to jedyne miejsce, ktore sie dubluje).

Uruchomienie:
    blender --python scripts/blender/preview/priest.py
albo z zakladki Scripting w otwartym Blenderze. Skrypt NIE czysci pliku - wszystko
laduje w nowej scenie "PriestSweep", obiekty maja prefiks "PS_", a scena jest przy
kazdym uruchomieniu budowana od zera. Nic poza nia nie jest ruszane.

    --broom=28,-12,1.8   nadpisuje kat kija do pionu, skret w bok i dlugosc (jak w grze)

solve_left_arm() liczy katy lewego ramienia tak, zeby dlon trafila w kij - wynik
wpisujemy do player.gd jako WORK_ARM_LEFT.
"""

import math
import os
import re
import sys

import bpy
from mathutils import Euler, Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(HERE))
import lib  # noqa: E402  (sciezka musi byc ustawiona wczesniej)

SCENE = "PriestSweep"
PREFIX = "PS_"
FPS = 24
CYCLES = 2  # ile pelnych wymachow ma miec animacja


# ---------- stale z GDScriptu ----------

def _gd(path):
	with open(os.path.join(lib.ROOT, "scripts", path), encoding="utf-8") as fh:
		return fh.read()


def _number(src, name):
	m = re.search(r"^(?:const|var) " + name + r"(?:: float)? :?= (-?[\d.]+)", src, re.M)
	return float(m.group(1))


def _vector3(src, name):
	m = re.search(r"^(?:const|var) " + name + r" :?= Vector3\(([^)]+)\)", src, re.M)
	return tuple(float(v) for v in m.group(1).split(","))


_ACTIVITY = _gd("activity_scene.gd")
_PLAYER = _gd("player.gd")
SWEEP_SPEED = _number(_ACTIVITY, "SWEEP_SPEED")
BROOM_GRIP = _number(_ACTIVITY, "BROOM_GRIP")
BROOM_TILT = _number(_ACTIVITY, "broom_tilt")
BROOM_YAW = _number(_ACTIVITY, "broom_yaw")
BROOM_LENGTH = _number(_ACTIVITY, "broom_length")
BROOM_ANCHOR = _vector3(_ACTIVITY, "broom_anchor")
BROOM_SPREAD = _number(_ACTIVITY, "BROOM_SPREAD")
SWEEP_PUSH = _number(_ACTIVITY, "SWEEP_PUSH")
SWEEP_LIFT = _number(_ACTIVITY, "SWEEP_LIFT")
SWEEP_TILT = _number(_ACTIVITY, "SWEEP_TILT")
SWEEP_BODY_YAW = _number(_ACTIVITY, "SWEEP_BODY_YAW")
BROOM_HEAD_HALF = _number(_ACTIVITY, "BROOM_HEAD_HALF")
WORK_BODY = 26.0     # set_pose("work"): pochylenie w pasie
CHEST_Y = _number(_PLAYER, "CHEST_Y")
SHOULDER = Vector(_vector3(_PLAYER, "SHOULDER"))
UPPER_ARM = _number(_PLAYER, "UPPER_ARM")
FOREARM = _number(_PLAYER, "FOREARM")
PHONE_HAND = Vector(_vector3(_PLAYER, "PHONE_HAND"))
WALK_STRIDE = _number(_PLAYER, "WALK_STRIDE")
WALK_LIFT = _number(_PLAYER, "WALK_LIFT")
WALK_BOB = _number(_PLAYER, "WALK_BOB")
WALK_ROLL = _number(_PLAYER, "WALK_ROLL")
WALK_SWING = _number(_PLAYER, "WALK_SWING")
WALK_HEM = _number(_PLAYER, "WALK_HEM")
ELBOW_POLE_R = Vector(_vector3(_PLAYER, "ELBOW_POLE_RIGHT"))
ELBOW_POLE_L = Vector(_vector3(_PLAYER, "ELBOW_POLE_LEFT"))

# ---------- bryly ciala, odbicie player.gd::_build_model() ----------
# ("typ", nazwa, parametry, pozycja w ukladzie Body, obrot w stopniach, kolor)
SHOE = (0.22, 0.1, 0.34)

# bryly wiszace na tulowiu (nogi i sutanna) - stoja pionowo, nie pochylaja sie
PARTS = [
	("cyl", "Sutanna_dol", (0.34, 0.52, 1.38, 10), (0, 0.84, 0), (0, 0, 0), "CASSOCK"),
	("box", "But_L", (SHOE,), (-0.16, 0.05, 0.05), (0, 0, 0), "SHOES"),
	("box", "But_P", (SHOE,), (0.16, 0.05, 0.05), (0, 0, 0), "SHOES"),
]
# bryly od pasa w gore, w ukladzie wezla piersi
CHEST_PARTS = [
	("cyl", "Tors", (0.3, 0.34, 0.55, 10), (0, 0.27, 0), (0, 0, 0), "CASSOCK"),
	("cyl", "Kolnierz", (0.2, 0.2, 0.12, 10), (0, 0.59, 0), (0, 0, 0), "COLLAR"),
	("cyl", "Szyja", (0.12, 0.12, 0.14, 8), (0, 0.7, 0), (0, 0, 0), "SKIN"),
	("sph", "Glowa", (0.29, (1, 1, 1)), (0, 1.0, 0), (0, 0, 0), "SKIN"),
	("sph", "Wlosy", (0.31, (1, 0.55, 1)), (0, 1.08, 0), (0, 0, 0), "HAIR"),
]


def shoulder_pos(side):
	return Vector((SHOULDER.x * side, SHOULDER.y, SHOULDER.z))


# ---------- narzedzia ----------

def _srgb_to_linear(c):
	return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _material(name, rgb=None):
	"""Material nazwany jak stala z Palette; kolor tylko do podgladu (w grze robi to ToonMaterial)."""
	key = PREFIX + name
	if key in bpy.data.materials:
		return bpy.data.materials[key]
	rgb = rgb or lib.PALETTE[name]
	mat = bpy.data.materials.new(key)
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes.get("Principled BSDF")
	bsdf.inputs["Base Color"].default_value = (*[_srgb_to_linear(c) for c in rgb], 1.0)
	bsdf.inputs["Roughness"].default_value = 0.95
	return mat


def _godot_quat(rx, ry, rz):
	"""Godot sklada eulery w kolejnosci YXZ - skladamy tak samo, zeby katy z .gd pasowaly."""
	m = (Matrix.Rotation(math.radians(ry), 4, "Y")
		@ Matrix.Rotation(math.radians(rx), 4, "X")
		@ Matrix.Rotation(math.radians(rz), 4, "Z"))
	return m.to_quaternion()


def _godot_euler_degrees(quat):
	"""Odwrotnosc _godot_quat: kwaternion -> katy, ktore mozna wpisac do .gd."""
	for order in ("YXZ", "ZXY", "XYZ", "YZX", "XZY", "ZYX"):
		e = quat.to_euler(order)
		cand = (math.degrees(e.x), math.degrees(e.y), math.degrees(e.z))
		if (_godot_quat(*cand).rotation_difference(quat).angle) < 1e-4:
			return tuple(round(v, 1) for v in cand)
	raise RuntimeError("nie udalo sie rozlozyc obrotu na katy YXZ")


class Rig:
	"""Scena podgladu razem z uchwytami do wezlow, ktore animujemy."""

	def __init__(self, scene):
		self.scene = scene
		self.conv = None
		self.player = None
		self.model = None
		self.body = None
		self.arm_right = self.elbow_right = self.hand_right = None
		self.arm_left = self.elbow_left = self.hand_left = None
		self.props = None
		self.chest = None
		self.shoe_right = self.shoe_left = self.cassock = None
		self.phone = None
		self.broom = None

	def link(self, obj):
		if not obj.name.startswith(PREFIX):
			obj.name = PREFIX + obj.name
		self.scene.collection.objects.link(obj)
		return obj

	def place(self, obj, parent, loc, rot=(0, 0, 0), scale=(1, 1, 1)):
		if parent:
			obj.parent = parent
			obj.matrix_parent_inverse.identity()
		obj.location = Vector(loc)
		obj.rotation_mode = "QUATERNION"
		obj.rotation_quaternion = _godot_quat(*rot)
		obj.scale = Vector(scale)
		return obj

	def empty(self, name, parent=None, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
		obj = bpy.data.objects.new(name, None)
		obj.empty_display_size = 0.2
		self.link(obj)
		return self.place(obj, parent, loc, rot, scale)

	def _adopt(self, name):
		"""Obiekt z bpy.ops trafia do aktywnej kolekcji - przenosimy go do naszej sceny."""
		obj = bpy.context.object
		for coll in list(obj.users_collection):
			coll.objects.unlink(obj)
		self.link(obj)
		obj.name = PREFIX + name
		return obj

	def cyl(self, name, parent, top, bottom, height, loc, rot=(0, 0, 0), segments=10, color="CASSOCK"):
		# Godot: CylinderMesh ma os wzdluz Y, Blender wzdluz Z - obracamy same wierzcholki,
		# zeby transform obiektu zostal wolny na katy przepisane z .gd
		bpy.ops.mesh.primitive_cone_add(vertices=segments, radius1=bottom, radius2=top, depth=height)
		obj = self._adopt(name)
		obj.data.transform(Matrix.Rotation(math.radians(-90), 4, "X"))
		obj.data.materials.append(_material(color))
		return self.place(obj, parent, loc, rot)

	def sphere(self, name, parent, radius, loc, color="SKIN", scale=(1, 1, 1)):
		bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=radius)
		obj = self._adopt(name)
		obj.data.transform(Matrix.Rotation(math.radians(-90), 4, "X"))
		obj.data.materials.append(_material(color))
		return self.place(obj, parent, loc, (0, 0, 0), scale)

	def box(self, name, parent, size, loc, rot=(0, 0, 0), color="CASSOCK", rgb=None):
		bpy.ops.mesh.primitive_cube_add(size=1.0)
		obj = self._adopt(name)
		obj.data.transform(Matrix.Diagonal(Vector(size)).to_4x4())
		obj.data.materials.append(_material(color, rgb))
		return self.place(obj, parent, loc, rot)

	def part(self, spec, parent, origin=Vector((0, 0, 0))):
		kind, name, args, loc, rot, color = spec
		loc = Vector(loc) - Vector(origin)
		if kind == "cyl":
			top, bottom, height, segments = args
			return self.cyl(name, parent, top, bottom, height, loc, rot, segments, color)
		if kind == "sph":
			radius, scale = args
			return self.sphere(name, parent, radius, loc, color, scale)
		return self.box(name, parent, args[0], loc, rot, color)


# ---------- budowa ----------

def _fresh_scene():
	old = bpy.data.scenes.get(SCENE)
	if old:
		for obj in list(old.objects):
			bpy.data.objects.remove(obj, do_unlink=True)
		bpy.data.scenes.remove(old)
	for obj in list(bpy.data.objects):  # resztki po poprzednim podgladzie
		if obj.name.startswith(PREFIX) and not obj.users_scene:
			bpy.data.objects.remove(obj, do_unlink=True)
	scene = bpy.data.scenes.new(SCENE)
	if bpy.context.window:
		bpy.context.window.scene = scene
	scene.render.fps = FPS
	for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
		try:
			scene.render.engine = engine
			break
		except TypeError:
			continue
	scene.render.resolution_x = 640
	scene.render.resolution_y = 360
	scene.world = bpy.data.worlds.new(PREFIX + "World")
	scene.world.use_nodes = True
	scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.08, 1)
	return scene


def build():
	"""Ksiadz w pozie stojacej, bez rekwizytow. Zwraca Rig z uchwytami do wezlow."""
	rig = Rig(_fresh_scene())
	rig.conv = rig.empty("GodotToBlender")
	rig.conv.rotation_mode = "XYZ"
	rig.conv.rotation_euler = Euler((math.radians(90), 0, 0), "XYZ")
	# CharacterBody3D stoi 1.1 nad ziemia, Model bierze yaw sceny, Body zgina sie w pasie
	rig.player = rig.empty("Player", rig.conv, loc=(0, 1.1, 0))
	rig.model = rig.empty("Model", rig.player)
	rig.body = rig.empty("Body", rig.model, loc=(0, -1.1, 0))
	# rekwizyty trzymane oburacz nie pochylaja sie z tulowiem, wiec kat kija liczy sie do ziemi
	rig.props = rig.empty("Props", rig.model, loc=(0, -1.1, 0))
	for spec in PARTS:
		obj = rig.part(spec, rig.body)
		if spec[1] == "But_P":
			rig.shoe_right = obj
		elif spec[1] == "But_L":
			rig.shoe_left = obj
		elif spec[1] == "Sutanna_dol":
			rig.cassock = obj
	rig.chest = rig.empty("Piers", rig.body, loc=(0, CHEST_Y, 0))
	for spec in CHEST_PARTS:
		rig.part(spec, rig.chest)
	rig.arm_right, rig.elbow_right, rig.hand_right = _build_arm(rig, 1, "P")
	rig.arm_left, rig.elbow_left, rig.hand_left = _build_arm(rig, -1, "L")
	rig.phone = rig.box("Telefon", rig.hand_right, (0.14, 0.26, 0.03),
		(0, 0.12, 0.08), (-17, 0, 0), color="PHONE")
	rig.box("Ziemia", rig.conv, (8, 0.04, 8), (0, -0.02, 0), color="GRASS")
	return rig


def _build_arm(rig, side, tag):
	"""Odpowiednik player.gd::_build_arm: bark -> lokiec -> dlon, w zerze zwisa w dol."""
	shoulder = rig.empty("Bark_" + tag, rig.chest, loc=shoulder_pos(side))
	# kula barku ma promien wiekszy niz odstep barku od tulowia, wiec w niego wchodzi
	# i nie zostaje szpara miedzy reka a cialem
	rig.sphere("Bark_bryla_" + tag, shoulder, 0.17, (0, 0, 0), color="CASSOCK_SLEEVE")
	rig.cyl("Ramie_" + tag, shoulder, 0.09, 0.09, UPPER_ARM, (0, -UPPER_ARM / 2.0, 0),
		segments=8, color="CASSOCK_SLEEVE")
	elbow = rig.empty("Lokiec_" + tag, shoulder, loc=(0, -UPPER_ARM, 0))
	# kula w stawie zakrywa szczeline miedzy ramieniem a przedramieniem przy zgieciu
	rig.sphere("Lokiec_bryla_" + tag, elbow, 0.09, (0, 0, 0), color="CASSOCK_SLEEVE")
	rig.cyl("Przedramie_" + tag, elbow, 0.08, 0.08, FOREARM, (0, -FOREARM / 2.0, 0),
		segments=8, color="CASSOCK_SLEEVE")
	hand = rig.empty("Dlon_" + tag, elbow, loc=(0, -FOREARM, 0))
	rig.sphere("Dlon_bryla_" + tag, hand, 0.13, (0, 0, 0), color="SKIN")
	return shoulder, elbow, hand


def _to_chest(rig, point):
	"""Punkt z ukladu rekwizytow na uklad piersi - tak samo jak player.gd::_to_chest."""
	return rig.chest.matrix_local.inverted() @ (rig.body.matrix_local.inverted()
		@ (rig.props.matrix_local @ Vector(point)))


def reach_arm(rig, side, target):
	"""IK dwoch kosci, odpowiednik player.gd::_reach. target w ukladzie tulowia."""
	arm = rig.arm_right if side == 1 else rig.arm_left
	elbow = rig.elbow_right if side == 1 else rig.elbow_left
	shoulder = shoulder_pos(side)
	to_target = Vector(target) - shoulder
	dist = max(abs(UPPER_ARM - FOREARM) + 0.01,
		min(to_target.length, UPPER_ARM + FOREARM - 0.01))
	axis = to_target.normalized()
	cos_a = (UPPER_ARM * UPPER_ARM + dist * dist - FOREARM * FOREARM) / (2.0 * UPPER_ARM * dist)
	angle = math.acos(max(-1.0, min(1.0, cos_a)))
	pole_def = ELBOW_POLE_R if side == 1 else ELBOW_POLE_L
	pole = Vector((pole_def.x * side, pole_def.y, pole_def.z))
	perp = pole - axis * pole.dot(axis)
	perp = perp.normalized() if perp.length > 0.001 else axis.cross(Vector((1, 0, 0))).normalized()
	elbow_pos = shoulder + (axis * math.cos(angle) + perp * math.sin(angle)) * UPPER_ARM
	hand_pos = shoulder + axis * dist
	down = Vector((0, -1, 0))
	arm.rotation_mode = "QUATERNION"
	arm.rotation_quaternion = down.rotation_difference((elbow_pos - shoulder).normalized())
	elbow.rotation_mode = "QUATERNION"
	elbow.rotation_quaternion = down.rotation_difference(
		(arm.rotation_quaternion.inverted() @ (hand_pos - elbow_pos)).normalized())
	return {"lokiec_poz": elbow_pos, "dlon_poz": hand_pos, "dystans": to_target.length,
		"lokiec_zgiecie": math.degrees((elbow_pos - shoulder).angle(hand_pos - elbow_pos)),
		"poza_zasiegiem": to_target.length > UPPER_ARM + FOREARM - 0.01}


def reach_hands(rig, target_right, target_left):
	"""Odpowiednik player.gd::reach_hands - cele podane w ukladzie rekwizytow."""
	return (reach_arm(rig, 1, _to_chest(rig, target_right)),
		reach_arm(rig, -1, _to_chest(rig, target_left)))


def set_pose(rig, pose):
	"""Odpowiednik player.gd::set_pose - tylko pozy, ktore da sie pokazac statycznie."""
	rig.model.location = Vector((0, 0, 0))
	rig.body.rotation_quaternion = _godot_quat(0, 0, 0)
	rig.chest.rotation_quaternion = _godot_quat(0, 0, 0)
	rig.body.scale = Vector((1, 1, 1))
	visible = pose in ("stand", "")
	rig.phone.hide_viewport = rig.phone.hide_render = not visible
	for node in (rig.arm_right, rig.elbow_right, rig.arm_left, rig.elbow_left):
		node.rotation_mode = "QUATERNION"
		node.rotation_quaternion = (1, 0, 0, 0)
	if visible:
		reach_arm(rig, 1, PHONE_HAND)
	if pose == "kneel":
		rig.body.scale = Vector((1, 0.78, 1))
		rig.chest.rotation_quaternion = _godot_quat(16, 0, 0)
	elif pose == "sit":
		rig.body.scale = Vector((1, 0.72, 1))
		rig.chest.rotation_quaternion = _godot_quat(6, 0, 0)
		rig.model.location = Vector((0, -0.3, 0))
	elif pose == "work":
		rig.body.scale = Vector((1, 0.94, 1))
		rig.chest.rotation_quaternion = _godot_quat(WORK_BODY, 0, 0)


def add_broom(rig, tilt=None, yaw=None, length=None, anchor=None):
	"""Odpowiednik activity_scene.gd::_broom(): miotla wisi na wezle rekwizytow, ktory nie
	pochyla sie razem z tulowiem, wiec kat kija to wprost kat do pionu."""
	tilt = BROOM_TILT if tilt is None else tilt
	yaw = BROOM_YAW if yaw is None else yaw
	length = BROOM_LENGTH if length is None else length
	anchor = BROOM_ANCHOR if anchor is None else anchor
	rig.broom = rig.empty("Miotla", rig.props, loc=anchor, rot=(-tilt, yaw, 0))
	rig.cyl("Miotla_kij", rig.broom, 0.04, 0.04, length,
		(0, BROOM_GRIP - length / 2.0, 0), segments=5, color="TRUNK")
	rig.box("Miotla_glowka", rig.broom, (0.38, 0.16, 0.14),
		(0, BROOM_GRIP - length + 0.06, 0.02), (tilt, 0, 0), color="CROSS")
	return rig.broom


def stick_dir(tilt):
	"""Kierunek kija w dol dla zadanego kata do pionu - jak activity_scene::_stick_dir."""
	return _godot_quat(-tilt, BROOM_YAW, 0) @ Vector((0, -1, 0))


def brush_base():
	"""Punkt styku szczotki z ziemia w spoczynku, z ktorego prowadzimy animacje."""
	down = stick_dir(BROOM_TILT)
	return (Vector(BROOM_ANCHOR) + down * (BROOM_LENGTH - BROOM_GRIP - 0.06)
		- Vector((0, BROOM_HEAD_HALF, 0)))


def sweep_frame(rig, elapsed):
	"""Jedna klatka _run_sweep: szczotka sunie po ziemi, w drodze powrotnej odrywa sie
	i kij sie kladzie, a dlonie ida za chwytami."""
	phase = elapsed * SWEEP_SPEED
	swing = math.sin(phase)
	back = max(0.0, -math.cos(phase))
	tilt = BROOM_TILT + SWEEP_TILT * back
	down = stick_dir(tilt)
	base = brush_base()
	push = Vector((stick_dir(BROOM_TILT).x, 0.0, stick_dir(BROOM_TILT).z)).normalized()
	contact = base + push * (swing * SWEEP_PUSH) + Vector((0, SWEEP_LIFT * back, 0))
	anchor = contact + Vector((0, BROOM_HEAD_HALF, 0)) - down * (BROOM_LENGTH - BROOM_GRIP - 0.06)
	rig.broom.location = anchor
	rig.broom.rotation_quaternion = _godot_quat(-tilt, BROOM_YAW, 0)
	bpy.context.view_layer.update()
	arms = reach_hands(rig, anchor, anchor + down * BROOM_SPREAD)
	rig.model.rotation_quaternion = _godot_quat(0, math.degrees(swing * SWEEP_BODY_YAW), 0)
	return {"faza": round(swing, 3), "powrot": round(back, 3), "tilt": round(tilt, 1),
		"arm_P": arms[0], "arm_L": arms[1]}


def walk_frame(rig, phase):
	"""Odpowiednik player.gd::walk: kroki widac po butach, sutannie i lekkim kolysaniu.

	Ksiadz nie ma nog, wiec krok pokazujemy trzema rzeczami naraz: buty jada w przod
	i w tyl na zmiane, cale cialo kolysze sie na boki, a rece odchylaja sie w przeciwfazie
	do butow. Bez tego postac sunie po ziemi jak duch.
	"""
	step = math.sin(phase)
	rig.shoe_right.location = Vector((0.16, 0.05 + max(0.0, step) * WALK_LIFT, 0.05 + step * WALK_STRIDE))
	rig.shoe_left.location = Vector((-0.16, 0.05 + max(0.0, -step) * WALK_LIFT, 0.05 - step * WALK_STRIDE))
	rig.model.location = Vector((0, abs(math.sin(phase * 2.0)) * WALK_BOB, 0))
	rig.body.rotation_quaternion = _godot_quat(0, 0, math.degrees(step * WALK_ROLL))
	rig.cassock.rotation_quaternion = _godot_quat(0, 0, math.degrees(-step * WALK_HEM))
	reach_arm(rig, 1, Vector((SHOULDER.x, SHOULDER.y - UPPER_ARM - FOREARM * 0.92,
		SHOULDER.z - step * WALK_SWING)))
	reach_arm(rig, -1, Vector((-SHOULDER.x, SHOULDER.y - UPPER_ARM - FOREARM * 0.92,
		SHOULDER.z + step * WALK_SWING)))
	return {"krok": round(step, 3)}


def animate_walk(rig, steps=4):
	"""Piecze cykl chodu na osi czasu: tyle krokow, ile podano."""
	frames = int(round(steps * FPS * 0.5))
	rig.scene.frame_start = 1
	rig.scene.frame_end = frames
	for f in range(1, frames + 1):
		walk_frame(rig, (f - 1) / float(frames) * steps * math.pi)
		for node in (rig.shoe_right, rig.shoe_left):
			node.keyframe_insert("location", frame=f)
		rig.model.keyframe_insert("location", frame=f)
		rig.body.keyframe_insert("rotation_quaternion", frame=f)
		rig.cassock.keyframe_insert("rotation_quaternion", frame=f)
		for node in (rig.arm_right, rig.elbow_right, rig.arm_left, rig.elbow_left):
			node.keyframe_insert("rotation_quaternion", frame=f)
	return frames


# ---------- solver pozy ----------

def body_radius(y):
	"""Promien bryly ciala na danej wysokosci - sutanna to stozek, wyzej tors i glowa."""
	if y <= 1.5:
		return 0.52 + (0.34 - 0.52) * (y / 1.5)
	if y <= 2.05:
		return 0.34
	return 0.2


def outside_body(p, margin=0.06):
	return math.hypot(p.x, p.z) >= body_radius(p.y) + margin


def _segment_clear(a, b, margin, samples=12):
	"""Czy odcinek (np. przedramie albo kij) omija bryle ciala."""
	for i in range(samples + 1):
		p = a + (b - a) * (i / float(samples))
		if p.y > 0.1 and not outside_body(p, margin):
			return False
	return True


def fit_broom(rig, grip_right, grip_left):
	"""Z dwoch chwytow (w ukladzie tulowia) wylicza ustawienie miotly do .gd.

	Latwiej wskazac, gdzie maja byc dlonie, niz zgadywac kat kija: kij to prosta przez
	oba chwyty, a kotwica to gorny chwyt. Zwraca liczby, ktore wpisujemy do
	activity_scene.gd: kat do pionu, skret, dlugosc i odstep rak.
	"""
	set_pose(rig, "work")
	bpy.context.view_layer.update()
	to_props = (rig.props.matrix_local.inverted() @ rig.body.matrix_local
		@ rig.chest.matrix_local)
	a = to_props @ Vector(grip_right)
	b = to_props @ Vector(grip_left)
	d = (b - a).normalized()
	tilt = math.degrees(math.acos(max(-1.0, min(1.0, -d.y))))
	yaw = math.degrees(math.atan2(d.x, d.z))
	below = (a.y - 0.08) / -d.y          # ile kija pod kotwica, zeby glowka siegnela ziemi
	head = a + d * below
	return {"broom_tilt": round(tilt, 1), "broom_yaw": round(yaw, 1),
		"broom_anchor": [round(v, 3) for v in a],
		"BROOM_SPREAD": round((b - a).length, 3),
		"broom_length": round(below + BROOM_GRIP + 0.06, 3),
		"zasieg_P": round((Vector(grip_right) - shoulder_pos(1)).length, 3),
		"zasieg_L": round((Vector(grip_left) - shoulder_pos(-1)).length, 3),
		"max_zasieg": round(UPPER_ARM + FOREARM, 3),
		"glowka_przed": round(head.z, 2), "glowka_bok": round(head.x, 2)}


def tune_length(rig):
	"""Dlugosc miotly, przy ktorej spod glowki dokladnie dotyka ziemi - mierzona na bryle."""
	def zmin(length):
		if rig.broom:
			for obj in list(rig.broom.children) + [rig.broom]:
				bpy.data.objects.remove(obj, do_unlink=True)
			rig.broom = None
		add_broom(rig, length=length)
		bpy.context.view_layer.update()
		head = [o for o in rig.broom.children if "glowka" in o.name][0]
		return min((head.matrix_world @ Vector(v)).z for v in head.bound_box)

	lo, hi = 0.8, 3.0
	for _ in range(40):
		mid = (lo + hi) / 2.0
		if zmin(mid) > 0.0:
			lo = mid
		else:
			hi = mid
	length = round((lo + hi) / 2.0, 3)
	zmin(length)
	return length


def check_sweep(rig, samples=13):
	"""Przeglada caly cykl i zwraca to, co moze sie zepsuc: zasieg rak, zgiecia lokci,
	wchodzenie rak i kija w tulow, odrywanie glowki od ziemi."""
	period = 2.0 * math.pi / SWEEP_SPEED
	worst = {"zasieg_P": 0.0, "zasieg_L": 0.0, "zgiecie_P": [999, -999], "zgiecie_L": [999, -999],
		"luz_ciala": 9.0, "luz_kija": 9.0, "glowka_zmin": [9.0, -9.0]}
	head = [o for o in rig.broom.children if "glowka" in o.name][0]
	for i in range(samples):
		frame = sweep_frame(rig, period * i / float(samples - 1))
		bpy.context.view_layer.update()
		for tag, arm in (("P", frame["arm_P"]), ("L", frame["arm_L"])):
			worst["zasieg_" + tag] = max(worst["zasieg_" + tag], arm["dystans"])
			bend = arm["lokiec_zgiecie"]
			worst["zgiecie_" + tag] = [min(worst["zgiecie_" + tag][0], round(bend, 1)),
				max(worst["zgiecie_" + tag][1], round(bend, 1))]
			side = 1 if tag == "P" else -1
			# ramiona licza sie w ukladzie piersi, a bryla ciala w ukladzie tulowia
			to_body = rig.chest.matrix_local
			for a, b in ((shoulder_pos(side), arm["lokiec_poz"]), (arm["lokiec_poz"], arm["dlon_poz"])):
				for j in range(9):
					p = to_body @ (a + (b - a) * (j / 8.0))
					worst["luz_ciala"] = min(worst["luz_ciala"],
						math.hypot(p.x, p.z) - body_radius(p.y))
		to_body_from_props = rig.body.matrix_local.inverted() @ rig.props.matrix_local
		top = to_body_from_props @ (rig.broom.matrix_local @ Vector((0, BROOM_GRIP, 0)))
		bottom = to_body_from_props @ (rig.broom.matrix_local @ Vector((0, BROOM_GRIP - BROOM_LENGTH, 0)))
		for j in range(21):
			p = top + (bottom - top) * (j / 20.0)
			if p.y > 0.15:
				worst["luz_kija"] = min(worst["luz_kija"], math.hypot(p.x, p.z) - body_radius(p.y))
		z = min((head.matrix_world @ Vector(v)).z for v in head.bound_box)
		worst["glowka_zmin"] = [min(worst["glowka_zmin"][0], round(z, 3)),
			max(worst["glowka_zmin"][1], round(z, 3))]
		dz = abs((rig.hand_right.matrix_world.translation - rig.hand_left.matrix_world.translation).z)
		worst.setdefault("roznica_wysokosci_rak", [9.0, -9.0])
		worst["roznica_wysokosci_rak"] = [min(worst["roznica_wysokosci_rak"][0], round(dz, 3)),
			max(worst["roznica_wysokosci_rak"][1], round(dz, 3))]
	worst["zasieg_P"] = round(worst["zasieg_P"], 3)
	worst["zasieg_L"] = round(worst["zasieg_L"], 3)
	worst["max_zasieg"] = UPPER_ARM + FOREARM
	worst["luz_ciala"] = round(worst["luz_ciala"], 3)
	worst["luz_kija"] = round(worst["luz_kija"], 3)
	return worst


def _fcurves(action):
	if hasattr(action, "fcurves"):  # Blender < 4.4
		return list(action.fcurves)
	return [fc for layer in action.layers for strip in layer.strips
		for bag in strip.channelbags for fc in bag.fcurves]


def animate_sweep(rig):
	"""Piecze klatki _run_sweep: pozycja miotly, katy obu rak i skret tulowia."""
	period = 2.0 * math.pi / SWEEP_SPEED
	frames = int(round(period * CYCLES * FPS))
	rig.scene.frame_start = 1
	rig.scene.frame_end = frames
	for f in range(1, frames + 1):
		sweep_frame(rig, (f - 1) / float(FPS))
		rig.broom.keyframe_insert("location", frame=f)
		rig.broom.keyframe_insert("rotation_quaternion", frame=f)
		rig.model.keyframe_insert("rotation_quaternion", frame=f)
		for node in (rig.arm_right, rig.elbow_right, rig.arm_left, rig.elbow_left):
			node.keyframe_insert("rotation_quaternion", frame=f)
	for node in (rig.broom, rig.model, rig.arm_right, rig.elbow_right, rig.arm_left, rig.elbow_left):
		for fc in _fcurves(node.animation_data.action):
			for kp in fc.keyframe_points:
				kp.interpolation = "LINEAR"  # ruch jest juz w kluczach, Bezier by go wygladzil drugi raz
	return frames


def add_cameras(rig):
	"""Dwie kamery: swobodna perspektywa do ogladania i ortho ustawiona jak camera_rig.gd."""
	sun_data = bpy.data.lights.new(PREFIX + "Sun", type="SUN")
	sun_data.energy = 4.0
	sun = rig.link(bpy.data.objects.new("Sun", sun_data))
	sun.rotation_euler = Euler((math.radians(52), 0, math.radians(40)), "XYZ")
	fill_data = bpy.data.lights.new(PREFIX + "Fill", type="AREA")
	fill_data.energy = 300
	fill_data.size = 6
	fill = rig.link(bpy.data.objects.new("Fill", fill_data))
	fill.location = Vector((-5, -4, 4))
	fill.rotation_mode = "QUATERNION"
	fill.rotation_quaternion = (Vector((0, 0, 1.2)) - fill.location).to_track_quat("-Z", "Y")

	free_data = bpy.data.cameras.new(PREFIX + "Cam")
	free_data.lens = 50
	free = rig.link(bpy.data.objects.new("Cam", free_data))
	free.location = Vector((5.2, -5.6, 3.4))
	free.rotation_mode = "QUATERNION"
	free.rotation_quaternion = (Vector((0, 0, 1.35)) - free.location).to_track_quat("-Z", "Y")

	# kierunek patrzenia rigu z gry: pitch -35, yaw 35 w Godocie, przeliczone na Blendera
	pitch, yaw = math.radians(-35.0), math.radians(35.0)
	fwd_godot = (Matrix.Rotation(yaw, 3, "Y") @ Matrix.Rotation(pitch, 3, "X")) @ Vector((0, 0, -1))
	fwd = Vector((fwd_godot.x, -fwd_godot.z, fwd_godot.y))
	game_data = bpy.data.cameras.new(PREFIX + "CamGame")
	game_data.type = "ORTHO"
	game_data.sensor_fit = "VERTICAL"
	game_data.ortho_scale = 5.0  # w grze scena ustawia zoom 10; blizej widac detal
	game = rig.link(bpy.data.objects.new("CamGame", game_data))
	game.location = Vector((0, 0, 1.1)) - fwd * 14.0
	game.rotation_mode = "QUATERNION"
	game.rotation_quaternion = fwd.to_track_quat("-Z", "Y")
	rig.scene.camera = game
	return game


def render_sequence(rig, out_dir):
	"""Klatki animacji do plikow - do skladania podgladu poza Blenderem."""
	rig.scene.render.image_settings.file_format = "PNG"
	rig.scene.render.filepath = os.path.join(out_dir, "f_")
	bpy.ops.render.render(animation=True)
	return rig.scene.render.filepath


def main(scene="sweep"):
	"""scene: "sweep" - zamiatanie, "walk" - cykl chodu."""
	rig = build()
	if scene == "walk":
		set_pose(rig, "stand")
		rig.phone.hide_viewport = rig.phone.hide_render = True
		frames = animate_walk(rig)
		add_cameras(rig)
		print("scena %s gotowa: %d klatek chodu" % (SCENE, frames))
		return rig
	set_pose(rig, "work")
	add_broom(rig)
	frames = animate_sweep(rig)
	add_cameras(rig)
	print("scena %s gotowa: %d klatek, %.2f s na pociagniecie"
		% (SCENE, frames, math.pi / SWEEP_SPEED))
	return rig


if __name__ == "__main__":
	main("walk" if "--walk" in sys.argv else "sweep")
