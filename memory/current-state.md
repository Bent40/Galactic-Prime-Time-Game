# Current State

<!-- wf memory: required sections below; keep the headings. -->
<!-- Last refreshed 2026-07-20 (post loop + KAN-2 sittings + repo audit). -->

## Done

- **The slice is a real, uninterrupted runtime loop (2026-07-20):**
  **Title → Bid → Combat → Verdict → New Run**. Boots to a title screen; the
  Incine-Dile **fights back** (enemy AI wired into the turn loop via the
  PausedClockDriver + `advance_moment`); combat-over detection (`combat_status` /
  `combat_ended`, WIN=no live enemies / LOSS=no live party) transitions to the
  verdict; the verdict restarts a run. Window is responsive (canvas_items stretch).
- **Per-skill mechanics un-stubbed (KAN-2):** model-side `simulation/skill_book.gd`
  maps skill key+level → a structured spec; `ActionResolver` dispatches 5 archetypes
  (committed_strike / self_guard / setup_debuff / conditional_followup / self_stance).
  The **6 demo skills** (strong_strike, overhead_slam, brace, feint, pressure_strike,
  dance) are faithfully implemented with their authored numbers. The other 37 fall
  back to a generic strike (content pass later).
- **The 3 KAN-2 design sittings DECIDED + formalized (2026-07-20):** S2.1 priming
  vocabulary (5 canonical prime types; reactions stance-gated), S2.2 R13 shock
  (event-model finalized), S2.3 R14 numbers (`damage = max(0, Force − Robustness)`).
  Recorded in `rules-addendum.md` R3/R13/R14 + `decision-log.md` #20–22.
  **Engine IMPLEMENTATION of all three is PENDING** (the current dev task).
- **Repo audit done (2026-07-20):** 18 dead stub files deleted; Godot 4.5→4.7 and
  all test/entity/seed counts reconciled; generated **`STATUS.md`** + `scripts/status.sh`
  (single-source-of-truth, no more hand-maintained counts); LICENSE (proprietary);
  3 design PDFs archived to `docs/archive/`; `docs/asset-provenance.md`; patron
  dataset ruling (decision-log #23).
- **Test suite: green — see `STATUS.md` for the live count** (177 at last refresh),
  real Godot 4.7.1. Determinism + save/resume intact throughout.
- Earlier foundations (all landed): KAN-1 data; KAN-2 core engine + S2.5 combined
  actions; KAN-3 scaffolding (autoload/signals, DAL, SaveManager, hex renderer,
  clock driver); enemy AI + Incinedile phase machine; hype/tag/spectacle engines;
  F2 boss discoverable-win hardening; mythology Waves 0–5 (224 entities); KAN-6
  HUD + bid + verdict screens.

## In progress

- **Implement the 3 decided sittings** — priming engine (5 prime predicates, delete
  dormant cooldown code, convert the cooldown-texted skills), R13 shock finalization
  (wire the tier effects + escalation), R14 numbers (force-vs-robustness function +
  reseed magnitudes as placeholders). This is the active dev work.

## Next

- **Make the Incine-Dile fight tuned & fun** (review #2): full phase progression,
  telegraphed breach, 10–20 min pacing.
- **Evidence-based verdict** (quote the player's actual choices, not hype-band flavor).
- **Reduce/declutter the HUD** + real art — the "Rework Visuals Properly" epic (#19).
- Remaining 37 skills' mechanics; CI (pin Godot, run tests/seeds/import); KAN-4 party
  (real OC creation to replace the hardcoded Imani/Dario fixtures + the Charm-30 hack).

## Blockers

- **None critical.** The three sittings are DECIDED (no longer owner-gated).
- **Content freeze in effect** (owner 2026-07-20): no new mythology / bosses / patrons
  (>6) / floors / recruitment / shared-world until the slice proves fun to a stranger.
- Owner decision items still open (non-blocking): animal-parts sitting (Sasha body
  plan), telepathy lane confirm, living-religion cultural review before any public build.
