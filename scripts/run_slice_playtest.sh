#!/usr/bin/env bash
# Headless slice playtest driver — plays the vertical-slice encounter through the
# real GameController and prints a broadcast trace.
# Requires a Godot 4.7 binary: $GODOT_BIN, or `godot` on PATH.
# Exit codes: 0 = clean run (win + no rejections), 2 = rejection/engine blocker,
#             other = Godot error, 3 = SKIP (no binary).
set -u

GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
	GODOT="$(command -v godot || true)"
fi

if [ -z "$GODOT" ]; then
	echo "SKIP: no Godot 4 binary available — slice playtest NOT executed (this is not a pass)"
	echo "      install Godot 4.7 and expose it as 'godot' on PATH or via \$GODOT_BIN"
	exit 3
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Fresh clones have no .godot/ cache, and a STALE cache silently breaks class_name
# lookups for scripts added since it was built (parse errors + a hung run).
# Re-import when the cache is missing OR any .gd is newer.
CACHE="$PROJECT_DIR/.godot/global_script_class_cache.cfg"
if [ ! -f "$CACHE" ] || [ -n "$(find "$PROJECT_DIR/simulation" "$PROJECT_DIR/controller" "$PROJECT_DIR/scripts" -name '*.gd' -newer "$CACHE" -print -quit 2>/dev/null)" ]; then
	"$GODOT" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1 || true
fi

"$GODOT" --headless --path "$PROJECT_DIR" -s scripts/slice_playtest.gd
exit $?
