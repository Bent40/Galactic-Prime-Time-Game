#!/usr/bin/env bash
# Render the demo-slice combat HUD (ui/hud/combat_hud.tscn) to a PNG for visual
# comparison against docs/ux-designs/demo-slice-2026-07-19/renders/combat-hud.png.
#
# Uses xvfb (NOT --headless) so Godot gets a real GL renderer and can capture the
# framebuffer. The xvfb screen must be >= the 1600x1000 window or the capture is
# clipped. ALSA "audio driver failed" lines in the log are harmless.
#
# Requires a Godot 4.5 binary: $GODOT_BIN, or `godot` on PATH.
# Output: $HUD_OUT if set, else <project>/hud_render.png.
# Exit codes: 0 = rendered, 3 = SKIP (no binary).
set -u

GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
	GODOT="$(command -v godot || true)"
fi
if [ -z "$GODOT" ]; then
	echo "SKIP: no Godot 4 binary — HUD not rendered (this is not a pass)"
	echo "      install Godot 4.5 and expose it as 'godot' on PATH or via \$GODOT_BIN"
	exit 3
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${HUD_OUT:-$PROJECT_DIR/hud_render.png}"
XVFB_SCREEN='-screen 0 1920x1200x24'

# Fresh/stale .godot cache breaks class_name + new-script lookups; reimport when
# the cache is missing or any presentation/script .gd is newer than it.
CACHE="$PROJECT_DIR/.godot/global_script_class_cache.cfg"
if [ ! -f "$CACHE" ] || [ -n "$(find "$PROJECT_DIR/ui" "$PROJECT_DIR/scripts" "$PROJECT_DIR/controller" "$PROJECT_DIR/simulation" -name '*.gd' -newer "$CACHE" -print -quit 2>/dev/null)" ]; then
	xvfb-run -s "$XVFB_SCREEN" -a "$GODOT" --path "$PROJECT_DIR" --import >/dev/null 2>&1 || true
fi

HUD_OUT="$OUT" xvfb-run -s "$XVFB_SCREEN" -a "$GODOT" --path "$PROJECT_DIR" -s scripts/hud_preview.gd
STATUS=$?
echo "render -> $OUT"
exit $STATUS
