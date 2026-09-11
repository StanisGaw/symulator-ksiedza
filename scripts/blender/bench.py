"""Lawka parkowa przed kosciolem - zastepuje cztery boxy z outside.gd.

Modelujemy w Blenderze (Z w gore), eksport sam przekreca na Y-up Godota.
Wymiary trzymamy z poprzedniej wersji z brył: 1.8 szerokosci, siedzisko na 0.5.
"""

import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lib

lib.reset()

W = 1.8       # szerokosc lawki
SEAT_Z = 0.5  # wysokosc siedziska

# siedzisko: cztery deski ze szczelinami, zamiast jednej plyty
for i in range(4):
	y = -0.21 + i * 0.14
	slat = lib.cube((W, 0.11, 0.045), (0, y, SEAT_Z), mat="BENCH")
	lib.bevel(slat, width=0.012)

# oparcie: trzy deski odchylone do tylu
for i in range(3):
	z = SEAT_Z + 0.18 + i * 0.16
	slat = lib.cube((W, 0.04, 0.12), (0, 0.24 + i * 0.035, z), mat="BENCH")
	slat.rotation_euler = (0.22, 0, 0)  # lekki odchyl oparcia
	lib.bevel(slat, width=0.01)

# nogi: zeliwne boki, lustrzane wzgledem srodka
leg = lib.cube((0.08, 0.5, SEAT_Z), (-W / 2 + 0.14, 0, SEAT_Z / 2), mat="BENCH_LEG")
lib.bevel(leg, width=0.015)
lib.mirror(leg)

# podparcie oparcia, wyrastajace z tylnej nogi
prop = lib.cube((0.07, 0.06, 0.62), (-W / 2 + 0.14, 0.26, SEAT_Z + 0.28), mat="BENCH_LEG")
prop.rotation_euler = (0.22, 0, 0)
lib.bevel(prop, width=0.012)
lib.mirror(prop)

lib.export("bench")
