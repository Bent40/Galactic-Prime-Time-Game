# Project Brief

<!-- wf memory: required sections below; keep the headings. -->

## Purpose

Convert the owner's live TTRPG campaign **Galactic Prime Time** (reality-TV dungeon
crawler; abducted contestants fight on an alien broadcast) into a video game. Committed
destination: a **shared world where the show runs globally** (see `docs/DIRECTION.md`),
reached by a staged ladder — never a big-bang MMO build. Near-term product: a 2.5D
tactical RPG vertical slice (Moment-clock combat, per-body-part conditions, audience
spectacle meter), then friends co-op, then an async global show service.

## Scope

- Godot 4.7 game (this repo): headless deterministic combat sim (command-stream),
  2.5D tactical presentation, SQLite static data + JSON saves per `docs/architecture/architecture.md` (origin: `docs/archive/GPT_ARCHITECTURE.pdf`).
- Digital rules addendum (`docs/rules-addendum.md`) answering the rulebook's gaps.
- Seed data completed from the rulebook + live campaign DB export.

## Out of scope

- Real-time shared space / MMO infrastructure (Stage 3 — gated on external traction).
- 3D presentation (reconsidered only at Stage 3).
- LLM game-master features (director stays procedural v1, behind one interface).
- The character-sheet web app (separate repo `Galactic-Prime-Time`) — it's the live
  campaign tool; don't break it, only read its data.

## Stakeholders

- **Owner/designer/dev:** Ben (solo, hobby cadence; also GM of the live campaign).
- **First players:** the live campaign table (5 players) — the built-in playtest group.
- **Target audience:** litRPG / Dungeon Crawler Carl readership (review-4 §1 lane).

## Constraints

- Solo developer, evenings/weekends; scope must respect the stall-risk evidence
  (review-4 §2) — every milestone shippable, smallest honest vertical slice first.
- Godot 4.7 / GDScript; architecture doc's MVC + headless-sim rules are binding.
- Sim must honor the command-stream contract (docs/DIRECTION.md) at every stage.
- Test runs require a Godot binary; containers without one must report SKIP, not green.
