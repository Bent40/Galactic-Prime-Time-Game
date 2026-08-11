# Current State

<!-- wf memory: required sections below; keep the headings. -->
<!-- Last refreshed 2026-07-25 (post 4-fix batch + KAN-4 engine + wave 2). -->

## Done

- **Suite: 511 passed / 0 failed** (`STATUS.md` is the live count). CI green on every
  gate (seeds · import · suite · slice smoke · balance WIN); branch
  `claude/session-continuation-next-steps-mpycyj` and `main` in lockstep at `9af6d09`.
- **Wave 3 — the whole unblocked backlog (2026-07-25):** pack synergy (R15 enemy
  combos, personality-gated opportunistic linking — two blocked roach bites merge
  into a wound) + serialized readable ai_stance (the aura_reading substrate);
  the G3 keyword tree (49 ruled entries, narrow/broad from book §4.5) + Gemstone
  mutation machinery (skill_forge.gd; Iron Stance recipe canonical, effect
  data-only pending a retarget-guard archetype; pricing = KAN-7); the WAR HOUND
  (compendium §4.6, first pack-hunting Elite, PROVISIONAL) + the 3-encounter demo
  run with the hype chain live (40%/60% openings pinned); KAN-5 arenas
  (arena.gd — opt-in bounds/walls/trash-cans respected by every movement path;
  dash wall bounces via the exact cube edge mirror; can explosions
  environment-attributed; the last two R11 #20 inert strings REAL; R28).
- **Sign-off batch RULED + implemented (decision #32, 2026-07-25):** R26 undodgable
  attacks (data-driven, every dodge path skipped rng-free, transparency mandatory,
  valve blasts first application); hype chains (40/60/80/100% retention, serialized
  chain index, replay-identical); story-driven recruit declines (`on_decline` data);
  epithets Sasha "Little shadow" / Nikita "The lonely".
- **The 2026-07-23/25 rulings batch, all implemented** (decision-log #27–31, addendum
  R22–R25, R11 #19–#20): explosion valves REAL (telegraph → escape → blast → KO =
  Helpless 2 Clocks → boss keeps fighting — dormancy bug dead); R22 dodge (Reflexes
  asks, 1d4 fallback, per-stat upgradeable threshold dice; dash = cost-2 windup with
  the counters ladder); R23 Antagonism engine (proximity × grudge × personality
  weighted targeting, exact 50/50 anchor, one salted draw); R24 feint-read (Mind
  counters feints; grudge on the read); skill-feel wins (loud feint fallout, prone
  boss = no dodge/no cone + real stand-up cost, part-pick everywhere).
- **Balance truth reset:** the old full-cadence WIN was a dormancy artifact. The
  harness now plays the real kit (feint denial, valve spread, merged pours) —
  **WIN t15, zero damage taken** (seed-robust). Feint dominance was found → owner
  ruled the counter (R24). `feint_reads=0` telemetry pins the regression bar.
- **KAN-4 engine complete:** run engine (`run_state.gd` — command-stream runs,
  encounter sequencing, roster carry with cited persists/resets policy, recruit
  offer/accept/decline), creation engine (`creation.gd` — spec → validated
  add_combatant, 7/7 trait split, R16 picks + cap-trade), Sasha & Nikita premade
  data (PROVISIONAL sheets), party-of-3 proven (3-way merged force, no sim changes
  needed), run persistence (`save_run`/`load_run`, byte-identical round trips),
  takedown attribution v2 (R11 #14 IMPLEMENTED — kills attribute to the killing
  blow's author through wound sources).
- **Wave 2 engine (KAN-2/5 boundary):** real hex geometry (`hex_geometry.gd` —
  120° cone arcs, dash charge lanes, arc-honest windup escapes), death_spin 3-beat
  grab sequence + dash knock-aside (R11 #19), Tactical Roll declared-hex dodge +
  AoE-center rule (R25/G1 canon), Incine-Dile phase upgrades real (R11 #20:
  drag-grabs, bendable dash lane, permanent P4 network exposure, P5 cone tracking
  + 2-Moment spin; wall bounces/trash cans pinned inert until KAN-5).
- **HUD (pre-rework state):** v2 shell + 13 components, status badges/pips, tween
  movement, part-pick flow, grudge ledger, valve announces, feint read-risk preview;
  smoke driver 91+ probes; frozen v1 drivers pass unedited. KAN-4 mockups
  (recruitment beat + creation) rendered at `docs/ux-designs/kan4/`.

## In progress

- Nothing in flight. All worktrees cleaned; no orphaned subagents.

## Next

- **Owner front rework (decision #31):** owner drafts all mockups; we build them
  against the ready engines. UI decisions from the KAN-4 mockup gate are deferred
  to that pass.
- **Small open leftovers from the ruled batch (#32):** the premades' 4th skill
  slots; cross-character CHAIN on Pressure Strike (stands as-is); the two
  PROVISIONAL on_decline story readings.
- Engine backlog (unblocked): pack synergy (R15 enemy combos), AI stances
  (aura_reading), second authored enemy/encounter, keyword tree (G3) + Gemstone
  mutations in sim data, then KAN-5 arenas (walls/environment un-inert the last
  two upgrade strings).

## Blockers

- None. Both open items are owner-paced (mockups; sign-off batch).
