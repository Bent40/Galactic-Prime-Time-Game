---
title: "GDD — Galactic Prime Time (working title)"
game_type: rpg (2.5D tactical)
platforms: [pc]
status: draft — OWNER REVIEW GATE
created: 2026-07-16
updated: 2026-07-16
supersedes: docs/GPT_GDD_v02.pdf (kept as history; this document wins where they conflict)
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

PC (Windows/Linux), Godot 4.5. Stage 0–1 offline single-player is a permanently
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
   spectating, and async multiplayer near-free (already implemented, 29/29 tests).

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
  (10 ticks per Clock; Moment counts 10→1; Clock resets are the reorganization beat) →
  declare actions in the declare window (drivers: paused-on-decision solo / timed ~3–5s
  co-op / wall-clock broadcast — sim never self-advances) → requirements auto-succeed;
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
  Recruited NPCs are **permanently losable** (canon). Player-OC death: run ends —
  campaign consequence OPEN (retire-into-patron / new-contestant-same-season are the
  candidates; GDD v0.2's Ascension NG+ is the base until ruled).
- **Campaign win:** clear the final floor-set; the verdict names your ruler-shape;
  Ascension = buying into the table with divinity (canon §3, cosmic-casino-canon).

## Game Mechanics

*The sim is the spec's enforcement: rules below marked ✅ are implemented and tested
(29/29). Numbers marked PLACEHOLDER await the tuning pass.*

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
- **Combined actions (R15, owner 2026-07-16)** — same-Moment allies link declarations:
  **assists satisfy requirements** (a boost supplies the jump attack's height), merged
  attacks count as **one hit** for breach/force thresholds (the party's path past what
  no single attacker can clear), buffs and item handoffs join the same economy, and a
  partner's Forced Action degrades — never vetoes — the combo. Choreography earns a
  hype bonus.

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
  per trait at creation (canon, matches live campaign data).
- **Races:** Human (4 free skills; may trade 1 skill for +1 cap on another), Animal
  (2 race-bound + 2 free), Robot (chassis & AI defined per character). Per-race body
  plans in `data/races.json`.
- **Leveling (R6):** admin/system grants level points to a single pool; a point buys +1
  levelBonus on any trait; Physique threshold crossings raise every part's max HP ✅.
  Over-10 stat caps (canon): Physique /5 → +1 part HP · Reflexes /12 → +1 Physical
  Resistance (allocated) · Mind /15 → +1 Psychic Resistance · Charm /20 → +1 Camera
  Call stack.
- **Skill points:** per trait = traitTotal − 1 (first point earns nothing); multi-stat
  skills cost 1 from **each** listed stat; refunds tracked for level-down.
- **Skills:** 44 seeded (canon content), levels with thresholds from L5+ (82 threshold
  rows), caps ≤ 10; `exclusive_to` supports character-bound kits (Nikita's Reversion is
  the priming showcase). **Effects/growth passover OPEN (owner).**
- **Background (OC creation):** structured picks (origin, vice, virtue, want) + freeform
  text → seeds starting **traits** (epithet track) and drives **patron-god bidding**
  (patron-gods.md). ⟨PROPOSED structure; system canon⟩

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
- **The Lounge** (comp suite): base/downtime layer — Stage-1 scope is menus-over-scenes
  ⟨PROPOSED⟩; shared space is Stage 3.

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
- Dialogue presentation ⟨PROPOSED⟩: lower-third broadcast framing; barks + short trees;
  no full VN layer in v1. (Dual-prose brand presentation: **post-MVP, set aside** —
  owner 2026-07-16.)

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
- **Tags vs epithets:** tags = audience labels (100 seeded; drift by behavior);
  **epithets** = trait-track myth recreation (traits from background + deeds; matching a
  legend's pattern grants its epithet; legends are artifacts of past games). Deliberately
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
- Difficulty: no difficulty menu in v1 ⟨PROPOSED⟩ — patron choice, Forsaken runs, and
  route selection are the difficulty dials the fiction already owns.

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

## Art & Audio Direction ⟨PROPOSED — mockup gate applies before production⟩

2.5D sprites over hex terrain; readability first (condition/part states visible at
glance); two-posture silhouettes as transformation language (Nikita). Broadcast UI
chrome (odds boards, lower-thirds, hype bar as an on-air graphic). Audio: announcer VO
is the flagship want (host voice pending Momus decision — OPEN); diegetic crowd;
tip/achievement stingers. Every art/UI direction ships a mockup for approval before
build (working rule).

## Technical Specifications (GDD-level)

- Godot 4.5 / GDScript; headless `simulation/` (RefCounted, command-stream, seeded RNG,
  full serialization, state_hash) — the purity contract is DIRECTION's and is enforced
  by tests (29/29, incl. determinism + mid-combat save/resume).
- Clock drivers pluggable (paused / declare-window / wall-clock); director behind one
  interface (procedural v1, LLM-augmentable); saves = snapshot + command-log offset,
  re-derivable from the log; IDs string-UUID at JSON boundaries.
- Data: JSON seeds validated by `scripts/validate_seeds.py` (172 rows green); SQLite
  static layer per architecture PDF (JSON-first DAL acceptable for the slice — KAN-3
  decision recorded in ISSUES).
- Tests are the honesty gate: `bash scripts/run_sim_tests.sh` (exit 3 = SKIP ≠ pass).

## Development Epics (summary — detail in `epics.md`)

| Epic | Scope | State |
|---|---|---|
| KAN-1 Data | schema + seeds + validator | ✅ done |
| KAN-2 Combat engine | headless sim, R0–R14, tests | ✅ core done (29/29) — remaining: priming impl, R13 confirm, R14 numbers |
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
