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
14. **Batch rulings (owner, 2026-07-18, in chat).**
    - **R19 skill framework = ALL DEFAULTS ACCEPTED** (the 10 cross-cutting questions):
      (1) passives generalize as passives, high rung may add an active toggle where it
      fits · (2) L10 rule-transcending tier is magic-only + source-gated · (3) the R16
      4-skill trade does NOT push a starting skill into the 6+ band; 6+ is earned in-run ·
      (4) chain-opener generalization loosens chain gates only at authored rungs, never
      automatically · (5) consume/mutate capstones sit OUTSIDE the 6–10 ladder; cap-10
      always Patron-Token-gated · (6) performance skills: Charm scales the crowd payoff, a
      shared "spectacle" rung is the standard L10 · (7) locked/NPC skills use the 0–10
      ladder only if a player could ever acquire them; player-inflicted mind-collapse
      gated per R5 · (8) NO ladder introduces true HP restoration (HP recovery stays
      scarce) · (9) approve ladder SHAPES now, tune magnitudes after R14 · (10) data
      hygiene (legacy cooldowns vs R3, empty effect rows, garbled Camouflage, Nightlurking
      stat drift) cleaned during implementation. → the 43 skill ladders are being
      finalized against this framework.
    - **Tag names: the 2026-07-17 RENAMES stand** (owner corrected 2026-07-18 — the pasted
      list is OLDER, so its NAMES are superseded; its DESCRIPTIONS are canonical and were
      ported). Canonical names: **Reckless, Gorefest, What a Beaut, Shill, Heart Melter,
      Not My Job, Winter Sheep** (Reckless + Gorefest are live slice tags). `data/tags.json`
      carries the rename name+key with the pasted-list descriptions attached.
    - **Mycelius Chrom → a SERVANT, not a god** (owner corrected 2026-07-18): a fungal
      servitor/attendant tied to a decay-and-death myth (retinue of a death/harvest god
      such as Osiris), not a fully-fledged deity. NOT slice-critical; art reused later.
    - **R11 #14 RULED (owner 2026-07-18):** (a) **same-batch goal completion is ALLOWED** —
      a goal can be insta-won off good prep or luck, no penalty (current code is correct as
      is). (b) **A friendly death completes the "takedown" goal ONLY IF a contestant killed
      them** (friendly-fire counts — "it's cinema"); credit the killer. (b) needs
      kill-attribution + team-awareness in the hype engine (the deferred attribution v2) →
      IMPLEMENTATION QUEUED; the v1 code over-fires on any death until then.
    - **Skill-ladder residuals RULED (owner 2026-07-18):** (R1 Brace) Intercept + Iron
      Stance = **separate lower-tier skills** with a merge-into-Brace upgrade path — author
      all three. (R2 Fire Ball) R19's **"Explosion" was a made-up illustrative example, NOT
      a skill** — no Explosion skill; Fire Ball generalizes on its own. (R3 Mind Burst) the
      **mind-collapse stays but as really-high-tier magic only** (L10, magic/source-gated,
      non-boss, per R5). **NEW OPEN — Telepathy:** owner unsure it fits, since the player
      **chat function already covers mind-to-mind comms**; leaning cut or repurpose (rec:
      repurpose to reading enemy/NPC hidden intent). Recorded in
      `docs/design/skills-r19-ladders-FINAL.md`; 42/43 ladders now final, Telepathy the
      one open skill.
    - **Telepathy RESOLVED + CONFIRMED (owner 2026-07-18):** comms use dropped (chat covers
      it); reading intent is Read the Pattern's job; Telepathy leans into the **manipulation
      lane** (read→write→influence→gated collapse). **43/43 ladders FINAL — no open skills.**
    - **Caishen influence RESTORED to 5 (owner 2026-07-18):** not a rubric error — played as
      him simply being a **better/more-popular casino player** ("some tables ARE more
      popular"; a son showing his dad new phone games). Overrides the Wave-4 auto-correction.
    - **R20 Stealth/detection/cover RULED (owner 2026-07-18):** complete model in
      `docs/rules-addendum.md` §R20 — vision = ~2× Mind via cones (eye position matters);
      hearing → investigate/alert (alerted-but-unlocated enables scapegoat/illusion plays);
      disguise = unrecognized outside a range; **cover is a real sized-geometry system**
      (skills pass sized gaps differently); stealth does NOT auto-suppress hype (spectacle
      depends on what you do); **production never interferes — rival gods out you**. Both
      combat + exploration. Cover-geometry/vision-facing phased to KAN-5. Q58 CLOSED.
    - **Wave 5 APPROVED (owner 2026-07-18):** the 24-god MVP roster
      (`docs/design/wave5-roster-shortlist.md`) is greenlit → build the patron-roster
      generator + domain→condition/affix maps (domain→tag waits on the I-13 tag effects).
    - **Animal parts:** owner requested a QUICK RESEARCH pass first — catalog the body parts
      UNIQUE to animals (tails, pincers, pouches/"pockets", wings, horns, beaks, shells,
      etc.) as a premade-parts library, before the full animal-layout sitting. Done:
      `docs/design/animal-parts-library.md` (38 parts).
    - **R21 body structure RULED (owner 2026-07-18):** Lego-style — a character type =
      typed parts (base head/torso/arms/legs + any animal part) each with a size range;
      deep customization (fur color, per-part sizing) DEFERRED, irrelevant to the demo.
      Character-creation UX: choose-by-PROPERTIES-then-filter (deferred to KAN-4/KAN-6, not
      the demo). Recorded in `docs/rules-addendum.md` §R21.
    - **Build-with-placeholders RULED (owner 2026-07-19):** proceed on PLACEHOLDER (R14)
      numbers and TUNE BY FEEL through playtest — "we wouldn't know numbers without feeling
      them out." R14 is no longer a gate on building systems; it becomes a tuning pass after
      the slice is playable.
    - **Demo UI mockups (owner 2026-07-19):** produce rendered demo mockups (KAN-6 mockup
      gate) via the BMAD gds-ux skill, styled after the char-sheet app's palette. Workspace:
      `docs/ux-designs/demo-slice-2026-07-19/`.
    - **Roster CORRECTION (owner-caught 2026-07-18):** slot #24 Anansi was MY MISTAKE — he's
      `folk`/`patron_capable:false`; I had wrongly authored him a patron_block to cover the
      error. **Reverted** (Anansi restored to folk dealer/contestant-legend) and **swapped
      for Ra** (genuinely patron-capable; also fills the roster's Egyptian gap). Process
      note: surface such errors as errors — do not quietly fabricate a fix.
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
15. **I-13 TagEngine merged (2026-07-19), attribution boundary recorded.** The slice
    tag engine (10 detectable tags + hype resonance + The Bit) passed two review gates
    (standard + adversarial); both flagged a MAJOR attribution defect, both fixed
    strict-side before the `--no-ff` merge (133 sim tests green, validate_seeds OK).
    **Scene Stealer** now credits the goal COMPLETER via a new `completed_by` field on
    `hype_goal_completed` (`HypeEngine._goal_completer`), not the completing event's
    subject — which for takedown/overkill/part_break is the maimed victim.
    **Reaction-dealt gore** now credits the reactor (`credited_actor` backward fallback).
    **Boundary (explicit, not silent):** the hype LEDGER itself still victim-credits
    those three goal kinds — aligning the ledger is the pre-existing provisional
    attribution deferred to **attribution-v2 (task #13, R11 #14)**, out of I-13 scope.
    The Bit's mechanical-null guarantee held under adversarial probing (combat state
    byte-identical before/after, incl. rejected bits). Numbers PLACEHOLDER (R14).
16. **Demo mockups APPROVED — KAN-6 mockup gate passed (owner 2026-07-19).** The three
    rendered mockups (combat/broadcast HUD, patron bid screen, verdict card) in
    `docs/ux-designs/demo-slice-2026-07-19/` are approved as the build target. Owner
    calls on the two flagged questions: **keep the 3-column director rail**; **keep the
    band display names** (enum `cold/warm/hot/on_fire` shown as ELECTRIC / ON FIRE). The
    gds-ux spines (DESIGN.md / EXPERIENCE.md) are marked APPROVED. Scene-building is
    unblocked; numbers stay PLACEHOLDER (R14), tuned by feel through playtest.
17. **F2 RESOLVED — boss discoverable-win-condition hardened (owner design 2026-07-19).** The slice
    playtest found the Incinedile could be defeated WITHOUT breaching, via **nine** off-network kill
    routes (condition-tier death, timer terminals, forced collateral). Owner design: bleeding reworked
    into a **systemic bleed-out drain** (scales with tier; death only when a LETHAL part empties;
    treatable), the network is **bleed-immune** ("mycelium doesn't bleed"), crushed/burn/head death gated
    to lethal parts, and — enforced as one principle — **HP damage never touches a hidden part; death /
    removal routes ONLY through a lethal, exposed part**. All nine closed at their sinks (attacks,
    conditions, timers, drain, collateral); verified DRY by an independent adversarial pass (finds
    converged 4→1→0). 152 sim tests, slice driver still wins via the network, determinism intact.
    Commits 4377fa2 / ecb867e / 6155e29. Detail: `docs/playtests/slice-playtest-2026-07-19.md` §F2. Open
    nit (not a bypass, owner call later): whether a lethal *condition* on the *exposed* network is an
    acceptable finisher, or "destroy the network" must strictly mean HP→0.
18. **Art-direction thread PARKED (candidate, NOT ruled — 2026-07-20).** Owner-originated
    exploration captured in `docs/design/art-direction-pieces.md`: contestants/bosses as the
    table's **themed game-pieces** (mahjong/chess/totem/bone by the governing god), big beasts
    as **aggregate swarms of pieces** (procedural formation animation, not sprites — maps 1:1
    onto the multi-part-body + surface-immunity boss, i.e. the mycelium puppet IS a
    piece-swarm; breach = pieces part to reveal the core), and a **visceral-injury** layer
    (cutaway maiming stinger + persistent damage decals on the piece, keyed to the existing
    part_destroyed / gorefest / hype events) so the brutality survives the abstraction. NOT a
    ruling — a direction to pressure-test at the UI revamp; open decisions listed in the note.
19. **"Rework Visuals Properly" — deferred epic/stretch PARKED (owner 2026-07-20).** The
    KAN-6 slice UI + all on-screen writing are **deliberately placeholder** — the goal of this
    phase was to prove the whole logic renders and plays end-to-end (bid → combat → verdict),
    which it does. A dedicated post-slice epic will do the real visual+copy pass: replace
    placeholder art/writing, DECLUTTER the HUD (owner: currently overloaded / no real stage /
    too much always-on UI), and execute the candidate **themed-game-pieces + visceral-injury**
    art direction (`docs/design/art-direction-pieces.md`). Numbers stay PLACEHOLDER (R14) until
    the tuning pass. Not scheduled now — a named stretch to pick up after the slice is content-
    complete. (Related tuning/feature debt already flagged: F1 camera-call stacks, F4 boss
    explosion phases, per-skill mechanics, the view-API adds for prone/slowed + hazard + boss phase.)
20. **S2.1 Priming vocabulary FINALIZED (owner 2026-07-20).** The no-cooldowns ruling
    (R3/NQ1) is now given a concrete, canonical **5-type prime vocabulary**, every skill's
    prime expressed as one (or a combo) of: **CHAIN** (must immediately follow a named
    action on the same target — already live via feint→pressure_strike), **STANCE** (hold a
    declared stance that ends on triggers), **STACK** (consume N accumulated charges — the
    Camera-Call model), **STATE/POSITION** (target/self in a state or relative position:
    Exposed, downed, behind), **PREP/CHANNEL** (spend a prep action to arm a one-shot prime).
    Primes are requirement-shaped (reuse the requirements gate). The two literal
    cooldown-texted defensive reactions (Tactical Roll, Acrobatic Save) are **STANCE-gated**
    (usable only while holding a light-footed/defensive stance — no timers). Implementation
    scope this pass: build the 5 prime predicates, DELETE the dormant cooldown code, convert
    the explicitly cooldown-texted skills; per-skill prime tags for the other ~37 ride the
    R19 ladder finalization. See rules-addendum R3.
21. **S2.2 R13 Shock FINALIZED — the provisional event-model is now ruled (owner 2026-07-20).**
    Shock is **momentary events off a per-combat high-water mark** (no pool, no in-combat
    decay, full reset at combat end). A source applies its **stated tier directly**;
    escalation is the exception — same-wound re-abuse (or a source that "elevates") gives
    `highest_this_combat + 1`, and an independent stack takes `max(current+1, source_tier)`
    so a strong source is never weakened by prior light shock. Tier effects: **T1 Shout**
    (noise/breaks stealth), **T2 Stutter** (current action fails), **T3 Faint** (Helpless
    1 Clock + drop items), **T4 Helpless+Exposed** rest of combat. **Burn T1 also inflicts
    Shock T1** KEPT (the cauterize cost — anti burn-cure-dominance). See rules-addendum R13.
22. **S2.3 R14 Numbers function DECIDED (owner 2026-07-20).** The force-vs-robustness gate is
    the damage: **damage = max(0, Force − Robustness)** (the gate and the number are one
    subtraction). **Force** = Physique contribution + weapon force rating (+ merged
    combined-action force, R15). **Robustness** = Physique-derived base + per-part
    armor/toughness. On a **blocked hit** (Force ≤ Robustness → 0 HP): Shock can still land;
    damaging conditions (bleed/burn/poison) do NOT (no wound to seed them). Scope: implement
    the function + reseed ALL magnitudes (weapon force, part HP, robustness, enemy budgets)
    as coherent PLACEHOLDER values, tuned later in a mutation + playtest pass — not final
    numbers now. See rules-addendum R14.
