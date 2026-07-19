# Galactic Prime Time — Experience Spine (demo-slice, KAN-6 mockup gate)

> **STATUS: APPROVED (owner 2026-07-19).** KAN-6 mockup gate passed — scene-building
> unblocked. Owner calls: keep the 3-column director rail; keep the band display names
> (enum `cold/warm/hot/on_fire` shown as ELECTRIC / ON FIRE). Numbers stay PLACEHOLDER (R14).

The interaction spine for the vertical-slice demo. Pairs with `DESIGN.md` (visual identity)
and the three rendered mockups (`renders/combat-hud.png`, `renders/bid-screen.png`,
`renders/verdict-card.png`). It answers *how the screen behaves and what the player does* —
DESIGN answers *how it looks*. Token names referenced below (e.g. `hype_bar`,
`unit_token`, `crowd_goal_card`) are defined in `DESIGN.md`.

> DIRECTION.md governs: **2.5D tactical**, broadcast-framed, "a verdict instead of a victory
> screen." Sim is command-stream only; the UI is presentation over `GameController` signals
> and never owns rules state. All numbers shown are **PLACEHOLDER (R14)**.

## Foundation

- **Engine surface.** Godot **Control** nodes over the headless sim (`simulation/`, no node
  deps). Scenes are presentation only; they render sim events and emit *commands*, never
  mutate state. The HUD subscribes to `GameController` signals (`hype_changed`,
  `boss_phase_changed`, `crowd_goal_offered`, `part_damaged`, `condition_applied`, …) and is
  a pure function of the command stream — the same feed drives live play, replays, and
  Stage-2 spectator broadcasts (DIRECTION clock-driver model).
- **Presentation target.** 2.5D tactical: a hex board tilted into an isometric plane
  (`transform: rotateX`) with **billboarded `unit_token`s** standing over it. In Godot this
  is a tilted board node + Control billboards / `Sprite2D` tokens; the mockup approximates it
  in CSS.
- **Input model — mouse-first declare UI (per GDD v0.2).** Click a `unit_token` or a hex to
  target; click an action button to declare; a **consequence-preview** line resolves the
  declaration before commit. Keyboard/controller is a later parity pass; the slice proves the
  mouse loop. "No turns" (DIRECTION) is honored as a **declare window on a shared Moment
  clock**, not a blocking menu — the clock/turn strip shows tick order and whose window is
  open.
- **No to-hit rolls.** Requirements auto-succeed; the failure path is the Forced Action d6
  (surfaced as an enemy pratfall / a fumbled player action), never a "miss."

## Information Architecture (combat HUD hierarchy)

Four bands, outermost = show, innermost = decision:

1. **Broadcast frame (always on).** `broadcast_bar` top (LIVE, brand, viewers, MOMUS),
   `chyron` bottom (Momus commentary). This never leaves — it *is* the diegetic container.
2. **Clock context.** `clock_pill` + `moment_pill` + turn-order strip with the boss
   **WINDUP** marker. Answers "what beat is it and who acts next."
3. **The stage + the crowd (side by side).**
   - **Center arena** (dominant): the tactical truth — board, tokens, part-HP-bearing units,
     `fire` hazard tiles, the flamethrower **cone** telegraph, broadcast-feed overlay.
   - **Left director rail:** the *why* — Slice Objective (breach the hidden network → Phase
     2), Hazard Read (Fire Heals It), and the god-wager ticker (the divinity economy leaning
     on the fight).
   - **Right spectacle column:** the *reward economy* — `hype_bar` + band + delta, the ONE
     active `crowd_goal_card`, the `camera_call_btn`.
4. **The player's instrument (bottom).** Two contestant panels (persona, patron badge, 6-part
   HP grid, conditions, shock, skill chips) + the action bar for the active contestant.

Reading order the layout enforces: **who's up → where they are → what the crowd wants →
what I can do → what it will cost.** Spectacle (hype/goal/camera) sits between the board and
the buttons on purpose — every action is priced in audience terms, not just damage.

## HUD & Diegetic UI (broadcast-overlay vs in-world)

The slice runs **two UI planes**, and the split is the point:

- **Broadcast overlay (the show's graphics, not the character's):** `broadcast_bar`, viewer
  count, `chyron`, the scanline/vignette **broadcast-feed** over the arena, the left rail's
  god-wager ticker, and the whole **Verdict card**. These are what *four million viewers*
  see — the production's lower-thirds and telemetry. They can editorialize (Momus is
  unreliable; the crowd is fickle).
- **In-world / player-agency UI (the tactical truth):** the hex board, `unit_token`s and
  their part-HP, condition chips, the clock/turn strip, the action bar, and the
  consequence-preview. These are honest, deterministic, sim-backed — the player's actual
  control surface.
- **The bridge layer** (hype, crowd goal, Camera Call, patron badges) is *both*: a real
  mechanic (payouts, multipliers, Charm-gated spotlight) rendered as broadcast furniture. It
  is where the two planes touch, and where the spine tension lives — the crowd's wants pull
  against the tactically correct play.
- **Diegetic discipline:** the win condition is discoverable **in-world** (the `unit_token`
  reads `NETWORK 🔒 HIDDEN` and `PHASE 1`; surface immune until breach) — never a quest-log
  pop-up. The overlay only *hints* (Hazard Read), it doesn't hand out the answer.

## Key Flows

### A combat turn: declare → resolve → hype (the core loop)

1. **Window opens.** Clock advances a Moment; the turn strip lights the active contestant
   `cyan` and their bottom panel gains the gold "ON THE CLOCK" edge. Boss WINDUP marker warns
   a telegraph is charging.
2. **Read the ask.** Right column shows the live `crowd_goal_card` ("SHOW-OFF! — land a hit
   from an Exposed state"); the `hype_bar` shows current band + last delta. Left rail shows
   the objective/hazard. The player weighs *tactically correct* vs *crowd-rewarding*.
3. **Target.** Click a hex / `unit_token`. The board previews range/legal targets; the
   flamethrower **cone** shows what's about to be dangerous.
4. **Declare.** Click a skill in the action bar. The **consequence-preview** resolves the
   declaration in plain language ("FEINT → forces a reaction · sets up Pressure Strike")
   *before* commit — this is where "no to-hit rolls, requirements auto-succeed" becomes legible.
5. **Optional gamble.** `camera_call_btn` (Charm-gated) spends a stack to **double the next
   spectacle swing** — gains *and* losses. The doubling-down beat.
6. **Commit → resolve.** UI emits the command; sim resolves deterministically and streams
   events. HP grids update (part → ramp color; a damaged part flips to `danger`), condition
   chips apply (🩸 BLEEDING T1), Forced-Action fumbles play out.
7. **Crowd reacts.** `hype_bar` animates the delta; band may step up (…→ ELECTRIC → ON FIRE);
   if the goal's condition was met it pays out and a new single goal is offered at the next
   Clock reset. Momus fires a `chyron` line off the beat.
8. **Advance.** Window closes; clock ticks to the next actor. Loop.

### The discovery beat (slice win moment)

The boss is **immune on the surface** (raw damage races are banned — CLAUDE.md hard rule).
Two authored breach paths, each a contestant's kit: **Bleeding-T2 on a part** (Dario:
Feint → Pressure Strike, re-applied) or **7+ damage in one hit** (Imani's Strong Strike +
the R15 combined-action merge). A breach exposes the hidden network → `boss_phase_changed` →
**Phase 2** = the slice's win. The HUD telegraphs the *existence* of the secret (NETWORK 🔒
HIDDEN), the crowd rewards finding it, and the moment it breaks is the crowd-detonating clip.

### Around the run: bid → play → verdict

- **Before (bid screen).** The player reviews competing god bids per contestant — deal sheet
  (favor/taboo/2 boons), influence stars, bid chips + multiplier, personality read — and
  **locks in patrons**. The slice seeds Imani→Hestia, Dario→Enyo (SIGNED); rival gods
  (Ares/Athena, Loki/Hermes) **outbid** to create buy-out tension, and stay in play to
  bless/curse mid-run.
- **During.** The chosen patron's favor/taboo re-color the crowd goals and the god-wager
  ticker; the fight is played as the loop above.
- **After (verdict card).** Not a victory screen — **a verdict**. It answers the spine
  question ("how much can we break your essence down in the name of entertainment?") with a
  read on the run, then the earned row: HYPE, an **epithet** unlock, patron standing (+
  blessing / displeasure), the crowd's star verdict, and the boss outcome
  (INCINE-DILE: BREACHED · Phase 2). Momus signs off — *"This is Momus. Stay tuned!"* — and
  teases the next contestant, closing the broadcast loop.
