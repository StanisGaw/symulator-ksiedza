#!/usr/bin/env bash
# Przebudowuje wszystkie modele z scripts/blender/*.py do assets/models/*.glb.
# Uruchom po każdej zmianie w modelu; wynikowe .glb trzymamy w repo, żeby gra
# odpalała się bez Blendera.
set -euo pipefail

BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
DIR="$(cd "$(dirname "$0")" && pwd)"

for f in "$DIR"/*.py; do
	[ "$(basename "$f")" = "lib.py" ] && continue
	echo "== $(basename "$f")"
	"$BLENDER" --background --python "$f" 2>&1 | grep -E "^zapisano|Error|Traceback" || true
done
