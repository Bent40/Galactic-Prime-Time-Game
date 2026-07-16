# Product Direction — Decision Record

**Date:** 2026-07-13 · **Status:** DECIDED (owner-confirmed) · Refines the recommendations in
[docs/review/review-4-verdict.md](review/review-4-verdict.md) §2–§5 where they differ.

## Decisions

- **D1 — North star: the shared-world show.** Galactic Prime Time's destination is a shared
  world where *the show is running globally* — every party's runs push the same floors, other
  players are the audience, and retired characters patron strangers' runs. Reached by the
  staged ladder below, never by a big-bang MMO build.
  *Chosen over:* single-player-only (F&H path with the MMO as a someday-dream) and a literal
  3D-MMO pivot (rejected: ~zero solo ship probability; infrastructure-first year with nothing
  playable; would warp or discard the Moment clock).
- **D2 — Presentation: 2.5D tactical**, per GDD v0.2. 3D is reconsidered only at Stage 3,
  and only with team/funding. Rationale: lowest asset cost, best Moment-clock readability,
  matches every solo-dev success comparable.

## Why (recorded reasoning)

The owner weights the shared-show *experience* as the goal, not just a shippable single-player
game. The review found the fiction is genuinely MMO-native — everyone-is-a-contestant explains
multiplayer; spectators are diegetic viewers; Ascension→Patron transposes into a cross-player
sponsorship economy no comp has. But solo-built MMOs are a graveyard (Project Gorgon: 2 devs,
a decade, niche; Book of Travels; BitCraft's funded multi-year build), and even a "one dungeon
beta" MMO needs the full substrate (accounts, servers, sync, anti-cheat, moderation, hosting,
live-ops) before any fun exists. The ladder keeps every rung shippable and valuable if the
next rung never happens, while keeping the destination technically reachable at every step.

## The ladder

### Stage 0 — Simulation core (now; = KAN-2 with a stricter contract)
Headless, deterministic combat engine, specified as a **server-authoritative command stream**
from day one (see technical contract). Ships nothing player-facing; ships a unit-tested engine.

### Stage 1 — Vertical slice, then co-op instanced runs
The review-4 §5 slice (one arena, two contestants, Incineradile Phase 1, visible hype meter,
broadcast-framed win/lose) single-player first; then friends-join-host co-op (host-based or a
thin Node relay). **Checkpoint demo: two clients, one host, one dungeon run.**
**Advance when:** the slice passes its fun bar (a stranger plays 20 minutes, understands the
clock, produces a clip-worthy moment, wants another run) and the home table plays voluntarily.

### Stage 2 — The async global show (the dream at hobby-feasible cost)
One lightweight central service (Express/Mongo — the owner's professional stack) that
aggregates all parties' runs into **global floor progress**, issues global directives and
broadcast events, enables **cross-player patronage** (Ascended characters sponsor other
players' runs), and serves **replays/spectating as broadcasts** (near-free given the command
stream). No shared physical space — but the *world* is shared. Pattern: Helldivers 2 galactic
war / Death Stranding async.
**Advance when:** external players (not the home table) return across multiple weeks and
organic patronage/spectating activity appears.

### Stage 3 — Real shared space (earned, not assumed)
Multiplayer Lounge hub, co-located persistent dungeon runs, live spectating at scale. Enter
only with traction + revenue and realistically not solo. 3D (stylized/lo-fi) is reconsidered
here for the social/exploration layer.

**Honesty rule:** each stage must prove itself with *external* evidence before the next is
funded with time. A stage that stalls does not invalidate the previous rung — every rung is a
complete product.

## Technical contract deltas (amendments to GPT_ARCHITECTURE.pdf)

1. **Command-stream simulation.** The sim advances only via ordered commands:
   `apply_command(cmd) -> [events]`. State must be a pure function of `(seed, command log)` —
   same inputs ⇒ same state hash. No wall-clock reads, no unlogged randomness inside the sim
   (RNG seeded and advanced only by commands). Replay, spectate, co-op sync, and Stage-2
   broadcasts all fall out of this one property.
2. **IDs multi-party-safe from day one:** entity IDs globally unique at the JSON boundary
   (string UUIDs), per the doc's existing int-in-SQLite / string-in-JSON rule.
3. **"Network: None" is rescoped** from a permanent principle to the Stage 0–1 client
   posture. Offline single-player remains a permanently supported mode at every stage.
4. **Director behind one interface** (goals, directives, audience reactions, narrative
   beats): procedural in v1, LLM-augmentable later, server-side from Stage 2. No game logic
   may call director internals directly.
5. **Saves reconstructible:** checkpoint = state snapshot + command-log offset; JSON save
   files remain, but the snapshot must be re-derivable from the log.
6. Unchanged: `RefCounted` headless model, MVC boundaries, SQLite static-data layer, DAL
   single-owner rule, signal catalog, naming conventions.

## Design sketch — combat fields & clock drivers (status: SKETCH, owner-proposed)

*Not yet DECIDED — promote after the digital rules addendum settles the tick rulings.*

**Idea (owner):** Moments only exist inside combat and as time calculations. In the shared
world, combat is a **field** — a delimited zone in the world; entering it binds you to that
field's shared Moment clock, with time pressure so players can't stall each other.

**Refinement (review):** treat Moments as **real-time ticks with a declare window**, not
turns with timers — the clock advances on a wall-clock cadence inside a field (tunable,
~3–5s/Moment, may accelerate when all combatants have committed); miss your declare window
and you idle or a default fires. Continuous pressure, no waiting on other players' menus,
faithful to "there are no turns."

- **Clock drivers are pluggable, sim never self-advances:** paused-on-decision (solo, ATB
  wait-mode feel) / timed declare windows (co-op fields) / pure wall-clock (spectated
  broadcasts). Same deterministic sim under all three — the driver only decides *when*
  commands are fed in. This slots directly into the command-stream contract above;
  no contract change required.
- **Precedents (pattern is MMO-proven):** Wizard101 combat circles, Dofus/Wakfu tactical
  fights with turn timers, Toontown cog battles, OSRS's global 0.6s tick.
- **Field rules to settle later:** hard boundary (entrants rooted, no shooting in/out,
  leavers forfeit); joining legal only at Clock resets (the book's existing reorganization
  beat; diegetically "the cameras cut to the new arrival"); interloper/pvp-adjacent join
  rules are Stage 3 only — Stages 1–2 fields are party-instanced.
- **Out-of-combat time:** overworld runs a coarse ambient clock (Clocks tick on wall time)
  so conditions/cooldowns keep advancing between fields; fields run the fine Moment clock.
- **Noise/absorption (compendium GDD v0.1, adopted):** noisy combat attracts nearby
  encounters — when a field's Clock completes, eligible area encounters can be absorbed
  into the ongoing fight. Kills grinding, makes stealth/social relevant, and the audience
  clock and absorption clock can be one system. Slots directly into the field model: an
  absorption = a join event at the Clock-reset beat.
- **Dependency:** raises the priority of the free-action-cap ruling (review-1 finding D1) —
  unlimited 0-cost actions inside a real-time tick would become an APM contest. The digital
  rules addendum must settle actions-per-tick first.

## Rulings adopted 2026-07-14 (owner)

- **No cooldowns — priming instead** (addendum R3): powerful skills gate on preparation
  conditions (channels, stacks, stances), never wait-timers; high-tier items may skip
  specific primes. Priming vocabulary designed with the owner's skill passover.
- **No party cap.** Recruiting allies is an economy, not a limit: strong allies are hard to
  recruit, weak ones are short-lived — "a thousand grunts if you can use them well."
  Per-fight numbers are bounded diegetically by arena deployment + exhaustion rotation
  (GDD) — never by a menu cap. (Answers the GDD's open "party size cap" question.)
- Incinedile canon: 6 phases (fight/explosion ×2, fight, large explosion); breach B =
  7+ damage in a **single hit**.

## Design sketch — the social director ("mother brain", Stage 2+ north star)

Owner-proposed: NPC contestants are ordinary clients running AI policies that **accept
override commands from a director service**. One central brain (or a few specialized ones)
watches the event stream and adjudicates social consequences — e.g. a player delivers a
speech accusing X; persuasiveness = Charm + LLM-judged quality of the *actual words*; the
director decides town Y turns hostile to X. Feasibility assessment (recorded): **sound and
staged-feasible**, with these binding constraints:

1. **LLM interprets, sim decides.** The director never mutates state; it emits *schema-bound
   commands* into the same logged stream as players (`faction_shift`, `npc_stance`,
   `goal_spawn`… with magnitude caps scaled by Charm). Determinism, replay, and bounded
   blast radius survive; the LLM picks from a legal-effects menu, it doesn't freewrite.
2. **One brain over many NPCs, never per-NPC models** (owner's instinct is correct — the
   proven pattern: deterministic triage picks affected NPCs by reach/graph/geometry, ONE
   batched adjudication call decides responses; small local model triages, big model only
   on notable events).
3. **Speech scoring = LLM-judge with fixed rubric** + deterministic combiner (Charm, tags,
   audience state). Guard against prompt injection and munchkining (schema-clamped scores,
   speech costs camera time, the audience reacting to manipulation is itself content).
4. **Two information planes (owner refinement, 2026-07-14).** Contestants are INSIDE the
   show — they never hear the announcer. Consequences reach each plane differently:
   - **Broadcast plane** (spectators, replays, dead-teammate spectating, Stage-2 viewers):
     the announcer explains everything. Dramatic irony is the product — the audience knows
     town Y is marching on player X before X does.
   - **Diegetic plane** (contestants): consequences arrive as *world manifestations* (a
     hunting party on the road, closed gates, bounty posters, NPC whispers) and — for
     uninvolved players inside the blast radius — as a **sudden quest**: intercept it,
     profit from it, or get out of the way. The Corporation's System messages (directives/
     goals) are the one legitimate in-fiction "HUD" channel and can carry director output
     when the Corporation would plausibly say it.
   Director command menu therefore includes `quest_spawn(scope, offer, urgency)`,
   `world_manifest(entities, behavior, location)`, `system_message(recipients)` — all
   schema-bound like everything else. Note the Stage-2 payoff: another party's actions
   ripple into *your* run as a sudden quest — cross-party consequence without shared space.
5. **Staging:** Stage 1–2 ships deterministic social scoring behind the director interface;
   the mother brain replaces the policy at Stage 2+ without engine changes. This is exactly
   why the command-stream contract exists.

## Rulings adopted 2026-07-16 (owner) — the setting frame

- **D3 — The frame is the Cosmic Casino, taken game-first.** The show is a table in the
  gods' casino (the owner's own novel world — *A Day of Ruin*; inventory:
  `cosmic-casino-canon.md`). **We take the game, not the story:** Marcus/Viola/the third
  protagonist are examples of how games look, never game content. Mix-and-match license is
  explicit — where casino canon and GPT differ on *gameplay*, **the dungeon/tables work
  closer to GPT's way**. (Options record: `setting-rebrand-options.md`.)
- **D4 — Cast structure:** the player is an **OC** (their own created contestant); NPCs
  are **predesigned characters with story arcs** (Sasha & Nikita are the first two —
  recruitable, `story-canon.md`).
- **D5 — Patron gods** (amended same day): a roster of gods with stats for **generosity,
  power, buff domains, and favor conditions**. Two tiers: **patrons** (plural — donator
  gods who buy you things; the exposure ladder's top rung) vs **THE patron god** (singular
  escort who directs the types of bets on you; usually your biggest donator). Assignment
  is **background-driven** (keywords from the player-written OC background draw god bids;
  only the patron-less can choose — ORV rule), not purely random. **Forsaken runs are
  god-initiated, not refusal:** the gods' way of going all-in — a champion *chosen* for a
  trial bigger than others; patron intact, all help sealed, higher divinity/payout.
  Buy-outs (god-side contract transfer) proposed. **Boon economy = the multiplier model:**
  the patron decides how much/which type/how strong — domain-tagged actions raise buff
  chances and tier odds, diffusely across related gods when patron-less, focused and
  amplified (patron domain top multiplier, faction spill-over, directed affection gains)
  under a patron. Design sketch: `design/patron-gods.md` (builds in KAN-7).
- Still open from the frame swap: TTRPG-table re-skin?, Momus shared vs sibling host,
  title, the timer (see `setting-rebrand-options.md` open decisions).

## Source-of-truth precedence

1. This document (owner-decided direction).
2. `docs/rules-addendum.md` (canonical digital rulings; R12 = compendium-adopted systems).
3. **`docs/GPT_Master_Compendium.md`** (consolidated design record through ~May 5: system
   v0.91, GDD v0.1 decisions, boss/modifier design, campaign story, party data). Where it
   conflicts with newer live data, see `docs/review/review-5-compendium-delta.md` NQ items.
4. The GDD/architecture PDFs, then the rulebook docx.

## What does NOT change

- **Build order:** digital rules addendum (review-1 fix-first five) → KAN-2 headless engine
  with unit tests → slice. No scenes before the engine.
- **Engine:** Godot 4 / GDScript. The web stack keeps serving the live campaign tool now and
  becomes the Stage-2 service later.
- **Market posture** (review-4 §1–§2): litRPG/DCC audience is the lane; the slice goes to the
  home table, then r/litrpg; pricing/ambition decisions wait for external signal.
