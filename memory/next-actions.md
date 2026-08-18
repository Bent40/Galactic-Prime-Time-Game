# Next Actions

<!-- wf memory: required sections below; keep the headings. -->
<!-- OWNER-FACING BY-ANGLE TRACKER. Last refreshed 2026-07-25. -->

## Next actions

### 🔀 branches
`claude/session-continuation-next-steps-mpycyj` and `main` in **lockstep** (every
commit pushed to both). Both at `e13d8e2` (wave 2 complete, CI green). Develop on
the session branch; push `-u` to both. NOTE: the owner also pushes ledger commits
directly to `main` — fetch + merge origin/main before pushing.

### ⏸️ Owner-paced (open items)
1. **Front rework (decision #31):** the owner drafts ALL mockups; we build against
   them. The engines are ready — everything driveable via commands + view API.
   KAN-4 mockup-gate UI decisions (docs/ux-designs/kan4/README.md) deferred to
   that pass.
2. **Sign-off batch RULED 2026-07-25 (decision #32) — implemented at `4d26a70`,
   CI green:** approvals as shipped + three changes now live: R26 undodgable
   attacks (valve blast first application, telegraph/schedule/preview all carry
   it); hype chains 40/60/80/100% retention; story-driven declines. Small
   leftovers still open: the premades' 4th skill slots; cross-character CHAIN
   on Pressure Strike (stands as-is); my two PROVISIONAL story readings —
   Sasha "Little shadow" may_reoffer / Nikita "The lonely" gone_for_run.

### ▶️ Backlog status (wave 3 DONE 2026-07-25 — all four landed at `9af6d09`)
- ~~Pack synergy + AI stances~~ · ~~keyword tree + mutations~~ · ~~second enemy
  (war hound) + 3-encounter run~~ · ~~KAN-5 arenas (bounces + can pops real)~~.
- ~~KAN-5 proper~~ **wave 4 DONE 2026-08-11 at `927fd0e`**: pathfinding, doors +
  room graph (R29), stealth/detection/cover (R20), the maze funnel (R11 #21).
  Still open there: R20's own deferred phases (facing cones, hearing/alert,
  disguise), objects beyond trash cans, owner-authored room layouts (all
  wall/can/door positions PLACEHOLDER).
- ~~Content pass~~ **DONE 2026-08-18 at `dc63b07`** (28 implemented, 13 deferred
  with named unblocks; facing primitive + tier machinery shipped alongside).
  Follow-ups queued: **tier-2 rung authoring** (the merged skills' own L1-5 —
  the 15 re-mapped threshold rows await placement); the two unblessed Mod-Center
  offers; the run_state carry-sanitizer gap for the new combat fields
  (guard/forced_save/conceal/channeling/held_by — self-healing sweeps cover it,
  a small dedicated story closes it properly, run_state was story-frozen);
  owner R14 glances flagged in Batch C/D notes (field_triage L3 range, frost's
  Crushed coupling, poison impact + vibe grudge magnitudes, intercept guard
  expiry).
- **KAN-7 (parked — needs owner pricing):** threshold-dice upgrade economy,
  Gemstone Bronze pricing, R6 XP, patron-roster migration, cap enforcement.

### 🧰 process notes
- Every wave: worktree → subagent ("do the work yourself") → main-agent verify
  (scope diff + real suite run + harness gates) → --no-ff merge → push both →
  CI monitor on the tip.
- Harness honesty: balance_sim WIN t15 zero-damage is the pinned regression bar;
  `feint_reads=0` proves R24 doesn't touch the seeded fight.
