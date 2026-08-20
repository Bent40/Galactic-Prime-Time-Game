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
   **↳ Annotation (D-22 reconciliation, 2026-08-10) — this entry records the state at the
   2026-07-16 GDD run only, and is no longer the live status:** title **kept for now** ·
   **Momus = shared host** · timer = **a *season* mechanic, not cosmology (Option E
   REJECTED)** — all three ruled the same day, see #8 below and
   `../setting-rebrand-options.md:157-164` · **Forsaken manual trigger CONFIRMED** (#8
   below) · **TTRPG re-skin SUPERSEDED 2026-08-10 by D-V2 — v1 is FROZEN and does NOT
   re-skin; the casino stays video-game-only** (`../versions/v2-decisions-round2.md`;
   `../ttrpg-update-plan.md:5-9`).
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
   for now · Momus shared host · ~~TTRPG re-skins to casino~~ **SUPERSEDED 2026-08-10 by
   D-V2 — v1 is FROZEN and does NOT re-skin; the casino stays video-game-only**
   (`../versions/v2-decisions-round2.md`; `../ttrpg-update-plan.md:5-9`) ·
   starving-pantheon REJECTED (bankruptcy-by-debauchery lore instead). Pending explanation before ruling: dialogue
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
23. **Patron dataset — roster is canonical; slice keeps the 5-god subset (2026-07-20).**
    Two files coexist: `data/patron_roster.json` (the Wave-5 generated **24-god roster** —
    CANONICAL) and `data/patron_gods.json` (the **5-god slice subset**, the bid screen's
    current source). The migration of the slice/bid screen onto the roster is **DEFERRED**
    (content work, held under the content freeze until the slice proves fun). No duplication
    bug is introduced meanwhile: the roster is the source of truth; the 5 are an explicit
    slice subset. Revisit when demo loadouts are re-pointed (memory/next-actions already
    tracks this).
24. **Network condition profile — per-part resistances, NOT a special gate (owner 2026-07-20).**
    The mycelium network is just another **body part with its own resistances** (the important
    distinction: parts carry per-part condition immunities/effects; we do NOT gate specific
    damage from it). Its profile: **immune to most conditions** — they never apply, so they
    never build tiers or destroy it (crushed / non-neural poison / chill / exhaustion /
    infection / suffocation / dissolution, plus the existing bleed-immunity); **NO resistance
    to force** — full HP damage grinds its 50 HP down (the intended kill, through the 35/18
    pressure valves; this closes the crushed-T3 shortcut the R14 tuning surfaced because the
    crushed *condition* no longer applies, while force HP still does); **fire HARMS it** — the
    network is exempt from the boss's fire-heal (`fire_harms`), so burn damages the fungus
    instead of healing it (a valid post-breach weapon); and **neural poison** (`poison_type:
    "neural"`) bypasses the poison immunity — mycelium is a neural network. Implemented as
    per-part data on the network (`condition_immunities` + `fire_harms`, data/enemies.json),
    checked in `ConditionEngine.apply` (immune conditions resist) and the fire-heal hook.
    Force/HP damage is never gated. Verified: balance harness network-kill 4→7 ticks (grind),
    slice WINS via `vital_part_destroyed` (HP), F2 intact. Tests: test_network_destruction_immune.gd.
25. **The Bit is AUTHORED, per-character content (owner 2026-07-22).** A bit is a specific
    thing a character canonically does all the time — mocking a downed enemy, a signature
    pose, a catchphrase — not a generic "The Bit" button. **Not everyone has a bit**; if a
    character has one, it is authored content on their loadout/character sheet. Mechanically
    The Bit stays NULL (decision #15's guarantee holds); what changes: the character data
    carries `bit {key, name, line}`, the sim REJECTS the_bit from an actor with no authored
    bit, bit_performed carries which bit, and the UI offers it (inside Free Actions) only
    for characters who have one. Slice: Dario's bit is **The Bow** (canonical — "bows after
    every kill"); **Imani has NO bit** (canonical — zero interest in the camera).
26. **HUD v2 structural spec ADOPTED as the front-rework build target (owner 2026-07-22).**
    `docs/ux-designs/hud-v2/ARCHITECTURE.md` (owner-supplied) governs the HUD rebuild:
    world-dominant center, party rail left, selected-summary top-left, Moment/Clock
    timeline top-center, crowd + contextual entity inspector right, action launcher with
    temporary flyouts + End Turn bottom, Momus ticker with a full event log; three
    visibility layers (persistent shell / contextual / modal). Corrections riding the
    adoption: skills menus scale past 4; individual allies show part-based HP everywhere
    (cards flag urgent parts; inspector shows full anatomy). Phased per
    docs/ux-designs/hud-v2/ADOPTION.md — v1 builds only what real systems back (odds/chat/
    popups/recruits wait for their systems). Vocabulary RULED (owner 2026-07-22): ENGINE
    terms stand — Clock = the 10-tick lap, Moment = the tick; the mockup's inverted usage
    was incidental (ADOPTION.md).
27. **Explosion beats are REAL; knockout = Helpless for 2 Clocks (owner 2026-07-23).**
    The pressure-valve explosions run as an actual sequence, not a collapsed transition:
    entering an explosion phase the boss telegraphs (visible steam, 1 Moment) → the escape
    window opens (`escape_moments`, canon 2 — contestants can run) → the blast fires at the
    authored radius (5 / 7) and everyone still inside is **knocked out: Helpless for 2
    Clocks** (owner ruling; not removed, not dead) → the network retreats (breach reset,
    wounds persist per #18/R11) → the phase machine **advances into the next Threshold
    phase and the boss keeps fighting**. This retires the v1 dormancy (boss idling
    `phase_not_implemented` forever after Valve I — the bug behind "the fight stalls").
    Phase 6 (death explosion, radius 19, instant kill) stays data-only: the fight ends at
    network 0 before it would choreograph; it becomes real with the arena/exploration
    layer (KAN-5).
28. **Dodge thresholds ask REFLEXES; a failed ask adds 1d4 (owner 2026-07-23).** Unified
    dodge model replacing the flat d6: a dodge threshold is checked against the dodger's
    Reflexes — **Reflexes ≥ threshold = auto-dodge**; otherwise roll the stat's
    **threshold die (d4 by default)** and add it: Reflexes + die ≥ threshold dodges.
    **Threshold dice are upgradeable through the game, per stat** (owner-proposed,
    adopted as the progression hook — d4 → d6 → d8; KAN-7 economy decides costs). Applied
    both directions: contestants dodging the Dash use the authored counters ladder
    (Reflexes ≥ 7 auto-dodge + 1-hex sidestep; ≥ 9 also counterattacks; below 7 the 1d4
    fallback), and the boss's own aimed-round dodge re-expresses as the same check —
    Incinedile threshold retuned 4 → 7 (PROVISIONAL) so Reflexes 4 + 1d4 keeps the old
    ~50% rate. Consequence surfaced to owner: Reflexes 2 + d4 maxes at 6 — Imani cannot
    dodge the Dash until a die/stat upgrade (tank identity: positioning is her counterplay).
29. **The Antagonism engine (owner 2026-07-23) — targeting is weighted, personal, and
    earned.** Mobs/bosses no longer beeline "nearest": each AI actor keeps an
    **antagonism score per opponent** — proximity supplies the base weight (closer =
    much likelier), and what you DID to it moves the score: damaging it builds grudge;
    mocking it builds grudge **if the mob is intelligent enough to get the insult**
    (personality-gated); sparing it reduces attention (personality-gated; needs a
    detectable mercy event — reserved hook until one exists). Two equally close targets
    with no history = exact 50/50. Selection is a weighted-random draw from the salted
    `ai_rng` stream (deterministic, serialized, replay-identical). **Personality types
    per enemy template** (data-driven: proximity bias, grudge weight, mock sensitivity,
    low-HP preference for elites, decay) are the tuning surface — Incinedile (Mind 1)
    is too dim to care about mockery; it remembers pain. See rules-addendum R23.
30. **Feint gets a counter: smart mobs READ it by Mind (owner 2026-07-25).** Response to
    the balance finding that cleanly-played feint zero-damages a dim boss: a feint now
    carries a **read threshold that asks the defender's MIND** through the same R22
    threshold machinery — Mind ≥ threshold auto-reads; otherwise Mind + its threshold
    die (d4 default, upgradeable) must reach it; below the die's reach the read is
    impossible and consumes no rng. A READ feint is wasted (nothing arms, the feinter's
    Moment is spent) and the reader adds mock-grudge (R23 — by definition it got the
    insult). Threshold scales with feint level (PLACEHOLDER R14: 4 + level): Incinedile
    (Mind 1, max 5) can never read Dario's L3 feint — the slice fight and the balance
    WIN are unchanged; a Mind-4 elite reads L3 on a 3+; Mind ≥ 7 auto-reads. Dumb
    bosses stay feintable by design — intelligence is the counter, which is the
    Antagonism personality system paying off.
31. **Engine-first mandate; front rework is owner-led (owner 2026-07-25).** The owner
    will rework the front completely and draft the mockups themselves ("Ill draft
    mockups later so you can build them") — the KAN-4 mockup gate's SCREEN decisions
    are therefore deferred to that pass, and engine work proceeds without waiting on
    UI approval: run/recruitment engine, creation-spec engine, and the remaining
    engine backlog land as sim/controller capability with driver-level tests, no new
    scenes. Two mechanical defaults ship PROVISIONAL in the run engine (canon-leaning,
    awaiting the owner's front pass): **recruits join AS-IS carrying their encounter
    damage** (wounds-persist canon) and **a declined recruit is gone for the run**
    (permanently-losable canon). The engine keeps trait sourcing agnostic (a creation
    spec carries final traits; whether the front derives them from a background/epithet
    track per R16 or direct allocation is presentation).
32. **The 2026-07-25 sign-off batch (owner, verbatim by number).** Approved as
    implemented: phase-5 merged spin beat, cone-tracking ties, the death-spin decide
    order, the R22 boss-threshold retune 4→7, roll eligibility (Exposed may roll),
    recruits join as-is, camera stacks 0..1, cap-raise stacking, the takedown edge
    readings (merged = last connected member; self-kill counts). Changed/new rulings:
    - **Undodgable attacks (supersedes R25's valve consequence):** some attacks can be
      declared **specifically undodgable — announced on the attack's windup so the
      player knows and never dies to a misunderstanding**. The valve blast IS
      undodgable: Tactical Roll's AoE-center escape does not apply to it (leaving the
      radius still does — that is movement, not a dodge). Mechanism is data-driven per
      ability/effect; the telegraph, schedule view, and preview must all carry the flag
      loudly. See R26.
    - **Hype chains across encounters (supersedes the per-encounter hype reset):**
      back-to-back encounters retain hype — the next encounter starts with **40%** of
      the previous meter, then **60%**, then **80%**, then **100%** for further links.
      Chaining encounters is rewarded with hype.
    - **Declined recruits: depends on their character story** (supersedes the global
      "gone for the run"): per-recruit data decides whether a declined offer can
      return. Authored per character.
    - **Epithets renamed:** Sasha **"Little shadow"**, Nikita **"The lonely"**.
    Open from #10 (unanswered, standing as-is): both premades' 4th skill slots; the
    cross-character CHAIN cash-in on Nikita's Pressure Strike.
33. **Content-pass rulings batch (owner 2026-08-18).** Three calls on the scoping flags:
    - **A FACING primitive is RULED IN** — "for sure needed", and it belongs to the
      stealth engine too: R20's deferred vision CONES build on it. Scope: a serialized
      hex-direction facing on combatants with a deterministic update rule; "behind"
      gates (decapitate / slip_through / vibe_control) read the rear arc instead of the
      Exposed approximation Batch A ships interim; R20 sight upgrades from 360° to
      facing cones. Lands as its own story between content batches (all sim files
      collide); Batch A's approximation is explicitly interim. **SHIPPED same day —
      contract of record: rules-addendum R30** (state + staging default + update
      table + arcs + the v1 no-facing-command limitation; `sees()` front-arc gated;
      the Batch-A slip_through/decapitate retrofit landed — vibe_control reads the
      same gate when its content pass lands).
    - **NO exclusive skills — G7 binds the sim.** The `exclusive_to` field is RETIRED
      (validator now rejects it); acquisition-requirement gates replace it
      (`acquisition` string on the row). reversion's `exclusive_to: nikita` converted
      to a G7-style acquisition gate (PROVISIONAL wording).
    - **F2 (the Brace/Intercept/Iron-Stance L6-10 band conflict) explained to the
      owner, ruling pending** — does not touch the L1-4 content pass.
      **↳ RESOLVED by #34: past-5 progression is merge/absorb-shaped; G6's merge is
      canonical, R1's fold-into-Brace is retired.**
34. **SKILL TIERS RULED IN (owner 2026-08-18): "Rule it in."** The tier-2 evolution
    model, per-skill (not universal):
    - **Tier 1** = every skill's L1-5, authored deeply; L5 = mastery of the base form.
    - Past 5, each skill is authored as ONE of three shapes: **MERGE** (Gemstone —
      both parents consumed, narrow-keyword-compatible, yields a tier-2 skill with its
      own L1-5; Iron Stance = the canonical example, Intercept Lv5 already the merge
      point), **ABSORB** (consume one compatible lesser skill to push the survivor
      into L6-8 — cheaper than a merge, keeps identity), or **LINEAR 6-10** reserved
      for skills ruled to deserve it (magic's L10 rule-transcending tier stays
      source-gated per the R19 framework ruling #2).
    - Keyword narrow-share gates merge/absorb legality (G3 becomes load-bearing);
      broad-only maps to Modification Center special offers. Token/economy
      re-expression (what Patron Tokens gate under tiers) = KAN-7 sitting.
    - Supersedes the R19 framework's "6+ earned in-run / cap-10 token-gated" as the
      universal shape; the 78 authored L5+ threshold rows re-map into tier-2 rungs
      and absorb bonuses (nothing discarded).
    - The L1-4 content pass is UNAFFECTED (identical under every tier shape).
    - **Next artifact (owner-directed): the per-skill tier proposal** — every skill
      stamped merge/absorb/linear with recipe/absorb candidates from the keyword
      data + the threshold re-map plan — drafted when content Batch B lands, for the
      owner's yes/no pass. Tabletop-shared (skills are shared spine; book §4.5
      already carries the merge rule).
35. **Tier proposal RULED (owner 2026-08-18, by number).** The 48 stamps + 8 recipes
    stand as proposed. The five questions:
    - **Q1 = route (a):** orphans stay LINEAR; the override mechanism is **authored
      Modification-Center special offers on broad-only pairs** (the three
      data-supported candidates — camouflage×nightlurking, feint×vibe_control,
      telekinesis×pressure_hold — enter as PROVISIONAL offers awaiting blessing).
      Taxonomy growth (route b) not adopted now.
    - **Q2:** ABSORB = flat unlock of the survivor's L6-8 band, gated on a **minimum
      fodder level** ("it might be unfair depending on skill stat dependency" —
      the minimum is authored PER ABSORB, mirroring Q5's per-recipe spirit).
      [Recorded reading: flat-unlock + min-fodder; correct if 'levels convert'
      was intended.]
    - **Q3: TIER-3 MERGES WILL EXIST** ("for sure... We need a lot more skills") —
      tier-2 skills keep short linear bands FOR NOW, and the recipe schema must
      never forbid tier-2 skills as future parents. Content-growth direction
      recorded: the skill catalog is expected to expand substantially.
    - **Q4:** strong_strike + acrobatics CONFIRMED LINEAR for now — owner intent
      recorded: **they become mergeable later** (revisit with the tier-3/content
      growth wave).
    - **Q5: per-recipe min-levels** (no global convention; the proposed 5/3 pairs
      are each recipe's own authored values, changeable per recipe).

## #36 — The front-rework gate: ten HUD decisions (owner, 2026-08-19)

Reviewing the five mockup frames (`docs/ux-designs/front-rework-2026-08-19/`), the
owner ruled on all ten questions. **Approved as built:** the §2 layout (1), the
blocking dodge-ask card (3), status effects surfaced in five places (4), stealth and
facing drawn on the board (5), the discovery-state vocabulary (6), targeting's three
information levels (7), and Camera Call / The Bit staying inside Free Actions (10,
with the amendment below). **Changed by ruling — full text in `docs/rules-addendum.md`
R34:**

- **(2) Enemy intent goes Slay-the-Spire, not timeline-band.** Every enemy carries an
  intent icon (type of action expected) with a hover explanation; the timeline keeps
  order/timing only. R26's undodgable transparency moves onto the icon. Unread enemies
  show UNREAD rather than a guess.
- **(8) Exploration is free-form.** No Clock, no Moment order, no turn to end out of
  combat; the clock starts on contact, and entering a room is the commit. The
  engine-side work is NOT built (today's sim is clock-driven end to end) — tracked as
  an open KAN-5/KAN-6 item; "contact" is undefined and flagged PROVISIONAL.
- **(9) Merge parents cap at 5.** A parent does not go past 5 unless that skill was
  already stated to be linear; declining an offer costs nothing but the ceiling. This
  amends #35's framing (LINEAR is the exception, not the fallback).
- **(10, amendment) Free actions are limited per turn.** They stay in the Free Actions
  category, but the category carries a per-turn budget shown on the button. The budget
  value, reset cadence, and per-entry costs are unruled; NOT implemented (free actions
  are uncapped in the resolver today) — tracked as a KAN-2 follow-up.

The mockups were rebuilt to match the rulings the same day; the gate README carries
the per-decision record. Scene-building (KAN-6) remains gated on the owner's sign-off
of the revised frames.

## #37 — The exploration layer ruled out (owner, 2026-08-19)

Answering the four gaps R34's exploration story named, plus the cadence question:

- **Free-action cadence: PER TICK** ("per tick is correct, keep it") — the budget of
  two refreshes every Moment, matching R3's live window. The PROVISIONAL per-Clock
  reading is retired.
- **Voicebox and lockpicking work in exploration** — the resolver-side cost waiver is
  theirs; free out of combat, full R3 costs once combat starts.
- **Mobs patrol during exploration** — enemies move and their eyelines move with them.
  ~~What advances a patrol without a clock is my call, flagged: the party's own
  exploration commands are the beat (one mob step per party walk), which makes standing
  still freeze the room.~~ **RETIRED the same day by the TIME ruling below** — the beat
  is the exploration time step, so standing still never freezes the room.
- **The crowd watches exploration** — a free-form walk can feed hype when something is
  at stake: danger nearby, good stealth, approaching a large boss, cross-party
  meetings. Idle walking through a cleared room pays nothing. Cross-party meetings are
  deferred to the shared-world stages that do not exist yet (recorded, not dropped).

**Two same-day owner additions, mid-story (2026-08-19):**

- **TIME FLOWS IN EXPLORATION** — *"i think time should just be moving. We have
  moment-to-time conversion units already established"* (+ a pause option for
  single-player). This **revises R34**: exploration is no longer "the clock is stopped"
  but "the clock runs, there is no turn order, and nothing costs Moments". `advance_tick`
  is the logged exploration time step and runs the one real tick path (R1: one tick ≈
  0.5 fictional seconds). PAUSE is the driver not issuing time steps — deliberately no
  sim state. Accepted consequence: exploration ticks run the ordinary per-tick sweeps,
  so wounds burn while you walk and hype decays between beats.
- **INVENTORY AND ITEM USE WORK IN EXPLORATION** — *"Time can pause during inventory
  and item use... Pokemon had the same system for poison or burn"*. Same free-form
  waiver as voicebox/lockpicking, and it additionally leaves R3's never-resetting
  `inventory_uses` ledger alone. The pause is again the driver's job: **stop the beat
  while an inventory UI is open** (a KAN-6 driver contract, not sim state).

**Epic placement (asked and answered):** only the run-loop + HUD wiring is KAN-6 and
gated on the mockup sign-off. The resolver waiver and patrols are KAN-5/KAN-2, and
exploration spectacle rides the already-live HypeEngine — all three were unblocked and
started immediately.

**SHIPPED at the sim layer 2026-08-20** (`simulation/exploration.gd`,
`CombatSim._patrol_beat`, `ActionResolver.declare_free_form` / `inventory_free_form`;
`tests/test_exploration_layer.gd`). Combat is provably unaffected — `enemy_ai.gd` has no
edit and both CI harnesses are byte-identical. Outstanding: the KAN-6 driver/HUD wiring,
and no seeded enemy authors a patrol route yet (content, not engine).
Full text: `docs/rules-addendum.md` R35 + R34's TIME AMENDMENT.

## #38 — The mockup gate is PASSED (owner, 2026-08-19)

*"Approved, hype decay is fine, give the hounds patrol routes"*

- **The five HUD v2 frames are APPROVED.** `docs/ux-designs/front-rework-2026-08-19/`
  is the build target for KAN-6; scene-building is unblocked. Changes from here are
  amendments to an approved design, not gate revisions. (Emoji remain placeholder art
  — ARCHITECTURE.md §7 still bans them from the final release — and every number is
  still PLACEHOLDER R14.)
- **Hype decay during exploration is RULED FINE** — the consequence R35 reported
  (walking runs the real tick, so the broadcast plane's Clock reset fires: hype decays
  and the crowd-goal director cycles). It stays as built; "the crowd is bored by
  safety" is now literal.
- **The hounds get patrol routes** — closing R35's "capability ships, content doesn't"
  gap for the kennel pack.

**Note recorded honestly:** patrol data alone is dormant in the shipped demo run,
because the run loop still enters every room directly in combat. The gate's approval
unblocks the wiring that makes it live, so the two ship together rather than leaving
authored routes that nothing ever drives.
