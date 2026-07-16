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
	echo "      install Godot 4.5 and expose it as 'godot' on PATH or via \$GODOT_BIN"
	exit 3
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Fresh clones have no .godot/ cache; build it so class_name lookups
# (CombatSim, SimTestBase, ...) resolve in headless -s mode.
if [ ! -f "$PROJECT_DIR/.godot/global_script_class_cache.cfg" ]; then
	"$GODOT" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1 || true
fi

"$GODOT" --headless --path "$PROJECT_DIR" -s tests/test_runner.gd
exit $?
