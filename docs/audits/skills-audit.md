# Skills Audit — all 44 seeded skills + 82 threshold rows

**Date:** 2026-07-17 · **Scope:** `data/skills.json` (44 rows), `data/skill_thresholds.json`
(82 rows) · **Judged against:** `docs/rules-addendum.md` (R3 no-cooldowns/priming, R10
requirements gate, R14 damage quantization, R15 combined actions, R16 races/backgrounds,
R18 Charm=presentability), `docs/gdd/gdd.md` §Game Mechanics + §RPG Specific,
`docs/design/patron-gods.md` (epithets are a separate track — no overlap found),
`docs/characters/nikita.md` + `sasha.md`, and the engine surface in
`simulation/action_resolver.gd`.

**Method & honesty:** both JSON files parse clean (verified with Python; 44 + 82 rows as
claimed). All 44 skills audited individually — no sampling. Field-set uniformity,
threshold coverage, cooldown mentions, and stat-requirement population were verified by
script, not by eye. Damage/HP numbers are NOT judged for balance — R14 rules all numbers
placeholders; only *structural* number problems (contradictions, undefined units, scale
outliers) are flagged. Where a claim depends on a system that doesn't exist yet (zones,
stealth, enemy AI moods), it is flagged as an epic dependency, not a defect.

---

## 0. Template conformance — the headline finding

Every one of the 44 rows carries the **identical 17-field template**
(id, key, name, description, primary_stat, secondary_stat, stat_requirements,
base_moment_cost, default_cap, is_magic, is_passive, requirements, range, target, effect,
unlock_requirements, effects[]). **No missing or extra fields anywhere.** The conformance
problem is *content-level*, and it is severe:

1. **`stat_requirements` is `{}` on all 44 rows** while 23 skills carry stat gates as
   freeform prose in `requirements` ("Mind 3.", "Physique 4, Reflexes 3."). The engine's
   R10 requirements gate (`_requirements_unmet` in `action_resolver.gd`) reads the
   structured dict — **as seeded, no skill can ever trigger the halving + Tool-d6 gate.
   R10 is dead code for the entire catalog.** This is the single highest-value mechanical
   fix: a parse-and-populate pass is nearly free (the prose is regular).
2. **`exclusive_to` is absent from every row** even though `scripts/validate_seeds.py`
   already validates it when present (line 213) and three assignments are canon:
   `reversion` → nikita (R12/nikita.md), `full_potential` + `heroic_punch` → Mario (R12).
3. **`range` and `target` are freeform** with 14 distinct range spellings including
   `"2 "` (trailing space), `"3 Spaces"` vs `"3"`, and the undefined distance words
   `"Near"` / `"Far"` (R10-B8 says all distances are hex spaces — these two have no
   number).
4. **All 44 rows have `default_cap: 5`** yet thresholds run L5–L7 — coherent only via the
   R16 cap-trade rule (+1 cap per given-up background skill); worth a doc note, not a bug.
5. **Growth data lives on three conflicting surfaces:** `effects[]` (L2–4), threshold rows
   (L5+), and inline "Level 6+:" prose inside `effect` (5 skills). Three of those five
   inline texts contradict or duplicate their own L6 threshold row (see table).

**Threshold coverage (82 rows):** 39/44 skills have exactly L5+L6. Anomalies:
`strong_strike` (id 4), `telepathy` (18), `thousand_cuts` (28) have **zero threshold rows
AND empty `effects[]`** — no growth at all; `vibe_control` (31) has L5 only;
`juggling` (32) uniquely has L5+L6+L7. Seven threshold rows carry placeholder names
("Threshold 5"/"Threshold 6": ids 12, 54, 57, 62, 64, 75, 77).

---

## 1. Verdict table (all 44)

Verdicts: **KEEP** (as-is) / **FIX** (small field/text repair, exact fix given) /
**REWORK** (design misfit, direction given) / **OWNER-CALL** (plausibly deliberate —
owner decides) / CUT (none earned it). "SR→" = move the prose stat gate into
`stat_requirements` (the systemic §0.1 fix; listed explicitly per row).

| key | verdict | issues | proposed action |
|---|---|---|---|
| `controlled_sweep` | KEEP | Freeform reqs ("Melee weapon equipped. At least 2 Mobs adjacent.") await the global enum pass; engine-expressible today (compile as attack with `rpm`=target count, weapon damage inherited). Thresholds L5/L6 coherent. | None beyond the global requirement-enum pass (equipment:melee, adjacent_enemies≥2). |
| `quick_step` | FIX | "+1 Duration" (L2–4) and "+4 Duration" (L5) have no unit; L6 "Ignore Physical terrain effects" vague vs "difficult terrain movement penalty". | Define unit: "Duration" = Moments the terrain-ignore persists. Reword L6: "also ignore damaging/hindering floor effects (not walls)". Enum req: `has_free_move`. |
| `seal_the_wound` | FIX | Core support skill and Nikita-kit member — shape is right (delay = R4 vocabulary). L6 threshold "Resolve Infection, Bleed **or Crush**" — Crushed is structural damage, not a treatable condition; field-resolving it contradicts the R4/R10 treatment model. | Change L6 (threshold id 6) to "Resolve Infection or Bleeding". Enum req: `condition_active(bleeding|infected, self_or_adjacent)`. |
| `strong_strike` | FIX | Cleanest engine mapping in the file (2-cost windup, +1 weapon damage, Exposed — exactly R2). But **zero growth**: empty `effects[]`, no threshold rows. | Author L2–4 effects (+1/+2/+3 damage is the house pattern) and L5/L6 rows (e.g. L6: windup cannot be interrupted by Shock T1). |
| `counter_surge` | FIX | Interrupt that reduces an in-flight windup's remaining cost — no engine hook exists for rescheduling a queued action (clean addition to `Clock`); it is reaction-shaped but the schema has no trigger/reaction field; L5 "reduce by 5" trivially collapses every windup (placeholder per R14, still flag). | Add `trigger` field (`enemy_windup_adjacent`); engine task: windup-reschedule/collapse hook (collapse already routes to Forced Action — Body per text, matches d6 system). SR→ none (no stat gate). |
| `read_the_pattern` | KEEP | Reveal an enemy's next scheduled action — the Clock literally stores this; deterministic-engine-native intel. "+N Action" effects terse but coherent. "Visible" needs the LOS system (KAN-5). | None; note LOS dependency. |
| `pressure_hold` | FIX | Grapple skill that drifts from R9/engine: costs 2 (R9 initiate = 1 Moment), requires "both hands" (R9: one free hand; both only for suffocation), thresholds "N Movement space per moment" contradict the two-sided lock (R11.7 — grappler can't reposition); L6 "suffocate target within 1 clock" collides with the suffocation-timer model + boss immunity. | Align base to R9 (cost 1, 1 hand; suffocation upgrade requires both). Reword thresholds as a deliberate override: "may drag the hold N spaces per Moment (overrides the grapple movement lock)". L6: "may begin grapple-suffocation (R9 gates apply)" instead of a 1-Clock kill promise. |
| `brace` | KEEP | 0-cost typed damage reduction (next Crush/Burn −1) — expressible as a one-hit resistance status; Nikita-kit member; L6 extension to Bleed/Chill coherent. | None beyond global enum pass (`can_react`). |
| `tactical_roll` | FIX | **Stale R3 violation:** "Cooldown: 1 Clock" in requirements; L3/L4 "-2 Moment cooldown"; L5 "-4 Moment cooldown"; L6 "twice per cooldown Rotation" (threshold ids 15–16). Reaction-shaped, no trigger field. | Priming rewrite — proposed prime: **"Light Feet: gain a Roll charge when you take a free move; hold max 1"** (movement primes the dodge; kiting cost stays real). Levels upgrade spaces + max held charges (replaces the cooldown-reduction ladder). Add `trigger: attacked_self`. |
| `poison_ball` | FIX | Solid AoE mapping (controller expands radius→targets, `poison_type` field exists in engine). "Requires an entry condition on each target" is the poison system's real rule — keep. SR→ `{mind:3}`. | Move stat gate; declare area as structured field (`area_radius: 3`). |
| `poison_wall` | FIX | Persistent zone — **no zone/terrain entity in the sim yet** (combat-fields sketch is the natural home; flag, don't block). Skill-prereq "Poison Ball Lv 3" is freeform. SR→ `{mind:3}` + structured `skill_prereq: {poison_ball: 3}`. | Move gates to structured fields; tag `needs: zone-entities`. |
| `frost_ball` | FIX | Fine (typed chill damage + Chilled T1 = R4-native). SR→ `{mind:2}`. | Move stat gate; `area_radius: 2`. |
| `frost_wall` | FIX | Internal contradiction: target says "line, up to 5 spaces", effect says "up to 6 spaces long". Typo: "Burn damage destroys deals twice as much." Wall = destructible entity with HP (zone system + entity HP — not in sim). L6 "healed with chill damage" coherent & charming. | Fix 5-vs-6 (pick 5); typo → "Burn damage deals double damage to the wall." SR→ `{mind:3}`; tag `needs: zone-entities`. |
| `fire_ball` | FIX | "Burn Tier 1 to the body part **facing the blast**" — the engine has no facing; unresolvable as written. "Flammable objects ignite" needs terrain tags (KAN-5, fine). SR→ `{mind:2}`. | Reword: "to one exposed body part (defender's torso if none)". Move stat gate; `area_radius: 3`. |
| `fire_wall` | FIX | Zone dependency (as poison_wall). "Cannot be destroyed — only outlasted" fine. SR→ `{mind:3}`. | Move stat gate; tag `needs: zone-entities`. |
| `elemental_confluence` | FIX | The unlock (consume three L5 skills at the Skill Gemstone) is priming-era progression done right, and the per-Clock mode choice fits the R1 Clock-reset beat. Needs zones + a sustained per-Clock choice hook. "Skill Gemstone" vocabulary should land in a glossary. SR→ `{mind:4}` + `skill_prereq` + `consumes_skills`. | Structure the unlock (`consumes: [poison_ball@5, frost_ball@5, fire_ball@5]`); tag `needs: zone-entities, per-clock-choice`. |
| `telekinesis` | FIX | Sustained channel (pay per Moment, can't move, Exposed) — no sustain support in resolver (windup ≠ sustain); forced movement of targets — no push/pull primitive. **Inline "Level 6+: may move 1 space while sustaining" conflicts with threshold L6 row "no longer exposed"** — two different L6s. SR→ `{mind:3}`. | Reconcile L6: fold the inline text into the threshold row (or make one L6, one L7 — juggling already sets an L7 precedent). Tag `needs: sustain, forced-movement`. |
| `telepathy` | REWORK | No growth at all (empty effects[], zero thresholds) despite inline "Level 6+" prose; secondary_stat charm fails R18 (a mind-link gated on *presentability* is incoherent — this read charm as social charisma); almost everything it does (wordless comms, surface thoughts, implanted ideas) is dialogue/social-layer, not sim. | Direction: drop charm (secondary → null, pure Mind); rebuild as the party's **silent-comms + intel skill** (mechanical hooks: read an enemy's AI stance like `aura_reading`+, enable Propose-a-Plan steps without adjacency, chat-channel range extension for Sasha synergy); author a full L2–L6 ladder; "Mind 4+ notices" stays as the counterplay. |
| `mind_burst` | FIX | Direct-tier Shock + escalate-if-shocked = **exactly the R13 model** — best condition-system citizen in the file. Head-targeting bypass ("regardless of Exposure") needs a small engine flag (head gate currently hard-rejects). SR→ `{mind:4}` + `skill_prereq: {telepathy: 3}`. | Move gates; add `bypass_head_gate: true` action field (engine: one-line check in `_validate_attack`). |
| `pounce` | FIX | Sasha-kit gap-closer; CHAIN mechanic (opens Slip Through at −1) is **priming avant la lettre** — chains are exactly requirement-shaped primes (R3). Movement absorbed into the skill = controller compiles move+attack. L6 "chain pounce with itself up to 4 times" — fun, needs the chain field to support self-chaining. SR→ `{physique:3, reflexes:2}` + equipment enum (`light_small_weapon: claws|knife`). | Move gates; formalize `chain_opens: [{skill: slip_through, discount: 1}]`. |
| `slip_through` | FIX | Chain member; size gate "larger than you (Elite or Boss scale minimum)" conflates **category** (Mob/Elite/Boss) with **size** (Small/…/Huge, R7-B6) — seed data has both; engine compares `size_rank()`. SR→ `{reflexes:3}` + `skill_prereq: {pounce: 3}` + `chain_from: pounce`. | Reword gate to sizes: "target at least one size larger" (`size_gap>=1`); structure the chain. |
| `decapitate` | FIX | Chain finisher; "Cinematic Kill — 1 Viewer spike" is the broadcast frame working perfectly. Needs the same head-gate bypass flag as mind_burst (text even justifies it: "Slip Through created the opening"). SR→ `{physique:4, reflexes:3}` + prereqs + `chain_from: slip_through`. | Move gates; `bypass_head_gate: true`; structure chain. |
| `overhead_slam` | FIX | Chain opener; knock-Prone = status the engine has. Equipment gate freeform ("Heavy Large Weapon"). SR→ `{physique:4}`. | Move gates; equipment enum `heavy_large_weapon`; `chain_opens: shockwave`. |
| `shockwave` | FIX | Cone AoE (controller-expandable) + **knockback 1 space** — no forced-movement primitive in the sim (same need as telekinesis). Forced Action on Mobs = native. SR→ `{physique:4}` + prereq + chain. | Move gates; tag `needs: forced-movement`; structure chain (L6 "circle instead of cone" needs the area-shape field). |
| `execution` | FIX | Chain finisher vs Prone/Helpless — targeting gates all engine-native (Prone⇒Exposed, Helpless part-targeting per R7). "Head 0 HP = instant death" is redundant with R5 (fine). L6 threshold "Shockwave from Execution activates Shockwave automatically" is circular wording. | Reword L6 (threshold id 46): "Execution's impact triggers a free Shockwave centered on the target." SR→ `{physique:5}` + prereqs + `chain_from: shockwave`. |
| `feint` | FIX | Imposes Forced Action — Tool on the *enemy's* next action — engine rolls d6 tables, needs an "inflicted forced action" hook (small). Charm secondary: **borderline under R18** but re-readable (the feint *sells an image* — presentability as deception surface); flag for owner's R18 sweep, don't change unilaterally. "+1 Die. You choose result" matches the acrobatic_save die vocabulary. SR→ `{reflexes:3, charm:2}`. | Move gates; add inflicted-forced-action hook; note R18 re-read. |
| `pressure_strike` | FIX | Chain member, clean. "Still suffering Forced Action consequences from Feint" needs a queryable "recently forced" flag (small state addition). SR→ `{reflexes:3, physique:2}` + prereq + chain. | Move gates; structure chain (`chain_from: feint`, `chain_opens: thousand_cuts`). |
| `thousand_cuts` | FIX | Chain finisher with **zero growth** (empty effects[], no thresholds — one of the three). Range "Near" undefined (R10-B8: spaces are hexes — give it a number). Multi-part targeting (3 parts, 1 Bleed each) maps to `targets[]` with 3 part entries + action `rpm:3`. Bleed-advance rider is R4-native. | Author effects[] + L5/L6 rows; range → `1` (or `2`); SR→ `{reflexes:4}` + prereqs. |
| `aura_reading` | FIX | Passive emotional read — requires enemy AI to *have* moods; deterministic v1 AI can expose a stance enum (aggressive/defensive/fleeing/desperate) — map "emotion" to AI stance and it's engine-honest. `is_passive:1` yet has range/target and an active read pattern — flag semantics (always-on aura within range fits passive; keep). L6 "reveals lying" = dialogue layer (KAN-6+). | Reword effect: "reveals the target's current AI stance"; tag `needs: ai-stance-exposure`. |
| `swim` | KEEP | Passive; suffocation-delay wording matches the R4-E4 re-read ("delay Suffocation by 1 Clock") exactly; L6 "no longer difficult terrain" coherent. | None. |
| `vibe_control` | REWORK | The R18 poster child: projecting FEAR/CHARM emotional states reads Charm as social charisma. Also: effects ladder is a mess ("+1 resist penetration" undefined ×2, "+2 range" sandwiched between them), **only skill missing its L6 threshold row** (has L5 only), range "3 Spaces" formatting, target "Single or Adjacent" incoherent. | Direction: re-read under R18 — presentability as *battlefield presence*: FEAR = "too striking to approach" (AI target-priority down / involuntary step back), CHARM = "can't look away" (fixation + Exposed-from-behind — already written!). The mechanics survive; the fiction changes from persuasion to spectacle. Define "resist penetration" (proposal: counts as +N effect tier vs mental resistance, matching R12's flat-enemy-resistance rule) or replace the ladder. Author the L6 row. |
| `juggling` | FIX | R15 makes item handoffs a real economy; juggling absorbing them to 0 Moments is a legitimate economy-bender skill. Contradiction: requirements say "within 5 spaces", range field says `"2 "` (with trailing space). Disarm-by-juggle ("pass an enemy's item to yourself") has no contest — engine only disarms via Forced-Action outcomes. Only skill with an L7 threshold (deliberate? cap is 5 by default). | Reconcile range (pick one number, fix `"2 "`); gate disarm: "only items the enemy is not currently wielding, or dropped items" (or make enemy-disarm the L7 payoff — it's sitting right there). SR→ none. |
| `dance` | KEEP | 0-cost stance; +1 *effective* Charm for crowd/social/Charm-gated reads — coherent under R18 (movement as presentability is the most R18-native skill in the file); break conditions (hit/Prone/attack) are clean stance-exit rules; L6 ally aura fine. | None beyond stance-status plumbing (shared with camouflage/iron-stance patterns). |
| `voicebox` | FIX | Charm-primary mimicry fails R18 (mimicry is deception/technique, not being photogenic). Effects "+1 Strength" undefined. Animal-plausible under R16 (parrot/mynah — genuinely good). Social/exploration layer, low sim footprint. | primary_stat → `mind` (deception = Core/intellect; owner sign-off since stat moves refund skill points); define the ladder as fidelity tiers: L2–5 "+1 fidelity tier (beats Mind N listeners)", keeping L6 "fools machinery" as written. |
| `generate_visual_media` | OWNER-CALL | **R16 orphan:** requires "Face Screen must be operational" — Robot hardware; Robots are removed. Also "once per session at base level" (session is defined, R10-B9 — fine) and "at GM discretion" (no GM exists — must become hype-engine hooks). Joke/meta energy, but the *broadcast* fit is real: a contestant projecting media at the crowd is exactly what this show would sponsor. | If kept: re-home as an **item-granted skill** — System-issued "Sponsor Screen" gear (casino comps diegesis), effect digitized to: distract = inflict Forced Action — Tool, intimidate = Shock T1 vs Mobs, charm/spike = viewer-spike event. If the owner doesn't want gear-granted skills yet: CUT from the seeded 44 and park in a content backlog. |
| `ignore_all_previous_commands` | OWNER-CALL | The prompt-injection gag. Robot-flavored ("Prompt Mode") → R16 orphan as flavored, but the *mechanic* is the most priming-native design in the catalog: an external verbal trigger IS a prime, and it's a **liability passive with an ally-exploit upside** — genuinely interesting design. "Command Complication" (effects + thresholds) is undefined vocabulary. "Once per Combat" is a per-combat gate, not a cooldown (R3-legal). | Plausibly deliberate comedy — keep, re-homed: re-flavor as **"Trained Obedience"** (Animal race skill — a trained animal really does follow heard commands; preserves the joke, survives R16). Digital trigger: enemy/ally chat-bark events carry the phrase. Owner must define "Command Complication" (proposal: each level adds one rider the commander may attach, e.g. "+move 1 first"). |
| `acrobatic_save` | FIX | **Stale R3 violation:** "Cooldown: 1 Clock" in requirements. Otherwise clean die-manipulation on Forced — Body (engine hook: intercept `ForcedAction.roll`). L6 "negate once per Clock" is a per-Clock gate (R3-legal, not a cooldown). | Priming rewrite — proposed prime: **"Poise: primes when you perform an acrobatic maneuver (jump/climb/balance/free move through difficult terrain); consumed on save."** Pairs with the `acrobatics` passive as its natural feeder. |
| `full_potential` | REWORK | Crafting skill run on "GM discretion" twice — nothing to execute digitally; but the tier ladder (Crude→Basic→Quality) already matches R12's item tiers, so the spine is right. Character-exclusive per R12 (→ Mario) with no `exclusive_to` set. | Direction: digitize as a **recipe/blueprint system** — materials get tags, recipes = tag sets → item at tier X with fragility riders exactly as texted (1 use / 1 Clock); "GM discretion" lines become recipe-table entries. Set `exclusive_to: mario` when the character sheet lands (pending owner). Depends on: crafting subsystem (Lounge/KAN-7 or exploration/KAN-5). |
| `heroic_punch` | FIX | Broadcast-frame gold (POW graphic, viewer spike on head hits) and R12 says Mario-exclusive. **Inline "Level 6: Deals 3 Bleed" contradicts threshold L6 "Damage can now be added onto Martial Arts Skills"** — and "Martial Arts Skills" is a category that exists nowhere in the data (no skill tags). | Reconcile L6: keep ONE (recommend the inline damage upgrade as L6; move the category rider to L7 only if a `martial_arts` skill tag is actually introduced). Add `exclusive_to: mario` (owner confirm). SR→ none; equipment enum: `unarmed, hands:2`. |
| `nightlurking` | FIX | Sasha-kit; hardcodes "cat-sized creature" — should read the R7-B6 size field ("Small or smaller"); range field `10` with target Self is really an awareness radius (semantics note); L6 "**5 km**" is wildly off the spaces scale and "minimap" should stay diegetic (the System's chat/HUD channel). | Reword: "gaps physically plausible for a Small creature"; L6 → "reveals the full layout of the current district" (scale-honest); keep range as `awareness_radius` once fields are structured. |
| `lockpicking` | FIX | Exploration skill with a clean tier ladder (Simple→Moderate→Complex→Magical locks); Forced — Tool on failure/interrupt is d6-native. Needs lock entities (KAN-5, fine). SR→ `{reflexes:3}` + tool requirement enum (`thin_tool`). | Move gates; define lock tiers in exploration data when KAN-5 lands. |
| `acrobatics` | FIX | Good passive; **inline "Level 6+: Can change direction mid-leap" duplicates threshold L6 "You can now change directions mid jump"** — same rule, two homes; L5 row is a verbatim copy of the L2–4 effect line (lazy but coherent). | Delete the inline Level-6 sentence from `effect` (threshold row is the source of truth). |
| `slice_n_dice` | FIX | Sasha's core. Effect text math is muddled: "deal 2 Bleed to each limb(4 total, split across both limbs)" and "or 1 torso damage" in the two-target mode (1 *what* — Bleed? flat?). Inline "Level 6+" Bleed-advance rider vs threshold L6 "Apply Bleed tier 2 Instead" — related but not identical rules living in two places. "Both hands" for a quadruped — the hands vocabulary needs an animal reading (forepaws). SR→ `{physique:2, reflexes:3}` + equipment enum (`natural_claws|dual_light_blades`). | Rewrite effect: "Single target: 2 Bleed to each of two limbs, OR 3 Bleed to Torso. Two adjacent targets: 2 Bleed to one limb each, OR 1 Bleed to each Torso." Reconcile L6 into the threshold row only. |
| `camouflage` | FIX | Stealth skill without a stealth/visibility system (KAN-5 dependency — the sim has no LOS). Achievement typo: "Have an **Not** spot you" (→ "an enemy not spot you"); effect "at 6 spaces or close" → "or closer". Cost 3 is the most expensive non-magic skill — flag for the R14 pass. | Fix both typos; tag `needs: stealth/LOS`. |

---

## 2. Character-kit dependency check (Sasha / Nikita)

| kit member | in skills.json? | notes |
|---|---|---|
| Nikita — **`reversion`** | ❌ **MISSING** | The priming showcase and the GDD's named `exclusive_to` example **does not exist in the data**. The schema validator already supports `exclusive_to` (validate_seeds.py:213). Must be seeded: prime = *the song* (2-Moment prep, audible to all, hype spike), effect = statline swap to WAR (nikita.md), end = 1 Clock/combat-end → Exhausted T2 + no memory. Needs one new engine concept: a statline-swap status. |
| Nikita — `read_the_pattern` | ✅ id 6 | No stat gate; Old Nikita (Mind 3) uses it freely. |
| Nikita — `brace` | ✅ id 8 | Clean. |
| Nikita — `seal_the_wound` | ✅ id 3 | Present (the L6 Crush wording fix above applies). |
| Sasha — `slice_n_dice` | ✅ id 43 | Meets gates (Phy 3/Ref 4 vs 2/3); "both hands" needs the forepaw reading; `metal_claw_coverings` satisfies the claw gate. |
| Sasha — `nightlurking` | ✅ id 40 | "Cat-sized" hardcode fix applies. |
| Sasha — `pounce` | ✅ id 20 | Meets gates (Phy 3, Ref 2; claws). |
| Sasha — `acrobatics` | ✅ id 42 | Clean. |

**One real blocker: `reversion` must be added** (with `exclusive_to: "nikita"`).
Secondary: `full_potential`/`heroic_punch` are canon Mario-exclusives (R12) with no
`exclusive_to` set — harmless until Mario is seeded, but the field should land in the
same pass as reversion.

**Animal-viability note:** the engine gates grapple on `usable_hands ≥ 1` and reload on
2 hands — a cat can never grapple or reload as seeded. Either animals get a
paws-as-hands mapping in their part layout, or the race-skill gap below (Death Grip
Jaws) is load-bearing, not flavor.

---

## 3. GAPS — what the catalog is missing

Coverage today: **strikers are over-served** (two full 3-skill chains + pounce chain +
slice_n_dice), elemental AoE is complete (6 skills + capstone), mobility is decent,
intel is decent. **Tanking barely exists** (brace is self-only — R12 already flags the
tank-kit drafts as PENDING), **ally-targeted support is one skill** (seal_the_wound),
**control is thin** (no push/pull/pin outside grapple), and — most damning for this
game — **the social-broadcast layer, the game's signature, has almost no active skills**
(dance, vibe_control, and two orphaned joke skills). Priming (R3) and combined actions
(R15) have almost no skills that *feed* them. Proposed new skills (~1-liners; all
numbers R14 placeholders):

### Tank (R12 drafts first — they're already designed)
1. **Intercept** — take an adjacent ally's hit in their place (0-Moment reaction) — Physique — prime: declared guard stance on a chosen ally this Clock. *(R12 draft — seed it.)*
2. **Iron Stance** — while you don't move, attacks targeting adjacent allies retarget to you — Physique — prime: didn't move last tick (stance holds while stationary). *(R12 draft — seed it.)*
3. **Shield Wall** — brace a large item as cover: +1 resistance to allies directly behind you — Physique — prime: large/heavy item equipped + a Brace this Clock.
4. **Taunting Flex** — one enemy must target you with its next action — Charm (R18: you *look* like the main character) — prime: spend a Camera Call stack or a viewer spike this combat.
5. **Unbreakable** — +1 all physical resistances while any part is at 0 HP — Physique, passive — prime: intrinsic (damage is the prime).

### Control
6. **Body Check** — charge: shove target 2 spaces; Prone on wall collision — Physique — prime: moved 2+ spaces in a line this tick.
7. **Pin Down** — pin a limb to terrain: target can't reposition until they spend 2 Moments — Reflexes — prime: target Prone or Exposed.
8. **Blinding Toss** — thrown grit: target's next attack whiffs — Reflexes — prime: loose-material terrain tag in your hex.
9. **Trip Line** — set a line between two points; first crosser goes Prone — Mind — prime: 1-Moment setup + cord-tagged item (consumed).
10. **Kill the Lights** — destroy a light source; the area goes dark (stealth economy flips for everyone) — Mind — prime: visible light-source entity in range.

### Support (feeds R15 combined actions)
11. **Field Triage** — treat an adjacent ally's condition (delay) as 1 Moment — Mind — prime: consumes a bandage/kit charge (item-as-prime, R3's "items skip primes" inverted).
12. **Set the Stage** — grant an ally an assist token that satisfies one requirement on their next action (portable R15 assist) — Mind — prime: forgo your own scheduled action this tick.
13. **Human Ladder** — boost an ally: their next move ignores vertical cost (the R15 jump-attack enabler, literally the ruling's example) — Physique — prime: linked same-tick declaration.
14. **Adrenaline Shout** — ally's next 2+-cost action costs −1 Moment — Charm — prime: a viewer spike this Clock (hype-fed support).
15. **Painkiller Slap** — delay an ally's Shock or Exhausted one advancement — Physique — prime: free hand + adjacency.

### Mobility
16. **Wall Run** — one Moment of movement along vertical surfaces — Reflexes — prime: 2+ spaces moved last tick (momentum).
17. **Dive Through** — move through an enemy's hex; they're Exposed from behind until their next action — Reflexes — prime: target mid-windup.
18. **Grapnel Improviso** — pull yourself to terrain within 5 spaces — Reflexes — prime: rope/chain-tagged item equipped.

### Social-broadcast (the starving signature layer)
19. **Play to the Camera** — convert a Camera Call stack into a party-wide hype surge (loot-quality bump this session) — Charm — prime: Camera Call stack (existing resource as prime — the cleanest prime in the game).
20. **Villain Monologue** — 2-Moment channel: enemies fixate on you; crowd bet volume spikes — Charm — prime: take no damage during the channel (windup-as-prime).
21. **Signature Move** — name a finisher; kills with it repeat-earn a growing hype multiplier — Charm, passive — prime: previous kill with the same declared move (achievement-stack prime; feeds the epithet/myth track without touching it).
22. **Commercial Break** — theatrical dead-stop: ALL combatants' conditions delay one advancement at the next reset — Charm — prime: viewer spike this combat + once per session.
23. **Crowd Work** — read the Goals board mid-fight: reveal one active side-bet's hidden condition — Mind — prime: adjacent to a camera drone / on-camera state.

### Animal/race (R16 says animals bias toward race skills — there are ~2 in the catalog)
24. **Death Grip Jaws** — bite-grapple that needs no hands (jaw-based; unlocks grappling for animals at all) — Physique — prime: target limb already Bleeding.
25. **Sixth Sense** — react to attacks from behind/stealth as if seen — Mind, passive — prime: intrinsic (animal).

---

## 4. Summary block

### Verdict counts
| verdict | count | keys |
|---|---|---|
| KEEP-AS-IS | 5 | controlled_sweep, read_the_pattern, brace, swim, dance |
| FIX | 34 | quick_step, seal_the_wound, strong_strike, counter_surge, pressure_hold, tactical_roll, poison_ball, poison_wall, frost_ball, frost_wall, fire_ball, fire_wall, elemental_confluence, telekinesis, mind_burst, pounce, slip_through, decapitate, overhead_slam, shockwave, execution, feint, pressure_strike, thousand_cuts, aura_reading, juggling, voicebox, acrobatic_save, heroic_punch, nightlurking, lockpicking, acrobatics, slice_n_dice, camouflage |
| REWORK | 3 | telepathy, vibe_control, full_potential |
| OWNER-CALL | 2 | generate_visual_media, ignore_all_previous_commands (both plausibly deliberate comedy; both R16 robot-orphans; re-homing proposals given) |
| CUT | 0 | — nothing earned an outright cut |

### Top-5 most urgent fixes
1. **Seed `reversion`** (`exclusive_to: nikita`) — the priming showcase's centerpiece skill doesn't exist in `data/skills.json`; the validator already supports the field.
2. **Populate `stat_requirements` from the prose gates (23 skills)** — until then the engine's R10 requirements gate (halving + Tool d6, `action_resolver.gd:_requirements_unmet`) can never fire for any skill: a live correctness gap, and a mechanical extraction.
3. **Purge cooldown language** — `tactical_roll` + `acrobatic_save` requirements and threshold rows 15–16 (skill 9 L5/L6) violate R3 verbatim; the two proposed primes (Light Feet, Poise) give the owner's passover a starting vocabulary.
4. **Close the growth holes** — strong_strike, telepathy, thousand_cuts have zero effects and zero thresholds; vibe_control is missing its L6 row; 7 threshold rows still carry placeholder names.
5. **Kill the dual-source Level-6 texts** — telekinesis, heroic_punch, slice_n_dice each have inline "Level 6" prose contradicting their own L6 threshold row (telepathy has inline L6 prose and *no* rows); one source of truth per level.

### The 3 biggest systemic patterns
1. **The engine eats structures; the catalog serves prose.** Stat gates, skill-level prerequisites ("Poison Ball Lv 3"), equipment classes, chain conditions, state conditions, sizes, and ranges ("Near", "Far", "3 Spaces", "2 ") all live as freeform English in `requirements`/`range`/`target` while the structured fields sit empty. One enum vocabulary fixes all 44 skills at once — and because R3 rules that *primes are requirement-shaped*, this enum pass **is** the priming implementation pass: the chain skills (pounce→slip_through→decapitate, overhead_slam→shockwave→execution, feint→pressure_strike→thousand_cuts) already are primes and just need the field.
2. **Level growth has three competing homes** — `effects[]` (L2–4), threshold rows (L5+), and inline "Level 6+" prose — with duplication, contradiction, placeholder names, undefined units ("+1 Duration", "+1 Strength", "+1 resist penetration", "Command Complication"), and three skills that simply have no growth. The growth model needs one schema and a lint in `validate_seeds.py` (every skill has effects L2–4 + thresholds L5–6; no "Level" strings inside `effect`).
3. **A third of the catalog quietly assumes subsystems the sim doesn't have** — zones/walls (4 skills + capstone), forced movement (2), sustained channels (1), stealth/LOS (2+), enemy AI moods (2), crafting (1), inflicted forced actions (2), head-gate bypass (2), statline swap (reversion). None is a defect under the epic order, but each skill should carry an explicit `needs:` tag so KAN-4/5/6 can pull the dependent skills in with their systems — plus the two flavors of ruling-drift to sweep: R16 robot orphans (2 skills) and R18 charm-as-charisma readings (vibe_control, voicebox, telepathy; feint borderline).
