# KAN3-S3 spike notes (2026-07-18)

- `boot-field.png` — live render of the actual boot demo (real sim, 11 events, hash
  shown): hex grid 12×8, four combatants with name plates, per-part HP pips
  (green→red by fraction, gray = disabled), condition dots stacked by tier
  (Roach: bleeding T1 over a damaged torso pip), Moment/tick header, shock rings and
  death X supported (not present in this frame).
- Rendered under **xvfb + software GL** (`xvfb-run godot --rendering-driver opengl3 --
  --shot`) — the screenshot path is scripted and repeatable.
- **Frame-time measurement: DEFERRED honestly** — software GL in a container measures
  the CPU rasterizer, not the target hardware. Measure AC3 on the owner's machine
  (scene cost is trivial: one polyline grid + ~10 draw calls per combatant).
- Styling: everything here is placeholder-by-ruling (ComfyUI shelved 2026-07-18; free
  placeholders interim). All look decisions belong to the KAN-6 mockup gate; the GPT
  arena style frame is the reference. Readability verdicts for KAN-6: name plates +
  pips read well at 1024×600; condition dots need to grow ~2× at real resolutions;
  the clock header wants broadcast chrome, not debug text.
