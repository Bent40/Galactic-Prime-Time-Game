---
title: "GDD — Galactic Prime Time (working title)"
game_type: rpg (2.5D tactical)
platforms: [pc]
status: draft — OWNER REVIEW GATE
created: 2026-07-16
updated: 2026-07-16
supersedes: docs/archive/GPT_GDD_v02.pdf (kept as history; this document wins where they conflict)
---

# Game Design Document — Galactic Prime Time ⟨working title — OPEN⟩

*Built on the APPROVED brief (`../brief/brief.md`). Precedence: DIRECTION.md >
rules-addendum.md > this GDD > compendium > PDFs > rulebook docx — this GDD consolidates
the first three and never contradicts them. All tuning numbers are PLACEHOLDER (R14
discipline) unless marked canon. ⟨PROPOSED⟩ = my draft awaiting owner taste; OPEN = an
owner decision not yet made; nothing OPEN is silently resolved here.*

## Executive Summary

A 2.5D tactical RPG where you are a contestant on a dungeon gameshow run as a **table in
the Cosmic Casino** — gods wager on mortals, and the game they built from human pop
culture is a reality show with dungeons. Turnless, diceless tactical combat (shared
Moment clock, requirements auto-succeed, failure cascades through Forced-Action tables)
over per-body-part HP and condition clocks; an audience economy (hype, camera, patron
gods, epithets) that converts spectacle into power; a campaign of floor-sets that each
stage one moral question; and a **verdict ending** — the show tells you what kind of
person you were and what kind of **ruler** you'll be, because winning promotes you into
the pantheon. Ships by the DIRECTION ladder: engine (done) → vertical slice → friends
co-op → async global show.

**Spine:** *"How much can we break your essence down in the name of entertainment?"*

## Target Platforms

PC (Windows/Linux), Godot 4.7. Stage 0–1 offline single-player is a permanently
supported mode. Co-op (Stage 1+) is host-based or thin-relay; the Stage-2 service is a
lightweight web stack. Performance target ⟨PROPOSED⟩: 60 FPS on a 2015-class laptop —
2.5D sprites over a hex field must never be the bottleneck.

## Target Audience

Primary: litRPG/DCC readers who play PC tactics/roguelites (20–60 min sessions,
permadeath-tolerant, build-crafters). Secondary: deterministic-tactics players (Into the
Breach, Darkest Dungeon); later co-op groups and Stage-2 spectators/patrons. (Brief §
Target Players; market grounding in review-4.)

## Goals & Context

1. Prove the core hypothesis in the slice: *clock combat + audience reaction is fun for a
   stranger for 20 minutes and produces a clip-worthy moment* (DIRECTION Stage-1 bar).
2. Every ladder rung is a complete, shippable game; no rung is funded without external
   evidence from the previous one (honesty rule).
3. Convert the owner's live TTRPG campaign and novel-world IP into a coherent digital
   product without breaking the running table tool (separate repo, read-only content
   source).

## Unique Selling Points

1. **The audience is a game system** — patron gods bid on you at creation, tip the dealer
   mid-fight, buy out your contract when your deeds feed them; attention is an economy.
2. **A verdict, not a victory screen** — essence axes scored by floor-set choices decide
   what god you become; tags (what the crowd calls you) deliberately diverge from essence.
3. **Turnless, diceless tactics** — no to-hit; requirements + consequence tables; a shared
   clock that reads on broadcast.
4. **Broadcast-native architecture** — command-stream determinism makes replays,
   spectating, and async multiplayer near-free (already implemented, headless-tested).

## Core Gameplay

### Pillars (canon, brief-approved)
1. **Everything is on air** — two information planes; attention economy (hype, camera
   calls, patron tips, epithets).
2. **No dice to hit — requirements and consequences** — deterministic clock tactics;
   failure cascades, never whiffs.
3. **The body is the resource** — per-part HP, condition clocks, priming over cooldowns,
   damage that lasts.
4. **Your choices are the scoreboard** — floor-set questions, essence vs label, verdict.

### Core loop
- **Moment-to-moment (combat field):** enter field → bound to the field's Moment clock
  (10 ticks per Clock; Moment counts 10→1; **one tick ≈ 0.5s of in-game time** — a
  Clock is ~5 fictional seconds; combat is diegetically hyper-fast and the real-time
  interface is the broadcast's slow-motion) → declare actions in the declare window
  (drivers: paused-on-decision solo / timed co-op at **5s default**,
  accelerate-on-all-committed / wall-clock broadcast — sim never self-advances) → requirements auto-succeed;
  unmet requirements halve effect and roll the **Tool d6**; wounded parts force the
  **Body d6** → damage lands on parts, conditions start/advance their clocks → spectacle
  moves the hype meter; gods react → deaths trade simultaneously within a tick (R2).
- **Session (run):** field → loot/comps → recruitment/social beats → noise & absorption
  pressure (loud fights pull neighbors in at Clock resets) → floor objective → time skip.
- **Campaign:** floor-set stages one question → route unlocks are path-dependent → tags
  drift, essence accrues, patron relationships evolve → floor ~20 → **the verdict**.

### Win / Loss
- **Fight:** bosses always carry a discoverable win condition — never a raw damage race
  (architecture rule; Incinedile P1's breach teaches it).
- **Contestant death:** lethal parts (head, torso) at 0 → death; delayable conditions →
  bleed-out window (R5: any further damage kills; stabilization is the clutch save).
  **Mind collapse (R5 amendment, RULED 2026-07-17): Dissolution completion removes the
  character from play PERMANENTLY — they become, forever, a puppet of whatever
  collapsed them.** No Ascension, no body to mourn; the party may meet what's left.
  Recruited NPCs are **permanently losable** (canon, every mode). **Player-OC death is
  run-type dependent (R17, RULED 2026-07-16):** softcore = normal respawn (the humane
  default; diegetic framing TBD), hardcore = permadeath (owner-preferred), Forsaken =
  hardcore by nature.
- **Campaign win:** clear the final floor-set; the verdict names your ruler-shape;
  Ascension = buying into the table with divinity (canon §3, cosmic-casino-canon).

## Game Mechanics

*The sim is the spec's enforcement: rules below marked ✅ are implemented and tested
(headless-tested). Numbers marked PLACEHOLDER await the tuning pass.*

- **Moment clock ✅** — absolute tick counter; `moment = 10 − (tick % 10)`; Clock
  completion advances all conditions (R4) and is the legal join beat for fields.
- **Actions ✅** — declared with Moment costs; multi-Moment actions are windups
  (channeling = Exposed, R2); reactions cost and resolve against the tick-start snapshot;
  R1 fixes the order of operations; R2 makes same-tick kills trade.
- **Requirements gate (R10) ✅** — unmet requirements: effect halved (floor) + Tool d6
  (whiff is the only negating consequence); condition-driven Forced Action – Body d6 on
  acting with a wounded part. The d6 tables are the drama generator, all rolls logged.
- **Per-part HP ✅** — Head 2 (lethal), Torso 5 (lethal), Arms 2, Legs 3 (canon per-race
  in `data/races.json`); parts disable at 0 (non-lethal), heads are not freely targetable
  (R7 targetability gates).
- **Conditions (9) ✅** — bleeding/crushed/chilled/exhausted/infected/burn/poison/
  dissolution as tier clocks (contiguous tiers, forced-action types, shock tiers);
  suffocation as a death **timer** (torso-only). Universal advancement on Clock reset;
  infected accelerates others; treat = delay one advancement, resolve = clear (R4/R10).
- **Breach ✅** — bleeding T2 on any part OR 7+ damage in a single hit opens the boss
  breach state (canon: Incinedile).
- **Shock — R13 PROVISIONAL** — direct-tier model (source tier applies; already-shocked
  escalates one above; high-water mark; T3 Faint = Helpless 1 Clock + drop items;
  combat-end reset). ✅ implemented as provisionally ruled; **owner confirm queued**.
- **Damage quantization (R14)** — 1 damage = lasting harm; unarmed untrained = 1; a slap
  between equals may be 0 — and 0-damage hits are real events (they can still deliver
  conditions). **Force-vs-robustness gate OPEN** (co-design session queued). All seeded
  damage numbers PLACEHOLDER until this lands.
- **Priming (R3, canon — replaces cooldowns)** — powerful skills gate on preparation
  states (channels, stacks, stances, conditions), never wait-timers; high-tier items may
  skip specific primes. **Vocabulary pending the owner's skills passover** — the engine's
  dormant cooldown path stays until then (KAN-2 remainder).
- **RPM / magazine (R8) ✅** — 1-Moment attack delivers up to RPM rounds, damage listed
  per round, magazine decrements per round, reload is an action. Flat item fields
  (`rpm`, `magazine`) — schema validated.
- **Movement ✅** — hex grid (axial coords); costs per R3; grapples (R9) with suffocation
  hooks; statuses (prone/slowed/overwhelmed); exposure states drive targetability.
- **Resistances ✅** — flat reduction by class (Physical/Affliction/Psychic), tier
  immunity distinct from reduction (R6); boss hooks: fire-heals, surface-immunity.
- **Friendly fire: ON (RULED 2026-07-17)** — spectacle wins; positioning is real.
- **Healing economy (RULED 2026-07-17):** applying a healing item costs a Moment; **no
  item regenerates HP** — items treat/delay conditions only; HP recovery is scarce by
  design (sources TBD: Lounge/rest candidates).
- **Combined actions (R15, owner 2026-07-16)** — same-Moment allies link declarations:
  **assists satisfy requirements** (a boost supplies the jump attack's height), merged
  attacks count as **one hit** for breach/force thresholds (the party's path past what
  no single attacker can clear), buffs and item handoffs join the same economy, and a
  partner's Forced Action degrades — never vetoes — the combo. Choreography earns a
  hype bonus.
- **Propose-a-Plan (owner 2026-07-16, sketch: `../design/propose-a-plan.md`)** — the
  party huddle as a mechanic: opt-in flowchart of steps; **per-step consent with
  written reasons** — an involved actor's rejection is an absolute conditional veto
  (step turns red, deletes, lands on the **refusal list** to replan around); **NPCs
  never propose — approve/reject/substitute only** ("I'll use skill X instead");
  executes as a **prefired run**; **branch from any step** (manual, or automatic when
  the plan is no longer possible) and **reconverge into previous plans** (a DAG);
  broadcast shows the called shot (full execution = hype multiplier); the **Tactician**
  selects NPC skills directly with condition visibility. Controller-layer only — plans
  compile to declarations; the sim never knows.

### Controls & Input ⟨PROPOSED⟩
Mouse-first declare UI: click combatant → action palette with requirement badges (met /
unmet-with-consequence preview) → target/part picker → confirm into the declare window.
Keyboard: number-row action slots, space = confirm, tab = cycle contestants. The
consequence preview (what the d6 could do) is load-bearing UX — pillar 2 demands the
player always sees the gamble they're taking.

## RPG Specific Elements

### Character System
- **Traits:** Physique / Reflexes (Body pillar), Mind / Charm (Core pillar).
  `total = base + bonus + levelBonus`. Creation: 7 across Body + 7 across Core, max 5
  per trait at creation (canon, matches live campaign data). **Charm = presentability
  (R18)** — objective aesthetics compared to others, the camera-facing stat; never
  charisma (likability lives in the audience systems).
- **Races (R16, owner 2026-07-16):** any living thing on Earth — **Human** and
  **Animal** only; **the Robot race is removed**. Per-race body plans in
  `data/races.json`; animals get an authored part layout at creation.
- **Leveling (R6):** **the system grants level points automatically** (owner 2026-07-16:
  the TTRPG's admin role is automated in the video game — progression rules issue
  `grant_level`, no human in the loop); points land in a single pool; a point buys +1
  levelBonus on any trait; Physique threshold crossings raise every part's max HP ✅.
  Over-10 stat caps (canon): Physique /5 → +1 part HP · Reflexes /12 → +1 Physical
  Resistance (allocated) · Mind /15 → +1 Psychic Resistance · Charm /20 → +1 Camera
  Call stack. **XP approved in principle (R6 amendment, 2026-07-17)** — level points
  may flow from XP rules; amounts are tuning.
- **Skill points:** per trait = traitTotal − 1 (first point earns nothing); multi-stat
  skills cost 1 from **each** listed stat; refunds tracked for level-down. **Respec
  (Q6, RULED 2026-07-17): never free — only via certain items or Lounge upgrades,
  always at a cost.**
- **Skills:** 43 seeded (jokes cut 2026-07-17; `reversion` seeded, exclusive to
  Nikita), thresholds at L5+ (78 rows); **level architecture RULED (R19): 0 =
  untrained, 1 = effect works, 1–5 = stat scaling, 6–10 = each level GENERALIZES the
  function to more situations while stats keep scaling** (Explosion example in R19).
  Detailed effects/growth passover still OPEN (owner) — R19 is its authoring template.
- **Background (OC creation):** structured picks (origin, vice, virtue, want) + freeform
  text → **grants the 4 starting skills** (R16 — humans free-ranging, animals biased
  toward race skills; any granted skill tradeable for +1 cap), seeds starting **traits**
  (epithet track), and drives **patron-god bidding** (patron-gods.md). The background is
  the single creation surface. ⟨picks structure PROPOSED; the rest canon⟩

### Inventory & Equipment
- Item types: weapon / equipment / consumable / tool / misc / key_item / system_item
  (28 seeded). Weapons carry typed damage (condition vocabulary), optional rpm/magazine.
- **Modifier economy (R12, canon):** tier gives affix slots — Crude 0/0 → Exceptional
  2/2 (prefix/suffix) — AND gates modifier-tier access; extraction friction scales by
  tier; 27 affixes seeded.
- Loot arrives as **comps** (casino diegesis): boxes/tiers, patron boons ride loot
  quality (buff taxonomy: temporary / continuous-on-condition / sometimes permanent).

### Quest System
- **Directives** = the house's commands (the one legitimate in-fiction HUD channel);
  **Goals** = crowd side-bets; both feed hype and favor. Sudden quests are the diegetic
  blast radius of other parties' actions (two-planes rule) — Stage 2 turns these
  cross-party. Floor objectives structure the main line; question-set choices are the
  branching spine.

### World & Exploration
- **Structure:** floors → districts/routes with **route exclusivity** and **time skips
  between floors** (the framework fast-forwards the host realm). ~20 floors in
  question-sets; sets 1–6 designed, 7+ paused (canon).
- **Fields:** combat is a delimited zone binding entrants to its clock; hard boundary
  (no shooting in/out; leavers forfeit); joins at Clock resets; **noise/absorption** —
  loud fights pull eligible neighbor encounters in at reset beats (anti-grind pillar).
- **Overworld time:** coarse ambient clock (Clocks tick on wall time) so conditions keep
  meaning between fields.
- **The Lounge (RULED 2026-07-16 — a walkable stage, not menus):** the comp suite you
  physically enter, and the EXCLUSIVE place where you **open loot**, **review contract
  changes** (patron deal updates, buy-out notices), and **tinker your character and
  run** — no field-side respecs or box-opening. Entering the Lounge also **triggers
  resets for ROAMING monsters** (see below). Multiplayer/shared Lounge remains Stage 3.
- **Roaming monsters (RULED 2026-07-16):** random encounters roam BETWEEN non-completed
  neighbourhoods; their state **resets when you visit the Lounge** — retreating to
  tinker repopulates the map. Retreat has a price; loitering has a price; the Lounge
  visit is a real decision.

### NPC & Dialogue
- **Recruitable NPCs with authored arcs** (canon): found in-world, earned via encounter,
  permanently losable. First two: Sasha (exit-calculus striker; recognition-asymmetry
  thread) and Nikita (Reversion showcase; the song prime). Player character is an OC.
- **No party cap** (canon): recruitment is an economy — strong allies are hard to get,
  weak ones short-lived; per-fight numbers bounded diegetically by arena deployment +
  exhaustion rotation.
- **Social consequences:** deterministic v1 behind the director interface; the
  mother-brain LLM upgrade (Stage 2+) emits schema-bound commands only (faction_shift,
  quest_spawn, world_manifest, system_message) — LLM interprets, sim decides.
- Dialogue presentation (RULED 2026-07-16): lower-third broadcast framing; barks + short
  trees; no VN layer, no cutscenes in v1. Animals cannot speak human — they talk to
  humans **through the chat function** (the System's comms channel renders their meaning;
  audibly it stays animal). (Dual-prose brand presentation: **post-MVP, set aside**.)

### Combat System
Covered in Game Mechanics — tactical, turnless, deterministic; ability system = skills +
priming; status effects = the condition clocks; party composition = no-cap recruitment.

## Audience & Casino Systems (the game's signature layer — KAN-7)

- **Exposure tiers:** Viewers → Followers → **Patrons (donator gods)**; above them THE
  **patron god** (singular escort; directs bet types; usually biggest donator).
- **Patron gods** (`design/patron-gods.md`, Q1–Q8 RULED): background-driven bidding
  (only the patron-less choose; refusal = plain patron-less run); multiplier boon
  economy (domain impressions; diffuse baseline vs focused patron gains; faction
  spill-over; per-god affection ledgers); tips as schema-bound `patron_tip` commands;
  buy-outs (notice of replacement; current god's agreement shown); abandonment =
  extraction or neglect, never contract exit; **Forsaken** = god-initiated all-in
  (hardcore opt-in; random offer from run 2+; manual after a first win ⟨PROVISIONAL⟩;
  never mid-run); god stats = fixed cores + seeded jitter.
- **Hype ✅ (v1 live):** deterministic spectacle meter inside state_hash; event-weighted
  (kills 60, breaches 45, damage 4/HP, forced actions 12 …all PLACEHOLDER), banded
  (cold/warm/hot/on-fire), decays per Clock, per-contestant ledgers; emits
  hype_spike / hype_band_changed into the broadcast stream.
- **Camera Call:** the odds board turns to you — stakes double, spotlight duty (canon
  mechanic; Charm-cap stacks). Numbers PLACEHOLDER.
- **Tags vs epithets:** tags = audience labels (84 live after the 2026-07-17 pass;
  drift by behavior). **Tag effects RULED: 5 declarative patterns (hype resonance,
  goal-weight bias, patron-impression lens, lifecycle dial, ≤10 flagship riders) + a
  6th — tags GATE unlocks: items, actions, and skills may require tags as obtain/use
  conditions.**
  **epithets** = trait-track myth recreation (traits from background + deeds; matching a
  legend's pattern grants its epithet; legends are artifacts of past games). **The myth
  catalog is real mythology, graded by level of myth — ORV-style (RULED 2026-07-16):**
  folk tale < local legend < heroic epic < world myth; ascended players' runs join the
  catalog at Stage 2. Deliberately
  separate systems; their divergence is the spine made mechanical.
- **Verdict system:** axes (necessary/right · safety/justice · self/many · …), each
  floor-set scores one axis from in-game choices; path-dependent unlock graph; final
  verdict function names the person and the ruler. **The convergence matrix is this
  instrument's data feed** (rev-6 top item — design in KAN-7, content in W4).
- **Two information planes (canon):** broadcast plane hears the announcer (dramatic
  irony is the product); contestants get world manifestations, sudden quests, System
  messages only.

## Progression & Balance

- Power comes from four faucets: trait growth (levels), skills (thresholds/priming),
  equipment (tiers/affixes), and **audience standing** (patron favor, epithets, comps).
  Balance philosophy ⟨PROPOSED⟩: the audience faucet is the widest — leaning into
  spectacle should out-earn safe play, because that *is* the spine's temptation.
- All numeric tuning is a dedicated pass after the R14 force-gate ruling; the tuning
  authority is live data from slice playtests, not theorycraft (small project — no
  spreadsheet economy yet).
- Difficulty (RULED 2026-07-16): **no difficulty menu** — run types (softcore/hardcore/
  Forsaken, R17), patron choice, and route selection are the difficulty surface the
  fiction already owns.

## Level Design Framework

- A floor-set = one moral question staged in the most entertaining way possible
  (canon). Every set needs: the question, 2+ routes with exclusivity, a set-piece boss
  with a discoverable win condition, at least one recruitment encounter, and a
  convergence-matrix touchpoint (what state persists into later floors).
- Arena canon: Incinedile P1 (41×60 hexes, 6-phase machine, breach = bleeding T2 any
  part or 7+ single hit, fire heals it, reflexes-counters at 7/9/roll-4+). The slice
  arena is P1 balanced for a party of 3 (player OC + Sasha + Nikita).
- Fields/absorption make level geometry tactical: encounter placement is a noise-budget
  problem for the player.

## Art & Audio Direction (visual-investment RULED 2026-07-16; style via mockup gate)

**ART ROUTE RULED (owner, 2026-07-18): GPT-generated stills + asset-ification pipeline**
(`docs/art/generation-prompts.md` — canon blocks for consistency; `scripts/spritify.py`
for alpha/palette/size; hybrid 64/48 fidelity). ComfyUI and Claude Design eliminated in
the bake-off. Owner hand-made art may layer on over time.

**Owner commitment: visuals get serious work even though they're our weaker side** —
quality bar over ambition bar. **16-bit pixel style is explicitly ACCEPTED as the
floor** if it buys consistency, good animation, and strong visual identity: a concise
style executed well beats an ambitious style executed raggedly. **Fidelity ceiling is an
open question (owner 2026-07-16: "maybe 16-bit is too little")** — the style-frame pass
tests a fidelity ladder (16-bit era → 32px → large-sprite "HD pixel" / 64-bit-era) and
the rule for choosing is: **the ceiling is set by ANIMATION cost, not still-frame
beauty** — we pick the highest fidelity we can animate consistently, not the prettiest
single frame. Direction: 2.5D sprites over hex terrain;
readability first (condition/part states visible at a glance); **animation is where the
budget goes** (the posture-swap transformations, hit reactions, the crowd's visual
temperature); two-posture silhouettes as transformation language (Nikita). Broadcast UI
chrome (odds boards, lower-thirds, hype bar as an on-air graphic) carries theme cheaply
at any fidelity. Audio: announcer VO is the flagship want (**Momus**, shared host —
RULED); diegetic crowd; tip/achievement stingers. Every art/UI direction ships a mockup
for approval before build (working rule) — the style decision itself goes through style
frames at the KAN-6 gate.

## Technical Specifications (GDD-level)

- Godot 4.7 / GDScript; headless `simulation/` (RefCounted, command-stream, seeded RNG,
  full serialization, state_hash) — the purity contract is DIRECTION's and is enforced
  by tests (headless-tested, incl. determinism + mid-combat save/resume).
- Clock drivers pluggable (paused / declare-window / wall-clock); director behind one
  interface (procedural v1, LLM-augmentable); saves = snapshot + command-log offset,
  re-derivable from the log; IDs string-UUID at JSON boundaries.
- Data: JSON seeds validated by `scripts/validate_seeds.py` (all rows green — live count in STATUS.md); SQLite
  static layer per architecture PDF (JSON-first DAL acceptable for the slice — KAN-3
  decision recorded in ISSUES).
- Tests are the honesty gate: `bash scripts/run_sim_tests.sh` (exit 3 = SKIP ≠ pass).

## Development Epics (summary — detail in `epics.md`)

| Epic | Scope | State |
|---|---|---|
| KAN-1 Data | schema + seeds + validator | ✅ done |
| KAN-2 Combat engine | headless sim, R0–R14, tests | ✅ core done (headless-tested) — remaining: priming impl, R13 confirm, R14 numbers |
| KAN-3 Scaffolding | main scene, GameController, DAL (JSON-first), hex renderer | next build block |
| KAN-4 Party | OC creation, recruitment, no-cap economy, exhaustion rotation | after KAN-3 |
| KAN-5 Exploration | floors/routes, fields, noise/absorption, overworld clock | |
| KAN-6 UI | declare UI, consequence preview, broadcast chrome, hype display | mockup gate first |
| KAN-7 Progression & audience | exposure, patron gods, epithets/myths, verdict, tuning | biggest epic — grew 3× with the frame adoption |
| SLICE (W3) | assembly of KAN-2..6 minimum + Incinedile P1 + fun-bar test | the MVP |

## Success Metrics

- **Slice (Stage-1 gate, canon):** a stranger plays 20 minutes, understands the clock,
  produces a clip-worthy moment, wants another run; the home table plays voluntarily.
- **Stage-2 gate:** external players return across multiple weeks; organic
  patronage/spectating appears.
- Engineering: suite stays green from a clean clone; determinism holds across
  save/resume (both already tested).

## Out of Scope (v1 / MVP)

Dual-prose brand presentation (post-MVP — owner 2026-07-16) · Stage 3 shared space & 3D ·
LLM director (deterministic v1 only) · VVIP/Forsaken mode (design canon now, build
post-slice) · PvP/interloper joins · buy-out events in the slice · the TTRPG book's
Narrative-Token table economy (digital replacement OPEN via questionnaire) · localization,
accessibility pass beyond baseline readability ⟨PROPOSED — a11y gate applies at UI epic⟩.

## Assumptions, Dependencies & OPEN Items

- **OPEN (owner):** title · Momus vs sibling host · TTRPG table re-skin · the timer
  (season mechanic vs starving-pantheon cosmology) · R13 shock confirm · R14
  force-vs-robustness gate co-design · skills effects/growth passover (priming
  vocabulary) · questionnaire batches (C/D/E/…) · player-OC death consequence ·
  Forsaken manual-trigger ⟨PROVISIONAL⟩.
- **[ASSUMPTION]** DCC-adaptation market timing (brief) — verify before public beats.
- **Dependencies:** live campaign data stays canonical content source (never break the
  char-sheet app); Workflow repo in session scope for the toolset; Godot binary via
  SourceForge mirror in containers.
