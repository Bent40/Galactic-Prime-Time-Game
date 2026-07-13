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
  universal rule.
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
- **SETTLED.** Cooldowns exist (F5): "Cooldown: N Moments" = N ticks from resolution;
  "1 Clock" = 10 ticks; tracked on the absolute timeline, unaffected by Clock resets.

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

- **SETTLED (codifies what the live table already does via the char-sheet app).** Levels
  are **awarded by the game** at authored milestones (bosses, floors, major achievements) —
  no XP curve. Each level grants **1 level point** into a pool; a level point buys +1
  `levelBonus` on any one trait. Creation rules unchanged (7+7 across pillars, max 5).
- **SETTLED (adopt the app's live-tested formulas verbatim).** Over-10 stat caps:
  Physique `floor(max(0, total-10)/5)` → +1 max HP per body part each;
  Reflexes `/12` → +1 allocatable physical resistance (Bleed/Crush/Burn);
  Mind `/15` → +1 psychic resistance tier; Charm `/20` → +1 Camera Call stack.
  The "rated 1–5" scale is **creation-only** (now stated explicitly).
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
9. Cooldown "1 Clock" = exactly 10 ticks regardless of Clock boundary [R3].
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

---

*Owner morning checklist: the PROVISIONAL rulings worth your eyes first — R2 miss/dodge
model, R3 cap numbers, R4 Burn-T1-costs-Shock, R6 level pacing (engine-ready either way),
R8 RPM numbers, R9 grapple gates, R10 requirements-halving + token-exchange cut.*
