# Next Actions

<!-- wf memory: required sections below; keep the headings. -->
<!-- OWNER-FACING BY-ANGLE TRACKER. Last refreshed 2026-07-25. -->

## Next actions

### 🔀 branches
`claude/session-continuation-next-steps-mpycyj` and `main` in **lockstep** (every
commit pushed to both). Both at `e13d8e2` (wave 2 complete, CI green). Develop on
the session branch; push `-u` to both. NOTE: the owner also pushes ledger commits
directly to `main` — fetch + merge origin/main before pushing.

### ⏸️ Owner-paced (both open items)
1. **Front rework (decision #31):** the owner drafts ALL mockups; we build against
   them. The engines are ready — everything driveable via commands + view API.
   KAN-4 mockup-gate UI decisions (docs/ux-designs/kan4/README.md) deferred to
   that pass.
2. **PROVISIONAL sign-off batch** (implemented-as-written, none blocking):
   phase-5 spin = chew+spin merged (R11 #20) · P5 cone-tracking tie rules ·
   Tactical Roll hard-counters valve KOs (R25 — blast centers on the boss's
   occupied hex) · recruits join as-is / decline final (#31) · Sasha & Nikita
   sheets + open 4th skill slots · boss dodge threshold 4→7 (R22 retune) ·
   camera stacks bounded 0..1 (creation engine).

### ▶️ Unblocked engine backlog (in rough priority)
- Pack synergy (R15 enemy combos) and AI stances for `aura_reading`.
- A second authored enemy/encounter from the compendium (the demo_run mob fight
  reuses roach templates).
- Keyword tree (G3, book §4.5) + Gemstone mutations (Iron Stance) in sim skill
  data — content grows past the 6 implemented skills.
- KAN-5 arenas: walls/bounds + environment objects (un-inerts "dash bounces" and
  "trash cans pop"), rooms/dungeon flow, stealth/detection (R20).
- KAN-7: threshold-dice upgrade economy (ruled, unpriced), R6 XP, patron-roster
  migration, cap enforcement (creation's R16 cap annotation has no runtime
  consumer yet).

### 🧰 process notes
- Every wave: worktree → subagent ("do the work yourself") → main-agent verify
  (scope diff + real suite run + harness gates) → --no-ff merge → push both →
  CI monitor on the tip.
- Harness honesty: balance_sim WIN t15 zero-damage is the pinned regression bar;
  `feint_reads=0` proves R24 doesn't touch the seeded fight.
