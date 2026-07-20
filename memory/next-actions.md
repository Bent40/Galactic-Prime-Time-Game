# Next Actions

<!-- wf memory: required sections below; keep the headings. -->
<!-- OWNER-FACING BY-ANGLE TRACKER. Last refreshed 2026-07-20. -->

## Next actions

### 🔀 branches
`claude/session-continuation-next-steps-mpycyj` and `main` are kept in **lockstep**
(every commit pushed to both). Both at the audit/loop work as of 2026-07-20. Develop on
the session branch; push `-u` to both.

### ▶️ Active dev — implement the 3 DECIDED KAN-2 sittings
The design is ruled (rules-addendum R3/R13/R14, decision-log #20–22); this is engine work:
1. **S2.1 Priming** — build the 5 prime predicates (CHAIN/STANCE/STACK/STATE-POSITION/
   PREP-CHANNEL) into the requirements gate; DELETE the dormant cooldown code; convert the
   cooldown-texted skills (Tactical Roll + Acrobatic Save → STANCE-gated; the "-4 Moment
   cooldown" threshold → CHAIN discount).
2. **S2.2 Shock** — wire the finalized event-model: high-water mark, `max(current+1,
   source_tier)` escalation, tier effects T1 Shout / T2 Stutter / T3 Faint / T4 Helpless,
   Burn T1→Shock T1. Regression tests.
3. **S2.3 R14 numbers** — implement `damage = max(0, Force − Robustness)` (Force = physique +
   weapon rating + merged combined force; Robustness = physique base + per-part armor);
   blocked hits land Shock but not bleed/burn/poison; reseed magnitudes as PLACEHOLDER;
   mutation pass after.

### ▶️ Queued (me) — after the sittings, still under the content freeze
- **Incine-Dile: tuned & fun full fight** (review #2) — phase progression, telegraphed
  breach, 10–20 min pacing target.
- **Evidence-based verdict** — record the player's real choices; the card quotes them.
- **HUD declutter + real visuals** — the "Rework Visuals Properly" epic (decision #19).
- Remaining **37 skills' mechanics**; **CI** (pin Godot, run tests/seeds/import/smoke);
  **KAN-4 party** (real OC creation → recruitment → replace the Imani/Dario fixtures + the
  Charm-30 hack with a proper granted-stacks field).
- R11 #14 takedown attribution v2 (task #13); I-11 priming impl folds into S2.1 above.

### ⏸️ Owner decision queue (none blocks the work above)
- LICENSE: substitute your legal name/entity as the copyright holder.
- Asset provenance: 15 raw photo/screenshot placeholders flagged in
  `docs/asset-provenance.md` — confirm rights / check watermarks before any public build.
- Animal-parts sitting (Sasha body plan) · telepathy manipulation-lane confirm ·
  living-religion cultural review before public release · patron slice→roster migration
  (deferred, decision-log #23).

### 🔄 Running now (agent)
- Nothing. All background agents complete, verified, and merged.

### ✅ Landed this session (2026-07-20)
- Integrated run loop (title→bid→combat→verdict→restart) + the boss fights back.
- Per-skill mechanics (SkillBook + 6 demo skills, 5 archetypes).
- The 3 KAN-2 sittings decided + formalized; window responsive.
- Full repo audit: dead-file cleanup, drift reconciled, STATUS.md, LICENSE, PDF
  archive, asset manifest, patron ruling. Content freeze adopted.
