# Animation Brief — what the game needs to animate

> **STATUS: DRAFT / CANDIDATE — 2026-07-21.** First-pass enumeration of every animation the
> game requires, grounded in the actual sim event hooks (all event names below verified present
> in `simulation/` + `controller/`). Companion to
> [`art-direction-pieces.md`](art-direction-pieces.md) (the piece direction) and
> [`../art/piece-template.md`](../art/piece-template.md) (the 3D piece spec). **The underlying
> mechanics are ruled/implemented; the visual *treatment* is a direction to build against, not a
> locked spec.** Three hard caveats live at the bottom — read them.

## 0 · How to read this (the model)

- **Rigid pieces → transform tweens, not frames.** The common case (move/attack/hit/die) is
  position/rotate/scale, not skeletal rigs or drawn frames. (`art-direction-pieces.md`)
- **Bind to sim events.** The sim is command-stream only and never touches presentation;
  `GameController` re-emits every sim event as a signal (`sim_event` for all, plus 17 typed
  signals). **Events are the only legitimate animation surface.** (`controller/game_controller.gd`)
- **Presentation-only.** Tween/wall-clock timing in the visual layer is fine — it can't affect
  the deterministic model.
- **The cost moves once.** Build **one formation/choreography controller**; then each creature =
  a formation set + a material reskin (per god-table: marble/jade/wood/obsidian). Reserve
  hand-authored art for **spectacle beats** only.
- **3D, rendered pixel** (see piece-template.md): animations are 3D transforms viewed through the
  low-res + palette-clamp pipeline.

**Legend** — Priority: **[MVP]** = needed for the Incinedile Phase-1 demo slice · **[Later]**.
Type: **PROC** = tween/decal (cheap, reusable) · **VFX** = particles/shader · **BESPOKE** =
hand-authored hero set-piece.

---

## 1 · Piece-level motion — the core vocabulary

The rigid-piece verbs and the six-formation set the direction names. A controller blends between
formations, driven by events.

| Formation / verb | What it is | Bind to event | Pri · Type |
|---|---|---|---|
| **idle** | resting baseline (subtle breathe/bob) | default state | MVP · PROC |
| **move-step** | slide/hop hex-to-hex (position tween + small arc); no walk cycle | `moved` | MVP · PROC |
| **lunge / attack** | actor lunges, taps/topples target; target rocks back | `action_resolved`(kind=attack) | MVP · PROC |
| **hit-recoil** | struck piece rocks back | `damage_applied` | MVP · PROC |
| **part-destroyed scatter** | the destroyed cluster scatters off the board, stays gone | `part_destroyed` | MVP · PROC |
| **breach-open** | pieces part to expose the core (swarm boss) | `breach_opened` | MVP · BESPOKE |

### The five hit-states (these are five *different* reads — do not merge)

No to-hit rolls exist; a hit that connects geometrically can still resolve five ways:

| State | Read | Bind to |
|---|---|---|
| **Wound** | weapon bites, blood + damage number + condition decal | `damage_applied` |
| **No-wound clang** | weapon *connects* but sparks/thunks off — no blood, no decal (Robustness ≥ Force) | `attack_no_wound` |
| **Whiff / miss** | swing passes through empty air (Forced-Action TOOL, or windup dodged) | `forced_action_triggered`, `action_invalidated` |
| **Dodged** | agile target weaves aside (boss dodge only) | `attack_dodged` |
| **Forced-action fumble** | the d6 "bad luck" beat — tear/lock/drop/stumble/collateral | `forced_action_triggered` |

Plus **Exposed** — a persistent, unmistakable "vulnerable" body cue (unlocks head/lethal
targeting), toggled by windups/grapple/prone/helpless. `exposed_state_changed`. **[MVP · PROC]**

---

## 2 · Attack-shape vocabulary

Reusable *targeting shapes*, authored once, separate from per-weapon hit-fx. The **windup
telegraph** (a charge over N Moments while the actor glows Exposed) is the single most important
readability beat. Telegraph on `action_declared`/`ai_decision`; resolve on `action_resolved`.

| Shape | Example | Pri · Type |
|---|---|---|
| Melee arc / thrust-line | greatsword sweep · rapier line | MVP · VFX |
| Projectile + tracer | pistol/bow · elemental ball → AoE detonation | MVP · VFX |
| Cone | Incinedile flamethrower (10-hex) | MVP · VFX |
| Line-charge / dash | Incinedile dash (knock-aside, 3 Crush) | MVP · VFX |
| Radius-burst | pressure-valve explosion, poison-soup | MVP · VFX |
| Persistent field / wall | fire/frost/poison wall (ticks on occupants) | Later · VFX |
| Multi-beat grab | Death Spin (Grab→Chew→spin-kill) | MVP · BESPOKE |
| Summon-spawn | elite `awaken_eggs` → brood | Later · PROC |

---

## 3 · Condition & state decals

The 9 conditions are **per-part** overlays that **escalate with tier**. Damage-type is the colour
language (must read on both the projectile *and* the resulting decal).

| Condition (type) | Decal escalation by tier | Pri · Type |
|---|---|---|
| **Bleeding** (phys) | gash → dripping → pooled/soaked → drained-grey | MVP · VFX |
| **Crushed** (phys) | dent → fracture cracks → caved-in → destroyed stump | MVP · PROC |
| **Burn** (phys) | sear → char → flaming/smoking → ash *(NB: some bosses `fire_heals` — show green heal, not damage)* | MVP · VFX |
| **Chilled** (afflict) | frost rime → ice crust → full ice-encasement (disable) | Later · VFX |
| **Poison** (afflict, typed) | coloured veins creeping from wound; **Poison-Soup** = multi-colour burst | Later · VFX |
| **Infected** (afflict) | pus → spreading veins → blackened sepsis (death timer) | Later · VFX |
| **Suffocation** (torso, timer) | choking/cyanosis + shrinking breath ring | Later · VFX |
| **Exhausted** (whole-body) | sweat aura → hunched → gasping/stumbling | Later · PROC |
| **Dissolution** (psychic, head, timer) | void/mind aura round the head; a "personal song" motif | Later · VFX |

Part states (any part can also carry): **part_disabled** (grey/limp), **part_destroyed**
(gone/detached), **part_locked** (Forced-Body lock-up). Lifecycle cues that need their own read:
`condition_applied` / `condition_advanced` / `condition_resolved` / `condition_resisted` (ward
sparkle) / `condition_delayed` (bandage — decal dims). **[MVP for bleed/crush/burn · rest Later]**

---

## 4 · Shock beats

Single per-combatant value, momentary, resets at combat end. Fire the tier beat only when newly
crossed. `shock_changed` + the tier events; `item_dropped` on faint.

| Tier | Beat | Bind to · Pri |
|---|---|---|
| **T1 Shout** | pain-cry burst + sound-ring; breaks stealth | `shock_shout` · MVP · VFX |
| **T2 Stutter** | freeze/glitch hitch — next action simply fails | `shock_stutter` · MVP · PROC |
| **T3 Faint** | collapse, items scatter, out for a Clock | `shock_incapacitated`, `item_dropped` · MVP · PROC |
| **T4 Helpless** | permanent down/limp, head-targetable | `shock_incapacitated` · MVP · PROC |

---

## 5 · Injury, death & the maiming stinger

| Beat | What it is | Bind to · Pri · Type |
|---|---|---|
| **Regular hit** | light feedback — piece **cracks + red flecks** (reserved so the big beat lands) | `damage_applied` · MVP · PROC |
| **Maiming stinger** | the signature: snap-to-black → high-contrast **white impact-frame** lighting/detaching the limb → cut back to piece with a **chunk bitten out + red**. The cutaway *hides* the change — **no dismemberment animation needed.** Broadcast money-shot. | `part_destroyed` / kill · MVP · **BESPOKE** |
| **Persistent scars** | the maimed cluster **stays gone the rest of the match** (no field HP regen); board carries accumulated carnage | (state after `part_destroyed`) · MVP · PROC |
| **Death / capture** | one **rotate-and-fall** topple off the board | `combatant_died` · MVP · PROC |
| **Bleed-out arc** | downed-but-not-out "will it topple?" tension for a Clock; can stabilise | `bleed_out_started`/`_draining`/`_stabilized` · MVP · PROC |
| **Mind-collapse** | Dissolution → removed **forever**, becomes the collapser's puppet. **NOT a topple** — a "taken/turned" beat, heavier than death | `mind_collapsed` · Later · **BESPOKE** |

> ⚠ **HARD REQUIREMENT (DoD accessibility gate):** the stinger's snap-to-black + white flash
> **must** ship behind a **photosensitivity / reduced-motion toggle** that swaps the flash for a
> non-flashing hold-state. Not optional polish. Keep the maiming **material** (chipped tile,
> splintered wood + red), not anatomical — stylised, not gore-porn.

---

## 6 · Bosses & swarms (the Incinedile is the worked example / slice target)

Aggregate creatures = many identical pieces (giant = pile, dragon = train, Incinedile = mycelium
swarm); **cluster = body-part** (per-part HP reads straight off the clusters). Hard rule: bosses
win by a **discoverable condition, never a damage race.**

| Beat | What it is | Bind to · Pri · Type |
|---|---|---|
| **Surface immunity** | pre-breach hits do **zero HP, cosmetic only** — the "why isn't this working?" read | `attack_blocked` · MVP · PROC |
| **Breach open (THE win)** | Bleed-T2 on a part, or a 7+ single/combined hit, exposes the hidden network → outer pieces **part to reveal the core** → phase flips | `breach_opened` + `boss_phase_changed` · MVP · **BESPOKE** |
| **Breach reset** | network retreats, core **re-closes** ("breach it again"); wounds persist | `breach_reset` · MVP · PROC |
| **Pressure-valve explosion** | **steam telegraph 1 Moment before** → radius flash → instant KO inside; camera shake | (phase state) · MVP · VFX |
| **fire_heals** | fire hitting the boss reads as **healing** (teaches the rule) | `healed` on burn · MVP · VFX |
| **Part-disable de-fang** | Crush-2 disables a cluster, permanently stripping an ability (flamethrower arm goes cold) | `part_disabled` · MVP · PROC |
| **Cinematic intro** | gates close → freeze → "Party vs Boss" → caged band spotlight → unfreeze | scripted · Later · BESPOKE |
| **Elite (Roach) summon/heal** | spawns a brood, seals its own wounds | `enemies_summoned` · Later · PROC |

---

## 7 · Spectacle / broadcast layer (the identity)

Every big combat beat also drives the audience layer — "a show that's watching you back."

| Element | What it is | Bind to · Pri · Type |
|---|---|---|
| **Hype meter + band step** | gold bar fill; band swaps COLD OPEN→WARMING UP→ELECTRIC→ON FIRE | `hype_spike`, `hype_band_changed` · MVP · VFX/UI |
| **Crowd-goal card** | one active side-bet; slide-in on offer, payout burst on complete, dim on expire | `hype_goal_offered/completed/expired` · MVP · UI |
| **Camera Call** | Charm spotlight — odds board "turns to you", spectacle **doubled**; light/vignette focus | `hype_camera_call_started`/`hype_spotlight_ended` · MVP · BESPOKE |
| **The Bit** | mechanically-null showmanship flourish, escalating payout on repeats | `bit_performed` · Later · BESPOKE |
| **Tag earned** | broadcast pop when a slice-tag is acquired (→ epithets) | `tag_acquired` · MVP · UI |
| **Broadcast overlays** | LIVE bar (one blinking red dot), Momus chyron/lower-third, odds board, god-wager ticker, scanline+vignette feed, R14 "placeholder" watermark | continuous · MVP · UI |
| **Verdict card** | "a verdict, not a victory screen": hero verb + earned row (hype/epithet/patron/stars/boss outcome) + Momus sign-off | `combat_ended` · MVP · UI/BESPOKE |
| **God boon / patron intervention** | bidding screen, `patron_tip` boon (diegetic + announcer names the god), outbid notice, patron badge pulse | *(KAN-7 — see caveat)* · **Later** · BESPOKE |

---

## 8 · Cameras & global feedback

- **Tactical** high-3/4 **orthographic**, hex board tilted to iso, tokens billboard to face camera. **[MVP]**
- **Exploration** over-the-shoulder (KAN-5) — same scene, camera transform, no new art. **[Later]**
- **Camera moves**: zoom/shake on breach, explosion, execution/finisher, maiming, Camera Call. **[MVP for breach/explosion]**
- **Clock HUD**: master readability element — Moment tick + Clock-reset reorganisation beat. `clock_moment_changed`/`clock_reset`. **[MVP · UI]**
- **Invalid input**: `command_rejected` → a rejection nudge (no illegal-move animation). **[MVP · UI]**

---

## 9 · Demo-slice cut list (build these first)

The Incinedile **Phase-1 fight + breach + Phase-2 valve** is the slice. Minimum animation set:

1. Piece verbs: idle · move-hop · lunge · hit-recoil · scatter · topple (§1).
2. The **five hit-states** + Exposed cue (§1).
3. Attack shapes actually used: melee arc, flamethrower **cone**, dash **line**, **radius** burst, projectile (§2).
4. Conditions that appear: **bleed / crush / burn** decals (tiered) + resisted/no-wound cues (§3).
5. **Shock** T1–T4 (§4).
6. **Maiming stinger + the a11y toggle** + persistent scar + topple death (§5).
7. The **breach set-piece** + surface-immunity + Phase-2 steam-telegraph explosion + camera shake (§6).
8. Broadcast layer: hype bar/band, crowd goal, **Camera Call**, tag pop, LIVE bar + Momus chyron, **Clock**, Verdict card (§7–8).

Everything else (chill/poison/infection/suffocation/exhausted/dissolution decals, fields/walls,
The Bit, patron layer, exploration cam, cinematic intro) = **v2**.

---

## Caveats (read these)

1. **Piece art direction is CANDIDATE, not ruled** (`art-direction-pieces.md` — owner thread
   2026-07-20). Six open decisions remain (identity-survives-abstraction, theming axis, piece
   grammar, "lose-an-eye" part granularity, camera zoom/shake, reserved bespoke VFX).
2. **The patron / god-boon layer is NOT implemented** — it's KAN-7 design with placeholder view
   stubs (R14 "placeholder numbers" throughout). Only **hype, tags, Camera Call, and The Bit** are
   live in the sim today. Don't brief boon animations as near-term.
3. **The maiming flash needs a photosensitivity / reduced-motion toggle** — a hard DoD gate, not
   polish (see §5).
4. **Bind to code event names, not the mockup doc.** `EXPERIENCE.md` cites `hype_changed`,
   `crowd_goal_offered`, `part_damaged` — **none exist in code**; use `hype_band_changed`/`hype_spike`,
   the event `hype_goal_offered`, and `damage_applied`.
5. **Explosion choreography past Phase 1 is deferred in the sim** — the boss idles past the
   Phase-2 transition, so animate P1 + the breach + the first valve; later phases are v2.

## Sources

Investigated across: `simulation/{combat_sim,action_resolver,condition_engine,enemy_ai,exposure_engine,forced_action,hype_engine,tag_engine,resistance,skill_book}.gd`,
`controller/game_controller.gd`, `data/{conditions,skills,enemies,races,items,crowd_goals}.json`,
`docs/design/art-direction-pieces.md`, `docs/rules-addendum.md`, `docs/GPT_Master_Compendium.md`,
`docs/DIRECTION.md`, `docs/cosmic-casino-canon.md`, `docs/story-canon.md`, `docs/design/patron-gods.md`,
`docs/ux-designs/demo-slice-2026-07-19/{DESIGN,EXPERIENCE}.md`. All event names verified present in
`simulation/` + `controller/`.
