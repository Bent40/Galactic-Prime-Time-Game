# Review 3 — The Existing Game Repo (Godot Attempt)

**Scope:** `Galactic-Prime-Time-Game` as it stands on `main` (8 commits, 2026-05-01 → 2026-05-02).
**Method:** full file inventory + first-hand verification of every load-bearing claim (stub
hashes, scene contents, `project.godot`, schema, seed data, both design PDFs read in full).

---

## Verdict

**Architecture-complete, implementation-not-started.** This repo is one finished epic
(KAN-1 Data Foundation) plus an excellent set of design documents wrapped around twelve
empty script templates and sixteen empty scenes. It is not a failed attempt — it is a
well-prepared start that stopped after two days. Nothing in it is rotten; almost nothing in
it is built.

The honest run-state: **the project opens in Godot 4.5 to an empty window.** No main scene
is set, no autoload is registered, and the required `godot-sqlite` plugin is not vendored
(`addons/` does not exist), so even the one piece of real code cannot execute.

---

## Inventory — what is actually here

| Layer | Files | State |
|---|---|---|
| Design docs (`docs/`) | 4 PDFs | **Real and strong** (see below) |
| DB schema (`data/migrations/001_initial_schema.sql`) | 246 lines | **Real** — 15 tables, CHECK + FK constraints, JSON-validity guards, versioning row |
| Migration runner (`data/migrations/run_migrations.gd`) | 202 lines | **Real** — typed, defensive, hand-written SQL splitter aware of quotes/comments; the only genuine game code in the repo |
| Seed data (`data/*.json`) | 7 files, ~730 lines | **Structurally real, content placeholder** — every description literally says "Placeholder" |
| Simulation layer (`simulation/*.gd`) | 7 scripts | **Empty** — byte-identical Godot templates (verified: all 12 gameplay scripts share one MD5) |
| Controller layer (`controller/*.gd`) | 5 scripts | **Empty** — same identical template |
| Scenes (`scenes/`, `ui/`) | 16 `.tscn` | **Empty** — each is 3 lines: one root node, no children, no scripts |
| Tests | 0 | **None** — despite the architecture doc's closing rule: "Do not skip writing unit tests for simulation classes" |

Git history is a single two-day burst: folder skeleton → docs → KAN-8/9/10 (database work),
then silence. The commit messages reference a Jira project (KAN), and the architecture doc
defines the epic order KAN-1 → KAN-7. Work halted exactly at the KAN-1/KAN-2 boundary —
i.e. right before the first hard problem (the headless combat engine).

## The genuinely valuable artifacts (keep these regardless of any restart decision)

1. **`docs/GPT_ARCHITECTURE.pdf` (15 pp)** — a real technical contract, not aspiration-ware:
   MVC with a headless `RefCounted` simulation layer, single-owner rules (only `dal.gd`
   touches SQLite, only `save_manager.gd` touches saves), a complete signal catalog, a
   serialization contract (`to_dict`/`from_dict` on every sim class), naming conventions,
   the KAN epic order, and a blunt "What Not To Do" list. If a competent developer followed
   only this document, the resulting codebase would be testable and save-safe. This is the
   single most valuable artifact in all three repos for the game effort.
2. **`docs/GPT_GDD_v02.pdf` (11 pp)** — coherent vision (2.5D tactical, clock combat, hex
   grid, party deploy/bench with exhaustion, three floors with time-skip consequences,
   Ascension→Patron NG+ loop, race-unlock meta) with an honest §9 "Open Design Questions"
   and §10 risk register that correctly names the four real risks (clock readability, Forced
   Action digitization, Narrative Token redesign, solo scope).
3. **The SQLite schema** — closely mirrors the TTRPG's data shapes (skill caps 0–10,
   condition tiers with shock, enemy phases, patron goals, tag goal-modifier weights) and is
   properly constrained.
4. **`run_migrations.gd`** — small but production-quality; shows the developer can write the
   code the architecture demands.

## Gaps — measured against the repo's own architecture doc

- **Per-body-part HP values exist nowhere in data.** `races.json` and `enemies.json` carry
  body-part *name lists* only; a grep for hp/health across all json/sql/gd returns nothing.
  The rulebook's Head 2 / Torso 5 / Arm 2 / Leg 3 never made it in. (Design intent parks HP
  in `CombatantState` — which is an empty stub — but *base/max* values are static data and
  belong in the seed.)
- **`condition_tiers` and `skill_thresholds` tables are never seeded** — the tier-by-tier
  condition effects and the level-5+ threshold system (both core mechanics) are schema-only.
- **Stubs already violate the architecture**: every simulation stub `extends Node`; the doc
  mandates `extends RefCounted` with no Node dependencies. Trivial to fix, but it means zero
  of the MVC discipline is actually instantiated yet.
- **No `addons/` (godot-sqlite), no `assets/`, no `content/`** — three of the doc's required
  top-level directories don't exist. Fonts named in the doc are not present.
- **No main scene / no autoload wiring** — `project.godot` is 16 lines; `GameController` is
  specified as an autoload singleton but never registered.
- **Item damage types in seed data only cover Bleed/Crush** — no burn/chill/poison weapons
  yet (the conditions themselves are all present in `conditions.json`, all nine, with
  resistance classes matching the rulebook).

## Sunk-cost analysis

Real, reusable work in this repo ≈ **450 lines of code/SQL + the documents**. The twelve
stub scripts and sixteen empty scenes represent zero hours of preserved effort — recreating
them is one `mkdir`/template pass. Therefore:

> **"Continue vs. start anew" is nearly a false choice at the code level.** Whichever way the
> decision goes, the actual next act is the same: implement KAN-2 (the headless combat
> engine) against an already-written spec. What the decision *really* determines is whether
> the design documents and schema stay authoritative — and they should (with amendments
> noted in Review 2, because the architecture doc hard-codes "Network: None / fully offline
> single-player," which now conflicts with the stated co-op target).

## One caution flag (process, not code)

The two-day burst → stall pattern, with the stall landing exactly where the first genuinely
hard implementation work begins, is itself a data point about scope risk — the same risk the
GDD's §10 already names ("Solo build scope"). The verdict document (Review 4) takes this
into account when recommending the ambition bar and the size of the first milestone.
