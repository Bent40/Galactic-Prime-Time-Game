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
  (spend a prep action to arm a one-shot prime). ~~The two literal cooldown-texted defensive
  reactions (Tactical Roll, Acrobatic Save) are **STANCE-gated** — usable only while holding
  a light-footed/defensive stance (no timers).~~ **SUPERSEDED by G1 (owner, 2026-07-23,
  skills-passover RULINGS; see R25): no stance, no charges, no cooldown — both skills'
  cost is the MOVEMENT FORFEIT** ("you give up your movement for the Moment"). The prime
  vocabulary itself is unchanged; these two simply no longer carry a prime. Implementation
  this pass: build the 5 prime predicates into the requirements gate, DELETE the dormant
  cooldown code, convert the explicitly cooldown-texted skills (Tactical Roll, Acrobatic
  Save, the "-4 Moment cooldown" threshold → CHAIN discount — the first two now resolved
  by R25's movement forfeit instead); per-skill prime tags for the other ~37 ride the R19
  ladder finalization. (Tactical Roll's engine implementation landed with R25; Acrobatic
  Save stays unimplemented content.)

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
    who CAUSED the spotlit combatant's drama is v2. **SUPERSEDED IN TABLETOP CANON
    (v2 D-10/Q-32, 2026-08-11): Camera Call is a declared double-or-nothing BET on an
    uncertain action — failure burns named Followers. The engine swap needs the v2
    named-Follower ledger (KAN-7; three-way guard items T-4/U-4) and is PARKED; the sim
    keeps the v1 doubling model until that ledger exists.** The spotlight ends at the end
    of the
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
      fire counts — "it's cinema"); the payout is credited to that killer. **IMPLEMENTED
      (attribution v2, 2026-07-25, task #13):** `combatant_died` carries the killer;
      wound sources are serialized so condition deaths attribute to the wound's author
      (latest named attacker wins); the hype takedown gate is team-aware (enemy deaths
      complete unconditionally, friendly deaths only on a contestant killing blow) and
      the payout credits the killer's ledger row. Flagged interpretation calls: merged
      kill single-credits the last connected member; self-kill counts per the literal
      text; per-event BASE hype points remain v1 victim-credited (the recorded
      boundary). Enemy deaths still complete it. Tests: test_takedown_attribution.gd.
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
    neighbor order, occupied hexes skipped, only strictly-improving steps;
    wave 4a upgrades this walk to real A* pathfinding when an arena has
    walls — no-arena movement stays this exact greedy rule, see R28),
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
    `sequence`/`effect`-only abilities are skipped by the STRIKE lookup
    (~~death_spin, drag_back deferred~~ — death_spin now has its own decide
    path, wave 2b #19; drag_back stays deferred); ~~"cone N"/"line" resolve as
    plain reach (true area geometry is KAN-5 scope)~~ **RETIRED (decision #31, 2026-08-10): cone/line are REAL
    shapes now** — `simulation/hex_geometry.gd` supplies the axial primitives
    (`line`/`line_extended`/`cone`/`blast`; deterministic tie rules and the
    120°-wedge cone model documented + ASCII-diagrammed in its header). The
    flamethrower sweeps the arc whose fixed-order aim direction catches the
    most opponents (a cone "reaches" an opponent iff the best arc contains
    it); the windup re-check re-evaluates the ARC per target (leaving it
    dodges the sweep for that target; an emptied sweep collapses). The dash is
    an honest CHARGE along its committed `line_extended` lane: the AI dashes
    only at a lane-reachable pick, the boss runs the lane to the hex
    adjacent-before the target (bodies stop the charge BEFORE the first
    occupied hex — stopped out of reach is an honest miss, not a collapse; an
    interloper shields the declared target), leaving the lane mid-windup
    dodges it, and the R22 sidestep now displaces the dodger OFF the lane
    specifically (first free fixed-order neighbor not on it). The explosion
    beat's radius rides the shared `blast` primitive, membership unchanged.
    Geometry stays unbounded — `arena_hexes` is authored data the engine does
    not read; bounds arrive with the KAN-5 arenas. Targets with no attackable
    part are skipped.
17. **Dodge Threshold — SUPERSEDED by R22 (owner 2026-07-23): thresholds now ask
    Reflexes with a 1d4 fallback; the flat d6 below is the retired v1 model.**
    (Original text kept for the record.) A combatant with
    `boss_traits.dodge_threshold` (1..6) rolls the
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
    abilities` list. ~~Explosion choreography (telegraph, escape window, KO) and
    phases 3–6 are deferred — past phase 1 the boss idles (`ai_decision` wait,
    `phase_not_implemented`)~~ **SUPERSEDED (owner 2026-07-23, decision #27):
    explosion beats are REAL — telegraph → escape window → blast (caught =
    Helpless 2 Clocks) → retreat → the machine advances into the next Threshold
    and the boss keeps fighting. Phase-6 death explosion stays data-only (the
    fight ends at network 0).** The phase-2 beat is the slice's win moment
    (review-4 §5, DIRECTION Stage 1). **Wave 2d (2026-08-10): the authored
    per-phase `behavior.upgrades` lists activate REAL effects as the machine
    advances — see #20 for the string→effect mapping; upgrades accumulate
    (union of every entered phase's list) and derive from `current_phase`, so
    the phase number stays the only serialized upgrade state. The retreat is
    now phase-2-only BY CANON, not by data coincidence: "network fully
    exposed" (phase 4+) suppresses any later valve's re-hide.**
19. **Death Spin is REAL; dash knock-aside is REAL (wave 2b, decision #31,
    2026-08-10 — retires the #16 "sequence abilities skipped" deferral for
    death_spin).** The authored 3-beat sequence runs as a real state machine
    (serialized like the explosion beats: `ai.death_spins`, hash-covered).
    **Pacing (documented ruling):** grab cost 1 → chew cost 1 → spin cost 1 —
    the authored `moment_cost 3` spans the WHOLE sequence, one Moment per
    beat; each beat is a real cost-1 resolver declare (feints, shock stutter,
    Forced Actions all apply; a denied beat is RETRIED, never skipped).
    **Decide order (documented ruling):** valve > stand > active-sequence
    continuation > cone > GRAB > dash > close — the grab is the boss's punish
    on a target that stays ADJACENT (authored grab range 1; no step-then-grab)
    while it is free to act; scarier than the dash, so it outranks it; the
    victim pick is the R23 draw over the ADJACENT candidates only.
    **Grab hand (data-honest ruling):** the flamethrower is authored on the
    LEFT hand, so the grab uses the first usable NON-flamethrower hand
    (right_hand); no usable non-flamethrower hand = no grab (AI never decides
    it; a hand-built command rejects `grab_hand_disabled`). The grab initiates
    a REAL R9 grapple (adjacent instant — the dodge model does not apply, R2).
    **Beat 2 CHEW:** 2 crushed to every arm part through the normal R14 gate,
    conditions per the normal path. **Beat 3 SPIN-KILL:** still honest R14 —
    a crushed hit of amount 8 (PLACEHOLDER R14; Force 8+3=11 fells a fresh
    5-HP torso through the gate, and an armored monster can genuinely survive
    it), then the victim is FLUNG down the spin lane (the HexGeometry ray from
    the boss through the victim, 3 hexes or until a body, prone on landing if
    it survives; the kill attributes to the boss through the normal
    `combatant_died.killer` path). **Counterplay chain (the design):** 2 full
    Moments of warning (grab → chew) in which ANY single recorded hit netting
    ≥ 5 on the boss (the R15/NQ2 single-hit seam — a merged combined hit
    counts as ONE) forces the release, or the victim escapes via R9 (1 Moment
    needs Physique ≥ 6, else 2 Moments — too slow past the chew, intended
    texture); grappling also EXPOSES the boss (R9), so its own dodge is off
    mid-sequence. Valve entry aborts the spin honestly (the valve outranks,
    #27 precedent), as do boss prone/helpless and victim death; a mid-batch
    release makes a same-tick chew/spin close on air (live grip re-check,
    the `grapple_suffocate` "grip_lost" family). ~~The "death spin grab range
    +1" / "death spin costs 2 moments" phase upgrades stay DATA-ONLY (wave
    2d).~~ **SUPERSEDED (wave 2d, 2026-08-10): both are REAL — grab range 2
    with a 1-hex drag from phase 3, the merged 2-Moment sequence at phase 5;
    see #20.** **Dash knock-aside:** the authored `"effect": "knock aside"` is
    real — a target the charge CONNECTS with (not dodged, not stopped-short;
    a robustness-blocked 0-net hit still connected) is displaced to the first
    free fixed-order neighbor OFF the committed lane (the involuntary sibling
    of the R22 sidestep) and knocked PRONE; no free off-lane neighbor = prone
    only (`knocked_aside`). The wave-2a charge rule is unchanged: the boss
    stops adjacent-before the target's SNAPSHOT hex, so after the shove it
    may stand adjacent to a now-empty hex (documented interaction).
    Tests: tests/test_death_spin.gd.
20. **The Incine-Dile phase upgrades are REAL (wave 2d, 2026-08-10 — the last
    wave-2 story; retires #19's data-only note).** The authored per-phase
    `behavior.upgrades` STRINGS in data/enemies.json are the SOURCE OF TRUTH;
    `EnemyAI.UPGRADE_EFFECTS` parses them into effect keys (an unmapped string
    is a data-only no-op — visible in data, never executed). Upgrades
    ACCUMULATE: active set = union over every phase entry with
    `phase_number <= current_phase`; everything derives from the serialized
    phase number — no new state. The mapping:
    | authored string (phase) | effect | model |
    |---|---|---|
    | "death spin grab range +1" (3) | `grab_range_plus_1` | grab reach 2; a range-2 grab DRAGS the victim adjacent first — a 1-hex pull to the boss-adjacent hex of the boss→victim line (fixed line tie rule); a living body on the pull hex blocks it and the grab fails honestly (`pull_blocked` — the AI never decides one, a hand-built command rejects/invalidates). The drag rides the `death_spin_grab` event (`dragged`/`dragged_from`/`dragged_to`). Plain R9 grapples stay range 1. |
    | "dash bounces between walls up to 2 bounces" (3) | `dash_wall_bounce` | ~~DATA-ONLY~~ **REAL since wave 3d (KAN-5 arenas)** — ARENA-GATED: with an arena set, a dash lane that hits a wall/bounds REFLECTS (up to 2 bounces; the edge-mirror model + all lane rules in **R28**); without an arena there are no walls and no bounces — the inert pin flipped to assert exactly that continuation. |
    | "flamethrower pops trash cans instantly" (3) | `cans_pop_instantly` | ~~DATA-ONLY~~ **REAL since wave 3d (KAN-5 arenas)** — ARENA-GATED: a burn cone's arc accumulates its burn on swept trash cans (5 explodes: 3 spaces, 2 Burn, environment attribution); with this upgrade the FIRST touch pops the can (no accumulation). Full model in **R28**; no arena = no cans = the old behavior. |
    | "network fully exposed" (4) | `network_stays_exposed` | from the phase-4 valve on the network NEVER re-hides. For the seeded boss this was already emergent (`breach_resets_after_phase: 2` gates the retreat to Valve I); the upgrade guard makes the string canon — a later valve's retreat is suppressed outright. Pinned by a full valve-II drive test. |
    | "dash can change direction mid-run" (4) | `dash_bend` | the charge lane may bend ONCE: two chained `line_extended` segments, total length ≤ the dash's range; the declare's `area_shape` carries the composite lane + the bend hex (phase-gated at the command surface — `bend_not_available` below phase 4). AI bend pick is deterministic and rng-free: tried only when no straight lane exists; candidates by segment-1 length ascending, then blast's (q, r) order; first legal composite (no self-intersection, intermediate hexes unoccupied) wins. ALL wave-2a/2b lane rules apply to the BENT lane (occupation stop on either segment, `left_lane` windup dodge, knock-aside off the FULL lane); the R22 sidestep steps off whichever SEGMENT the dodger stood on (the bend hex belongs to both; segment-2 checks first). `dash_charged` carries the bend. |
    | "flamethrower tracks closest target" (5) | `cone_track_closest` | the cone's `toward` selection AIMS at the NEAREST opponent (min hex distance, ties keep the earlier sorted-id candidate) instead of maximize-targets — the authored text says TRACKS, i.e. it hunts YOU. Among the arcs containing the quarry, most swept targets wins (ties keep the earlier fixed-order direction). ONLY the aim shifts: shape, size and the ≥ 2-target decide gate are unchanged — a lone quarry is not a crowd, so the boss falls through to the (upgraded-reach) grab instead. The chosen aim rides the `ai_decision` event (`aim`). PROVISIONAL. |
    | "death spin costs 2 moments" (5) | `spin_two_moments` | ruled reading of the authored line (PROVISIONAL): the sequence ACCELERATES — chew and spin MERGE into one beat, so the kill is grab (1 Moment) → chew+spin (1 Moment), total 2. The merged declare is the spin action carrying the chew's arm rounds as riders; chew fires first, then the kill, same R14 gates as the 3-beat run. The counterplay window shrinks by exactly one Moment — release-on-5 / R9 escape must land in the single Moment between grab and merged beat (a same-tick release still makes the jaws close on air; nothing lands). The grab's own cost never changes. |
    Every effect activates exactly AT its authored phase and is OFF below it;
    serialization round-trips mid-phase-5 sequence with no new state.
    Tests: tests/test_phase_upgrades.gd (+ the flipped pin in
    tests/test_death_spin.gd; the wave-3d arena-gated mechanics in
    tests/test_arena.gd).
21. **The war-hound maze funnel is REAL (KAN-5 wave 4d, 2026-08-11 —
    `corner_the_prey` flips from the wave-3c DATA-ONLY note to the shipped
    §4.6 signature: the pack corners the quarry and cuts off its escape).**
    Personality-gated — `herder: true` + the shared `pack` family on the
    war_hound personality is THE engine-read gate (data-driven, no species
    check; the corner_the_prey ability entry stays the authored FLAVOR
    RECORD, still skipped by the strike lookup like drag_back, #16) — and
    layered ON TOP of the unchanged strike-or-close flow: only a decide that
    could NOT strike its quarry this Moment (the plain-move / no-step exits)
    may be rewritten, so **a herder never skips a kill it can make** —
    herding is positioning, never pacifism. **The contract (v1, all
    deterministic, ZERO new rng — the actor's own R23 draw picks the quarry,
    one draw as ever):** among the living able-to-act herders of the actor's
    team+family, the CLOSEST to the quarry chases (hex distance; ties keep
    the earliest sorted id); every OTHER herder repositions onto the
    quarry's nearest ESCAPE — **the v1 escape rule: the OPEN door nearest
    the quarry** (ties keep the earliest authored door); no arena / no open
    door / no legal step → fall back to the normal chase (widest-gap
    inference is future work). The cut-off routes via `Pathing.next_steps`
    (stop_range 0 — standing ON the open door denies it); a herder already
    ON the hex HOLDS its post (`wait`, reason `holding_cutoff`, stance
    "hunting" via the second documented stance exception) until the quarry
    comes into reach. **R20 honesty: a herder herds only prey it can SEE**
    (`Stealth.sees` — the war hound's Mind 1 = sight 2, so the funnel is
    close-quarters: blocked corridors, bodies in the way; a stealthed quarry
    never reaches herding at all). A decided cut-off move emits
    `pack_herding {herder, quarry, cutoff_hex}` once the step really
    resolves (the pack_synergy honesty pattern). **No new serialized
    state** — roles and cut-off hexes re-derive from sorted state every
    decide; the AI dict keeps its exact wave-3a key set. The kennel arena
    authors the funnel's stage (the kennel-run fence + open gate,
    PROVISIONAL — R29). Tests: tests/test_herding.gd (+ the flipped
    data-contract pin in tests/test_second_enemy.gd).

Not yet implemented (scoped to later epics, hooks in place): poison spread topology,
dissolution cause-tracking, Camera Call's Viewership/Follower/Patron counters (hype meter
stands in — KAN-7), token economy, Lounge/session mechanics. Enemy AI v1 (R11 #15–#18)
ships the mob/elite policies, the dodge-threshold ability and Incinedile Phase 1 + the
phase-2 transition beat; still open there: drag_back (forced movement) only —
pack synergy (R15 enemy combos) and the AI stances for `aura_reading` moved to REAL per
wave 3a (2026-08-11): personality-gated (`pack_hunter` + a shared `pack` family, authored
on the roach mob) opportunistic pair-linking through the EXISTING R15 merged-force path
(each pack hunter's own R23 draw picks; draws agreeing on the victim link the second
strike to the first's pending declare — zero extra rng, pairs only, `pack_synergy` event),
and every AI combatant now carries a serialized, hash-covered `ai_stance` written at
decide time (aggressive / hunting / defensive / building — table in
`simulation/enemy_ai.gd`'s header), exposed additively on `view_combatants` (AI rows).
The `aura_reading` SKILL itself remains unimplemented — it rides the content pass; the
stance substrate is the readable layer the audit said it needs.
Explosion choreography and the Dash Reflexes-counters moved to REAL per
R22/R23 + decision #27 (2026-07-23); true cone/line geometry moved to REAL per
decision #31 (2026-08-10, `simulation/hex_geometry.gd` — see the #16 retirement note);
death_spin + the dash knock-aside moved to REAL per
wave 2b (2026-08-10, #19); the phase upgrades moved to REAL per wave 2d (2026-08-10,
#20); wall bounces + trash cans — the last two — moved to REAL per wave 3d
(2026-08-11, KAN-5 arenas: OPT-IN bounds/walls/objects, R28 — no arena = the
unbounded legacy combat, byte-identical; rooms/dungeon FLOW shipped wave 4b
(R29) and stealth/detection R20 shipped its v1 binary-sight slice wave 4c —
see the R20 IMPLEMENTED marker for what remains downscoped); the war-hound
maze funnel (`corner_the_prey` herding) moved to REAL per wave 4d
(2026-08-11, #21 — the KAN-5 capstone).

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
- Enemy pack-combos become possible by the same mechanism (Mob synergy) — SHIPPED for
  pairs per wave 3a (2026-08-11): see the R11 tail — personality-gated opportunistic
  linking through this section's merged-force path, untouched.

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

**Charm is NOT charisma.** It measures **PRESENCE — how compelling you are to look at
and to listen to**, as compared to others: striking looks, bearing, voice, facial
control, body language. Presentation used as an instrument. Warmth, likability, and
parasocial pull live in the AUDIENCE systems (tags, hype, crowd reads), never in the
Charm number. Existing formulas stay coherent under this reading (Charm /20 → Camera
Call stacks: the camera seeks the aesthetic; speech scoring's Charm term: presence
shapes how words land).

**↳ WIDENED 2026-08-10 (owner, D-25).** The original wording — *"objectively aesthetic",
"photogenics, striking looks, visual impressiveness"* — was **too narrow**, and it put
this ruling in direct contradiction with book §2.3, which keys **Command**, **Persuade**
and **Intimidate** to Charm. Under a purely visual reading those mappings are
incoherent (*you talk people around by being photogenic*). The owner's clarification:
Charm covers **voice, facial expression and body-language control** as well as looks —
*"it's just not some cosmic attraction."*

**Therefore the errata is to the DEFINITION, not the action table.** §2.3's mappings are
correct as written and **do not change** — so **no skill-point refunds are owed**
(`audits/skills-audit.md:98` would have applied only if a stat had moved). Book §2.1 has
been updated to match and now states the §2.3 link inline, so the contradiction cannot
silently return. This is a **shared-spine fix — it holds for v1 and v2 alike.**

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

**IMPLEMENTED — the v1 binary sight/hearing slice (KAN-5 wave 4c, 2026-08-11), exactly
the phase-in the paragraph above authorizes.** `simulation/stealth.gd` (pure sight
queries) + the sim's `stealth` command (`{"actor", "set": "hide"|"reveal"}`; hide costs
the R3 FREE-ACTION SLOT — the door/bit family; this section prices nothing, so the slot
is a documented v1 choice — reveal is free). **STRICTLY OPT-IN, default = everyone
detected:** the `stealthed` key serializes (combatant dict + tick snapshot) ONLY while
true, so a stealth-free fight's dict/hash is **byte-identical** to the pre-stealth
engine (pinned against recorded e6c7c37 hashes in `tests/test_stealth.gd`; both CI
harnesses byte-diff clean). Every check is deterministic and **rng-free** — this section
authors no detection roll, so no stream is ever touched.

- **SHIPPED — sight:** seen iff a hostile observer (alive, in play, not helpless — a
  fainted guard keeps no watch; allies are exempt: you hide WITH your party FROM the
  enemy) has the target within **exactly 2 × Mind** ("roughly 2×" resolved to exactly —
  PROVISIONAL number, R14 family) **and** line-of-sight: the hex line with walls +
  **CLOSED doors** + out-of-bounds blocking — the one R29 query LOS was promised to
  read; an OPEN door blocks nothing. "Mind sufficient" IS the range: Mind 0 sees
  nothing, even adjacent (the roach_dog). Entry requires being UNSEEN (rejected
  `in_enemy_sight`, observer named) and un-grappled (`in_grapple` — physical contact is
  detection). Detection re-checks after **every command** (either side moving, a door
  opening, an observer recovering — the `_stealth_checks` sweep in `_post`); breaks emit
  `stealth_broken` with reason `seen` (+observer) / `shout` / `downed` /
  `revealed_self`.
- **SHIPPED — the noise seed:** Shock-T1 Shout **breaks the shouter's stealth**
  (R13 wire via `shock_shout`, range-free — a shout is heard). Damage ALONE never
  breaks stealth (not a ruled break) — but a hit whose condition shocks (burn T1) shouts
  the hider out through this path.
- **SHIPPED — AI honesty:** a stealthed target is **excluded from `_opponents`**
  (targeting, cone counting, the R23 draw — zero rng consumed on the shrunken pool);
  with every opponent hidden the mob **waits (`no_targets`) — it honestly loses the
  target**. Hostile player-surface asks mirror it: declares (attack/skill/grapple) and
  damaging reactions at a stealthed hostile reject `target_stealthed`; an aimed hostile
  **windup collapses** if its target hides mid-windup (R2 snapshot re-check). Attacking
  FROM stealth neither breaks it (sight/noise are the only ruled breaks — sight usually
  reveals a melee attacker anyway: adjacent + Mind ≥ 1) **nor grants any bonus** (this
  section authors no first-strike rule; none invented).
- **SHIPPED — physicality over information (documented v1 line):** committed AREA
  geometry — cone arcs, charge lanes, blasts — hits **bodies by hex**, stealthed or
  not; stealth gates targeted INFORMATION, it never phases the body out.
- **SHIPPED — views (additive):** `view_combatants().stealthed` (the broadcast stays
  omniscient — cameras see everything, per the hype bullet above); preview rows carry
  `target_stealthed` when the ask would reject. Stealth resets between encounters
  (RunState carry) and never touches hype (nothing scored, nothing suppressed).
- **DOWNSCOPED — flagged loudly, not silently dropped** (each needs a system that does
  not exist yet):
  * **vision cones/facing** — no positional facing exists (this section's own phasing
    defers true cones); v1 sight is 360°;
  * **hearing beyond the Shout** — no noise-propagation substrate: the
    investigate/ignore personality reactions, the per-creature smart threshold, and the
    **ALERTED-but-unlocated** state (the scapegoating/illusion/decoy design space) all
    wait on it;
  * **disguise** — no disguise items/skills exist to carry the range property
    (PLACEHOLDER R14 regardless);
  * **cover heights / sized gaps / skill-by-gap-size** — sized terrain unmodeled (own
    phasing defers); v1 cover = full-height wall/closed-door LOS blocking only, and
    environment OBJECTS (trash cans) deliberately do NOT block sight (no height model
    to say they should);
  * **the rival-god curse-unstealthy lever** — divine interventions are KAN-7;
  * **the Camouflage skill itself** — rides the content pass (the `stealth` command is
    its substrate); enemy AI never DECIDES to stealth in v1 (no policy path — the
    command works for any combatant, like doors).

Tests: `tests/test_stealth.gd` (entry/exit/slot, the exact 2×Mind boundary both sides,
Mind-0 blindness, ally exemption, wall/door LOS both states with the mid-fight door
reveal, the Shout wire + the quiet-damage negative, AI exclusion/honest loss/
re-acquisition with rng pins, every hostile-surface gate, windup collapse vs. instant
no-re-check, cone-burns-the-hidden-body, serialization round-trip mid-stealth,
lockstep, determinism, zero-rng discipline, carry reset, and the legacy hash pins).

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

## R22 — Dodge thresholds ask Reflexes; the 1d4 fallback; upgradeable threshold dice (owner, 2026-07-23)

Unified dodge model — SUPERSEDES the flat-d6 dodge of R11 #17 and the d6 line of the
Dash `reflexes_counters` data. One check, both directions (contestant dodging a boss
ability; boss dodging an aimed round):

- **The threshold asks the dodger's Reflexes.** Reflexes ≥ threshold → **auto-dodge**
  (no roll, no rng consumed).
- **If Reflexes can't fulfil it, it adds the stat's threshold die** — default **1d4**:
  Reflexes + die ≥ threshold dodges. The roll comes from the salted AI stream and is
  always emitted (`attack_dodged` / `dodge_failed` carry roll, die size, threshold) —
  no unlogged randomness. Reflexes + die max < threshold → the dodge is impossible
  (emit the attempt as impossible or skip; either way the schedule/preview must say so).
- **Threshold dice are upgradeable through the game, PER STAT** (owner-proposed;
  adopted): each stat carries a threshold die size (default 4), serialized on the
  combatant, raised by progression (d4 → d6 → d8; costs live in the R6/KAN-7 economy —
  UNPRICED for now). Reflexes' die is the only one consumed today; the field is
  per-stat so future stat-threshold checks (Mind vs fear, Physique vs forced movement)
  inherit the mechanism.
- **Eligibility unchanged from R11 #17:** no dodge while Helpless or Exposed; prone
  now also blocks dodging (the slam punish window, fix-4). Collateral, condition,
  forced-action and environment damage are never dodged.
- **Dash counters ladder (the authored `reflexes_counters`, now REAL):** threshold 7.
  Reflexes ≥ 7 auto-dodge **+ 1-hex sidestep** (deterministic: first free hex off the
  charge line); Reflexes ≥ 9 auto-dodge **+ counterattack** (one free basic strike at
  the dasher); below 7 → the 1d4 fallback (sidestep rides any successful dodge).
- **Incinedile's own `dodge_threshold` retunes 4 → 7 (PROVISIONAL):** Reflexes 4 + 1d4
  ≥ 7 succeeds on 3–4 = the same ~50% the old d6-vs-4 gave. Flagged for owner sign-off
  with the rest of the R14 numbers.
- Surfaced consequence: Reflexes 2 + d4 maxes at 6 < 7 — Imani **cannot** dodge the
  Dash until a die or stat upgrade; positioning and Brace are her counterplay. This is
  intended texture, recorded so it never reads as a bug.
- **Tactical Roll is a DIFFERENT, positional dodge (R25)** — a roll is movement, so
  where an ability authors an R22 threshold, that check still applies independently: a
  roller whose destination is still inside the attack's pattern at resolution gets hit
  through the pattern re-check AND still rolls its authored R22 dodge there, exactly as
  any repositioned combatant would.

## R23 — The Antagonism engine (owner, 2026-07-23)

Mob/boss targeting is a **weighted-random draw, not a rule cascade** — SUPERSEDES the
nearest → lowest-HP → id priority of R11 #16 (elites keep their weak-target taste as a
personality bias, below).

- **Score:** each AI actor keeps `antagonism[target_id]` — a serialized, hash-covered
  float per living opponent. Base weight comes from **proximity** (closer = much
  likelier); the score multiplies it.
- **Earning attention:** damage you deal it builds grudge (scaled by net damage);
  **mockery builds grudge only if the mob is intelligent enough to get it**
  (personality-gated — Feint and other taunt-shaped acts count); **sparing it lowers
  attention** (personality-gated; requires a detectable mercy event — hook RESERVED,
  no mechanic ships until one exists).
- **The 50/50 anchor (canon):** two equally close targets with no history draw at
  exactly even odds. The selection consumes ONE draw from the salted `ai_rng` per
  targeting decision — deterministic, serialized, replay-identical (this widens
  `ai_rng` beyond dodge; the R11 #15 "decide() is rng-free" line is amended to
  "decide() consumes rng ONLY for the antagonism draw").
- **Personality types per enemy template** (data-driven, the tuning surface):
  proximity bias, grudge weight, mock sensitivity (Mind-derived default), low-HP
  preference (the elite "picks off the weak" persona, now a bias not a rule), decay.
  Incinedile: Mind 1 — immune to mockery, remembers pain, strongly proximity-driven.
- All numbers PLACEHOLDER (R14) until the tuning pass; the invariants above (auto-dodge
  ladder, 50/50 anchor, determinism) are the contract.

## R24 — Feint-read: the Mind counter to feints (owner, 2026-07-25)

The counter-texture to feint dominance (the balance finding of 2026-07-23): **smart
mobs read feints by Mind**, through the R22 threshold machinery unchanged:

- A feint carries a **read threshold** (skill data; PLACEHOLDER R14 default
  4 + feint level). The threshold asks the DEFENDER's Mind: Mind ≥ threshold →
  **auto-read** (no rng). Else Mind + its threshold die (d4 default, per-stat,
  upgradeable — R22) ≥ threshold reads. Mind + die max < threshold → the read is
  impossible, no rng consumed.
- **A read feint is WASTED**: nothing arms on the reader, the feinter's Moment is
  spent, and a `feint_read` event (R22-shaped payload: reader, feinter, roll/auto,
  die, threshold) is emitted for the broadcast layer.
- **The reader adds mock-grudge** (R23): passing the Mind gate IS getting the
  insult — mock_sensitive gates grudge from LANDED feints, the read replaces it for
  smart defenders.
- Rolls come from the salted AI stream, always emitted. The read never blocks
  non-feint setup skills; only feint-shaped taunts are readable.
- Consequences preserved on purpose: Incinedile (Mind 1) can NEVER read an L3 feint
  (max 5 < 7) — the slice fight and the full-cadence balance WIN are byte-identical;
  intelligence, not stats-frozen tuning, is the counter (rulebook v0.92 G4 stat
  freeze is respected).

## R25 — Tactical Roll: the declared-hex dodge + the AoE-center rule (owner G1, 2026-07-23)

The G1 ruling (char-sheet repo, `rulebook/skills-passover.md` RULINGS block) — SUPERSEDES
the R3/S2.1 "STANCE-gated" line for both skills: **"Tactical Roll is a declared-hex dodge:
you give up your movement for the Moment and declare the hex you roll to; the attack still
resolves — if your hex is inside its range/area you get hit anyway. No charges, no stance,
no cooldown. Acrobatic Save gets the same movement-forfeit cost in place of its cooldown."**
And the round-2 refinement: **"AREA attacks (blasts/bursts) MISS a rolling target entirely
unless the destination hex is the area's CENTER; single/multi-target attacks (arcs, lines,
cones) hit if the new hex is still within their range/pattern."**

- **Cost = exactly the movement allowance (design call).** The G1 text says "you give up
  your movement" — nothing more — so the roll consumes the R3 movement allowance
  (`moved_this_tick`) and ONLY that: rolling and moving are mutually exclusive in a tick
  (roll after any move → rejected `movement_spent`; free move after a roll → rejected
  `already_moved`), while the free-ACTION slot stays untouched — The Bit, the first
  inventory use and 0-cost declares/reactions remain legal the same tick.
- **The move happens IMMEDIATELY at declare** (it is a dodge, not a scheduled action; 0
  Moments). Through the R2 tick-start-snapshot rules this IS the single/multi-target half
  of the refinement with no new machinery: a windup resolving on a LATER tick re-checks
  its cone arc / dash lane / plain range against the roller's new hex (still inside the
  pattern → hit anyway; outside → the standard windup dodge/collapse). Rolling on an
  attack's own resolution tick dodges nothing, and instants (cost ≤ 1) are never dodged
  by movement — R2 unchanged.
- **The AREA half rides a `rolled_this_window` marker** (serialized, hash-covered): set at
  roll declare, cleared at the actor's next tick start — the honest minimal model: the
  dodge window IS the roll's Moment ("give up your movement for the Moment"). An AREA
  attack resolving that Moment misses the roller entirely unless the roller's hex is the
  area's CENTER. Dodging the explosion blast therefore means rolling ON the blast Moment —
  informed counterplay, since the telegraph broadcasts `moments_until_blast`.
- **VALVE-COUNTER CONSEQUENCE (flagged for the owner).** The one real AREA attack today,
  the explosion blast, centers on the boss's OWN hex — and rolling onto an occupied hex is
  impossible — so a well-timed roller ALWAYS escapes the valve KO, from anywhere in the
  radius, regardless of distance. Tactical Roll is a hard counter to explosion valves.
  This is presumably the design (the declared-hex dodge is the skill's whole identity),
  and the center-hex exception stays live in the engine for future area attacks with
  unoccupied centers — but it deserves an explicit owner sign-off.
- **Eligibility (mirrors movement, PROVISIONAL).** No roll while grappled (R9 movement
  lock), winding up (R2 commit) or Prone (R3 prone-can-only-crawl + the R22 punish
  window). Exposed does NOT block the roll: Exposed combatants may still move under R3,
  and R22's Exposed gate governs the threshold dodge, not movement. Slowed/terrain
  interactions are UN-RULED — no interaction implemented yet.
- **R22 interaction:** Tactical Roll is a positional dodge, orthogonal to the R22
  threshold dodge — a roll is movement, so where an ability authors an R22 threshold that
  check still applies independently to a roller who ended up inside the pattern.
- **Range ladder.** Base **2 hexes at L1 — PLACEHOLDER (R14)**; the book's effect text
  says 1 and the digital base is a tuning call. Level scaling follows the seed ladder's
  space increments (skills.json id 9 / the skills-audit's "levels upgrade spaces"):
  L2 +1, L3 +1, L4 +2 → ranges 2/3/4/6. The "-2 Moment cooldown" riders on L3/L4 and the
  cooldown-based L5/L6 threshold rows (char-sheet template ids 15–16) are DEAD per
  G1/R3 — **data-only, not implemented**.
- **Acrobatic Save:** its COST MODEL is ruled (the same movement forfeit, replacing its
  cooldown), but the skill itself (die manipulation) is NOT implemented — recorded here
  so the ruling isn't lost and nobody re-derives a stance prime for it.
- Event vocabulary: `tactical_roll` (actor, from, to, spaces, range, level) on success;
  `blast_missed_roller` when the AoE-center rule spares a roller; rejections
  `movement_spent` / `no_move` / `roll_out_of_range` / `hex_occupied` /
  `invalid_destination` plus the mirrored movement gates (`grappled` / `winding_up` /
  `prone`).

## R26 — Undodgable attacks: declared, announced, honest (owner, 2026-07-25)

Some attacks are **specifically undodgable** — a data-driven flag on the ability or
effect, never a hardcoded case:

- An undodgable attack is immune to EVERY dodge-shaped escape: the R22 threshold
  dodge, the R25 Tactical Roll / AoE-center rule, and any authored dodge block.
  **Movement is not a dodge** — leaving an area/range before resolution still works
  where the shape allows it (R2 windup re-checks unchanged).
- **Transparency is the rule's other half (owner's words: "declared on attack
  windup so the player knows and doesnt die due to a misunderstanding"):** the flag
  must ride the windup/telegraph event, `view_schedule`, and `preview_action` —
  loudly. An undodgable attack the player couldn't see coming is a bug, not a
  feature.
- **The valve blast IS undodgable** (first application — supersedes R25's
  valve-counter consequence): a blast-Moment Tactical Roll no longer escapes the
  KO; running out of the radius during the escape window remains the counterplay.

## R27 — The G3 keyword tree + Gemstone mutations (owner G3/G6, 2026-07-23)

**SETTLED (ruled — G3 round 2 + G6 round 3, char-sheet repo
`rulebook/skills-passover.md` RULINGS; book `gpt-system-v0.92.md` §4.5).** The
Gemstone compatibility system is **model A: the keyword tree**, adopted as data +
machinery in this repo:

- **Data:** `data/skill_keywords.json` — the book §4.5 taxonomy (9 BROAD groups,
  31 NARROW members — the book classifies EXPLICITLY, nothing provisional about
  the split) + the ruled per-skill assignments, a VERBATIM port of the char-sheet
  repo's `server/apply-skill-passover.js` KEYWORDS map (44 skills) plus the 5
  G6-approved new-skill seeds (intercept, death_grip_jaws, field_triage,
  iron_stance, play_to_the_camera). This is DATA canon even where the sim has not
  implemented the skill. `reversion` has NO ruled assignment (postdates the
  44-row table) — flagged, not invented; `validate_seeds` surfaces it as a NOTE.
- **The rule** (`simulation/skill_keywords.gd`): share ≥ 1 NARROW keyword =
  compatible (`basis: "narrow_shared"`, auto-legal). Sharing only a BROAD group =
  the ruled **GM-call tier** — machine-READABLE (`basis: "broad_only"`), never
  machine-LEGAL: the engine rejects it unless a recipe carries an explicit
  authored `compatibility_override` (the recorded GM fiat). No overlap =
  incompatible (`basis: "none"`). Deterministic, symmetric, data-driven.
- **Mutations** (`simulation/skill_forge.gd` + `data/skill_mutations.json`):
  recipes are authored data `{key, name, parents: [{key, min_level}], result:
  {key, level}, note}`. `validate_mutation` returns EVERY violation at once
  (missing parent / underleveled / incompatible parents / result already owned /
  malformed recipe); `apply_mutation` is a PURE function on the from_spec-shaped
  skills array — **both parents CONSUMED**, result granted at the recipe level.
  Recipes validate against skill KEYS + LEVELS only: a roster may own an
  unimplemented skill as data (`CombatantState.from_spec` has no KNOWN_KEYS
  gate), which is load-bearing — neither parent Intercept nor any mutation
  result needs a SkillBook entry to be granted.
- **The canonical example (G6 round 3):** **Intercept Lv 5 + Brace Lv 3 →
  Iron Stance Lv 1, both parents consumed** — compatible through the shared
  NARROW keyword `bracing` in the ported data (exactly as the book records:
  "compatible through *bracing*"), so the shipped recipe carries no override.
  Iron Stance itself stays **DATA-ONLY** in the sim: its ruled effect (stance —
  attacks on adjacent allies retarget to you, persistent Crush/Burn reduction)
  needs a retarget-guard archetype in ActionResolver before an honest encode;
  seeding it into `data/skills.json` rides the same content pass.
- **Economy is deferred to KAN-7:** the compendium's Modification Center prices
  a Skill Gemstone use at **1 Bronze** ("disassemble/consume/merge") — recorded
  in the data note, deliberately unpriced in the engine. When/how a merge is
  OFFERED (Lounge flow, player consent — §4.5 "never automatic") is
  progression/UI scope; the engine here only answers "is this merge legal, and
  what does the roster look like after."

## R28 — Arenas: bounds, walls, environment objects (KAN-5 wave 3d, 2026-08-11 — PROVISIONAL)

**The arena is STRICTLY OPT-IN.** A combat carries an arena only when staged
with one (`set_arena` — issued by the controller from the encounter def's
`arena` block; defs LIVE on the encounter in `data/demo_run.json`, documented
in `simulation/arena.gd`). **Absent arena = the unbounded legacy combat,
byte-identical**: no behavior changes, and `to_dict()` carries no `arena` key,
so every pre-arena save/hash/harness is untouched (pinned; the CI harnesses
stage no arena and byte-diff clean). `data/enemies.json`'s `arena_hexes`
(`[41, 60]` on the incinedile) stays the per-enemy design record the den's
encounter block mirrors.

- **Model** (`simulation/arena.gd`, serialized on CombatSim under `arena`,
  hash-covered): `bounds` (axial rect `width`×`height` with an optional
  `origin`, default centered — an axial parallelogram, PROVISIONAL room shape —
  or an explicit hex set), `walls` (blocked hex set, authored), `objects`
  (trash cans: `{key, position, burn}`).
- **Movement honesty** — bounds+walls block EVERY position-changing path when
  an arena is set; trash cans block like an OCCUPIED hex until destroyed
  (occupied-hex logic composes with walls — both block). Per path: free +
  scheduled **moves** reject (`out_of_bounds`/`hex_blocked`); **AI steps**
  are PATHFOUND (wave 4a, 2026-08-11 — `simulation/pathing.gd` retires the
  wave-3d "greedy step strands on concave walls" limitation): with any
  authored wall (or explicit-hex-set bounds, which can be concave) the
  walker plans a deterministic A* route around walls/bounds/cans/bodies —
  concave traps are navigated across successive decides, allowance
  permitting — and a goal PROVEN unreachable (sealed room) yields no step,
  so the AI waits honestly instead of thrashing at the wall. Bounded: a
  4096 node-expansion cap; hitting it falls back to the legacy greedy walk
  honestly (never hangs, never fakes a path). Without an arena, or in a
  wall-less rect arena, the walker IS the legacy greedy step, byte-identical
  (no-arena space is infinite, and straight-line greedy is provably optimal
  in the open — the tie-break/cap contract and the convexity argument live
  in `simulation/pathing.gd`'s header); **tactical rolls**
  reject; **feint/pressure repositions** into a blocked hex hold position;
  **sidesteps** skip blocked candidates (no legal hex = dodge still negates,
  no displacement); **knock-asides** skip blocked candidates (no legal hex =
  no displacement, target stays and is STILL knocked prone); **flings** stop
  on the last free lane hex before a blocked one (still prone on landing);
  **grab drags** fail on a blocked pull hex (`pull_blocked`); **summons**
  place on legal ground only; **staging** rejects a spawn on a blocked hex
  (`staging_out_of_bounds`/`staging_blocked_hex`), and `set_arena` itself
  rejects walls/objects out of bounds or any already-staged combatant left
  illegal.
- **Dash wall bounces** (un-inerts the phase-3 "dash bounces between walls up
  to 2 bounces" — `dash_wall_bounce`): with an arena set and the upgrade
  active, a dash lane that hits a wall/bounds REFLECTS, up to 2 bounces;
  without the upgrade (or past the budget) the lane ENDS at the wall. **The
  reflection model** (authority: `Arena.bounced_lane`; verbatim from its
  header): the lane walks hex-by-hex along its current ray direction v (an
  INTEGER cube vector); when the next hex W is a wall/out-of-bounds, the
  incoming unit step n = W − P (always axial — consecutive lane hexes are
  adjacent) names the blocked EDGE, and the ray mirrors across that edge's
  plane: **v' = v − (v·n)n** (cube; n·n = 2) — the n-component reverses, the
  tangential component is preserved; equivalently a SWAP of the two cube axes
  n mixes. Integer in, integer out, hex norm preserved. A head-on hit
  reflects straight back (a ricochet may legally revisit hexes; the
  chosen-bend no-hairpin rule does not apply to forced bounces). Total lane
  length stays ≤ the dash's range ACROSS ALL SEGMENTS. ASCII (the arena.gd
  example — the (1,1)-diagonal ray, wall W at (2,1), range 6):

  ```
        q ->                          lane (in order):
    r=0   O  1  .          O=(0,0)    (0,0) (1,0) (1,1)   incoming E,SE,...
    r=1    4  2  W         1=(1,0)    -- step E into W=(2,1): BOUNCE at 2 --
    r=2   .  5  .  .       2=(1,1)*   v=(3,-6,3) n=E=(1,-1,0) v.n=9
    r=3    6  .  .         4=(0,1)    v'=v-9n=(-6,3,3)  (cube x<->y swap)
                           5=(-1,2)   (0,1) (-1,2) (-2,2) (-3,3) outgoing
                           6=(-2,2)   W,SW,... — the mirror image of the
                           7=(-3,3)   incoming diagonal across the N-S edge
  ```

  ALL lane rules apply to the full reflected lane: occupation stops the
  charge on any segment, leaving the corridor mid-windup dodges it
  (`left_lane`), the R22 sidestep steps off the whole bounced lane (bounces
  never split the sidestep exclusion — only a chosen bend does), knock-aside
  shoves off it. **Bounce vs bend composition:** a bounce is FORCED by walls,
  a bend (phase 4) is CHOSEN — one lane may carry both (validated: ≤ 1 bend +
  ≤ 2 bounces; each marker phase-gated: `bounce_not_available` /
  `too_many_bounces` / `lane_blocked` for a lane containing a wall hex). The
  AI planner never composes them itself: it tries the straight/direct ray
  (with forced bounces), then a fixed-order bank-shot aim search (6 axial + 6
  diagonal directions — coarse by design, PROVISIONAL), then the chosen-bend
  search on wall-free corridors. Cans never bounce or end a lane — **a
  charge SMASHES through a trash can**, destroying it (`trash_can_smashed`,
  no explosion — a smash is not a burn touch).
- **Trash cans** (un-inerts the phase-3 "flamethrower pops trash cans
  instantly" — `cans_pop_instantly`); canon off the authored flamethrower
  note "trash cans explode at Burn 5 (3 spaces, 2 Burn)": a can in a resolved
  BURN cone's arc accumulates the cone's per-round burn amount (independent
  of whether the combatant rounds landed; a Whiff negates the sweep); at
  burn ≥ 5 it EXPLODES — `HexGeometry.blast` radius 3, burn 2 to every
  living combatant in it **through the normal damage/condition paths with NO
  attacker** (environment: no killer on a death — takedown-v2 honesty; no
  grudge; the boss's fire-heal hook applies, so the Incinedile is HEALED by
  its own props). Collateral is never threshold-dodged (R22 valve precedent
  — implemented via the R26 undodgable skip, ZERO rng); the R25 AoE-center
  roller-miss still applies. The blast is a burn TOUCH (+2) on other cans in
  radius (cascades; the instant pop never chains — it belongs to the
  flamethrower). With the upgrade active the FIRST cone touch pops the can
  (no accumulation). A destroyed can's hex unblocks. Events:
  `trash_can_burned` / `trash_can_exploded` / `trash_can_smashed`; state
  additively exposed via `view_arena()` (bounds/walls/objects + live burn).
- **Still OPEN for KAN-5 proper:** ~~real AI pathfinding~~ SHIPPED wave 4a
  (`simulation/pathing.gd`, the AI-steps bullet above); ~~rooms/dungeon FLOW
  (corridors, doors, multi-room exploration)~~ SHIPPED wave 4b (R29 below);
  ~~stealth/detection/cover (R20, wave 4c)~~ SHIPPED wave 4c — the v1
  binary-sight slice (`simulation/stealth.gd` + the `stealth` command; the
  R20 IMPLEMENTED marker lists what stays downscoped: cones/facing, hearing
  beyond the Shout + ALERTED, disguise, sized cover, the rival-god lever);
  ~~the hound maze-funnel herding (`corner_the_prey`, wave 4d)~~ SHIPPED
  wave 4d — the herder chase/cut-off role split, R11 #21 (the KAN-5
  capstone: `pack_herding`, the kennel gate, tests/test_herding.gd).
  Remaining: hearing/facing per R20's own phasing (the investigate/ALERTED
  reactions a fuller funnel would lean on), environment objects beyond the
  trash can, and owner-authored room layouts (every authored wall/can/door
  position is PLACEHOLDER — the owner redesigns rooms with the front).
  Tests: `tests/test_arena.gd` (+ the flipped pins in
  `tests/test_phase_upgrades.gd`); the wave-4a pathfinding contract is
  pinned in `tests/test_pathing.gd`; the wave-4c stealth contract in
  `tests/test_stealth.gd`; the wave-4d herding contract in
  `tests/test_herding.gd`.

## R29 — Doors & dungeon flow: the room graph (KAN-5 wave 4b, 2026-08-11 — PROVISIONAL)

**Doors and the dungeon room-graph shipped** — the structure layer of KAN-5
proper. Both are STRICTLY OPT-IN like the arena itself: a door-less arena and
an exits-less encounter list behave (and serialize) byte-identically to wave
3d; the CI harnesses stage neither and byte-diff clean.

- **Doors** (`simulation/arena.gd` `doors: [{key, position, state:
  "open"|"closed"}]`, authored per arena on the encounter def; serialized with
  the arena, hash-covered, the `doors` key present only when authored): a
  **CLOSED door blocks exactly like a wall through the ONE existing blocking
  query** (`Arena.is_wall`, which `blocks_lane`/`blocks_movement` compose) —
  so every consumer inherits doors with zero edits: free/scheduled moves
  reject `hex_blocked`, AI steps detour or wait, dash lanes END at a closed
  door (and a phase-3+ dash **BOUNCES off a closed door like any wall**),
  sidesteps/knock-asides/flings/summons/repositions all treat it as solid,
  and LOS-when-it-exists will read the same query. An **OPEN door blocks
  nothing** (standing in a doorway is legal). **Staging never spawns on a
  door hex**, open or closed (`staging_on_door_hex`); `set_arena` validates
  door placement (in bounds, off walls/objects/other doors —
  `arena_door_misplaced`) and the seed validator mirrors both plus the
  spawn check.
- **The `door` command** (`{actor, key, set: "open"|"closed"}`): the actor
  must be alive/ready and **ADJACENT** (distance exactly 1 — standing ON an
  open door cannot close it under itself), and the flip **costs the
  free-action slot** (R3, the inventory-interaction family: one free action
  per combatant per tick, shared with The Bit / the free move / the first
  inventory use / 0-cost reactions; v1 deliberately grants NO Moment-cost
  fallback, so one door interaction per tick is the cap). Closing onto a hex
  with a live body rejects (`door_blocked_by_body`). **Enemies never issue
  it in v1** — the AI never decides doors (no enemy_ai path exists; a closed
  door honestly walls an enemy off — the greedy walker waits like any walled
  mob). Event: `door_changed {actor, key, position, state}`.
- **Dungeon flow** (`simulation/run_state.gd`): the run's encounter list
  generalizes to a **room graph** — defs author `exits: [{key, to, label}]`;
  index 0 is the entry room. After a room's combat WINs (and any recruit
  beat resolves — the offer outranks), the cleared room's exits decide:
  **0 exits = a TERMINAL room, the run auto-finishes WIN** (the graph
  counterpart of "every encounter cleared"; `end_run` in a graph run is
  always early extraction = ABANDONED); **1 exit auto-advances**
  (`run_exit_chosen {auto: true}` — corridor cadence, no beat); **2+ exits
  open the EXPLORATION beat** (`run_exploration_beat`; the view exposes the
  exits; the `choose_exit {key}` run command resolves it — rejected
  mid-combat/mid-offer/outside the beat, and the beat is unmissable like the
  offer beat). **The graph is a DAG in v1** (documented; loops are future):
  `revisitable` defaults false, visited tracking is DERIVED from logged
  state (records + active room — replay-safe), and the validator gates
  authored maps (exits resolve, terminal exists, no cycles, all rooms
  reachable). **Chain semantics:** choosing an exit is still back-to-back —
  the hype chain persists through exploration beats untouched; a future REST
  beat stays the one chain-breaker (unchanged data hook). Sim seeds stay
  `encounter_seed(room index)` — path-independent. Full backward compat: a
  def set with no exits is the exact pre-graph linear run (same behavior,
  same serialization — no graph key ever appears).
- **The authored demo branch** (`data/demo_run.json`): Brood Landing →
  choice of the Kennel Gauntlet (hound pair) or the Service Corridor (light
  roach reuse) → the Incine-Dile den (terminal; its arena authors the closed
  service hatch + the open kennel gate — ~~the §4.6 maze-funnel texture as
  DATA, no herding AI~~ **the maze funnel is REAL since wave 4d (R11 #21)**:
  the kennel arena now also authors the kennel-run fence + the OPEN
  kennel_run_gate, the escape the second hound's cut-off posts on).
  **Every door/exit position and label is PLACEHOLDER (R14) —
  owner-authored maps still pending.**
  Tests: `tests/test_doors.gd` + `tests/test_dungeon_flow.gd` (+ the updated
  run-engine pins in `tests/test_run_state.gd` / `tests/test_run_persistence.gd`).

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
