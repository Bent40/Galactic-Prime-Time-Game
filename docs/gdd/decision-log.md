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
10. **Mythology research spec RULED (owner, 2026-07-18, in chat):** all four decision
    points approved with caveats — sensitivity policy ✓ with **messenger carve-out**
    (Metatron/Gabriel-tier depictable as corporate staff of investor institutions;
    sacred core never depicted) + **Abrahamic-holding-company lore approved** (three
    brands, one company, segmented fronts for sales/gambling volume) · volume targets ✓
    (26-family census, ~150 entities, ~120 myths, 24-god MVP roster) · internet folklore
    AND cosmic horror (Cthulhu mythos, outer gods) **researched but `ship_status:
    deferred`** · historical figures OUT (deified included, revisitable) · **Forsaken
    amendment: ANY god can all-in regardless of influence, existence can be the stake,
    a god's loss can unlock new stages.** Spec: `docs/design/mythology-research-spec.md`;
    propagated to `docs/design/patron-gods.md` §5 + `docs/cosmic-casino-canon.md` §3/§4.
11. **Depiction policy v2 RULED (owner, 2026-07-18, in chat):** register = pop-culture
    mythological fiction (Helltaker / mythology manhwa / Shinto anime precedent). Angels,
    demons, God-figures, and living-religion deities depictable as characters, positively
    or negatively — per-figure `living` gate DROPPED; investor-institution frame becomes
    creative choice, not protective requirement; `depiction_risk` kept as data only.
    Bar: respectful, never racist; thesis = how the mythos shaped humanity + how each
    figure is perceived today. **Modern-life pantheon attributions wanted** (Greek =
    Hawaii vacation, Roman = food-obsessed, Abrahamic = three managers fighting over one
    company). FSM-class parody figures eligible in principle. **Held for explicit
    confirmation:** named Islamic prophets (recommend OUT — the line precedent media
    itself holds) · culturally closed ceremonial material (recommend exclusion stands).
    Propagated: spec §3.3 v2 + `cosmic-casino-canon.md` §4.
12. **Wave-2 shortlist + carve-outs RULED (owner, 2026-07-18, in chat):** extraction
    GO on the 14 wave-1 traditions at **up to 15 entities per tradition** (~210,
    revising ~150 upward). Both depiction carve-outs **confirmed as recommended**:
    named Islamic prophets OUT; closed-ceremonial-material collection exclusion
    stands. Also clarified: **"OC" = player-created character in character creation**
    (KAN-4 S4.1) — the two drafted slice "premades" exist only as a slice-scoping
    device; their final role (demo/quick-start loadouts vs creation-first slice)
    awaiting owner pick.
13. **Slice cast + tag slice RULED (owner, 2026-07-18, in chat).** Imani/Dario
    **demoted to demo/quick-start loadouts + test fixtures — and BUILD them** (all 8+1
    proposal questions answered; rulings recorded in
    `docs/design/slice-contestants-proposal.md` §RULED). Headlines: 1 Camera Call
    stack per loadout for system testing (no R6 change) · **bid screen IS in the
    slice, one chosen patron seeded per loadout** · stub forge/fire +
    fortune/trickster archetype gods · owner principle: demo content is rewireable to
    the real story later. **Tag slice APPROVED** (all 9 questions answered; rulings in
    `docs/design/slice-tags-proposal.md` §RULED). Headlines: `tag_effects.json` ·
    weighted goals stay deferred · loadouts start tagless, everything earned on
    camera · 3 new goal rows approved · same-batch attribution blessed ·
    non-contestants hold no tags · **The Bit constraint: signature actions must be
    mechanically NULL — pure flavor, zero benefit, spectacle is the only payout.**
    Char-sheet `passive` fix commit **approved**. Tag descriptions: owner will paste
    rulebook text into a committed markdown scaffold
    (`docs/rulebook-tag-descriptions.md`) instead of supplying the docx.
