# Slice Tags — Proposal: the ~10 detectable tags with real effects (issue I-13)

*Status: **PROPOSAL — awaiting owner approval.** Nothing here is canon until ruled.
The full 100-tag catalog (84 live rows) stays deferred — issue I-27. This document
selects the vertical slice's working set: tags with (a) a concrete mechanical effect,
(b) a detector the current sim event stream can actually evaluate, (c) a crowd-goal /
hype hook, (d) a reachable path in the slice content
(`slice-contestants-proposal.md` premades + Incinedile Phase 1), and (e) a clean join
to the mythology pipeline's domain vocabulary (`mythology-research-spec.md` §4).*

***R14 discipline applies throughout:* every multiplier, threshold, count, and payout
below is **PLACEHOLDER (R14)**. Shapes, detectors, and selections are what is being
proposed, not values.*

**Sources honored:** all tag names come from `data/tags.json` verbatim (no new tags;
descriptions stay empty — the rich text lives in the out-of-repo rulebook docx and is
NOT invented here; effects are derived from the names + the audit's mechanical-intent
notes). Effect patterns follow the owner-approved model (rulings batch 2026-07-17:
"the 5 audit patterns PLUS pattern 6", `docs/audits/campaign-residuals-audit.md` §1.2).
Engine facts verified against `simulation/hype_engine.gd`, `simulation/combat_sim.gd`,
`simulation/action_resolver.gd`, `simulation/condition_engine.gd`,
`simulation/forced_action.gd`, and `data/crowd_goals.json`.

---

## What "detectable" means here (the contract)

Review-2 §2: tags earned by table consensus become **detector systems per tag** —
achievement-style predicates over the sim event log, same determinism discipline as
everything else in `simulation/`. Concretely, a slice tag needs:

- **Unlock/reinforce detector** = a machine-evaluable predicate over events the sim
  already emits (or a precisely-specified event another approved ruling already owes
  us). Thresholds are PLACEHOLDER.
- **Effect** = pattern 1 (hype resonance), pattern 2 (`goal_modifier_weights` bias),
  pattern 4 (lifecycle weight as the dial), and at most one pattern-5 flagship rider
  in the whole set. Pattern 3 (patron-impression lens) activates at KAN-7 via the
  same `domains` declaration; pattern 6 (tags gate unlocks) is out of slice scope.
- **Slice-visible in v1: all effects are audience-side** (hype/goal/broadcast), never
  combat-stat buffs. Tags change what the crowd pays for, not what your body can do —
  keeps the slice honest about the two information planes and dodges a balance pass
  the R14 rework would invalidate anyway.

**Attribution convention (PROVISIONAL — extends R11 #14 attribution v1):** damage,
condition, and part events are *victim-attributed* (`damage_applied` carries
`combatant` = the one hit, no attacker field — `condition_engine.gd:390`). The tag
detector credits an offensive event to the **actor of the next
`action_resolved`/`reaction_resolved` in the same command batch** (the resolver emits
strike events *before* their closing `action_resolved` — `action_resolver.gd:546-551`,
so the pairing is deterministic and replay-stable). Events with no such closer in the
batch (e.g. condition-advancement damage at `clock_reset`) go uncredited — correct:
nobody performed them. This is a detector-side convention, **zero engine event changes**.

---

## The slice set — 10 tags

Spread: offense ×2 (Gorefest, Reckless) · defense/support ×2 (Survivor, Craft
Services) · movement ×1 (3am Energy) · showmanship ×3 (Scene Stealer, The Bit, Fan
Favorite) · teamwork ×1 (Formation) · comedy/failure ×1 (Blooper Reel).

All multipliers/thresholds PLACEHOLDER (R14). "Resonance" = pattern-1 hype-point
multiplier applied to the named events when attributed to the tag holder, scaled by
the tag's lifecycle weight (pattern 4).

### 1. Reckless (id 6, `reckless`) — risk/offense

- **(a) Effect:** resonance ×1.5 on spectacle from attacks the holder lands while
  Exposed **and** on damage the holder takes while Exposed — the crowd pays for the
  gamble in both directions. Goal bias: Risk kinds (`exposed_strike`).
- **(b) Detector:** `action_resolved` (kind `attack`, result `ok`, rounds > 0) while
  the actor's exposed mirror is true — **verbatim reuse of the existing
  `exposed_strike` goal predicate** (`hype_engine.gd:253-258`), fed by
  `exposed_state_changed`. Unlock: N=3 exposed hits in one deployment. New events: 0.
- **(c) Crowd hook:** feeds the existing `exposed_strike` ("Show-Off!") goal; biases
  its draw weight.
- **(d) Slice path:** Imani's Strong Strike is a 2-Moment windup, Exposed while
  performing — she farms this every swing. Dario reaches it attacking out of the
  Death Spin grab (R9: both grappler and grappled are Exposed).
- **(e) Domains:** `war` · `chaos` · `luck_gambling` (recklessness as staking your
  body — the casino nobility's own domain watches this tag).

### 2. Gorefest (id 19, `gorefest`) — offense/spectacle

- **(a) Effect:** resonance ×1.5 on `part_destroyed`, `bleed_out_started`, and
  Bleeding `condition_advanced` reaching tier ≥ 2, when batch-credited to the holder.
  Goal bias: `part_break` + `overkill`.
- **(b) Detector:** `part_destroyed` {combatant, part} and `condition_advanced`
  {condition: bleeding, to_tier ≥ 2}, credited via the batch convention. Unlock: N=2
  such events caused in one deployment. New events: 0.
- **(c) Crowd hook:** the existing `part_break` ("Break Something!") and `overkill`
  goals — this tag is those goals' repeat customer.
- **(d) Slice path:** both breach doors produce it — Dario's Pressure Strike Bleeding
  ladder (Breach A is literally Bleeding T2), Imani's Overhead Slam driving Crushed
  toward the flamethrower-disable `part_destroyed`; the boss's Chew (2 Crush both
  arms) generates the events in the other direction.
- **(e) Domains:** `war` · `death_underworld`.

### 3. Blooper Reel (id 99, `blooper_reel`) — comedy/failure

- **(a) Effect:** resonance ×2 on the holder's own `forced_action_triggered` (base
  weight already 12 — "comedy beat") and its consequence family (`collateral_hit`,
  item drops). Failure becomes content; the tag makes the sim's signature d6
  pratfall economy legible.
- **(b) Detector:** `forced_action_triggered` {actor, table, roll, consequence} —
  perfectly actor-attributed already. Unlock: suffer N=3 Forced Actions in one
  deployment. New events: 0.
- **(c) Crowd hook:** proposed goal-table row **"Pratfall!"** (kind `forced_action`:
  completes on any `forced_action_triggered`; params could filter table/consequence)
  — one new `match` arm over an existing event.
- **(d) Slice path:** Dario's Feint turns the *boss's* next action into a Forced
  Action — he farms the Incinedile's blooper reel (attribution v1 lands the tag on
  the pratfaller, which is the joke). Contestants earn their own via R10
  desperation moves (unmet requirements still act, halved, d6 fires).
- **(e) Domains:** `trickery` · `chaos`.

### 4. Scene Stealer (id 37, `scene_stealer`) — showmanship

- **(a) Effect:** the holder's crowd-goal completions pay ×1.25; goal bias toward
  Performance-flavored rows. (One clause, deliberately — the "steal" flavor comes
  from *who* completes goals, which the detector already measures.)
- **(b) Detector:** `hype_goal_completed` {combatant} and `hype_camera_call_started`
  {actor} — consuming the hype engine's own outputs. Legal: the `hype_` prefix guard
  is HypeEngine's internal anti-double-count (`hype_engine.gd` header), not a stream
  taboo; the tag engine ingests *after* hype output is appended
  (`combat_sim.gd:125`). Unlock: complete N=2 goals, or 1 while spotlit. New events: 0.
- **(c) Crowd hook:** all four existing goal kinds (it biases and feeds on the goal
  system itself); Camera Call synergy is native.
- **(d) Slice path:** Dario's expected drift tag #1 — camera calls before stunts,
  stolen finishing blows completing `takedown`. Imani's flamethrower-disable clip
  completing `part_break` reaches it from the other temperament.
- **(e) Domains:** `music_performance` · `trickery`.

### 5. The Bit (id 55, `the_bit`) — showmanship/authored — **the set's one flagship rider (pattern 5)**

- **(a) Effect (rider):** an authored signature action performed repeatedly pays
  **escalating** spectacle — base X, +Y per prior performance this deployment;
  an interrupted bit (`action_invalidated`) resets the ladder. All numbers
  PLACEHOLDER.
- **(b) Detector:** `action_resolved` {actor, kind, key} for the authored bit key
  (e.g. Dario's `bow` — the resolver's generic branch already resolves any declared
  kind, `action_resolver.gd:455`), and the bit's declared payload carries
  **`spectacle_points`** so the existing generic hook scores it with zero engine
  change (`hype_engine.gd:167` + R11 #13/#14 authored-content hook). The rider's
  escalation lives in the tag engine, which emits the bonus as its own
  spectacle-carrying event. Unlock: perform the bit N=3 times. New events: 0 —
  this is the spectacle_points hook doing exactly what it was documented for.
- **(c) Crowd hook:** pairs with `takedown` (the bow lands after kills);
  authored-content spectacle path.
- **(d) Slice path:** Dario's kill→bow is specified as "the bit" in his proposal;
  interrupting the bow is the designed jeopardy. The Incinedile band-cage intro
  uses the same authored `spectacle_points` channel — one hook, both uses.
- **(e) Domains:** `music_performance` · `poetry_story`.

### 6. Fan Favorite (id 15, `fan_favorite`) — audience/heart

- **(a) Effect:** a small global lens — all spectacle attributed to the holder
  ×1.15 (the camera simply finds them more); goal bias toward crowd-pleaser rows.
  The brand-contract empathy hooks (story-canon) attach here later, free.
- **(b) Detector:** cumulative credited spectacle ≥ X within a deployment. The tag
  engine tracks its own per-combatant credit counter using the same attribution
  helper the hype ledger uses (it ingests the identical stream — no new events, no
  reads into HypeEngine state). New events: 0.
- **(c) Crowd hook:** amplifies every existing goal payout the holder completes via
  resonance; the KAN-7 Patron-conversion channel is this tag's real payday later.
- **(d) Slice path:** Imani's expected drift tag — slow-build ledger from saves,
  body-blocks, and the disable clip. The crowd loves her *despite* her ignoring them.
- **(e) Domains:** `love_beauty` · `protection_home` (empathy tags draw hearth-domain
  gods — audit pattern 3).

### 7. Survivor (id 30, `survivor`) — defense/jeopardy

- **(a) Effect:** resonance ×1.5 on the holder's own jeopardy beats:
  `bleed_out_started`, `bleed_out_stabilized`, `shock_changed` to tier ≥ 3,
  `part_disabled`/`part_destroyed` on self while remaining alive. Near-death is
  this tag's content; no combat buff.
- **(b) Detector:** `bleed_out_started` → `bleed_out_stabilized` on the same
  combatant (the clutch-save pair the hype engine already prices at 40/35), or
  ending a deployment alive with ≥ 2 parts disabled/destroyed. All existing,
  victim-attributed events — no batch correlation even needed. New events: 0.
- **(c) Crowd hook:** feeds the jeopardy side of `takedown` drama; natural home for
  a future Risk row ("Without Healing" — compendium §2.20) at I-27.
- **(d) Slice path:** the Death Spin grab (5 damage to the hand releases) is
  scripted crowd-favorite jeopardy for whoever gets grabbed; Imani's Brace-tank
  pattern walks the near-death line deliberately.
- **(e) Domains:** `death_underworld` · `time_fate`.

### 8. Craft Services (id 49, `craft_services`) — support

- **(a) Effect:** resonance ×1.5 on support beats credited to the holder:
  protective reactions (`reaction_resolved` with a protective key, e.g. `brace`),
  `attack_blocked`, and ally-benefiting treat/heal/handoff events (`healed`,
  `condition_delayed`, `inventory_used` share interactions, batch-credited).
  Support stops being dead air on the broadcast.
- **(b) Detector:** `reaction_resolved` {actor, key} — actor-attributed today;
  `attack_blocked`; treat/heal outcomes batch-credited to the treater. Unlock: N=3
  ally-benefiting support events in one deployment. New events: 0.
- **(c) Crowd hook:** proposed goal-table row **"Body Block!"** (kind `body_block`:
  completes on `attack_blocked` or a protective `reaction_resolved` while an ally
  was the attack's target) — predicate over existing events; this is the
  "No Safety Play" / protective-spectacle Goal Imani's proposal says her kit serves
  on a plate.
- **(d) Slice path:** Imani's Brace-into-the-flamethrower-cone for someone else —
  the tank fantasy as spectacle; bandage use and R15 item handoffs extend it.
- **(e) Domains:** `protection_home` · `healing` · `earth_harvest` (the name is
  literally the food table — harvest/hearth gods get the joke).

### 9. Formation (id 75, `formation`) — teamwork/choreography

- **(a) Effect:** resonance ×1.5 stacking with R15's committed combined-action hype
  bonus — choreography pays extra for the tagged; goal bias: `overkill` (merged
  hits are how 8+ single-hit numbers happen).
- **(b) Detector:** the **R15 combined-action merge event** — the one detector in
  this set keyed to an event that doesn't exist yet. It is NOT new surface added by
  this proposal: R15 (RULED 2026-07-16) already commits merged same-tick hits and
  their hype bonus, and the slice's Breach B (7+ merged single hit) cannot ship
  without it. This proposal adds one requirement to that pass: **the merge event
  must enumerate all linked `actors`** so every participant is creditable. Unlock:
  participate in N=2 combined actions.
- **(c) Crowd hook:** `overkill` (an 8-threshold single hit is the pair's merged
  swing); R15's own hype bonus.
- **(d) Slice path:** the designed Breach B discovery — Imani's windup as the base,
  Dario's assist as the link; the audit already re-anchored this tag to R15
  combined actions.
- **(e) Domains:** `war` · `music_performance` (war bands and dance troupes both
  claim choreography).

### 10. 3am Energy (id 68, `3am_energy`) — movement

- **(a) Effect:** resonance on movement chains: `moved` events by the holder gain
  spectacle while a streak is live (≥ K spaces inside one Clock — motion becomes
  content); goal bias toward the proposed movement row.
- **(b) Detector:** `moved` {actor, spaces} accumulated between `clock_reset`
  boundaries — trivially machine-evaluable, actor-attributed. Unlock: M=2 streak
  Clocks in one deployment. New events: 0.
- **(c) Crowd hook:** proposed goal-table row **"Zoomies!"** (kind `move_spaces`,
  params {spaces: N, within_clocks: 1} — completes on `moved` accumulation; the
  first movement goal in a table that currently only pays violence).
- **(d) Slice path:** Dario's whole locomotion identity — Dance declaration,
  Pressure Strike's free spaces, dodging Dash lines and the flamethrower cone
  ("he simply isn't there"). Imani deliberately can't reach it (Reflexes 2) — the
  pair's contrast made legible.
- **(e) Domains:** `travel_speed` · `beasts_wild` · `moon_night` (it is, after all,
  3am).

---

## Near-misses (recorded so I-27 doesn't re-litigate)

| tag | why not in the slice set |
|---|---|
| Menace (13) | Dario's drift tag, but *intent* (deliberate endangerment) isn't machine-evaluable under attribution v1; its honest detector (collateral/friendly-fire events) collapses into Blooper Reel's event family. Revisit when cross-referenced attribution (v2, R11 #13) lands. |
| The Monologue (38) | needs speech mechanics (director speech scoring) — no sim surface in the slice. |
| Protagonist (21) / Antagonist (22) | narrative-arc labels — need multi-deployment story state, not one-fight detection. |
| Oops (11) | same event family as Blooper Reel; one comedy-failure tag earns its slot. |
| Visual (72) | best stat-linked tag (R18 Charm reading) but the detector is a stat threshold, not behavior — nothing for the slice to *do*. Strong early I-27 candidate. |
| Off Script (94) | needs Directives (KAN-7). |
| Safe Mode (89) | absence-detection (punishing over-caution) needs longer windows than one boss fight. |
| Fan Service (82) | overlaps Scene Stealer + Fan Favorite inside the slice's small surface. |

---

## Coverage matrix — every tag reachable in the slice

● = primary/designed path · ○ = reachable · — = not in slice scope

| tag | Imani "The Door" | Dario "Encore" | Incinedile P1 | environment |
|---|---|---|---|---|
| Reckless | ● Strong Strike windups (Exposed) | ○ attacks while grabbed (R9 Exposed) | ○ its own 3-Moment Death Spin windup is an Exposed channel (boss-tag question, OQ7) | — |
| Gorefest | ● Overhead Slam → Crushed T2+ hand | ● Bleeding ladder to T2 (Breach A) | ● Chew crushes both arms | ○ trash-can burst Burn |
| Blooper Reel | ○ desperation moves (R10 halving + d6) | ● Feint farms the boss's pratfalls | ● receives Feint's Forced Actions | ○ Tool-3 collateral absorbed by scenery |
| Scene Stealer | ○ disable clip completes `part_break` | ● camera calls + stolen `takedown`s | — | — |
| The Bit | — (no authored bit yet; future ritual candidate) | ● the bow, post-kill | — | ○ band-cage intro rides the same `spectacle_points` hook |
| Fan Favorite | ● slow-build ledger (saves, the clip) | ○ heel heat still credits spectacle | — | — |
| Survivor | ● Brace-tank near-death line, bleed-out save | ● grabbed-Encore jeopardy (5-dmg release) | — | ○ (Pressure Valve escapes are P2+, out of P1) |
| Craft Services | ● Brace-into-the-cone, bandage, handoff | ○ item handoff (R15 support verbs) | — | — |
| Formation | ● base of the merged hit | ● the assist/link | ● Breach B target (7+ merged) | — |
| 3am Energy | — (Reflexes 2, by design — the contrast) | ● Dance + free-space chains, dodging | ○ Dash/cone pressure forces the movement show | ○ arena geometry makes it legible |

Every row has at least one ● inside Phase 1 content. The two deliberate "—" cells on
premades (The Bit for Imani, 3am Energy for Imani) are the pair's designed contrast,
not gaps.

---

## Implementation sketch

**Data (choose one — OQ2; recommendation: sibling file):**
- Recommended: new **`data/tag_effects.json`** — 10 entries keyed by tag key:
  `{key, domains[], resonance {event_selector → multiplier}, goal_bias {kind → weight},
  unlock {predicate, threshold}, rider {…}}` (rider on `the_bit` only). Keeps
  `data/tags.json` a pristine port of the live catalog (the char-sheet app is the
  catalog of record; descriptions stay empty pending the rulebook docx) while the
  schema's existing `unlock_conditions`/`goal_modifier_weights` columns get filled at
  the I-27 catalog pass from this file's proven shape.
- Alternative: fill the 10 rows of `tags.json` in place (fields already exist and are
  empty). Cheaper now; couples game data to catalog syncs.
- Plus (OQ5): 3 optional rows in `data/crowd_goals.json` — **Pratfall!**
  (`forced_action`), **Body Block!** (`body_block`), **Zoomies!** (`move_spaces`) —
  payouts/deadlines PLACEHOLDER (R14).

**Engine:**
- New `simulation/tag_engine.gd` — RefCounted, mirrors the HypeEngine consumer
  pattern exactly: wired in `CombatSim.apply_command` immediately after
  `hype.ingest` (`combat_sim.gd:125`) so it sees hype outputs
  (`hype_goal_completed`, `hype_camera_call_started`); holds per-combatant tag
  weights (lifecycle 0–3, pattern 4) + unlock progress + the batch-credit helper;
  emits **`tag_*`-prefixed events** (`tag_progressed`, `tag_acquired`,
  `tag_reinforced` — same self-guard convention as `hype_*`); fully
  `to_dict()`/`from_dict()` serialized and covered by `state_hash`.
- HypeEngine extension (~20 lines): a `tags` mirror rebuilt from `tag_acquired`/
  `tag_reinforced` events (same pattern as its `exposed` mirror) + one resonance
  lookup applied alongside `_spotlit` in `ingest`.
- Goal predicates: up to 3 new `match` arms in `_goal_completed_by`, all over
  existing events.
- The Bit's escalation: tag engine emits the bonus as a `spectacle_points`-carrying
  event — scored by the existing generic hook, no HypeEngine change.

**Rough size:** comparable to hype engine v1 — ~250–350 engine lines + 10 data
entries + tests (determinism/state-hash round-trip; one unit test per detector;
resonance multiplication; rider escalate-and-reset; goal-row completion).

**New-surface accounting (the criterion):**
- New sim events required for detection: **0**. One tag (Formation) keys off the R15
  combined-action event the slice already owes Breach B; one (The Bit) is the
  documented `spectacle_points` authored-content hook doing its job.
- New consumers: 1 module (TagEngine) + a ~20-line HypeEngine resonance hook.
- New goal kinds: 3, all predicates over existing events, all optional/deferrable.
- New output events: 3 `tag_*` types (system outputs, mirroring `hype_*` — not
  detector inputs).

---

## Open questions for the owner

1. **The selection itself:** approve the 10 (Reckless, Gorefest, Blooper Reel, Scene
   Stealer, The Bit, Fan Favorite, Survivor, Craft Services, Formation, 3am Energy)?
   Near-miss swaps welcome — Menace and Visual are the strongest benched candidates,
   each with the recorded detector cost.
2. **Data landing:** sibling `data/tag_effects.json` (recommended — keeps the ported
   catalog pristine) or fill the 10 `tags.json` rows in place?
3. **Goal bias vs the v2 deferral:** pattern-2 `goal_modifier_weights` requires
   weighted goal selection, which R11 #14 explicitly deferred to v2 (v1 draws
   uniformly). Ship the slice with pattern-1 resonance only and park the bias fields,
   or pull minimal weighted draw forward now? (Recommendation: park it — resonance
   alone makes tags legible; weighting changes goal-RNG replay behavior.)
4. **Starting tags vs earned-live:** do the premades *start* tagged (Dario pre-tagged
   `the_bit`/`scene_stealer` as his broadcast persona) or does every tag get earned
   on camera during the slice (cleaner demo of the detector system; slower first
   session)? Lifecycle: full acquired→reinforced→faded ladder in the slice, or
   binary held/not-held with the 0–3 weight dial deferred?
5. **The three new goal rows** (Pratfall! / Body Block! / Zoomies!): approve adding
   to `crowd_goals.json` (numbers PLACEHOLDER), defer, or cut?
6. **Attribution convention:** bless same-batch attacker crediting (PROVISIONAL,
   extends R11 #14 attribution v1) as the detector standard until cross-referenced
   attribution v2?
7. **Can non-contestants hold tags?** The Incinedile column shows the boss
   *generating* detectable beats; a tagged boss ("What a Beaut" someday) would need
   the same ledger on enemies. Slice assumes contestants-only — confirm.
8. **The Bit's rider** is the set's single pattern-5 flagship (audit cap: ≤10
   catalog-wide). Approve the escalate-and-reset shape, or keep the slice 100%
   declarative and let riders wait for I-27?
9. **Tag descriptions:** engine and data need only the mechanical fields —
   confirmed acceptable that `description` stays empty until the rulebook docx text
   is ported (nothing in this proposal invents lore text)?

## RULED (owner, 2026-07-18) — status: APPROVED, build it

1. The 10-tag selection — **approved**.
2. Data landing — **`data/tag_effects.json`** (as recommended).
3. Weighted goal selection — **stays deferred** (v1 uniform draw; resonance only).
4. **Demo loadouts start with NO tags — everything is earned on camera.** (Lifecycle:
   binary held/not-held for the slice per the recommendation; the 0–3 weight ladder
   stays deferred — owner did not rule the ladder explicitly, inferred default.)
5. The three new goal rows (Pratfall! / Body Block! / Zoomies!) — **approved**
   (numbers PLACEHOLDER).
6. Same-batch attacker attribution — **blessed** as the detector standard until v2.
7. **Non-contestants do NOT hold tags** (boss generates beats, holds nothing).
8. The Bit — **approved with a HARD DESIGN CONSTRAINT: the signature action must add
   NOTHING but flavor.** It is not any normal action — no damage, no buff, no
   positioning value, nothing mechanical. The character chooses to do the bit despite
   it giving them zero benefit; spectacle is the only payout. The detector action must
   be mechanically null by construction.
9. `description` fields stay empty pending the rulebook text port — **approved**
   (scaffold: `docs/rulebook-tag-descriptions.md`).
