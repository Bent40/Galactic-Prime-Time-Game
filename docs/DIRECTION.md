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

## What does NOT change

- **Build order:** digital rules addendum (review-1 fix-first five) → KAN-2 headless engine
  with unit tests → slice. No scenes before the engine.
- **Engine:** Godot 4 / GDScript. The web stack keeps serving the live campaign tool now and
  becomes the Stage-2 service later.
- **Market posture** (review-4 §1–§2): litRPG/DCC audience is the lane; the slice goes to the
  home table, then r/litrpg; pricing/ambition decisions wait for external signal.
