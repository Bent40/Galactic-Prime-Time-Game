# Digital Rules Addendum — Canonical Rulings for the Simulation

**Status:** draft v1 (overnight 2026-07-13) · **Authority:** where the TTRPG book is silent,
ambiguous, or broken (catalog: `docs/review/review-1-ttrpg.md`), the simulation implements
THIS document, not the book. Each ruling cites the finding it answers.
**SETTLED** = the book/char-sheet app/live play already implies the answer, or it's the only
coherent engineering reading. **PROVISIONAL** = a design taste call — owner review requested;
the sim implements it as written until changed.

Rulebook language preserved wherever possible; the goal is the smallest set of decisions
that makes the system computable.

---

## R0 — Timeline vocabulary (foundation for everything below)

**AMENDED (owner, 2026-07-17):** canonically, **one tick ≈ 0.5 seconds of in-game
time** — a full Clock is ~5 fictional seconds. Diegetically everything happens
*really, really fast*; the real-time declare windows and paused drivers are the
broadcast's slow-motion, not the fiction's pace.

**SETTLED.** Internally the sim runs a **monotonic absolute tick counter** starting at 0.
"Moment" is presentation: `moment = 10 - (tick % 10)` (so ticks 0..9 display as Moments
10..1). A **Clock** is one full lap of 10 ticks; "Clock reset" happens after the tick
displaying Moment 1 completes. Cooldowns, timers, and condition durations are all stored in
ticks. Clock **drivers** (who advances the tick: paused-on-decision solo / timed declare
windows in co-op fields / wall-clock for broadcasts) are outside the sim per
`docs/DIRECTION.md` — the sim only ever receives "advance to tick N" plus commands.

## R1 — Scheduling & the Clock boundary (answers C1)

**SETTLED.** `next_action_tick = current_tick + moment_cost`. There is no wrap ambiguity
because ticks are absolute; a 2-cost action declared on Moment 1 simply resolves at Moment 9
of the next Clock. Order of operations at each tick:

1. Resolve all actions due this tick (see R2 simultaneity).
2. Apply Forced-Action consequences queued by step 1.
3. If this tick completes a Clock: run **condition advancement** (R4), tick lounge/ambient
   timers, fire reorganization beats (enemy phase logic, combat-field join window).
4. Advance to the next tick when the driver says so.

## R2 — Declare/resolve timing, simultaneity, misses, reactions (answers C2, A5)

- **SETTLED.** Actions with cost 0 or 1 declare and resolve on the same tick. Multi-Moment
  actions declare at tick T, resolve at `T + cost`, and the actor is **Exposed** for the
  duration (book rule, unchanged).
- **SETTLED.** All resolutions at a tick compute against the **state snapshot at the start
  of that tick** — simultaneous kills can trade; nobody gets tick-order priority. Where two
  same-tick effects genuinely collide (e.g. both grab the last item), the sim resolves by a
  **logged seeded roll** (deterministic, replayable).
- **SETTLED.** Consequence: you can dodge a *windup* (multi-Moment action) by leaving its
  range/area before its resolution tick; you cannot dodge an instant (cost ≤1) action.
  Range and validity are re-checked at resolution; an invalidated action collapses into
  Forced Action – Tool (book rule).
- **PROVISIONAL (design taste).** "Miss" exists only as an explicit effect (e.g. Slick
  Hide's "first melee attack against you misses" = that attack resolves with no effect).
  There is no universal dodge roll. The live table's homebrewed **Dodge Threshold** d6
  becomes an *enemy ability pattern* (used by agile bosses like Incineradile), not a
  universal rule. *Compendium refinement:* specific boss attacks carry **Reflexes-gated
  player counters** (e.g. vs Dash: Reflexes 7 = auto-dodge + 1-space move, Reflexes 9 =
  auto-dodge + counterattack, below = roll 4+ to dodge) — authored per-ability, still not
  a universal mechanic.
- **PROVISIONAL (numbers).** Reactions: a reactive skill declares a **trigger**; when it
  fires, the reaction resolves immediately, out of schedule. Its Moment cost is added to
  the reactor's `next_action_tick` (you pay by acting later). **Max one reaction per
  combatant per tick**, and 0-cost reactions also consume the free-action slot (R3).

## R3 — Action caps: free actions, movement, inventory, cooldowns (answers D1, D2, C6, F5, F10)

- **PROVISIONAL (numbers; shape settled).** Per tick a combatant gets at most: **one
  scheduled action** (the one due this tick) + **one free (0-Moment) action** + **one
  reaction**. 0-cost skills are legal (F10) — they consume the free-action slot.
- **SETTLED (kills infinite kiting).** Movement: a move of 1–3 spaces is free but consumes
  the free-action slot, **once per tick**. Longer moves cost `ceil((spaces - 3) / 4)`
  Moments as a scheduled action. You cannot move twice in one tick.
- **SETTLED (deletes the reset-loop exploit).** Inventory: the *first* inventory
  interaction of a combat is free (consumes the free slot); every later one costs 1 Moment.
  The book's "resets upon using a different action" clause is **deleted**. An item's own
  listed Moment cost *replaces* the interaction cost when higher (one cost, never two).
- **RULED (owner, 2026-07-14 — NQ1): cooldowns do not exist.** Skills are gated by
  **priming** instead: powerful effects require preparation conditions *before* use
  (channel/prep actions, consumed stacks, stances, positions), not a wait-after-use timer.
  High-tier items may **skip specific prime requirements** — deliberate design space.
  Consequences: (a) the priming vocabulary is designed WITH the owner's pending skill
  passover — each cooldown-texted skill (Tactical Roll, Acrobatic Save, "-4 Moment
  cooldown" thresholds) gets re-expressed as primes in that pass; (b) the engine's dormant
  cooldown support is deprecated and gets removed in the priming implementation pass;
  (c) acceptance criterion 9 is superseded (see the criteria list). Mechanically, primes
  are requirement-shaped — the engine's existing requirement checks are the substrate.
- **FINALIZED (owner 2026-07-20, S2.1 — decision-log #20): the prime vocabulary is a
  canonical 5-type set.** Every skill's prime is one (or a combo) of: **CHAIN** (must
  immediately follow a named action on the same target — already live via
  feint→pressure_strike); **STANCE** (hold a declared stance that ends on triggers);
  **STACK** (consume N accumulated charges — the Camera-Call model); **STATE/POSITION**
  (target/self in a state or relative position: Exposed, downed, behind); **PREP/CHANNEL**
  (spend a prep action to arm a one-shot prime). The two literal cooldown-texted defensive
  reactions (Tactical Roll, Acrobatic Save) are **STANCE-gated** — usable only while holding
  a light-footed/defensive stance (no timers). Implementation this pass: build the 5 prime
  predicates into the requirements gate, DELETE the dormant cooldown code, convert the
  explicitly cooldown-texted skills (Tactical Roll, Acrobatic Save, the "-4 Moment cooldown"
  threshold → CHAIN discount); per-skill prime tags for the other ~37 ride the R19 ladder
  finalization. (Engine implementation PENDING — this records the design ruling.)

## R4 — Damage, condition application, universal advancement, missing tiers (answers A4, C8, E1, E2, E3, D3)

- **SETTLED (matches every authored weapon + live play).** An attack deals its **listed
  damage** to the chosen body part after flat resistance (floor 0). The book's "usually 1"
  sentence is void. Small HP pools are the design: parts fail fast, the fight is about
  which parts and which conditions.
- **SETTLED (matches the live table's boss notes).** Condition application: a damage type
  applies its condition at **Tier 1** on first application to a part; while active, a new
  application of the same type to that part **advances it one tier** — at most one
  attack-driven advance per part per tick.
- **SETTLED (the universal rule E1 was missing).** At every Clock reset, **every active,
  non-delayed condition advances one tier** (generalizing Bleeding's rule; this matches the
  seed data's `advances_on_clock_reset`). A **Delayed** condition skips exactly one
  advancement and loses its delay. Chilled's "8 Moments" oddity is respecified: Chilled T1
  resolves at the next Clock reset if it was not re-applied during the Clock (E2).
- **Missing tiers filled (E3):**
  - **Crushed** T3: part destroyed — lethal on torso/head, permanent loss on limbs.
    T4: death (torso/head only). (Was: stopped at T2 with "rapid escalation" to nowhere.)
  - **Burn** T1: cauterizes (stops Bleeding, removes Chill) **and applies Shock T1** —
    the previously-missing drawback (PROVISIONAL: Shock as the cost is a taste call).
    T2: as book + Forced Action – Body. T3: part disabled; on torso/head starts a 1-Clock
    death timer. T4: death.
  - **Exhausted** (PROVISIONAL numbers): T1 +1 Moment on actions costing 2+; T2 +1 Moment
    on all actions; T3 every action is Forced – Body. Recovers one tier per Clock spent
    taking no scheduled actions; fully resolves out of combat.
  - **Infected**: T1 prevents healing/resolution of other conditions; T2 all other active
    conditions advance one extra tier at Clock reset; T3 starts a 2-Clock death timer.
  - **Suffocation / Dissolution**: stay tierless timers (book). Items saying "Suffocation
    Tier 1" (E4) are re-read as "delay Suffocation by 1 Clock".
- **Burn-cure dominance (D3) is closed by the above:** cauterizing costs HP + Shock and the
  Burn itself advances at Clock resets like everything else — a desperate trade, no longer
  strictly dominant over bandages/antitoxins.

## R5 — Death, bleed-out, KO (answers A1, A2)

- **AMENDED (owner, 2026-07-17) — MIND COLLAPSE:** a character whose mind collapses
  (Dissolution completion) is **gone from this play and can never be played again — it
  is now, forever, a puppet of the one who collapsed it.** Worse than death: no
  Ascension, no body to bury, and the collapser gains the puppet (an enemy asset the
  party may meet again). Supersedes the earlier PROVISIONAL fiction call on Dissolution
  completion.
- **SETTLED.** Death: head or torso at 0 HP (book).
- **SETTLED (fixes the contradictory list).** Bleed-out: if head/torso hit 0 via a
  *delayable condition* (Bleeding, Poison, Infection, Burn timer), the character enters a
  1-Clock bleed-out: **Helpless** (R7), any damage kills, delaying/curing the causing
  condition returns them at 0-HP-stabilized. Direct weapon damage or Crushed to 0 =
  immediate death, no bleed-out. **Exhausted is removed from the death-states list** (it
  has no death mechanism — A1).
- **PROVISIONAL (fiction call).** Dissolution timer completion = the contestant is
  **removed from play** (mind collapsed; body alive). Whether that's death, brainwashing,
  or a rescue hook is content, not engine — the sim emits `mind_collapsed`, never `died`.

## R6 — Advancement & the stat economy (answers B1, C3, C4)

- **AMENDED (owner, 2026-07-17):** an **XP system is approved in principle** ("just a
  matter of how much") — level points may flow from XP rules rather than pure grants;
  amounts are a tuning-pass concern.
- **SETTLED (codifies what the live table already does via the char-sheet app).** Levels
  are **awarded by the game** at authored milestones (bosses, floors, major achievements) —
  no XP curve. Each level grants **1 level point** into a pool; a level point buys +1
  `levelBonus` on any one trait. Creation rules unchanged (7+7 across pillars, max 5).
- **SETTLED (adopt the app's live-tested formulas verbatim).** Over-10 stat caps:
  Physique `floor(max(0, total-10)/5)` → +1 max HP per body part each;
  Reflexes `/12` → +1 allocatable physical resistance (Bleed/Crush/Burn);
  Mind `/15` → +1 psychic resistance tier; Charm `/20` → +1 Camera Call stack.
  The "rated 1–5" scale is **creation-only** (now stated explicitly).
  *(The compendium's `[OPEN]` "app seeds Mind /10" is stale — verified 2026-07-14: the app
  computes /15, matching the doc. Closed.)* Creation allocation confirmed by compendium +
  party data: **7 points across Body traits + 7 across Core traits**.
- **SETTLED (app rule wins over the book's N — C4).** Skill points per trait =
  `max(0, traitTotal - 1 - spent)`; multi-stat skills cost 1 point from **each** listed
  stat; refunds follow the instance's `traitCosts` history.
- **SETTLED (A3).** Psychic resistance tiers: tier N = immunity to psychic effects of tier
  ≤ N; the Dissolution *timer* is not tiered — psychic resistance instead **slows** it
  (+1 Clock per tier). (This makes the Mind-15 reward real without inventing tiers the
  condition doesn't have.)

## R7 — States glossary (answers B2, B3, B4, B7, E5)

- **Helpless** (SETTLED shape): cannot act or react; is Exposed; attackers may target any
  part including the head.
- **Prone** (PROVISIONAL): is Exposed; may only crawl 1 space per tick; standing costs
  1 Moment (scheduled action).
- **Channeling** (SETTLED): alias for "performing a multi-Moment action" — already Exposed
  by R2; the word adds no new state.
- **Slowed** (PROVISIONAL): free-move allowance drops from 3 spaces to 1; movement Moment
  costs double.
- **Shock stacking** (E5, SETTLED shape): a new independent Shock source while already
  Shocked escalates one tier above the current. Shock T3 (Faint) = Helpless for 1 Clock +
  drop held items.
- **Sizes** (B6, SETTLED shape): every combatant gets a `size` field —
  Small / Medium / Large / Huge. Effects referencing Small/Large read this field. Default:
  humans Medium; sizes are authored per enemy in seed data.

## R8 — Ranged weapons, RPM, reload (answers C5)

**PROVISIONAL (numbers; shape settled).** Firing is a **1-Moment action delivering up to
RPM rounds** (same target, or split across targets in the firing arc). Listed damage is
**per round**. Weapons gain two data fields: `magazine` (rounds before reload; defaults:
light ranged 6, heavy ranged 2) and reload = **2 Moments, both hands** (book's "2 hands"
kept). Content flag: multi-RPM authored items (e.g. Spark-volver, RPM 3) need a per-round
damage pass — at 3 rounds × (2 Burn + 1 Crush) per Moment the book values out-damage a
greatsword; rebalance at content-port time, not in the engine.

## R9 — Grapple (answers B5, D4)

**PROVISIONAL.** Grappling requires a free hand and a target no more than one size larger.
- **Initiate** (1 Moment): succeeds automatically if grappler Physique ≥ target Physique;
  otherwise it's Forced Action – Body (always allowed, consequences apply).
- **While grappled:** target cannot reposition; both are Exposed (book/skill text kept).
- **Escape:** 2 Moments = automatic; 1 Moment if Physique ≥ grappler's.
- **Suffocation via grapple** (Pressure Hold, Amphibious Smother): additionally requires
  both grappler hands and a coverable airway; **bosses and anything ≥2 sizes larger are
  immune to grapple-Suffocation** — boss win conditions must be discovered, not choked out
  (architecture doc's own boss rule).

## R10 — Economy & metagame patches (answers D5, D6, D7, A6, B8, B9, B11, B12, B14)

- **Poison incompatibility (B12/D5, PROVISIONAL):** poisons of *different types*
  (neuro/hemo/myo/pneumo/cyto) are incompatible; same-type applications stack tiers.
  Poison-Soup burst damage is capped at `part max HP − 1` on head/torso — brutal, never a
  guaranteed instant kill in either direction (closes both the nuke and the free-antidote).
- **Requirements gate (D6, PROVISIONAL — flagged for owner):** acting with unmet stat
  requirements still triggers the Forced Action (book) **and** halves the action's damage
  /effect magnitude (round down). Stats become a real gate; desperation moves stay legal.
- **Boss-Token → Patron-Token exchange (D7, PROVISIONAL):** **cut from the digital game.**
  Patron Tokens come only from the audience loop (new Patrons via Goals, Directives per
  next line). Rationale: the exchange bypassed the flagship system and ignored token tiers.
- **Directive rewards (A6, PROVISIONAL):** Directives award tiered loot (achievement
  channel); **Goals** that convert a Patron award Patron Tokens. One reward contract per
  system — corporate pays in stuff, the audience pays in belief.
- **Spaces (B8, SETTLED):** 1 space = 1 hex ("tile" in item text = space). All ranges/areas
  in spaces on the hex grid.
- **Session (B9, SETTLED shape):** for per-session charges (Camera Call), a session = one
  dungeon deployment (leave Lounge → return/extract/die).
- **Healing & downtime (B11, PROVISIONAL — deliberately harsh):** in the field, conditions
  can only be Delayed/Resolved per their treatments; HP does not regenerate. At the Lounge,
  HP restores fully and resolvable conditions resolve. Field HP recovery exists only via
  explicit items/skills (as the book intends: "extremely rare and explicitly stated").
- **Upgrade Tokens (B14):** out of engine scope until the Lounge epic (KAN-7); noted as an
  open economy design item.

## R11 — Engine interpretation log (implemented in KAN-2; all PROVISIONAL)

Calls the engine had to make where R0–R10 were silent. The sim implements these today;
overturning one is a code change, not a rewrite.

1. **Forced-Action table for stat shortfall:** weapon/tool stat or hands shortfall → Tool
   table; condition-driven and above-weight-grapple rolls → Body table.
2. **Snapshot boundary is tick start:** same-tick movement never dodges anything; movement
   on any earlier tick dodges windups; instants never re-check.
3. **Torso conditions gate all actions:** a Forced-Body condition tier on the torso (or the
   acting part) forces every action — torso is the whole-body proxy.
4. **Shock stacking vs strong sources:** `max(current + 1, source_tier)` — a Burn-T3 Shock 3
   is never weakened by the target already being lightly shocked (refines E5's literal text).
5. **Resistance splits cleanly:** flat physical resistance reduces HP only and never blocks
   condition application; tier immunity (Affliction/Psychic) is the condition blocker.
6. **Above-weight grapple still lands** (Forced Actions are always allowed; the grappler
   eats the Body roll) — size ≥2 gap and bosses still immune to grapple-Suffocation (R9).
7. **The grappler can't reposition either** while holding (two-sided lock).
8. **Combat's one free inventory interaction is literal** — if the tick's free slot is
   already spent, the freebie is consumed as a paid action and never comes back.
9. **Timers and partial Clocks:** timers created mid-Clock count the partial Clock at the
   first reset (harsh); bleed-out always gets one full Clock of grace (R5); timers created
   during a reset start at the next reset.
10. **Collateral (Tool 3)** hits the nearest combatant excluding actor and intended target,
    torso-preferred, HP only; the environment absorbs it when nobody qualifies. **Whiff**
    negates the action entirely and does not consume magazine.
11. **Magazine defaults** apply only to explicit `magazine` fields or key-matched weapon
    classes; the ported items.json rows don't carry rpm/magazine yet (content pass open).
12. **Bleeding T4 kills from any part** (tier table as authored — you can bleed out from a
    limb wound).
13. **Camera Call (spectacle engine v1):** stacks per R6's Charm over-cap formula, spent
    per use (`camera_call` command); the "doubled gains AND losses" canon is read as
    *spectacle points attributed to the spotlit combatant are doubled* — cross-referencing
    who CAUSED the spotlit combatant's drama is v2. The spotlight ends at the end of the
    spotlit combatant's current-or-next action (resolved or invalidated), at their death,
    or after a 2-Clock fallback so it can never dangle; one spotlight at a time. The caller
    passes the same actor gates as declared actions (alive → not removed → not Helpless): a
    Helpless contestant cannot call the camera. Session reset of spent stacks (B9: session
    = one deployment) is controller scope, not sim.
14. **Crowd Goals (spectacle engine v1):** ONE active goal, offered at Clock resets (the
    book's reorganization beat) from `data/crowd_goals.json`; selection draws from a
    dedicated RNG stream seeded off the sim seed (so goal draws never perturb Forced-Action
    rolls); expiry costs a small hype penalty; completion pays the goal's hype payout
    (doubled when the completing event is the spotlit combatant's). Kinds implemented:
    takedown / overkill / part_break / exposed_strike. Goals pay HYPE only — the Patron
    conversion + Patron-Token reward channel (R10) is KAN-7 scope. Recorded v1 limits:
    - **Deferred to v2:** weighted / audience-state-driven goal selection (v1 draws
      uniformly) and the compendium's Solo Action template.
    - **RULED (owner 2026-07-18) — takedown = a kill YOU caused:** a friendly death
      completes the takedown goal ONLY IF a contestant dealt the killing blow (friendly
      fire counts — "it's cinema"); the payout is credited to that killer. IMPLEMENTATION
      PENDING — this needs kill-attribution + team-awareness in the hype engine (the
      deferred attribution v2); until then the v1 code over-fires on ANY `combatant_died`,
      a known tracked gap (task queued). Enemy deaths still complete it.
    - **RULED (owner 2026-07-18) — same-batch completion ALLOWED:** a goal offered at a
      clock_reset CAN be completed by later events in that same batch — an insta-win off
      good preparation or luck is not punished. Current behavior is correct as-is; no
      change.
    - **Pre-I9 saves:** envelopes without `goal_rng_state` resume with state 0, which
      diverges from a full log replay. Pre-release saves are declared disposable; no
      migration shim.

15. **AI commands enter the log as `ai_decide` (enemy AI v1, I-16):** enemy
    decision-making is a deterministic policy INSIDE the sim
    (`simulation/enemy_ai.gd`), driven by an explicit `{"type": "ai_decide",
    "actor"}` command the driver/controller feeds once per ready enemy per tick
    (`CombatSim.ai_ready_ids()` / `GameController.run_enemy_turn()`), exactly like
    `advance_tick`. The decision derives from (sorted sim state, salted `ai_rng`)
    only, so a log replay recomputes the identical decision — the sim stays
    passive (never self-advances, never self-decides), and the command log stays
    the single source of truth. `decide()` itself consumes NO rng (pure
    priorities); the AI stream exists for the dodge d6 (#17) and future
    variability, salted like the hype engine's goal stream so AI draws never
    perturb Forced-Action rolls. Actor gates and rejection vocabulary mirror
    `declare_action` (`not_ai_controlled` added). AI-controlled = category
    Mob/Elite/Boss/Super Boss; hostility = a differing `team` string (an enemy
    with an EMPTY team sees no targets and waits — teams are explicit). AI state
    (rng state, boss phases, summon counts) serializes under `"ai"` and is
    covered by `state_hash`; pre-I16 saves resume with a fresh salted stream.
16. **Policy tiers v1 (all numbers PLACEHOLDER, R14):** MOB — nearest target
    (ties: lowest total HP, then id), torso-line part pick (`part_bias`
    honored), free-move up to 3 toward the target (greedy hex steps, fixed
    neighbor order, occupied hexes skipped, only strictly-improving steps),
    attack when in reach — move-then-attack can share a tick (free + scheduled,
    R3); a grappled mob bites its grappler. ELITE — summon once per combat when
    it has a summon ability (brood spawns on the nearest free hexes,
    deterministic ids `<elite>_brood_N`, acts from the NEXT tick; the summon is
    a cost-1 instant), self-heal when a lethal part falls below half (the heal
    resolves on schedule at the actor's then-most-damaged part, halved by unmet
    requirements, negated by Whiff), otherwise strikes the LOWEST-HP target in
    reach (ties: nearest, then id) and punishes exposure — head when targetable,
    else the lowest-HP part. BOSS — see #18. v1 ability model: `damage` +
    `range`/`area` = strike (first damage entry only), `summon`, `heal`;
    `sequence`/`effect`-only abilities are skipped (death_spin, drag_back
    deferred); "cone N"/"line" resolve as plain reach (true area geometry is
    KAN-5 scope). Targets with no attackable part are skipped.
17. **Dodge Threshold (the R2 boss-ability pattern; live-table homebrew
    adopted):** a combatant with `boss_traits.dodge_threshold` (1..6) rolls the
    d6 from the salted AI stream once per AIMED weapon round against it; roll ≥
    threshold negates that round entirely — "miss" stays an explicit authored
    effect, never a universal rule (R2). No dodge while Helpless or Exposed:
    windups, grapples and prone are the discoverable punish windows. Collateral,
    condition, forced-action and environment damage are never dodged, and Burn
    still feeds `fire_heals` instead of being dodged. Every roll is emitted
    (`attack_dodged` / `dodge_failed`) — no unlogged randomness. Incinedile
    ships threshold 4 (PLACEHOLDER, R14).
18. **Incinedile phase machine v1:** per-boss phase number (AI state, starts
    at 1); while in a fight phase, the health part (`surface_immunity.
    health_part`) dropping to a later explosion phase's `hp_at_or_below` fires
    `boss_phase_changed`. Entering the `breach_resets_after_phase` phase applies
    the canonical retreat IMMEDIATELY (v1 collapses the explosion beat into the
    transition): breach closes, the network re-hides (`breach_reset`), and the
    burst-damage counter clears so the old wound cannot instantly re-breach.
    **Wounds PERSIST across the valve (owner-ruled 2026-07-18, was PROVISIONAL):**
    the boss's active conditions and accumulated part damage carry over — only
    the breach threshold resets, never the harm. The burst-counter clear still
    blocks a same-tick re-breach; the Bleeding-T2 path can only re-open on a
    fresh advancement, not from a lingering already-T2 wound. Phase-1 behavior: cone sweep when ≥2 targets stand in
    reach, else the line charge at the mob-priority target (torso bias), else
    close distance; the ability set is filtered to the phase's `behavior.
    abilities` list. Explosion choreography (telegraph, escape window, KO) and
    phases 3–6 are deferred — past phase 1 the boss idles (`ai_decision` wait,
    `phase_not_implemented`); the phase-2 beat is the slice's win moment
    (review-4 §5, DIRECTION Stage 1).

Not yet implemented (scoped to later epics, hooks in place): poison spread topology,
dissolution cause-tracking, Camera Call's Viewership/Follower/Patron counters (hype meter
stands in — KAN-7), token economy, Lounge/session mechanics. Enemy AI v1 (R11 #15–#18)
ships the mob/elite policies, the dodge-threshold ability and Incinedile Phase 1 + the
phase-2 transition beat; still open there: explosion choreography + phases 3–6,
death_spin/drag_back (forced movement), true cone/line geometry (KAN-5), the Dash
Reflexes-counters (player-side), pack synergy (R15 enemy combos), and AI stances for
`aura_reading` (skills-audit dependency).

## R12 — Session-designed systems adopted from the Master Compendium (2026-07-14)

Source: `docs/GPT_Master_Compendium.md` (design record through ~May 5). These are owner
designs, adopted as canon; engine/content implementation lands with their epics.

- **Weapon tiers → modifier slots:** Crude 0/0 · Basic 1/0 · Quality 1/1 · Superior 2/1 ·
  Exceptional 2/2 (prefix/suffix). **Modifier-tier access gates on weapon tier:** Basic →
  Lesser only; Quality → up to Normal; Superior → up to Higher; Exceptional → up to
  Legendary. Progression = access, not just slots.
- **Extraction friction (Enchantment Altar):** Lesser/Normal extractable with a
  destroy-the-modifier chance (odds improved by Lounge upgrades/skills); Higher+ extraction
  drops the weapon one tier; Legendary+ extraction destroys the weapon.
- **Lesser modifier working list:** Poisoned, Serrated, Weighted, Spiked, Hollow Point,
  Chilling, Explosive Tip, Barbed; Padded/Reinforced flagged out (candidates: Wrapped,
  Balanced, Sure-grip); Draining capped once per Clock per target.
- **Enemy mental resistance is FLAT** (not tiered), and exceeding it by a significant
  margin grants the attacker a bonus (viewer spike / secondary effect).
- **Noise/absorption:** noisy combat attracts nearby encounters — when a Clock completes,
  eligible area encounters can be absorbed into the ongoing fight. The audience clock and
  absorption clock may be one system. (Adopted into DIRECTION; KAN-5 implements.)
- **Death model (game):** checkpoint rewind — full world-state reset on death; character +
  Lounge upgrades persist. Non-PC party members can permanently die.
- **Character-exclusive skills exist** (Full Potential, Heroic Punch → Mario): the skills
  schema needs an `exclusive_to` lock field (content pass).
- **Dissolution encounter pattern:** noble presence starts the Mind timer + a personal
  emotional "song"; embrace = removed-from-play (ghoul persists as story object); escape =
  survive with a permanent scar (one emotion amplified near demons). Matches R5's
  mind-collapse event model.
- **Tank-kit drafts** (Intercept: take an adjacent ally's hit, 0-Moment, Physique-based;
  Iron Stance: declare, don't move, adjacent-ally-targeting attacks retarget to you,
  Physique 5): PENDING finalization (questionnaire), then seed as skills.

## R13 — Shock — **RULED/APPROVED (owner, 2026-07-17: "R13 is approved"; no shock decay
in combat — combat-end reset is the only recovery)**

**SETTLED (owner):** Shock is a pain response, mostly narrative pressure; it **resets fully
at combat end**. Table practice: accumulates per organ; owner open to direct-status,
non-escalating form.

**FINALIZED (owner 2026-07-20, S2.2 — decision-log #21):** model Shock as **momentary
events, not an accumulating stat**:
- A shock source applies its **stated tier directly** (the book already says "works at the
  tier specified"); escalation is the exception, not the rule.
- The combatant stores only a **high-water mark** for the combat. A source that "elevates"
  applies `highest_this_combat + 1`.
- **Per-organ flavor without a per-organ ledger:** a shock source hitting a part that
  already produced shock this combat elevates +1 (repeated abuse of the same wound).
- **Escalation formula:** an independent stack takes `max(current + 1, source_tier)` — a
  strong source is never weakened by the target already being lightly shocked.
- Tier effects are **momentary events**: T1 Shout (noise/stealth break), T2 Stutter
  (current action fails), T3 Faint (Helpless 1 Clock, drop items), T4 Helpless/Exposed for
  the rest of combat.
- **Burn T1 also inflicts Shock T1** is KEPT (the cauterize cost — cauterizing stops
  Bleeding + removes Chill, so the Shock is the deliberate price that stops burn-cure
  dominance).
- Full reset at combat end. This dissolves the "how does Shock decay" gap (Q21) — it
  doesn't decay; it's not a pool.

## R14 — Damage quantization & the numbers rework (owner direction, 2026-07-15)

**RULED (owner): the whole numbers system gets a video-game rework pass.** Founding
principles, canon now:
- **1 damage = a hit that causes LASTING harm** — and it is the basic unit. An untrained,
  unarmed contestant with basic hitting ability deals 1.
- **0 damage is a real outcome.** A slap between equal-physique combatants may deal nothing:
  insufficient force = no lasting wound.
- Consequence: below the damage number sits a **force-vs-robustness gate** (to be designed:
  attack force from physique+weapon vs target robustness from physique/armor; force not
  exceeding robustness → 0 damage, possibly still conditions/shock). Design pass with the
  owner decides the exact function.
- **All currently seeded damage/HP numbers are placeholders pending this pass** (weapon
  values, part HP, resistances, enemy budgets). Supersedes/absorbs NQ5 (tutorial HP tuning)
  — the "hard to hurt without killing" problem gets solved by the rework, not a patch.
- **FINALIZED FUNCTION (owner 2026-07-20, S2.3 — decision-log #22):** the force-vs-robustness
  gate IS the damage — **`damage = max(0, Force − Robustness)`** (the gate and the number are
  one subtraction). **Force** = Physique contribution + weapon force rating (+ merged
  combined-action force, R15 — the party's answer to high robustness). **Robustness** =
  Physique-derived base + the struck part's armor/toughness (per-part). On a **blocked hit**
  (Force ≤ Robustness → 0 HP, no lasting wound): **Shock can still land** (the impact/pain),
  but damaging conditions (bleed/burn/poison) do NOT — there is no wound to seed them.
  Scope: implement the function + reseed ALL magnitudes (weapon force, part HP, robustness,
  enemy budgets) as coherent PLACEHOLDER values, tuned later by a mutation + playtest pass —
  not final numbers now. (Engine implementation PENDING — this records the design ruling.)

## R15 — Multi-character combined actions (owner direction, 2026-07-16)

**RULED (owner): characters acting on the same Moment can act TOGETHER** — combined
attacks, boosting an ally into a jump attack, buffing another, handing items across.
Digital shape (mechanism per below; verbs/numbers ⟨PROPOSED⟩ pending the skills passover):

- **Timing:** a combined action is a set of **linked declarations resolving on the same
  tick** — R2's simultaneity is the substrate; nothing new in the clock. All linked
  actors pay their own Moment costs.
- **Assists provide requirements** (the priming philosophy applied to teamwork): a
  partner's assist can satisfy an otherwise-unmet requirement — a brace supplies "steady
  ground," a boost supplies the height for a jump attack, a feint supplies the opening.
  Teamwork's primary power is *unlocking*, not just adding numbers.
- **Combined attacks merge force (RULED 2026-07-16):** merged damage counts as **one hit** for
  thresholds — the party's designed path to 7+ single-hit breaches, and (once the R14
  force-vs-robustness gate lands) the intended counter to robustness no single attacker
  can clear. The R14 design pass must treat force-combination as a first-class input.
- **Support verbs:** ally-targeted buffs/heals and item handoffs are legal combo
  members; handoffs ride the existing inventory-interaction economy (R3).
- **Failure cascades together (RULED 2026-07-16):** if a linked actor's requirement fails or a
  Forced Action fires on them, the combo resolves *degraded* — their contribution drops
  out, their d6 consequences land normally, the partners' parts still resolve.
  Coordination risk is drama, never a veto.
- **Spectacle:** combined actions earn a hype bonus (the crowd loves choreography) —
  PLACEHOLDER weight in the hype engine.
- Enemy pack-combos become possible by the same mechanism (Mob synergy) — not v1.

## R16 — Races: Earth-life only; background-granted skills (owner, 2026-07-16)

- **RULED: the Robot race is REMOVED entirely.** Playable contestants are any living
  thing on Earth — **Humans and Animals**. Seed data updated; the rulebook's Robot entry
  becomes TTRPG-only history.
- **RULED: the background grants the starting skills.** Humans: the background gives
  **4 skills**, and any of them may be given up for **+1 cap on another** (the trade
  rule survives, now background-sourced). **Animals work the same, with a higher bias
  toward race skills** in what the background offers.
- **RULED (same day): the system grants level/skill points automatically** — the
  TTRPG's admin role is automated in the video game; progression rules issue
  `grant_level`, no human in the loop.
- Consequence: the **background is now the single creation surface** — skills (this
  ruling) + starting traits (epithet track) + patron-god bidding all flow from who you
  were before the show. Creation flow: KAN-4 S4.1.
- **NPC stats fit the CHARACTER, not creation budgets (owner, 2026-07-16):** the 7/7
  creation spread and the 5-per-trait cap describe an *unchanged human at creation* —
  authored NPCs ignore both. Old Nikita may sit at 2s; War Nikita may run 10s or 20s if
  it fits. Profile over process.

## R18 — Charm semantics (owner clarification, 2026-07-16)

**Charm is NOT charisma.** It measures **how PRESENTABLE you are — objectively
aesthetic as compared to others.** The camera-facing stat: photogenics, striking looks,
visual impressiveness. Warmth, likability, and parasocial pull live in the AUDIENCE
systems (tags, hype, crowd reads), never in the Charm number. Existing formulas stay
coherent under this reading (Charm /20 → Camera Call stacks: the camera seeks the
aesthetic; speech scoring's Charm term: presentability shapes how words land).

## R17 — Run types & death (owner, 2026-07-16)

- **Death rules depend on the RUN TYPE.** Owner's stance: permadeath-favored, but a
  **softcore mode with normal respawn** exists so the bar to entry stays humane.
- Shape: **softcore** = respawn on death ⟨diegetic framing of the respawn TBD⟩;
  **hardcore** = permadeath (the owner-preferred way to play); **Forsaken** runs are
  hardcore by nature (the gods went all-in). Recruited NPCs remain permanently losable
  in every mode (canon).
- No difficulty menu (RULED same day): run types + patron choice + route selection ARE
  the difficulty surface.

## R19 — Skill level architecture (owner, 2026-07-17)

**RULED.** Skills run **0–10**:
- **0** = untrained (skill known but unusable).
- **1** = the effect works.
- **1–5** = **normal modifiers** — the basic stats scale (damage, range, etc.).
- **6–10** = each level **changes the basic function to apply to MORE SITUATIONS**,
  while the basic stats keep scaling.

**Owner's canonical example — Explosion:** 1–5 decide damage and range · 6 makes it
**cluster** · 7 adds **sub-damage of a chosen type** (poison/fire/…) · 8 lets it
**originate away from the caster** · 9 **enhances activation range and conditions** ·
10 unlocks **psychic/radiant-class damage** — each of 6–10 still increasing range and
damage. (Existing L5+ threshold rows get re-read under this architecture in the skills
passover; the generalization ladder 6–10 is the authoring template for every skill.)
**NOTE (owner 2026-07-18): "Explosion" is an ILLUSTRATIVE teaching example only — there is
NO Explosion skill. Fire Ball generalizes on its own terms; do not seed an Explosion skill.**

## R20 — Stealth, detection & cover (owner, 2026-07-18)

**RULED — the complete model.** Applies to BOTH combat and exploration. Parts may be phased
in implementation (§ "Phasing" below); the design is settled.

- **Vision (sight detection).** An entity sees out to roughly **2× its Mind stat** in range,
  through **vision cones** — eye positioning and field of view matter, so different creatures
  (and animal part-layouts, R21) have different cones. **If you are seen, you are not
  stealthed** (binary: within cone + in range + line-of-sight + Mind sufficient → revealed).
- **Hearing.** If an entity **hears** you it may, per its personality/AI, **investigate,
  ignore, or otherwise react**. Two escalation paths: (a) reacting to the sound **turns/moves
  it so you enter its vision cone → you are unstealthed**; (b) an entity **smart enough**
  (an AI/Mind threshold we set per creature) becomes **ALERTED** — it does **not** know where
  you are, only that *something* is there. Alerted-but-unlocated is a deliberate design space:
  it enables **scapegoating** (make something else look like the intruder), **illusions**,
  decoys, and misdirection plays.
- **Disguise.** You can disguise yourself: an entity **outside a specified range does NOT
  recognize you as an intruder even if it has the Mind to see you** — it only sees through the
  disguise within that close range. (Disguise range is a property of the disguise, PLACEHOLDER
  R14.)
- **Cover — a real geometric system.** Covers have **real heights and sizes**; gaps/holes in
  walls have **real dimensions**. This is load-bearing: **some skills pass through or exploit
  specific gap sizes and do different things by size** (a mouse-hole vs a crawlspace vs a
  window are mechanically different). Cover blocks line-of-sight/vision-cone per its geometry.
- **Hype interaction — stealth does NOT auto-suppress hype.** Sneaking past every guard
  impeccably is spectacle; stalking prey as a hunter is spectacle. **What you DO with stealth
  determines the hype**, not the hiding itself. **Production NEVER interferes directly in the
  show** (correction to an earlier proposal). The diegetic destealth lever is **rival gods**:
  a rival patron can **curse you unstealthy / out you** as a divine intervention.

**Phasing (implementation, not design — defer freely):** v1 can ship the binary
sight/hearing model on the existing hex positions with a simple facing/cone; **full cover
geometry (heights, sized gaps, skill-by-gap-size interactions) and true vision-cone
facing are KAN-5-era** (they need positional facing + sized terrain the sim doesn't model
yet). The Camouflage skill (data id 44: "hides you; revealed within 6 spaces or on move")
is the seed of the sight rule; Shock-T1 Shout ("breaks stealth") is the noise seed. This
ruling supersedes the review-1 B10 gap ("stealth referenced, no rules"). Q58 CLOSED.

## R21 — Body structure: Lego-style part composition (owner, 2026-07-18)

**RULED — the structural model.** A character **type** (human, animal, hybrid) is a
**structure composed of typed parts** — like Lego. Parts are drawn from a single library:
the base set (**torso, arms, legs, head**, …) **plus** any part from the animal-parts
library (`docs/design/animal-parts-library.md`, the R21 source catalog: tails, pincers,
pouches, wings, horns, beaks, shells, stingers, gills, compound eyes, …). Each part carries
a **range of size**. A layout is just "which parts, how many, what size" (e.g. crab =
carapace-torso + 8 legs + 2 pincers; snake = head + long segmented torso, no limbs).

- **Deferred customization** (owner: "later if we REALLY want to"): fur/hair color, per-part
  size sliders beyond the range, cosmetic variants. **None of it matters for the demo** (the
  demo runs the two human loadouts).
- **Engine reconciliation items** (from the parts research, for the implementation pass, not
  now): (1) manipulation parts need a **`can_manipulate` flag** — the sim currently detects
  "hands" by an `arm`/`hand` substring in the part key; (2) every layout must include a
  **torso-equivalent + head-equivalent** so torso/head-routed conditions have a landing part.
- All part HP / lethal / size numbers are **PLACEHOLDER (R14)** until the numbers pass.

**Character-creation UX (deferred design — KAN-4 creation / KAN-6 UI, NOT the demo):** a flat
list of "human + a billion animals + every part" is too heavy for a user. Direction: let the
player **choose by PROPERTIES and filter first** (e.g. "aquatic", "flying", "has a grab
limb", "small"), then pick a body/parts from the filtered set. Design later; recorded so it
isn't lost.

## Rulings batch 2026-07-17 (owner, in chat)

- **Friendly fire: ON** (Q69) — spectacle wins.
- **R13 approved as written; no in-combat shock decay** (Q21).
- **Healing economy (Q29):** applying a healing item costs **a Moment**; **no healing
  item regenerates HP** — items treat/delay conditions only; HP recovery is deliberately
  scarce (recovery sources TBD — Lounge/rest candidates).
- **Encounter baseline (Q47):** live table's party of 5 cleared 12 enemies/room without
  trouble → assume a **party of 3 handles ~12/room** as the tuning starting point.
- **Slice + premades approved** (Q68): player OC + Sasha & Nikita recruitment
  encounters, party of 3.
- **Joke skills cut** (ignore_all_previous_commands, generate_visual_media — robot
  orphans; kunai's dev-chat stays as intentional comedy).
- **Tags:** renames/cuts/migrations applied per owner list (84 live tags; 5 words moved
  to the epithet track; K-pop cluster removed). **Effect model = the 5 audit patterns
  PLUS pattern 6: tags GATE unlocks — items, actions, and skills may require tags as
  obtain/use conditions.**
- **Animal part layouts deferred** (Q61) — dedicated sitting later.
- **Q72 — THE PROVISIONAL BUNDLE IS APPROVED (owner, 2026-07-17)** with three
  amendments now recorded in place: R0 tick ≈ 0.5s in-game · R5 mind-collapse =
  permanent loss + puppet of the collapser · R6 XP approved in principle. All other
  PROVISIONAL markers (R2 miss model, R3 cap numbers, R4 Burn-Shock, R8 RPM defaults,
  R9 grapple gates, R10 requirements-halving, R11 items 1–12) are **RULED as written,
  pending playtest tuning only**.
- **Respec (Q6, RULED):** no free refund or respec, ever — available **only via certain
  items or Lounge upgrades, and always at a cost.**
- **Declare window (Q71, RULED):** co-op default **5 seconds**, accelerate-on-all-
  committed; revisit on first co-op playtest feel.

## KAN-2 acceptance criteria (what the engine tests must prove)

Each line is a test target; ruling in brackets.

1. Absolute ticks map to Moments 10→1 and Clock resets fire after Moment 1 [R0/R1].
2. A 2-cost action declared at Moment 1 resolves at Moment 9 of the next Clock [R1].
3. Two lethal same-tick attacks kill both combatants (snapshot semantics) [R2].
4. A combatant that moves out of a windup's range before its resolution tick is unharmed;
   an instant attack cannot be dodged by later movement [R2].
5. Reaction resolves immediately and delays the reactor's next scheduled action by its
   cost; a second reaction in the same tick is rejected [R2].
6. Second 0-cost action in one tick is rejected (free-slot consumed) [R3].
7. Move of 3 spaces = free once per tick; second move same tick rejected; 7-space move
   costs 1 Moment [R3].
8. First inventory interaction free, second costs 1 Moment, no reset exploit [R3].
9. ~~Cooldown "1 Clock" = exactly 10 ticks~~ SUPERSEDED by the no-cooldowns ruling (R3):
   replace with — a prime-gated skill is rejected without its prime; a prep action grants
   the prime; use consumes it. (Test lands with the priming implementation pass.)
10. Damage = listed − flat resistance, floor 0; applies condition T1; re-application same
    tick does not double-advance; next-tick re-application advances to T2 [R4].
11. At Clock reset every active condition advances one tier; a Delayed condition skips
    exactly one advancement [R4].
12. Burn T1 stops Bleeding, removes Chill, applies Shock T1, deals its HP damage [R4].
13. Infected T2 makes other conditions advance twice per Clock reset [R4].
14. Torso to 0 by Bleeding ⇒ 1-Clock bleed-out (Helpless), delay of Bleeding stabilizes;
    torso to 0 by weapon damage ⇒ immediate death; Exhausted never kills [R5].
15. Head targeting rejected unless target Exposed/Helpless/Overwhelmed [book, kept].
16. Level point → +1 levelBonus; over-10 formulas produce app-identical derived stats for
    the five live characters' sheets (fixture test against real campaign data) [R6].
17. Grapple: Physique-gated initiate; 2-Moment escape; Suffocation-by-grapple rejected vs
    a boss [R9].
18. RPM 3 weapon fires 3 rounds in one 1-Moment action, magazine decrements, empty ⇒
    reload required (2 Moments, 2 hands) [R8].
19. Determinism: identical (seed, command log) ⇒ identical state hash after 100 mixed
    commands; snapshot → restore → replay tail ⇒ same hash [DIRECTION contract].
20. Forced Action: unmet requirements halve effect and roll the correct d6 table; "always
    allowed" preserved [R10/book].
21. Combined action: two linked same-tick attacks merge into a single hit for breach
    checks (7+); an assist satisfies a partner's requirement; a Forced Action on one
    partner degrades but does not cancel the others' contributions [R15 — IMPLEMENTED
    (S2.5): `combined_action` command + single-hit breach (NQ2); test_21_combined_action].

---

*Owner morning checklist: the PROVISIONAL rulings worth your eyes first — R2 miss/dodge
model, R3 cap numbers, R4 Burn-T1-costs-Shock, R6 level pacing (engine-ready either way),
R8 RPM numbers, R9 grapple gates, R10 requirements-halving + token-exchange cut.*
