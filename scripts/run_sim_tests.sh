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

# Run the suite, keeping the full output visible while we also inspect it.
# GDScript reports a runtime/parse error on stderr and CARRIES ON — the runner
# sees no recorded failure, so an aborted test could report PASS. The runner
# now fails a zero-check test itself; this is the outer guard for anything that
# errors WITHOUT costing a check (a broken _post sweep, a bad class_name, a
# parse error in a file that never got to run).
OUTPUT="$("$GODOT" --headless --path "$PROJECT_DIR" -s tests/test_runner.gd 2>&1)"
STATUS=$?
printf '%s\n' "$OUTPUT"

if printf '%s' "$OUTPUT" | grep -qiE "SCRIPT ERROR|Parse Error|Cannot call method|Invalid access"; then
	echo ""
	echo "==== RUNNER GUARD: engine errors appeared during the run ===="
	echo "A green suite is NOT green when the engine logged errors — a test that"
	echo "aborts mid-run records no failure. Offending lines:"
	printf '%s' "$OUTPUT" | grep -inE "SCRIPT ERROR|Parse Error|Cannot call method|Invalid access" | head -20
	exit 1
fi

exit $STATUS
