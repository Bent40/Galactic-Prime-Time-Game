#!/usr/bin/env bash
# Render every mockup frame to PNG at 1600x1000 @2x with headless Chromium.
# The headless viewport is ~95px shorter than --window-size in this build, so
# render with a 1120-tall window and crop to the top 2000 device rows.
set -e
cd "$(dirname "$0")"
CHROME="${CHROME:-/opt/pw-browsers/chromium}"
for f in hud-ready hud-targeting hud-dodge-ask explore-branch mod-center; do
  "$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
    --window-size=1600,1120 --force-device-scale-factor=2 \
    --screenshot="$f.png" "file://$PWD/$f.html" 2>/dev/null
  python3 crop_png.py "$f.png" 2000
  echo "rendered $f.png"
done
