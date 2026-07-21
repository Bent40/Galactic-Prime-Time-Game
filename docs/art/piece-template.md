# Themed Game-Piece — 3D Piece Spec & Identity System

> **STATUS: CANDIDATE / EXPLORATION — direction updated 2026-07-21.** Owner ruled this
> session: **pieces are 3D models rendered through a pixel-art lens** (not hand-drawn 2D
> sprites). This **supersedes the 2D pixel-canvas approach** of the previous revision — the
> 64/128 canvas contract is kept only as the *conceptual* registration/identity reference (see
> `piece-template.html`). Technical companion to
> [`../design/art-direction-pieces.md`](../design/art-direction-pieces.md). **Presentation-layer
> only** — the deterministic headless sim is untouched. Palette / scale values PROVISIONAL.

## Direction: 3D pieces · pixel-render identity · multi-camera

Why 3D (decided this session): the pieces are geometrically trivial (a pawn is a surface of
revolution, a mahjong tile a rounded box, a totem stacked primitives), and going 3D **dissolves
two hard problems at once**:

- **Perspective** — one model serves *every* camera. The tactical high-3/4 battle view **and** a
  behind-and-above exploration view come from the same asset; no per-angle sprite sets.
- **Lighting / shadows** — real-time lights and shadows are native, so "dark hallways with
  changing light" is free; no baked normal maps or occluder authoring.

**Art identity is preserved by rendering, not by modelling.** Model in 3D; render through the
pixel pipeline (§3) so the game still *reads* as pixel art. References: Square Enix **HD-2D**
(Octopath, and **Triangle Strategy** — a tactics game) proves pixel identity + 3D depth +
dynamic light + a tactical camera ship together; **Delver** proves full 3D geometry rendered as
pixel art for a dungeon crawler.

## 1. Piece geometry & registration (3D)

- **Model low-poly.** The pixel-render filter embraces low detail — simple is a feature.
- **Base pivot = the anchor.** Model origin at the **base-centre**, sitting on the hex-cell
  centre. (3D heir of the old ⟨32,58⟩ anchor — every piece and every gear overlay registers to
  it.)
- **One scale unit.** Define **1 hex = N units** plus a target silhouette height, so every piece
  sits uniformly regardless of theme.
- **Clear silhouette.** Pieces must read from the tactical camera height (3D heir of "reads at
  1×"). Simple, distinct shapes.
- **Gear sockets.** Named attachment points (empties/bones): `base` · `weapon` (hand) · `head`
  (crown) · `shoulders` (cloak) · `emblem` (face). Gear = a mesh parented to a socket (3D heir of
  the 2D overlay slots).

## 2. Cameras (one scene, many views)

- **Tactical (battle):** high-3/4 looking down, **orthographic** preferred — clean grid, uniform
  piece size regardless of position (the Into the Breach read).
- **Exploration:** over-the-shoulder, behind-and-slightly-above. Later epic (KAN-5); the model
  already supports it, no new art.
- Both cameras view the same scene — switching is a camera transform.

## 3. Pixel-render pipeline (the identity)

1. Render the 3D scene into a **low-resolution `SubViewport`** (the game's internal pixel res).
2. Upscale to screen with **nearest-neighbor** (no smoothing).
3. **Clamp the output to the locked global palette** (posterize / palette shader) — this carries
   the pixel-art *colour* identity. The global-palette decision still stands (recommend
   Endesga-32); ramps become materials/textures instead of hand-placed pixels.
4. Optional: **dither** + a thin **outline** post-process for extra signature.

## 4. Identity system (decided)

How a piece reads as a *specific* contestant, at a glance:

- **Emblem = patron-god glyph** — a decal/texture (or light engraving) in the `emblem` slot; one
  glyph per god, reused across that god's stable. Carries *allegiance*.
- **Colour = the individual** — a material tint (from the global palette) on the emblem + a trim,
  base material neutral. Disambiguates same-patron contestants; matches character vibe.
- **Weapon = role-overlay** — a mesh in the `weapon` socket showing the weapon **class**
  (blade / hammer / bow / staff / claw), updating with loadout. Carries *how they fight* — a
  tactical signal, not identity, so it may change mid-run.
- **Unaffiliated = the `Finit hic imperium Dei` seal** ("Here ends god's dominion" — for
  contestants who took no patron), two resolutions:
  - **On the piece:** a **broken ring** (the circle of the divine, ended) — legible tiny.
  - **On the card / inspect / HUD:** the full circular inscription in epigraphic caps, V-for-U
    with interpuncts — `FINIT · HIC · IMPERIVM · DEI`.
- **Contestant vs generic:** named contestants = themed base + emblem + colour (+ optional gear);
  **generic units / swarm-boss pieces = plain themed pieces** (no identity slot). The
  mahjong-symbol library lives here (emblems + generic tiles).

## 5. Per-theme materials (the god-table)

One material per table (the governing god sets it); per-god reskin = swap material/texture — a
force-multiplier across the many-tables ladder.

| Theme | Material |
|---|---|
| Greek / European | marble / stone |
| Chinese | jade |
| Tribal / totemic | carved wood |
| Death | bone / obsidian |

## 6. Animation model (procedural rigid pieces)

From `art-direction-pieces.md`: pieces are rigid bodies, so common motion is **transform
tweens**, not frames — move = hop between hexes; attack = lunge + topple target; die =
rotate-and-fall; conditions = **decals** on the piece. Aggregate creatures = swarms of identical
pieces (giant = pile, dragon = train). Real art spend goes to **spectacle beats**. Full animation
requirements: see [`../design/animation-brief.md`](../design/animation-brief.md) *(draft)*.

## Decisions

**Locked (provisional, 2026-07-21):**
- **Global palette = Endesga-32** (`lospec.com/palette-list/endesga-32`) — applied as a
  render-time palette clamp; every material/ramp samples from it.
- **European material = dark stone / obsidian** — cool grey → near-black, violet-cool shadow
  bias (matches the v2 render).
- **Identity = accent-colour emblem** (per §4) — patron glyph + a per-contestant accent hue.

**Still open:**
- **Tactical camera** — angle steepness; orthographic vs slight perspective.
- **Pixel-render internal resolution** — how much surface detail / inscription legibility survives.

## Files & supersession

- `piece-template.md` — this file, the canonical (now **3D**) spec.
- `piece-template.html` — the original 2D dimensioned sheet; **retained as the conceptual
  registration/identity reference** (anchor → base-pivot, silhouette, growth-zone → sockets), not
  a literal 2D build target.
- See also: `../design/art-direction-pieces.md` (direction), `../making-art-and-music.md` §1.4
  (palette rules, now applied at render time), `../design/animation-brief.md` (animation
  requirements).
