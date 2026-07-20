#!/usr/bin/env bash
# Headless KAN-2 sim test runner.
# Requires a Godot 4 binary: $GODOT_BIN, or `godot` on PATH.
# Exit codes: 0 = all tests passed, 1 = failures, 3 = SKIP (no binary).
set -u

GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
	GODOT="$(command -v godot || true)"
fi

if [ -z "$GODOT" ]; then
	echo "SKIP: no Godot 4 binary available — sim tests NOT executed (this is not a pass)"
	echo "      install Godot 4.7 and expose it as 'godot' on PATH or via \$GODOT_BIN"
	exit 3
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Fresh clones have no .godot/ cache, and a STALE cache silently breaks
# class_name lookups for scripts added since it was built (parse errors +
# a hung runner). Re-import when the cache is missing OR any .gd is newer.
CACHE="$PROJECT_DIR/.godot/global_script_class_cache.cfg"
if [ ! -f "$CACHE" ] || [ -n "$(find "$PROJECT_DIR/simulation" "$PROJECT_DIR/tests" "$PROJECT_DIR/controller" -name '*.gd' -newer "$CACHE" -print -quit 2>/dev/null)" ]; then
	"$GODOT" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1 || true
fi

"$GODOT" --headless --path "$PROJECT_DIR" -s tests/test_runner.gd
exit $?
