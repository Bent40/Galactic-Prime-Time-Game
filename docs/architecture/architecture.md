# Architecture — Galactic Prime Time (consolidated, 2026-07-16)

*Status: draft — owner review. Consolidates: `GPT_ARCHITECTURE.pdf` (base — MVC contract,
signal catalog, KAN epic order; still authoritative where unamended) + DIRECTION.md
technical deltas + the live implementation (simulation/, headless test suite — see STATUS.md) + designed-unbuilt
systems (GDD, patron-gods). This doc owns the HOW; the GDD owns the WHAT. ⟨PROPOSED⟩ =
new consolidation-time calls; everything else is already decided and dated.*

## Executive Summary

Headless deterministic simulation core (Godot 4.7 / GDScript, `RefCounted`, zero node
deps) advanced ONLY by a command stream — state is a pure function of (seed, ordered
command log), enforced by tests. Presentation (scenes) and control (GameController, DAL,
save manager) sit on top per the PDF's MVC contract. Everything the ladder needs later —
replay, spectate, co-op sync, async global show — is a property of the command stream,
not a bolt-on. The director (goals, audience, patron tips, social consequences) is a
single interface with a deterministic v1 policy; LLM augmentation slots in behind it
without engine change.

## Decision Summary

| Category | Decision | Affects epics | Source/date |
|---|---|---|---|
| Engine | Godot 4.7 / GDScript, 2.5D | all | review-4 + owner 2026-07-13 |
| Sim contract | command-stream purity; no wall-clock; single seeded RNG advanced only in `apply_command`; every roll logged as an event | KAN-2+ | DIRECTION delta 1 (✅ built) |
| IDs | string UUIDs at JSON boundaries; ints allowed inside SQLite | all | DIRECTION delta 2 |
| Clocking | drivers OUTSIDE the sim feed `advance_tick` (paused / declare-window / wall-clock) | KAN-3/5 | DIRECTION delta + R0 (✅ sim side) |
| Saves | snapshot + command-log offset; snapshot re-derivable from log | KAN-3 | DIRECTION delta 5 |
| Director | ONE interface for goals/directives/audience/patron tips/social; schema-bound commands into the same logged stream; deterministic v1 | KAN-7 | DIRECTION delta 4 + patron-gods |
| Static data | JSON seeds validated by `validate_seeds.py`; **JSON-first DAL for the slice**, SQLite deferred | KAN-3 | ISSUES (owner-acked deferral) |
| Audience state | hype = derived sim state inside `state_hash` (✅ built); exposure cache per combatant (✅) | KAN-2/7 | this repo 2026-07-16 |
| Network | "None" = Stage 0–1 client posture; offline single-player permanent | KAN-3+ | DIRECTION delta 3 |
| Testing | headless runner, honesty gate (SKIP ≠ pass), determinism + save/resume suites | all | this repo (✅) |

## Project Structure (current + planned)

```
Galactic-Prime-Time-Game/
├── simulation/          # MODEL — RefCounted, headless, command-stream only (✅ live)
│   ├── combat_sim.gd    # facade/reducer: apply_command -> [events]; state_hash
│   ├── clock.gd  combatant.gd  action_resolver.gd  condition_engine.gd
│   ├── forced_action.gd  resistance.gd  exposure_engine.gd  hype_engine.gd
│   └── (planned) priming.gd · director/ (interface + deterministic policy,
│       patron_engine consuming affection ledgers) · verdict_store.gd
├── controller/          # GameController autoload, dal.gd (single data owner),
│   │                    # save_manager.gd (single save owner), patron_manager.gd
│   └── (KAN-3: JSON-first dal behind the same API the SQLite dal will honor)
├── scenes/              # presentation ONLY; talks through GameController signals
├── data/                # JSON seeds (validated); migrations/ (SQLite, deferred)
├── tests/               # test_runner.gd + suites (see STATUS.md)
└── scripts/             # run_sim_tests.sh (import-guard), setup_godot.sh, validate_seeds.py
```

## Epic ↔ Architecture Mapping

| Epic | Architecture surface |
|---|---|
| KAN-2 remainder | `priming.gd` replaces dormant cooldown path; R13/R14 finalization touches condition_engine + resolver only |
| KAN-3 | GameController + signal catalog (PDF §signals); JSON DAL; clock driver (paused); save manager |
| KAN-4 | creation flows over existing CombatantState.from_spec; roster in controller state |
| KAN-5 | field manager (binds parties to a sim instance; join-at-reset; absorption = scripted join events); overworld coarse clock driver |
| KAN-6 | scenes consume events/signals; zero sim knowledge; consequence-preview queries resolver validation paths read-only |
| KAN-7 | director interface + policies (directives/goals/patron tips); affection/epithet/verdict stores as sim-adjacent derived state ⟨PROPOSED: same purity discipline as hype — serialized, hashed⟩ |

## Implementation Patterns & Consistency Rules (binding for all agents)

- **Purity:** nothing in `simulation/` reads wall-clock, spawns nodes, or touches
  filesystem; RNG only via the sim's seeded instance inside `apply_command`; any
  randomness must emit its roll in an event.
- **Events:** flat Dictionaries, `type` + snake_case fields, stamped with `tick` (and
  `moment` on clock-boundary events) by `_post`; rejected commands emit ONE
  `command_rejected` and mutate nothing. Iterate dictionaries with **sorted keys** —
  unordered iteration breaks replay determinism.
- **Serialization:** every sim class ships `to_dict()`/`from_dict()`; state comparisons
  go through `CombatSim.canonical_serialize` (key-sorted, type-stable). New derived-state
  modules (patron/verdict) MUST join `to_dict` + `state_hash` (hype is the precedent).
- **Single owners:** only `dal.gd` touches static data storage; only `save_manager.gd`
  touches save files; scenes never import simulation classes directly.
- **Naming:** GDScript 4 typed style, tabs, `class_name` PascalCase, snake_case members;
  test files `tests/test_*.gd` auto-discovered (runner needs no registration). New
  `class_name` scripts require the import-guard (stale `.godot` cache pitfall — see
  learnings `godot-stale-class-cache`).
- **Error handling:** sim = reject-and-event, never assert/crash on bad commands;
  controller validates before feeding commands; tests use accumulate-failures base.
- **Logging:** the event stream IS the log. No print-debugging left in sim code.

## Data Architecture

- Seeds: races · enemies (phases, traits, resistances) · conditions (tier tables) ·
  skills (+thresholds, `exclusive_to`) · items (flat `rpm`/`magazine`) · tags ·
  modifiers · patron_gods (stub) — all validated (172 rows, cross-refs, enum mirrors of
  the SQLite CHECKs).
- Contestant runtime state: CombatantState (traits w/ level_bonus, per-part HP dicts,
  conditions per part, statuses, items, cooldowns[deprecated-dormant], shock,
  bleed_out, exposure cache) — fully serializable.
- Planned stores (KAN-7): per-god `affection` ledger, `traits`/epithets, verdict axes +
  unlock graph state, convergence-matrix world-state — all keyed to the same
  serialization discipline ⟨PROPOSED⟩.
- Cross-repo: the char-sheet app's MongoDB stays the live-campaign content source
  (one-way: export → seeds; never write back; vocab drift catalogued in review-1).

## API Contracts

- **Sim boundary:** `apply_command(cmd: Dictionary) -> Array[Dictionary]` — the complete
  command vocabulary is documented in `combat_sim.gd`'s header and MUST stay in sync
  with it (single source).
- **Director interface (KAN-7, from DIRECTION §director + patron-gods):**
  `propose(events, state) -> [schema-bound commands]` where commands ∈ {goal_spawn,
  directive, faction_shift, npc_stance, quest_spawn, world_manifest, system_message,
  patron_tip(boon|trial, magnitude, target)} with magnitude caps. v1 policy is
  deterministic; the interface is the contract, policies are swappable.
- **Stage-2 service (future):** consumes command logs/replays; Express/Mongo; out of
  scope until Stage-1 evidence.

## Security & Integrity

Stage 0–1: no network surface; integrity = determinism (state_hash comparisons catch
drift/tampering in co-op later — server-authoritative from Stage 2). LLM-director era:
schema-clamped commands, magnitude caps, injection guards on speech scoring (DIRECTION
§mother-brain constraints 1–4). Secrets: none in repo; no telemetry in v1 ⟨PROPOSED⟩.

## Performance

Sim is O(combatants × parts) per tick with sorted-key iteration; hex fields are small
(≤ 41×60). Budget ⟨PROPOSED⟩: sim tick < 1 ms typical on the perf-target machine;
renderer owns the frame budget (GDD: 60 FPS on a 2015 laptop). Measure in the slice via
`gds-performance-test` before optimizing anything.

## Deployment & Environments

- Dev: clean clone → `bash scripts/setup_godot.sh` (SourceForge mirror; container-safe)
  → `bash scripts/run_sim_tests.sh` (exit 3 = SKIP, honesty rule) →
  `python3 scripts/validate_seeds.py`. `wf validate` wraps both (bmad.config.yaml).
- Ship (Stage 1): desktop export presets, offline. Stage 2 adds the service — separate
  repo/deployment, not this one.

## ADRs (index — full context at the cited sources)

1. **Command-stream sim** (DIRECTION Δ1, 2026-07-13) — everything multiplayer-shaped
   falls out of purity. Status: built, tested.
2. **Clock drivers external** (R0/Δ; 2026-07-13) — sim never self-advances. Built.
3. **JSON-first DAL for the slice** (ISSUES, owner-acked) — SQLite deferred until
   content volume demands it; DAL API written SQLite-shaped so the swap is internal.
4. **Hype as hashed derived state** (2026-07-16) — audience state lives INSIDE the
   determinism envelope; precedent for patron/verdict stores.
5. **Priming replaces cooldowns** (R3, owner 2026-07-14) — cooldown code dormant until
   the skills passover names the priming vocabulary; then deleted.
6. **Director-behind-interface** (Δ4 + mother-brain constraints, 2026-07-14) — LLM
   interprets, sim decides; one brain, schema-bound commands.
7. **Import-guard on headless runs** (2026-07-16) — stale class cache breaks
   `class_name` resolution; the test script re-imports when any .gd is newer.

## OPEN (architecture-relevant)

R14 force-gate (touches resolver damage path) · priming vocabulary (shapes `priming.gd`)
· R13 confirm (condition_engine) · co-op transport choice at Stage 1.5 (host-based vs
thin relay — decide on slice evidence) · SQLite re-entry point (content volume trigger).
