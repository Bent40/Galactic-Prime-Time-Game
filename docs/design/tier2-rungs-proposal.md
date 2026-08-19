# Tier-2 Skills — Their Own L1–5 Ladders (the nine unauthored results)

**Status: BLESSED (owner 2026-08-18: "Bless all ladders") — S1–S10 all approved as
written, with OQ1/OQ2 ruled in place.** The implementation wave is OPEN: the ladders
become `skills.json` rows + threshold rows and the [NEEDS] machinery lands in
dependency-ordered stories (names stay PROVISIONAL pending the owner's rename pass).

> **[IMPLEMENTATION STATUS — wave 1 landed 2026-08-19.]** The data import is DONE:
> all ten ladders are `skills.json` rows ids **51–60** (L1 = a-rung core, L2–4 =
> b–d `effects[]`, acquisition = the recipe/offer) + `skill_thresholds.json` L5 rows
> ids **93–102**; [NEEDS]-blocked rung content imported as authored text. Three
> ladders are ENCODED in `SkillBook`/`ActionResolver` (deliberately NOT in
> KNOWN_KEYS — acquisition-gated, keyword rulings pending):
> **S5 perfect_evasion** — a IMPLEMENTED (the `fused_evasion` arming: one forfeit,
> both defenses) · b IMPLEMENTED (both halves scale) · c IMPLEMENTED per OQ2 (the
> serialized `evasion` window record; same-attack re-roll rejected) · d IMPLEMENTED
> (the once-per-Clock negate beside save_severity, `negate_used_clock` serialized)
> · e DATA (threshold row 97).
> **S7 vice_grip** — a IMPLEMENTED (grip "any": hands OR bite through `_grip_unmet`;
> hold + the drag override) · b PARTIAL (the grip closes with a real Bleed wound on
> the held part + the standing per-Clock condition advancement carries it; the
> literal while-held per-reset re-application still [NEEDS] the Clock-reset rider —
> combat_sim's sweep, outside wave 1's footprint) · c DATA ([NEEDS] multi-hold) ·
> d IMPLEMENTED (drag 5 + grapple-Suffocation via the existing kind; a full jaw
> grip substitutes for both-hands at L4+, R9 caps uncut) · e DATA (row 99).
> **S10 phantom_grasp** — a IMPLEMENTED (the `sustained_channel` hold with grip
> "psychic"; R9 escape actions against it, contest = target Physique vs holder
> MIND per OQ1, `escape_holder_stat`; Exposed/drag/break-on-damage kept) · b
> IMPLEMENTED (range/drag rows) · c DATA ([NEEDS] collision damage) · d DATA
> ([NEEDS] multi-hold) · e DATA (row 102; [NEEDS] the suffocation hook for a
> channel hold).
> **S1–S4, S6, S8–S9: DATA-ONLY this wave** — rows carry the blessed content with
> [NEEDS] flags; undeclared keys resolve through the honest `strike` fallback.
> Tests: `tests/test_tier2_wave1.gd`.

> **[IMPLEMENTATION STATUS — wave 2 landed 2026-08-19.]** Two more ladders are
> ENCODED (same conventions: not in KNOWN_KEYS, magnitudes PLACEHOLDER R14):
> **S6 combat_medic** (ally_treatment extended) — a IMPLEMENTED (delay ANY
> condition on self or any ally within range; Triage's charge economy kept
> ALLY-only — self-treatment never burns a charge) · b IMPLEMENTED (delay/range
> rows) · c DATA ([NEEDS] freeze/arrest — a hold-open distinct from multi-Clock
> delay: blocking re-application advancement is engine machinery this wave did
> not build) · d IMPLEMENTED ([FROM row 6, Crush dropped]: the RESOLVE mode —
> full removal of one active Infection or Bleeding through ConditionEngine.treat's
> own gates, once per Clock via `treat_resolve_used_clock`, REJECTED while the
> condition drives a bleed-out — the lethal state is held, not cured; the batch-C
> no-HP structural pin holds and was updated honestly to the new source shape) ·
> e DATA (row 98 — the once-per-combat economy + the stabilize rider; the resolve
> PATH it needs now exists).
> **S1 counterscript** (fused_counter) — a IMPLEMENTED (the standing read on the
> pattern_reads substrate — Clock-reset expiry + the owner-gated view projection
> ride the existing sweeps — plus the WIDENED counter gate: no winding_up prime,
> the read is the whole prime; any declared action of the read target with
> remaining cost is answerable — a future windup (cut/collapse → Forced BODY) or
> a same-tick still-pending scheduled instant (collapses at its own slot). The
> honest boundary, stated: an action that already RESOLVED can never be countered
> — same-tick instants resolve in declaration order, so in practice the widened
> gate covers exactly the SCHEDULED remainder) · b IMPLEMENTED (deepened cut +
> the serialized per-source immunity window `counter_immunities` — the countered
> source cannot affect the counter-actor for the next 3 Moments [PH], enforced at
> the hit seams the way guard/dodge compose; others still affected) · c
> IMPLEMENTED (read_targets 2 at L3+ — a read past the cap replaces the oldest —
> + row 10's deeper queue reveal) · d DATA ([NEEDS] R15 combined-action hooks —
> cross-footprint) · e DATA (row 93; [NEEDS] boss win-condition telegraph
> exposure). Tests: `tests/test_tier2_wave2.gd`.
**How to answer: by number.** Skills are **S1–S10**; each skill's five rungs are lettered
**a–e** (a = L1 … e = L5). "S1–S7 yes, S8-c reword, S10 hold for OQ1" is a complete
answer. All names stay PROVISIONAL pending the owner's rename pass.
**Directed by:** decision-log **#34** (tiers ruled in) + **#35** (the by-number pass on
`docs/design/skill-tiers-proposal.md` — RULED; recipes M2–M8 + the three Q1 offers) ·
addendum **R31** (the shipped machinery). **Voice/format of record:**
`docs/design/skills-r19-ladders-FINAL.md` — these ladders are written to its house rules
(a rung buys a **new situation**, numbers `[PH]` per R14, chain discipline per default #4,
no HP/no full-cure per default #8, identity texture per `docs/audits/skills-audit.md`).
**Q3 note (decision #35):** tier-2 skills keep **short linear bands FOR NOW** and tier-3
merges will exist later — so these ladders stop at **L5 (the tier-2 mastery rung)** by
design. **No L6+ is authored here**; that band is deferred until the tier-3/content-growth
wave (iron_stance's L6 row, threshold id 90, is the existing precedent for what a tier-2
L6 looks like — deferred, not forgotten).
**Inputs:** `data/skill_mutations.json` (M2–M8 + M8's twin) · `data/mod_center_offers.json`
(the three BLESSED offers) · `data/skills.json` + `data/skill_thresholds.json` (the source
rows re-homed here) · `docs/design/skill-tiers-proposal.md` §3 appendix (the re-map) ·
`docs/audits/skills-audit.md`.

---

## 0. Conventions (all PROVISIONAL)

- **The iron_stance template.** Iron Stance is the shipped tier-2 precedent: its own
  L1–5 already exists (`skills.json` id 49 — L1 core + L2–4 effects + threshold L5, id
  89) and is **not re-authored here**. Every ladder below copies its shape: **L1 = the
  merged core** (both parents' identities fused into one skill that works on day one),
  **L2–4 = scaling** (the house `+N`-rows-as-totals precedent), **L5 = the tier-2
  mastery rung**.
- **Inherited threshold rows.** Each re-mapped row from the ruled proposal's §3 appendix
  lands at a specific rung, marked **[FROM row N]**, content kept faithful; the two
  ruled re-expressions (row 42 per default #2, row 16 per R25) and the two audit fixes
  (row 6 drops Crush, row 46 reworded) are flagged where they ride along. §2 verifies
  the count: **15/15 placed, nothing discarded.**
- **Mechanics honesty.** Every rung states whether it is expressible with TODAY's
  machinery (the `SkillBook` archetype named in parentheses) or needs new machinery,
  flagged **[NEEDS: …]** the way the ladders/audit docs flag engine needs. A [NEEDS]
  flag blocks nothing — results stay data-declared until their implementation pass.
- **Numbers.** Every magnitude `[PH]` (R14). Where a rung inherits a parent's authored
  magnitude, the placeholder is anchored to it ("≥ the parent's L5 value") so the tier-2
  never regresses below the consumed mastery.
- **Header lines** give PROVISIONAL stat/cost/cap frames derived from the
  identity-primary parent. All tier-2 caps are 5 (Q3). Acquisition = the named recipe or
  offer; never learnable directly.

---

## 1. The ten ladders

### S1 — Counterscript · physique / mind · 1 Moment · cap 5 · [TIER-2 · M2: Counter-Surge Lv 5 + Read The Pattern Lv 3]
**Identity.** You don't read the pattern and then counter — every declared action near
you is already an opening you answer.
**PROPOSED L1–5:**
- **a (L1) — the standing read & the scripted answer.** One skill, two uses that feed
  each other: hold Read the Pattern's read on one visible enemy (their scheduled
  action(s) until the Clock reset), and against **your read target** the counter's gate
  widens — any declared action with remaining cost can be countered, not only a 2+
  Moment windup; a connected counter cuts remaining cost by `[PH — ≥ the parent's L5
  cut]`, collapse → Forced Action — Body. *(intel_reveal declared_read +
  interrupt_counter, both shipped; the widened gate is the fusion —* [NEEDS:
  read-linked counter gate — interrupt_counter currently requires an executing 2+
  Moment action] *)*
- **b (L2) — the counter denies.** [FROM row 8] The cut deepens to `[PH — row 8's 5]`,
  and even if the countered action doesn't collapse, **it cannot affect you for the
  next 3 Moments** `[PH]` — you already answered it, so it simply misses you. *(row 8's
  two clauses kept whole —* [NEEDS: per-source immunity window on the actor] *)*
- **c (L3) — read the room.** [FROM row 10] The read holds on a **second enemy** at
  once, foreseeing more of their queue (`+[PH]` actions — row 10's "+4"); the counter
  answers either read target. *(intel_reveal already reveals N actions; the second
  concurrent read is a spec extension.)*
- **d (L4) — share the script.** Allies you tell gain position/first-strike against a
  revealed action (R15) — the read stops being private (the re-homed ladder #6 L7 rung;
  the tier proposal names it tier-2 material). *(view-layer reveal exists;* [NEEDS: R15
  combined-action hooks for the first-strike half] *)*
- **e (L5, mastery) — the whole fight is scripted.** Read a boss's discoverable
  **win-condition telegraphs**, not just scheduled actions (the re-homed ladder #6 L9 —
  the anti-damage-race tool), and a fully collapsed counter refunds the collapsed
  action's Moments to **you** as tempo `[PH]` (the re-homed ladder #5 L10 full
  reversal — mundane). *(*[NEEDS: boss win-condition telegraph exposure — must stay
  consistent with authored boss win conditions, the FINAL doc's standing
  cross-reference flag] *)*
**1–4 scales underneath:** cut magnitude and read depth, continuing both parents' L2–4
rows `[PH]`.

### S2 — Predator's Arc · physique / reflexes · 2–3 Moment [PH] · cap 5 · [TIER-2 · M3: Pounce Lv 5 + Decapitate Lv 3] · [CHAIN: opener]
**Identity.** The leap and the kill are one motion — the apex-predator takedown that
still opens/loops through Slip Through.
**PROPOSED L1–5:**
- **a (L1) — the merged core: leap onto the kill.** Leap up to `[PH — ≥ Pounce's L5
  reach]` spaces and strike on landing. The strike adapts to the opening: against an
  Exposed target struck from the **rear arc** (R30 `is_behind`) it targets the **Head**
  with Decapitate's bypass (Head → 0 = Cinematic Kill + Viewer spike); otherwise it is
  Pounce's torso Bleed `[PH]`. **Ruling-#4 authored chain seat, placed HERE:
  Predator's Arc counts as Pounce for Slip Through's chain gate** (−1 Moment, same
  target) — placed at L1 so a merged character never loses the chain her parents
  carried (she owned Pounce Lv 5 by definition). *(leap_strike + head_finisher both
  shipped —* [NEEDS: fused leap→conditional-finisher spec — one skill composing the
  two archetypes] *)*
- **b (L2) — the arc continues.** [FROM row 40] `+[PH]` Bleed (row 40's "+4"), and
  after the landing strike you **may chain into another Slip Through if a target is
  adjacent** — the takedown feeds the next takedown. *(the chain field already opens
  skills;* [NEEDS: post-resolve chain-open into a second target — the audit's
  self-chain plumbing, same hook] *)*
- **c (L3) — ambush from anywhere.** The leap may originate off a wall, an ally boost
  (R15), or from cover/concealment, and ignores difficult terrain and gaps under the
  arc (the re-homed ladder #20 L8–L9 texture — the aerial ambush). *(declare-position
  legality —* [NEEDS: vertical/boosted origin vocabulary; R15 hooks for the boost] *)*
- **d (L4) — the arc loops.** [FROM row 36] `+[PH]` damage, `+[PH]` space (row 36's
  +2/+2), and the Arc **may chain into itself up to 4 times at 1 Moment each** `[PH]`
  — the predator ricochets through the pack. *(*[NEEDS: self-chaining support on the
  chain field — the audit already flags this for the source row] *)*
- **e (L5, mastery) — the highlight-reel takedown.** Off the leap, behead/tear **any
  lethal part** of a **non-boss** Exposed target for a max Viewer spike `[PH]` — the
  re-homed ladder #22 L10, mundane lethality (the Cinematic-Kill fantasy, never an
  HP-bypass; boss bound kept). *(head_finisher's kill event + spectacle payout exist;
  the any-lethal-part widening is spec-level.)*
**1–4 scales underneath:** leap distance and Bleed, continuing both parents' L2–4 rows
`[PH]`.

### S3 — Earthbreaker · physique · 2–3 Moment [PH] · cap 5 · [TIER-2 · M4: Overhead Slam Lv 5 + Execution Lv 3] · [CHAIN: opener]
**Identity.** Down them and end them in a single gravity arc.
**PROPOSED L1–5:**
- **a (L1) — the merged core: one gravity arc.** Bring the full arc down for heavy
  Crush `[PH — ≥ the Slam's L5 output]`. The arc adapts to what it lands on: a
  **standing** target is knocked Prone (Exposed); a target **already Prone/Helpless**
  takes the execution payload instead (Torso → Shock T3; Head → instant death at 0 —
  Execution's authored core). You are Exposed during the wind-up. **Ruling-#4 authored
  chain seat, placed HERE: Earthbreaker counts as Overhead Slam for Shockwave's chain
  gate** — same L1 placement rationale as S2-a. *(committed_strike + downed_finisher
  both shipped —* [NEEDS: state-forked strike spec — one declare forking on the
  target's standing/downed state] *)*
- **b (L2) — the mass tells.** [FROM row 42 — **⚠ re-expressed per default #2**]
  `+[PH]` Crush delivered as **added force through the R14 force-vs-robustness gate**
  — the row's "ignores 3 Resistance" is a non-magic resistance-bypass and re-maps as
  force, not bypass (content kept, wording fixed — the same discipline that demoted
  Execution's draft L10). *(pure numbers — expressible now.)*
- **c (L3) — the arc closes in.** Close 1–2 spaces into the arc (movement absorbed),
  and any improvised heavy object serves as the weapon (the re-homed ladder #23 L8–L9
  texture) — the gravity arc opens from range and from scavenge. *(leap_strike's
  absorbed-move precedent; equipment gate widening is data.)*
- **d (L4) — the ground answers.** [FROM row 46 — audit rewording rides along]
  **Earthbreaker's impact triggers a free Shockwave centered on the target.**
  *(aoe_cone_strike shipped —* [NEEDS: action-triggers-action hook — a resolve-time
  free cast] *)*
- **e (L5, mastery) — fault-line.** The arc **guarantees the Shockwave chain**, the
  knockback becomes a wide stagger `[PH]`, and one arc may take **two adjacent downed
  targets** (the re-homed ladder #23 L10 + #25 L6 double-finisher, fused). Mundane
  throughout. *(*[NEEDS: multi-target finisher spec] *)*
**1–4 scales underneath:** Crush, continuing both parents' L2–4 rows `[PH]`.

### S4 — Vivisection · physique / reflexes · 3 Moment [PH] · cap 5 · [TIER-2 · M5: Slice n' Dice Lv 5 + Thousand Cuts Lv 3]
**Identity.** The complete shredder — many wounds on many parts, every wound worsening;
the bleed-out clock made a skill. *(Rename caution: the primary parent is a v2
display-rename skill — mechanics under sim keys, display names data-sourced, never baked
into flavor text.)*
**PROPOSED L1–5:**
- **a (L1) — the merged core: the shredding arc.** One crossing flurry: choose `[PH —
  3–4]` body parts across **one or two adjacent targets**, deal Bleed `[PH]` to each;
  any hit landing on an already-Bleeding part **advances that Bleed one tier** (both
  parents' bleed-advance identity, fused and unconditional — no all-3 gate).
  *(crossing_arc_strike + multi_part_flurry both shipped —* [NEEDS: one fused
  many-parts/many-targets spec — a parameterized union of the two archetypes] *)*
- **b (L2) — wider arc.** `+[PH]` parts and a 180° wrap — three targets stand in the
  arc (the re-homed ladder #43 L8 / #28 L6 crowd-shredder texture). *(target-count
  scaling — spec-level.)*
- **c (L3) — tier-2 bleeds.** [FROM row 80] The flurry's magnitudes rise `[PH — row
  80's +2 Torso / +1 limbs / 2-on-Head]` and its wounds **apply Bleed Tier 2
  instead**. *(ConditionEngine applies stated tiers today — expressible now.)*
- **d (L4) — venom coat.** A poison rider: each Vivisection wound counts as an **entry
  condition**, and a chosen wound seeds Poison T1 `[PH]` (the re-homed ladder #28 L7 —
  the many small wounds become doorways). *(poison application exists in aoe_blast;*
  [NEEDS: melee poison-rider spec field] *)*
- **e (L5, mastery) — the bleed-out clock.** Against an Exposed target, guarantee
  **multi-part Bleed T2** — an unignorable bleed-out + Viewer spike `[PH]` (the two
  parents' L10s — "cleaning this is a bother" and "death by a thousand cuts" — are the
  same fantasy; this is it, once). Mundane. *(expressible with today's condition
  machinery.)*
**1–4 scales underneath:** Bleed per cut and parts chosen, continuing the parents' L2–4
rows `[PH]` (thousand_cuts' L2–4 are themselves PROVISIONAL authored-at-implementation
rows — their magnitudes stay coupled).

### S5 — Perfect Evasion · reflexes · 0 Moment (movement forfeit, R25) · cap 5 · [TIER-2 · M6: Tactical Roll Lv 5 + Acrobatic Save Lv 3]
**Identity.** The whole evasion suite in one stance — dodge-move and forced-action save
fused; both halves stay R25 movement-forfeit-gated.
**PROPOSED L1–5:**
- **a (L1) — the merged core: one forfeit, both defenses.** Forfeiting your movement
  for the Moment (R25 — no stance, no charges, no cooldown) now arms **both** halves at
  once: the declared-hex roll (`[PH — ≥ the Roll's L5 range]` hexes; the R25 AoE-center
  rule applies) **and** the armed save (your next Forced Action — Body draws `+[PH — ≥
  the Save's L5 dice]` dice, keep the lowest severity). One price, the full suite.
  *(declared_dodge + forced_roll_save both shipped and both already priced by the same
  movement forfeit —* [NEEDS: a fused arming spec — one declare setting both states;
  small] *)*
- **b (L2) — farther, luckier.** `+[PH]` roll range, `+[PH]` save dice — the suite
  scales both halves together (the parents' L2–4 rows continued).
- **c (L3) — the second evasion.** [FROM row 16 — **⚠ re-expressed per R25**: the
  row's chain/cooldown wording is dead per G1/R3; **reading RULED by OQ2 (owner
  2026-08-18: "2nd roll 2nd attack")**] `+[PH]` roll range (the row's "+2 Space"
  kept), and **one movement forfeit now covers a SECOND roll: when a second
  distinct attack resolves against you in the same window, you may declare the
  hex-roll again against it** — two dodges from one forfeit, never two forfeits
  waived. *(the R25 plumbing exists;* [NEEDS: a small second-roll-this-window
  marker — serialized, hash-covered like `rolled_this_window`] *)*
- **d (L4) — the negation.** [FROM row 68] Once per Clock, **negate a Forced Action —
  Body outright** — the save stops softening the roll and vetoes it. *(a per-Clock
  gate, R3-legal — ForcedAction interception exists;* [NEEDS: negate path beside
  save_severity; small] *)*
- **e (L5, mastery) — untouchable.** Once per encounter, declare the perfect Moment:
  **every attack targeting you this tick is dodged** (the re-homed ladder #9 L10
  bullet time) **and** a Forced Action that would end the fight is auto-passed (the
  re-homed ladder #37 L10 clutch save) `[PH]`. Still movement-forfeit-priced, still
  mundane. *(*[NEEDS: tick-wide dodge window — a widened `rolled_this_window`] *)*
**1–4 scales underneath:** roll distance and save dice `[PH]`.

### S6 — Combat Medic · mind · 1 Moment · cap 5 · [TIER-2 · M7: Seal The Wound Lv 5 + Field Triage Lv 3]
**Identity.** The arena medic: anyone, anywhere, conditions held — delay/arrest/
stabilize only, **never HP, never a full cure of a lethal state** (default #8, kept at
every rung).
**PROPOSED L1–5:**
- **a (L1) — the merged core: one medic, whole party.** Treat **yourself or any ally
  within `[PH — 2 spaces, Triage's L5 reach]`**: delay **any** condition's advancement
  by `[PH — ≥ Seal's L5 Clocks]` (Seal's self+Bleeding/Infection lane and Triage's
  ally+any-condition lane, fused into one skill); ally treatment still consumes a
  bandage/kit charge (Triage's economy kept). *(ally_treatment shipped with both
  carriers — the fusion is one spec carrying self_allowed + any-condition + range;
  expressible now.)*
- **b (L2) — deeper reserves.** `+[PH]` Clocks of delay, `+[PH]` range — the parents'
  L2–4 rows continued.
- **c (L3) — arrest, don't cure.** Hold one condition **frozen (no advancement) for
  `[PH]` duration** rather than only delaying its next tick — deeper management, still
  not a cure and never HP (the re-homed ladder #3 L7). *(*[NEEDS: freeze/arrest mode
  in ConditionEngine — delay exists, hold-open doesn't] *)*
- **d (L4) — resolve the treatable.** [FROM row 6 — **audit fix rides along: Crush
  dropped** (Crushed is structural damage, not a treatable condition)] Fully **resolve
  one active Infection or Bleeding** condition `[PH — once per Clock]`. Boundary kept
  honest: this clears a condition instance — it never restores HP and never touches a
  lethal state (default #8's line is HP/lethal, and this row is the ruled exception
  the re-map carries for conditions). *(*[NEEDS: condition-resolve path in
  ally_treatment — the shipped resolver mode is DELAY ONLY by design; this rung is
  where the resolve path gets built] *)*
- **e (L5, mastery) — triage supremacy.** [FROM row 88] **Once per combat, fully
  resolve ANY one condition instead of delaying** — the fused medic's signature (the
  ruled proposal: big enough that it should cost a merge). And the stabilize texture
  rides with it: delaying a downed ally's lethal condition returns them
  **0-HP-stabilized per R5** — alive, held, not healed (the re-homed ladder #3 L10;
  no HP restored, the lethal state is held, not cured). *(same [NEEDS] as d.)*
**1–4 scales underneath:** delay Clocks and treatment range `[PH]`.

### S7 — Vice Grip · physique / reflexes · 1 Moment (R9 initiate) · cap 5 · [TIER-2 · M8: Pressure Hold Lv 5 + Death Grip Jaws Lv 3 — **and** the twin vice_grip_animal: Jaws Lv 5 + Hold Lv 3]
**Identity.** The perfected hold regardless of anatomy — hands, jaws, whatever you have
(R9 size/boss caps uncut). **One ladder, both recipes:** the mirrored animal-side twin
yields the SAME result key, so every rung below is written grip-neutral — "the grip"
means whichever anatomy initiated it.
**PROPOSED L1–5:**
- **a (L1) — the merged core: the grip that fits the body.** Grapple with hands **or**
  jaws — the R9 grip gate is satisfied by either anatomy, one skill for every body
  plan. While held: the standard R9 hold (no reposition, both Exposed) plus drag up to
  `[PH — ≥ the Hold's L5 drag]` spaces per Moment (the deliberate R11.7 override the
  audit words: "overrides the grapple movement lock"). *(skill_grapple shipped — spec
  "grip" already parameterizes hands/bite; the fusion is a grip:any value; expressible
  now.)*
- **b (L2) — the grip wounds.** [FROM row 86] The held part takes **1 Bleed at each
  Clock reset** `[PH]` — the grip itself is a weapon now, whichever anatomy holds.
  *(ConditionEngine per-Clock advancement exists;* [NEEDS: a held-part Bleed-on-reset
  rider; small] *)*
- **c (L3) — control two, or pin a limb.** Hold **two adjacent targets** at once, or
  lock a single target's chosen limb (disabling its actions) `[PH]` (the re-homed
  ladder #7 L6). *(*[NEEDS: multi-hold / limb-pin state — held_by is single-link
  today] *)*
- **d (L4) — the squeeze.** [FROM row 12 — the audit reword rides along: no 1-Clock
  kill promise] Drag rises to `[PH — the row's 5]` spaces per Moment, **or the grip
  may begin grapple-Suffocation (R9 gates apply)** — both grappler hands / a full jaw
  grip and a coverable airway required; **bosses and anything ≥2 sizes larger stay
  immune** (R9 uncut — boss wins are discovered, not choked). *(suffocation timers
  exist;* [NEEDS: grapple-suffocation start hook honoring the R9 gate set] *)*
- **e (L5, mastery) — the apex hold.** Initiate on targets up to Elite scale the base
  Physique gate forbade `[PH]` (the re-homed ladder #7 L9, still bounded by R9's size
  caps for Suffocation), and any hold may **end in the body-slam finisher**: release
  for Crush to Head/Torso + knock Prone (Exposed) — a Cinematic-Kill candidate `[PH]`
  (the re-homed ladder #7 L10). *(*[NEEDS: end-hold strike spec] *)*
**1–4 scales underneath:** drag distance and grip strength, continuing both parents'
L2–4 rows `[PH]`.

### S8 — The Unseen · reflexes / mind · 3 Moment [PH] · cap 5 · [TIER-2 OFFER: Camouflage Lv 5 + Nightlurking Lv 3 — broad-only `infiltration`, blessed 2026-08-18]
**Identity.** The ghost and the prowler fuse: not hidden-in-place, not moving-unseen —
simply not there until it chooses to be. *(No inherited rows — both parents' L6 rows
stay linear on the parents; these five rungs are authored fresh from the fused
identity.)*
**PROPOSED L1–5:**
- **a (L1) — the merged core: concealment that moves.** Enter concealment (the R20
  substrate: an override reveal radius `[PH — ≤ the parent's L5 radius]` capping every
  observer's sight) — and **slow movement no longer breaks it** (only fast movement or
  attacking does). The prowler's sense rides along always-on: you know the nearest
  exit/gap/vent in any room, and squeeze through Small-plausible gaps without a Forced
  Action. *(stealth_conceal shipped BUT hex-anchored — any displacement breaks it
  today —* [NEEDS: moving concealment — lift the anchor for slow movement] *; and*
  [NEEDS: nightlurking's awareness/squeeze passive — not in SkillBook yet] *)*
- **b (L2) — harder to find.** `−[PH]` reveal radius, `+[PH]` awareness range — both
  parents' L2–4 rows continued.
- **c (L3) — vanish through.** Use a detected gap/vent **without breaking
  concealment** — enter and leave rooms unseen; emerging from a gap onto an unaware
  target Exposes them `[PH]` (the fused traversal-into-ambush — the prowler's routes
  serving the ghost's strike). *(R20 + R29 room graph exist;* [NEEDS:
  concealment-preserving room transition] *)*
- **d (L4) — the second shadow.** Conceal **one adjacent ally** under your cover, or
  leave an afterimage/decoy at your last position when you move `[PH]` — the room
  watches the wrong shape. *(*[NEEDS: ally-conceal link; decoy entity] *)*
- **e (L5, mastery) — simply not there.** Once per scene, choose: **vanish in place**
  (effectively invisible until you act, even at adjacency) or **be already gone**
  (declared relocation to any known opening you've sensed) `[PH]`. Mundane stealth —
  no radiant/psychic tier (the two parents' L10s, fused into one choice). *(*[NEEDS:
  relocation toggle; the vanish half is the conceal override at radius 0] *)*
**1–4 scales underneath:** reveal radius down, awareness range up `[PH]`.

### S9 — The Long Con · reflexes / charm · 1 Moment · cap 5 · [TIER-2 OFFER: Feint Lv 5 + Vibe Control Lv 3 — broad-only `performance`, blessed 2026-08-18]
**Identity.** The combat misdirection and the crowd's mood fuse into one sustained
deception: the fight you show them was never the fight you were having. *(No inherited
rows — authored fresh. Rename caution: the secondary parent is a v2 display-rename
skill; no old display name appears in any rung text.)*
**PROPOSED L1–5:**
- **a (L1) — the merged core: declare the con.** Project a false read of your intent at
  `[PH — 1–2]` targets who can **perceive you** (Vibe Control's perception gate, R30
  cone): while the con holds, each affected target's next action **against you**
  becomes a Forced Action — Tool (Feint's inflicted fumble, made ambient), and each
  time it fires you may reposition 1 space at no cost `[PH]`. *(setup_debuff +
  projection_control both shipped —* [NEEDS: a sustained multi-target misdirection
  status — the con as a serialized state, not a one-shot debuff] *)*
- **b (L2) — sell it wider.** `+[PH]` targets, `+[PH]` range, `+[PH]` die manipulation
  on the inflicted roll (the parents' L2–4 rows continued).
- **c (L3) — pick the fumble.** Choose the inflicted result per target: **Tool** (the
  fumble) or **Body** (the stumble — Exposed) `[PH]` (the feint ladder's authored
  fork). *(the parameterized collapse table exists — expressible now.)*
- **d (L4) — the con pays the crowd.** While the con holds, the deception is also a
  performance: hype ticks accrue and **Charm scales the payoff** `[PH]` (R18 —
  presentability as the audience economy; the show half of the fused identity).
  *(HypeEngine shipped —* [NEEDS: a con-duration hype hook; small] *)*
- **e (L5, mastery) — the reveal.** Spoof one target's **whole next-Clock plan** —
  they act as if you're where you aren't `[PH]` (the re-homed feint ladder L10, total
  misdirection, mundane) — and when you break the con with a strike, the reveal IS the
  show: a Viewer spike scaled by Charm `[PH]`. *(*[NEEDS: AI misdirection hook — the
  spoofed-position plan; the spike half is HypeEngine] *)*
**1–4 scales underneath:** targets, range, dice `[PH]`.

### S10 — Phantom Grasp · mind · 1 Moment + sustain · cap 5 · [TIER-2 OFFER: Telekinesis Lv 5 + Pressure Hold Lv 3 — broad-only `control`, blessed 2026-08-18]
**Identity.** The hold without the hands: the grapple discipline projected through
psychic force — a pin at range. R9's boss/size Suffocation caps ride along uncut. *(No
inherited rows — authored fresh. **OQ1 RULED (owner 2026-08-18): mundane-PSIONIC,
not magic — no magic privileges ever on this band; escape contest = target's
Physique vs the holder's MIND.**)*
**PROPOSED L1–5:**
- **a (L1) — the merged core: the phantom hold.** Grip one visible target at `[PH — ≥
  Telekinesis' L5 range]`: the grip is a **hold**, not just a lift — the target cannot
  reposition (R9's lock at range), escape per R9's escape actions — **contest: target's
  Physique vs the holder's MIND (OQ1 ruled)**. The sustain occupies your scheduled action each Moment and may drag the
  target `[PH]` spaces (the trained hold replaces raw lifting). You are Exposed while
  sustaining (the parent's base; its L6 un-Exposed row stays linear on Telekinesis —
  not inherited here). *(sustained_channel shipped with held_by movement-lock — most
  of this rung exists;* [NEEDS: a "psychic" grip value on the R9 gate set — the
  escape contest is ruled (Physique-vs-Mind), only the gate plumbing remains] *)*
- **b (L2) — longer reach, harder grip.** `+[PH]` range, `+[PH]` drag — the parents'
  L2–4 rows continued.
- **c (L3) — constrict and hurl.** While held: Crush-over-time to a chosen part
  `[PH]` (the squeeze, at range), **or** hurl the held target `[PH]` spaces — collision
  Crush to them and anything they hit (the re-homed telekinesis ladder L7 texture
  through the grapple frame). *(*[NEEDS: forced-movement collision damage — the
  standing forced-movement need] *)*
- **d (L4) — many hands.** Hold **two targets** at once at reduced drag, or pin a
  single target's chosen limb `[PH]` (the re-homed telekinesis L8 / pressure_hold L6
  texture, fused). *(same multi-hold [NEEDS] as S7-c.)*
- **e (L5, mastery) — close the airway.** Initiate on targets up to Elite scale
  `[PH]`, and the phantom grip may **begin grapple-Suffocation** — the "both grappler
  hands + coverable airway" requirement met by the two-handed phantom grip `[PH
  gate]`; **R9's caps uncut: bosses and anything ≥2 sizes larger are immune** — no
  hold, phantom or physical, chokes out a boss. *(psionic per OQ1 — the phantom
  two-handed grip satisfies the requirement mundanely, no magic reading needed;*
  [NEEDS: S7-d's suffocation start hook] *)*
**1–4 scales underneath:** range and drag `[PH]`.

---

## 2. The inherited-row placement ledger — 15/15, verified

The ruled proposal's §3 appendix marks **15 threshold rows BECOMES-TIER-2-RUNG**
(verified against `data/skill_thresholds.json`: ids 6, 8, 10, 12, 14, 16, 36, 40, 42,
46, 68, 80, 84, 86, 88). All 15 are accounted for — **13 placed at specific rungs in
§1, 2 already realized by the shipped Iron Stance ladder** (cited, not re-authored):

| row id | source (L6) | content gist | lands at |
|---|---|---|---|
| 8 | counter_surge | cut 5 + "doesn't affect you 3 Moments" | **S1-b** |
| 10 | read_the_pattern | +4 actions, second enemy | **S1-c** |
| 36 | pounce | +2/+2, self-chain ×4 at 1 Moment | **S2-d** |
| 40 | decapitate | +4 Bleed, chain to another Slip Through | **S2-b** |
| 42 | overhead_slam | +4 Crush, ignores 3 Resistance | **S3-b** ⚠ re-expressed (default #2 — force, not bypass) |
| 46 | execution | impact triggers a free Shockwave | **S3-d** (audit rewording rides along) |
| 80 | slice_n_dice | +2/+1/+2, Bleed Tier 2 instead | **S4-c** |
| 16 | tactical_roll | +2 space, twice per chain | **S5-c** ⚠ re-expressed (R25 — chain/cooldown wording dead) |
| 68 | acrobatic_save | negate Forced — Body once per Clock | **S5-d** |
| 6 | seal_the_wound | resolve Infection, Bleed or Crush | **S6-d** (audit fix rides along — Crush dropped) |
| 88 | field_triage | once per combat, fully resolve | **S6-e** |
| 12 | pressure_hold | drag 5 / begin suffocation | **S7-d** (audit reword — R9 gates, no 1-Clock kill promise) |
| 86 | death_grip_jaws | held part 1 Bleed per Clock reset | **S7-b** |
| 14 | brace | reduction extends to Bleed/Chill | **M1 Iron Stance — ALREADY SHIPPED as its L4 effect** (`skills.json` id 49; the re-map mechanism's live proof) |
| 84 | intercept | guard two allies | **M1 Iron Stance — SUBSUMED by its shipped L1 core** (the stance retargets attacks on ANY adjacent ally — strictly ≥ "guard two"; +L3 widens the radius) |

The three offer results (S8–S10) inherit **no** rows by ruling — their parents' L6 rows
stay linear on the parents (the parents are LINEAR-stamped; consuming them via the
offer is the build choice, exclusive with walking their own bands).

## 3. Consistency checks — done and reported

1. **Chain-gate inheritances placed** (ruling #4 authored seats): Predator's Arc counts
   as Pounce for Slip Through at **S2-a**; Earthbreaker counts as Overhead Slam for
   Shockwave at **S3-a**. Both at L1, deliberately: a merged character owned the parent
   at Lv 5 by recipe minimum — a later seat would strip a chain she already had, which
   would be the only regression in the model. Flagged PROVISIONAL like every placement.
2. **Combat Medic never heals**: every rung is delay/arrest/resolve-a-condition; no
   rung touches HP or a lethal state (default #8). The resolve rungs (S6-d/e) carry
   the ruled row content faithfully with the boundary stated in place.
3. **Perfect Evasion stays R25-gated**: every use of either half is priced by the
   movement forfeit; S5-c (RULED by OQ2) stretches one forfeit to a second roll
   against a second attack in the same window — the forfeit itself is never waived.
4. **Vice Grip keeps R9's caps at every rung** — suffocation gates apply at S7-d and
   the size caps bound S7-e; Phantom Grasp repeats them verbatim at S10-e.
5. **No lore invented**: every identity line is the ruled proposal's / the blessed
   offers' own wording; every rung's fiction is the parents' authored ladder texture
   re-homed, per the tier proposal's stated intent (e.g. #42's "ladder L7/L9 become
   tier-2 rungs", #20's combo-enabler arc).
6. **Rename hygiene**: no v2-renamed display name is baked into any rung text
   (S4 / S9 flagged); sim keys only.
7. **No data or sim edits** — this document is the owner-review artifact only. On
   blessing, S1–S10 become `skills.json` rows + threshold rows and the [NEEDS] list
   becomes the implementation story's checklist.

**Honesty caveats.** (a) Rung placements and all magnitudes are proposals — PLACEHOLDER
per R14, anchored to the parents' authored values but untested; (b) nothing here was
play-verified — no sim run was needed or performed for this design artifact; (c) the
[NEEDS] flags are engine-need estimates read from `simulation/skill_book.gd`'s shipped
archetype set, not scoped stories; (d) the S2-a/S3-a L1 chain seats are my authoring
call within ruling #4's discipline — the owner can move them by letter.

---

## 4. Open questions for the owner (only what the data cannot decide)

- **OQ1 — RULED (owner 2026-08-18: "psionic, not exactly magic. Your read is
  correct.").** Phantom Grasp is **mundane-psionic** — no magic privileges, no
  source-gated transcending tier ever on its band. The escape contest is the
  confirmed natural reading: **target's Physique vs the holder's MIND** (the R9
  contest shape with the holder's stat swapped). S10-a/e implement accordingly.
- **OQ2 — RULED (owner 2026-08-18: "2nd roll 2nd attack").** Row 16 re-expresses as
  a **second roll against a second attack in the same window** — one movement
  forfeit arms the defenses; when a second distinct attack resolves against you in
  the same window, you may roll the declared-hex dodge a second time against it.
  The forfeit-waiver draft reading is retired; S5-c is re-authored to this ruling.
