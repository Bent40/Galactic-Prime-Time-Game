# Decision log — GDD (create run, 2026-07-16, headless)

1. **Game type:** matched `rpg` (high-complexity; stats/party/inventory/progression all
   present) from game-types.csv; turnless combat deliberately subverts turn-based-tactics
   conventions — noted rather than adopting that fragment. `needs_narrative` = yes
   (authored NPC arcs, question architecture) → gds-create-narrative offered as next step
   (already queued as BMAD pass 4).
2. **Workspace:** `docs/gdd/` (same rationale as the brief: repo keeps planning artifacts
   under docs/; gds config paths are uncustomized installer defaults).
3. **Supersession:** GDD supersedes GPT_GDD_v02.pdf where they conflict; PDF kept as
   history. Precedence chain restated in the GDD header so downstream readers can't
   mis-rank it against DIRECTION/addendum (which it consolidates, not overrides).
4. **Nothing OPEN was resolved:** title, Momus/host, TTRPG re-skin, timer, R13 confirm,
   R14 force gate, skills passover, player-OC death consequence, Forsaken manual trigger
   — all carried as OPEN with owners. Player-OC death defaults to GDD v0.2's Ascension
   NG+ until ruled (recorded as the base, not a new decision).
5. **Owner note honored:** dual-prose brand presentation excluded from MVP scope (Out of
   Scope section) per approval note on the brief.
6. **⟨PROPOSED⟩ items introduced by this draft** (each needs only a nod or an edit, none
   blocks build): 60 FPS/2015-laptop perf target · mouse-first declare UI with
   consequence preview · no difficulty menu (patron/Forsaken/routes as the dials) ·
   audience-faucet-widest balance philosophy · Lounge as menus-over-scenes in Stage 1 ·
   dialogue as lower-third barks/short trees · a11y baseline scope.
7. **Epics:** KAN order kept authoritative; KAN-2 remainder split into S2.1–S2.4; KAN-7
   scope re-derived from the casino adoption (patron gods, epithets, verdict). Stories
   shaped for gds-create-story with EARS criteria at creation time (clears `wf audit`
   SETUP-NEEDED).
8. **Decision slate RULED (owner, 2026-07-16, in chat):** R15 merged-one-hit ✓ ·
   degraded combos ✓ · plan objections non-binding for uninvolved ✓ · planning free at
   combat start, Moment cost mid-combat ✓ · Tactician = trait, capstone pre-auth ✓ ·
   bidding flow as written + gods' explicit dos/don'ts (taboos) ✓ · Forsaken manual
   trigger CONFIRMED · no difficulty menu ✓ (run types are the surface) · audience
   faucet widest ✓ · declare UI + consequence preview ✓ · 60 FPS/2015 laptop ✓ ·
   **Lounge = walkable exclusive hub (loot/contracts/tinkering) + roaming-monster
   resets** (overrides menus-over-scenes) · **death rules per run type (R17):
   softcore respawn / hardcore permadeath / Forsaken hardcore** · episode beats ✓ ·
   found documents ✓ · arena-as-psyche floor-set 3+ ✓ · never-moralize principle ✓ ·
   myth catalog = real mythology graded ORV-style + Stage-2 player myths ✓ · title kept
   for now · Momus shared host · TTRPG re-skins to casino · starving-pantheon REJECTED
   (bankruptcy-by-debauchery lore instead). Pending explanation before ruling: dialogue
   delivery (#14), production-cast-via-patrons (#20), Sasha/Nikita page details (#22).
9. **Finalize degradations (honest):** input-reconciliation and discipline-pass
   subagents unavailable (container classifier outage) — both applied inline by the
   drafting agent instead (brief cross-checked section-by-section; template/genre-guide
   sections all present; density and no-engine-leakage rules self-audited). Re-run
   `gds-gdd` validate intent as a fresh-context pass any time for a second opinion.
