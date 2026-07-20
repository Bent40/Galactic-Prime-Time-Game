# Galactic Prime Time (working title)

2.5D tactical RPG: a dungeon gameshow run as a table in the gods' **Cosmic Casino**.
Deterministic command-stream combat on a shared Moment clock, per-body-part damage, an
audience that is an economy, and a verdict instead of a victory screen.

**Orientation for contributors/agents:** read `CLAUDE.md`, then `docs/DIRECTION.md`
(decided direction), `docs/gdd/gdd.md` (design), `docs/rules-addendum.md` (canonical
digital rules R0–R19).

## Run from a clean clone

```bash
# 1. Godot 4.7 (containers: installs 4.7.1 from the SourceForge mirror)
bash scripts/setup_godot.sh          # or use your own godot 4.7+ on PATH / $GODOT_BIN

# 2. Verify the engine honestly (exit 3 = SKIPPED, which is NOT a pass)
python3 scripts/validate_seeds.py    # seed-data integrity
bash scripts/run_sim_tests.sh        # headless sim suite

# 3. Launch (main scene boots the controller wiring and reports engine status)
godot                                # or: godot --headless --quit-after 3
```

## Layout

`simulation/` headless deterministic model (RefCounted, command-stream only) ·
`controller/` GameController autoload + (in progress) DAL/saves ·
`scenes/` presentation, talks only through the `Game` autoload signals ·
`data/` validated JSON seeds · `tests/` auto-discovered suite · `docs/` the design corpus.

## Art pipeline

GPT-generated stills (canon prompt blocks: `docs/art/generation-prompts.md`) →
`scripts/spritify.py` (alpha extract, palette quantize, nearest-neighbor resize).
