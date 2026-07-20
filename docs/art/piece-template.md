# Themed Game-Piece — Authoring Contract & Palette System

> **STATUS: CANDIDATE / EXPLORATION — NOT RULED.** Technical companion to
> [`../design/art-direction-pieces.md`](../design/art-direction-pieces.md) (owner-originated,
> 2026-07-20). That doc is the *why/what* (contestants & bosses rendered as the table-god's
> game-pieces); this is the *how to actually author one piece* — canvas, registration,
> palette architecture, layering. Honors the house style in
> [`../making-art-and-music.md`](../making-art-and-music.md) §1.4 (one global palette,
> per-material ramps, hue-shift, solid dark outline, 3/4 billboard). **Palette values here
> are PROVISIONAL** until the global palette is locked (see Open Decisions).

Rendered dimensioned sheet: **[`piece-template.html`](piece-template.html)** — open in a
browser for the visual diagram. This file is the canonical text spec.

---

## 1. Canvas & registration

| Field | Value |
|---|---|
| Canvas | **64 × 64 px** (power of two) |
| Top / bottom margin | 6 px each |
| Left / right margin | 15 px each |
| Piece envelope | **34 × 52 px** (max silhouette) |
| Widest point | 34 px — base, centred |
| Center axis | between **col 32 & 33** (even canvas → seam, no center pixel) |
| **Anchor** | **⟨32, 58⟩** — center-bottom / feet / ground contact |
| Growth zone | the margins — reserved for gear that extends past the bare piece |

- **The anchor is law.** Every layer, and every material theme, aligns its base to ⟨32, 58⟩.
  A cloak drawn once then lands on any piece; a jade piece and a marble piece register
  identically. Never nudge the anchor per-asset.
- **Growth zone.** The bare piece must *not* fill the margins — leave headroom & side-room
  so crowns, cloaks, staves, and totem-caps have somewhere to go without clipping the frame.
- **Even-canvas symmetry.** There is no true center pixel; the axis falls between columns 32
  and 33. Make central features **2 px wide**, or commit to a consistent 1 px lean.

## 2. Perspective & animation (settled by house style)

- **Single 3/4 billboard** that faces the camera — per DIRECTION D2 and `making-art-and-music.md`
  (3/4-view sprites over a hex arena). A rigid piece does **not** get multi-facing sheets
  unless it proves it needs them, so the usual *(assets × angles)* multiplier collapses to
  **× 1 angle**.
- **Procedural motion, not frames** (from art-direction-pieces.md): move = hop between hexes,
  attack = lunge/topple tween, die = rotate-and-fall. Conditions = **decals** on the piece
  (crack = crushed, drip = bleeding, flame = burn). Art spend goes to **gear + spectacle
  beats**, not walk cycles.

## 3. Palette architecture

House rule (`making-art-and-music.md` §1.4): **don't free-pick colours.** One global
~32-colour palette; every material ramp is a subset of it; hue-shift shadows cooler /
highlights warmer; solid dark outline; 3–6 colours per element. The piece palette has five
layers:

1. **Global palette** — *[LOCKED = TBD — recommend Endesga-32]*. The master; every pixel on
   every piece and every theme comes from here.
2. **Per-theme material ramp** — a 5–6 step subset that *is* the god-table's material. One
   material per table (art-direction-pieces open-decision #2):
   | Theme | Material | Ramp source |
   |---|---|---|
   | Greek / European | marble / stone | *TBD from global* |
   | Chinese | jade | *TBD from global* |
   | Tribal / totemic | carved wood | *TBD from global* |
   | Death | bone / obsidian | *TBD from global* |
3. **Identity accent** — one signature hue per contestant (emblem / base trim), so
   same-material pieces still read as different characters (open-decisions #1 & #2: the
   table's god sets the material, the contestant's own patron shows as an emblem).
4. **Condition decals** — fixed, cross-theme cues (crack / drip / flame / …), pulled from the
   global palette and identical on every theme so "arm at half HP" always reads the same.
5. **Maiming red** — the single red reserved for the visceral-injury stinger and persistent
   scars (art-direction-pieces "Visceral injury").

### European stone ramp — PROVISIONAL placeholder

Structure: `keyline → core-shadow → body → mid → highlight → specular` (6 steps), hue-shifted
(shadow toward cool blue-violet, highlight toward warm). Values below are **eyeballed from the
v2 render — replace with real values pulled from the locked global palette.**

| Role | Placeholder | Use |
|---|---|---|
| Keyline | `#141414` | silhouette outline |
| Core shadow | `#363636` | deepest form shadow |
| Body | `#565656` | main mass |
| Mid | `#767676` | lit mid-tone |
| Highlight | `#A6A6A6` | upper-left planes |
| Specular | `#D0D0D0` | sharpest point (head) |

Light source: **upper-left, single source, on every layer.**

## 4. Layering contract (invariants)

- **One canvas** — every asset authored on the same 64×64 with the same margins.
- **Anchor is law** — align every overlay's base to ⟨32, 58⟩; never nudge per-asset.
- **One light** — upper-left single source on every layer, or gear reads as pasted on.
- **Mind the seam** — central features 2 px wide (no true center pixel), or a consistent lean.
- **Margins are reserved** — the bare piece leaves headroom & side-room for gear.
- **Reads at 1×** — check the silhouette at actual size; if it turns to mud, simplify first.
- **Locked ramp** — pull every pixel from the material ramp; new gear adds no new greys.
- **Optional shoulder ref** — if cloaks need a hook, fix one shoulder line and reuse it; feet
  stay the master.

## 5. Composite order (back → front)

`cast shadow → base piece → body gear (cloak) → head gear (crown) → front props (totem/staff)`

Condition decals and the maiming layer composite **on top** of the piece (per
art-direction-pieces.md).

## Open decisions (pending owner sign-off)

Mirror and extend the open decisions in `art-direction-pieces.md`:

1. **Global palette lock** — Endesga-32, or a different Lospec ~32-colour set?
2. **European material** — pale marble (the doc's literal wording) vs. dark stone / obsidian
   (the v2 render reads as cool charcoal, not white marble). These pick different ramps.
3. **Identity mechanism** — per-contestant accent emblem, gear/silhouette only, or a small
   face/emblem sprite.
4. **Single 3/4 billboard confirmed** — assumed here; flag if any piece needs true facing.

## Files

- `piece-template.html` — rendered dimensioned sheet (open in a browser).
- `piece-template.md` — this file, the canonical text spec.
- See also: `../design/art-direction-pieces.md` (the direction), `../making-art-and-music.md`
  §1.4 (house palette rules), `generation-prompts.md` (generator-route tests).
