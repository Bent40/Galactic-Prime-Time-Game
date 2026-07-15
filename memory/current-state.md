# Current State

<!-- wf memory: required sections below; keep the headings. -->

## Done

- Full four-part project review committed: `docs/review/review-0..4` (TTRPG defect catalog,
  conversion analysis, repo assessment, market-grounded verdict).
- Direction decided + recorded: `docs/DIRECTION.md` (shared-world ladder, 2.5D, sim contract).
- Workflow wiring: memory pack, `_workflow/learnings.jsonl` (8 seed entries),
  `_workflow/traces/` enabled + overnight trace running, `_workflow/boot.json` receipt
  (profile game, size small), `bmad.config.yaml`.
- KAN-1 (Data Foundation) was completed by the owner pre-review: SQLite schema
  (`data/migrations/001_initial_schema.sql`) + migration runner + placeholder seed JSONs.

## In progress

- **KAN-2 is VALIDATED LIVE (2026-07-15): 22/22 tests green under Godot 4.5.2** — first
  real execution of the suite, zero failures, determinism suite included. `wf validate`
  fully green (seed data + sim tests). Godot installs in-container via
  `bash scripts/setup_godot.sh` (SourceForge mirror; env domain allowlist enabled it).
  Next engine work: the priming pass (replaces deprecated cooldown support, NQ1 ruling).

## Next

- **Owner morning review:** PROVISIONAL rulings in `docs/rules-addendum.md` (R2 dodge
  model, R3 caps, R4 Burn-Shock, R8 RPM, R9 grapple, R10 requirements-halving + exchange
  cut) **+ the R11 engine interpretation log** (12 implemented judgment calls).
- **Run the test suite on a machine with Godot 4.5** — the trace `overnight-2026-07-13` is
  honestly labeled *failed* until this passes; re-record the signal when green.
- Vendor godot-sqlite into `addons/` (blocked in-container: proxy 403s GitHub + asset lib).
- KAN-3 scaffolding (main scene, GameController autoload — deliberately NOT done overnight
  to respect the epic order; the empty-window state persists until then).
- Content pass: rich tag descriptions live in the rulebook docx (DB export has empty
  strings); items need rpm/magazine fields (R8); Camouflage's third stat (charm) was
  dropped by the 2-stat schema — decide whether the schema grows.

## Blockers

- No Godot 4 binary obtainable in session containers (proxy) — live validation is
  owner-side or CI-side only.
