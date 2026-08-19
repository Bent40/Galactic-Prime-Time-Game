# Next Actions

<!-- wf memory: required sections below; keep the headings. -->
<!-- OWNER-FACING BY-ANGLE TRACKER. Last refreshed 2026-08-19. -->

## Next actions

### 🔀 branches
`claude/session-continuation-next-steps-mpycyj` and `main` in **lockstep** (every
commit pushed to both). Both at `5b90ea0` (tier-2 wave complete — Rounds 1–5,
844/0, CI green). Develop on the session branch; push `-u` to both. NOTE: the
owner also pushes ledger commits directly to `main` — fetch + merge origin/main
before pushing.

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

### ▶️ Backlog status (tier-2 wave DONE 2026-08-19 — Rounds 1–5 at `5b90ea0`, 844/0)
- ~~Zones (R32)~~ · ~~terrain+locks (R33)~~ · ~~seven unblocked KAN-5 skills~~ ·
  ~~hearing/alert (R20 ph2)~~ · ~~ALL TEN tier-2 ladders~~ · ~~voicebox~~ ·
  ~~carry-sanitizer~~ — all shipped; harnesses byte-identical throughout.
- **Owner-court queue (blocks the next content-quality pass):** the tier-2
  RENAME pass (every fusion name PROVISIONAL); the R14 numbers glance-list
  (field_triage L3 range, frost's Crushed coupling, poison/vibe magnitudes,
  intercept guard expiry, quick_step slot-free economy, acrobatics roll-range —
  plus every wave-authored placeholder, tagged per value in the specs);
  PROVISIONAL content review (war hound, arenas, decline readings, investigate
  personalities); premades' 4th skill slots + cross-character CHAIN; the front
  mockups (decision #31 — owner drafts, we build → KAN-6).
- **Dev-side ready when green-lit:** tier-3 merges ("we need a lot more
  skills"); the deferred DATA rungs each name their unblock (decoy entity,
  in-encounter gap/vent substrate, equipment vocabulary, verticality, the L5
  mastery band → the tier-economy pass); disguise (R20's last phase).
- **KAN-7 (parked — needs owner pricing):** threshold-dice upgrade economy,
  Gemstone Bronze pricing, R6 XP, patron-roster migration, cap enforcement,
  Camera-Call v2 engine swap (named-Follower ledger, R11 #13).

### 🧰 process notes
- Every wave: worktree → subagent ("do the work yourself") → main-agent verify
  (scope diff + real suite run + harness gates) → --no-ff merge → push both →
  CI monitor on the tip.
- Harness honesty: balance_sim WIN t15 zero-damage is the pinned regression bar;
  `feint_reads=0` proves R24 doesn't touch the seeded fight.
