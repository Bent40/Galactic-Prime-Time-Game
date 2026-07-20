# Art Direction — Themed Game-Pieces + Visceral Injury

> **STATUS: CANDIDATE / EXPLORATION — NOT RULED.** Owner-originated design thread
> (2026-07-20). Captured so it survives to the planned UI revamp. Nothing here is
> committed; it's a direction to pressure-test, not a spec to build.

## The core idea
Represent contestants and bosses as the **game pieces of the table's governing god**,
themed to that god's cultural register — jade **mahjong** tiles for a Chinese patron,
marble **chess** for a Greek/European one, carved **totems / wood** for a tribal/totemic
one, **bone/obsidian** for a death god, and so on. The Cosmic Casino frame is literally
gods wagering at a table; rendering the fighters as the *pieces on that table* makes the
premise visual — you are pieces in the gods' game.

### Why it's a fit (not just a cost-cut)
- **On-brand / diegetic.** Turns a budget constraint into worldbuilding.
- **Art budget.** One readable silhouette per character, sharing a cohesive per-theme set;
  far cheaper than per-character animated sprites.
- **Animation becomes procedural** (the big win — see below).
- **Scales with the mythology content.** Per-god **material/style reskins** give every
  table a distinct identity without redrawing characters — a force-multiplier for the
  shared-world "many tables" ladder (DIRECTION.md).
- **Reads at 2.5D tactical scale.** Pieces are designed to be identified from above on a grid.

## Animation model — rigid pieces, procedural motion
A piece is a **rigid body**, so the common-case animations are **transform tweens**, not
hand-drawn frames or skeletal rigs:
- **Move** = slide/hop between hexes (position tween + small arc). No walk cycle.
- **Attack** = lunge + tap/topple the target (translate/rotate/scale tween); target rocks back.
- **Die** = topple off the board / captured (one rotate-and-fall tween).
- **Conditions** = decals on the piece (crack = crushed, drip = bleeding, flame = burn).

Spend real art only on the **spectacle beats** (a god's boon, a signature skill, The Bit) —
which aligns art spend with the game's hype/spectacle economy. The cost **moves** from
"drawing frames" to **authoring a formation/choreography system**: programming, reusable
across every creature and theme, and front-loaded — the *first* creature builds the system,
each one after is a formation set + a reskin. **Presentation only** — the animation layer
reads sim events and tweens; it never touches the deterministic command-stream model, so
wall-clock/tween timing in the *visual* layer is fine.

## Aggregate creatures — big beasts as swarms of pieces
A large creature is **many identical pieces**, not one big sprite — which inverts the usual
economics (big bosses are normally the *most* expensive to animate; here they're the easiest):
- A **giant** = a stack/pile that slams into hexes and reconfigures ("changes form to bite" =
  retarget the pieces into a jaw at the target hex, tween, snap back).
- A **dragon** = a **train of pieces** slithering hex-to-hex — which also gives multi-hex
  occupation and striking different body segments, almost for free.
- Formations to author: idle · move-step · lunge/bite · hit-recoil · **part-destroyed scatter**
  · **breach-open**. A controller blends between them, driven by sim events.

### The alignment worth noticing
This is the **literal correct visual** for the Incinedile boss we already have and just
hardened (F2): a **mycelium puppet** — a body of cosmetic parts animated by a *hidden inner
network*. A **swarm of pieces moved by an unseen core** *is* that boss. It maps 1:1 onto the
sim's multi-part-body model: **each cluster of pieces = a body part** with its own HP, so a
destroyed arm = that cluster scatters off the board, and the per-part HP the HUD already
shows reads straight off the clusters. The **breach** (the discoverable win) becomes the
pieces **parting to expose the core**. Fiction + tech + data model all want the same thing.

## Visceral injury — keep the brutality
The game is a **brutal** reality-TV dungeon crawler; abstraction must **not** sanitize the
violence. Losing an arm / eye / etc. has to land, and **stay** landed.
- **Maiming stinger (cinematic cutaway).** On a real maiming, punch in: snap to black → a
  high-contrast **white impact-frame** that lights the limb and **detaches** it → cut back to
  the piece now with a **chunk bitten out + red**. The classic cheap-but-effective trick: the
  cutaway *hides* the transition (change state off-screen, cut back changed) — no dismemberment
  animation needed. Diegetically it's a **broadcast money-shot** — the show cuts to the carnage,
  and the crowd loves it.
- **Persistent scars.** The injury **stays on the piece** for the rest of the match — a
  one-armed contestant plays on as a maimed piece; a giant that lost a limb-cluster stays
  short those pieces. The board carries the accumulated carnage; brutality isn't a one-frame
  flash, it's a lasting state.
- **Hooks the existing sim + economy.** Keys off events we already emit — `part_destroyed` /
  `part_disabled` (R4 permanent limb loss, which F2 preserved: a crushed limb *caps* at
  destroyed). It already feeds the audience economy: `part_destroyed` → the **gorefest** tag +
  a hype spike. The stinger is just the *presentation* of a beat the sim already produces.
- **Pacing.** Reserve the full stinger for **meaningful maimings** (part destroyed / kills);
  regular hits get lighter feedback (piece cracks, red flecks) so the big moment keeps its punch.
- **Tone.** Stylized, not gore-porn — the piece abstraction *helps* here (a bitten jade tile is
  brutal without being torture-porn), landing well against the depiction policy (respectful,
  Helltaker/manhwa register) and broadcastability.
- **Accessibility.** The flash/black-cut needs a **photosensitivity / reduced-motion toggle**
  (DoD accessibility gate).

## Open decisions (resolve when this is picked up — NOT now)
1. **Identity survives abstraction** — a face/emblem/color on the piece + persona text in the
   HUD so a chess knight still reads as *Imani*.
2. **Theming axis** — the **table's governing god** sets the piece material/board (clean, one
   theme per encounter); the contestant's **own patron** shows as an emblem on the piece.
3. **Piece grammar** — piece-count → size/threat; cluster → body-part; consistent so 100
   creatures stay coherent and stay **tactically readable** (must still read "arm at half HP"
   off a clacking pile).
4. **Body-part granularity** — "lose an eye" specifically needs finer parts than
   head/torso/arms/legs, or lives as a cosmetic/narrative flourish. Decide later.
5. **Camera** — a 30-tile giant slamming a hex needs a zoom/shake to land the weight;
   board-as-stage supports it, flat top-down wouldn't.
6. **Reserve bespoke** VFX for a handful of hero moments so not *everything* is "pieces."

## Relationship to the current build
Not a pivot — an **evolution**: the arena is already token/piece-based (🐊/🛡️/🎭 on a board,
not sprites). The headless render harness (`scripts/render_hud.sh`) lets us **prototype** a
jade-mahjong or carved-wood piece look and screenshot it in minutes before committing to any
art. Also relevant: the owner's read that the current HUD is **overloaded / no real stage /
too much always-on UI** — leaning into board-as-stage with cleaner, contextual panels plays
*better* with a piece aesthetic than the dense broadcast overlay does. A UI revamp and this
art direction reinforce each other.
