class_name SkillBook
extends RefCounted
## Per-skill mechanics authority (MODEL — no Godot node deps, pure + stateless).
##
## A skill is NOT just "an attack with a key" — each has an authored effect. This
## book maps (skill key, level) -> a structured mechanics spec that
## ActionResolver dispatches on. Keeping the authority here (not in the HUD)
## honours the architecture rule: scenes are presentation only; mechanics live in
## the sim, are a pure function of (seed, ordered command log), and serialize.
##
## ARCHETYPES (ActionResolver dispatches by "archetype"):
##   committed_strike     — windup single strike; actor Exposed; optional knockdown
##   self_guard           — no target; buffers the next Crush/Burn hit (brace)
##   setup_debuff         — no damage; the target's next action collapses to Tool
##   conditional_followup — a strike with a bonus rider when a setup is pending
##   self_stance          — no target; a stance buff that ends on a trigger
##   declared_dodge       — the G1 declared-hex dodge (tactical_roll): spends the
##                          actor's MOVEMENT for the Moment, moves at declare
##   leap_strike          — leap absorbed into the declare + a landing strike (pounce)
##   slip_reposition_strike — chained leg strikes + REAR-ARC reposition + Exposed
##                          rider (slip_through; R30 facing — F5 retired)
##   head_finisher        — chained bypass-head-gate slash from BEHIND (R30
##                          rear arc); Head->0 = cinematic kill event +
##                          spectacle payout (decapitate)
##   aoe_cone_strike      — cone Crush to every enemy in the arc + 1-hex knockback
##                          + Forced Body on Mobs (shockwave)
##   downed_finisher      — chained heavy strike vs Prone/Helpless; Torso adds a
##                          Shock rider (execution)
##   multi_part_flurry    — 3 chosen parts, 1 Bleed each; all-3-on-bleeding
##                          advances tiers (thousand_cuts)
##   adjacent_mob_sweep   — up to N extra adjacent Mobs as separate single-target
##                          strikes; gate >= 2 Mobs adjacent (controlled_sweep)
##   crossing_arc_strike  — the G8 crossing arc: two limbs / torso, one or two
##                          adjacent targets (slice_n_dice)
##   pow_strike           — committed unarmed Crush; Exposed-Head hit adds a Shock
##                          rider + the crowd POW beat (heroic_punch)
##   retarget_guard       — batch B "Guardians & Grapplers": hits AIMED at a
##                          guarded ally retarget to the guardian at the top of
##                          _strike_round. Two forms via spec "form":
##                          "reaction" (intercept — one declared ally, costs the
##                          reaction slot per hit) and "stance" (iron_stance —
##                          ANY adjacent ally, no reaction cost, persistent
##                          flat reduction; breaks on movement/Prone)
##   skill_grapple        — batch B: the R9 grapple as a skill — hold (neither
##                          repositions, both Exposed) + the L2-4 drag ladder;
##                          spec "grip" parameterizes the R9 hands gate
##                          ("hands" = pressure_hold, "bite" = death_grip_jaws)
##   interrupt_counter    — batch B: strike an adjacent winding-up enemy; a
##                          connected hit CUTS the remaining windup cost (Clock
##                          reschedule); a full cut collapses the action into
##                          Forced Action – BODY (the parameterized collapse
##                          table — the feint path keeps Tool, F3)
##   ally_treatment       — batch C "Medics & Minds": delay a condition's
##                          advancement on self/an ally via ConditionEngine.delay
##                          — the BASE mode is DELAY (FINAL default #8: never a
##                          cure of a lethal state, never HP; no heal path
##                          exists in the resolver, structurally). Two batch-C
##                          carriers via spec fields: seal_the_wound
##                          (self_allowed, bleeding/infected only) and
##                          field_triage (ally-only, any condition, consumes a
##                          bandage_charge via the generic STACK prime).
##                          Tier-2 wave 2 (combat_medic — S6-d, [FROM row 6,
##                          audit fix: Crush dropped]): a spec carrying
##                          "resolve_conditions" (L4+) additionally accepts
##                          {"mode": "resolve"} — fully REMOVE one listed
##                          condition (Infection/Bleed) through the ENGINE's
##                          own removal path (ConditionEngine.treat mode
##                          "resolve" — R10's infection gate honored), once
##                          per Clock (treat_resolve_used_clock), NEVER while
##                          the condition drives a bleed-out (the lethal
##                          state is held, not cured — default #8's line) and
##                          still NEVER HP (the no-HP structural pin holds)
##   intel_reveal         — batch C: knowledge plays, zero rng. Two forms:
##                          "declared_read" (read_the_pattern — reveal one
##                          VISIBLE enemy's scheduled action(s) until the Clock
##                          reset; visibility = Stealth.sees, the observer's R30
##                          facing cone applies) and "passive_aura"
##                          (aura_reading — no declare: OWNING the skill exposes
##                          the ai_stance of enemies the owner currently SEES on
##                          the contestant-facing view surface; feeling, never
##                          intent — GameController._aura_reads gates it)
##   psychic_strike       — batch C (mind_burst — a strike VARIANT, not a new
##                          family): windup psychic hit that applies Shock at
##                          the spec tier via ConditionEngine.apply_shock (the
##                          stated-tier + escalation model handles the already-
##                          Shocked); may target the Head regardless of Exposure
##                          (bypass_head_gate); needs line of sight below the
##                          L8 threshold rung; no HP damage, no physical dodge
##   aoe_blast            — batch D "Casters & Showfolk": a ranged declare at a
##                          TARGET HEX ("at"); the detonation is
##                          HexGeometry.blast(center, radius) resolved per
##                          caught combatant through _strike_round-grade rows
##                          (snapshot membership, R2; the R25 AoE-center rule —
##                          a blast-Moment roller escapes unless standing on
##                          the CENTER; NOT undodgable — only valve blasts
##                          carry that flag, R26). Carriers: poison_ball
##                          (Tier-1 Poison, the entry-condition gate per
##                          target), frost_ball (impact typed CRUSH per G8 +
##                          the Chilled T1 rider), fire_ball (Burn + the
##                          trash-can ignition family's blast-shaped sibling)
##   stealth_conceal      — batch D (camouflage): a 3-Moment concealment
##                          windup on the R20 substrate — resolves into
##                          stealthed WITH an override reveal radius
##                          (combatant.conceal, read by Stealth.sees) that
##                          caps every observer's sight range; anchored to
##                          the woven hex — ANY displacement breaks it (the
##                          CombatSim sweep), alongside the normal break rules
##   projection_control   — batch D (vibe_control): two declared modes vs a
##                          PERCEIVING hostile (the target must SEE the actor
##                          — Stealth.sees with the R30 cone). FEAR = 1-hex
##                          push (the knockback helper) + a grudge REDUCTION
##                          (EnemyAI.reduce_antagonism, floor 0); CHARM =
##                          fixation (grudge INCREASE + the target faces the
##                          actor — the second ruled involuntary facing) + a
##                          1-hex actor reposition + the Exposed window whose
##                          "from behind" half is the REAL R30 is_behind gate
##   hype_surge           — batch D (play_to_the_camera): spends ONE
##                          Camera-Call stack via the existing
##                          camera_calls_used ledger and opens the timed
##                          party-wide surge window in HypeEngine (serialized
##                          only-when-set): party spectacle GAINS ×2 until
##                          the actor's next Moment (+L2-4 duration rows)
##   sustained_channel    — batch D (telekinesis): grip one visible target at
##                          range — actor Exposed (ExposureEngine) + rooted,
##                          target movement-locked (held_by); the sustain
##                          occupies the actor's scheduled action each Moment
##                          (re-declare {"sustain": true}, else the grip
##                          lapses at tick end); a sustain may drag the
##                          target 1 hex (forced movement, wall-honest);
##                          breaks on actor damage / grapple / helpless
##                          (the CombatSim sweep)
##   item_flow            — batch D (juggling): the first combatant-to-
##                          combatant item transfer — a 0-Moment (free-slot)
##                          pass/catch moving one item dict between two
##                          combatants within range, the juggler always one
##                          end; enemy-source flow only for DROPPED items
##                          (G8: wielded disarm is the L7 payoff, data)
##   forced_roll_save     — batch C (acrobatic_save): the G1 MOVEMENT-FORFEIT
##                          arming (R25 — NO prime, NO stance: the ladders doc's
##                          old prime note is superseded by its tail
##                          annotation). Declaring spends the Moment's movement
##                          (the tactical_roll plumbing) and ARMS the save;
##                          the owner's next Forced Action – BODY roll draws
##                          spec extra_dice extra dice from the SAME action rng
##                          stream and keeps the LOWEST-severity result
##                          (ForcedAction.save_severity — tie keeps the
##                          original); the arming is consumed per roll
##   fused_evasion        — tier-2 wave 1 (perfect_evasion, S5 — BLESSED
##                          2026-08-18): ONE R25 movement-forfeit declare arms
##                          BOTH parents' defenses at once — the declared-hex
##                          roll (moves at declare, rolled_this_window set, the
##                          AoE-center rule applies) AND the armed save
##                          (forced_save, the acrobatic_save consume path). L3+
##                          (S5-c, OQ2 RULED "2nd roll 2nd attack"): the same
##                          forfeit covers a SECOND declared-hex roll against a
##                          second DISTINCT attack resolving in the same window
##                          ({"second_roll": true, "against": attacker} — the
##                          serialized `evasion` window record enforces
##                          distinctness; the forfeit is never waived). L4+
##                          (S5-d, row 68): the armed save NEGATES a Forced
##                          Action – Body outright once per Clock
##                          (negate_used_clock, serialized only-when-set)
##   fused_counter        — tier-2 wave 2 (counterscript, S1 — BLESSED
##                          2026-08-18): intel + counter fused. Mode "read"
##                          (action {"mode": "read"}): the standing read —
##                          intel_reveal's declared_read lane (visible enemy,
##                          read_range, until the Clock reset via the same
##                          pattern_reads record + expiry sweep + owner-gated
##                          view projection) CAPPED at spec read_targets
##                          concurrent reads (1 at L1; S1-c's second enemy at
##                          L3+ — a read past the cap REPLACES the oldest,
##                          attention moves). Default mode "counter": a
##                          cost-1 strike vs an adjacent READ TARGET — the
##                          WIDENED gate (S1-a): no winding_up prime; any
##                          declared-but-unresolved action of the read target
##                          with remaining cost can be countered — a future
##                          windup (cut remaining cost / collapse → Forced
##                          BODY, the counter_surge machinery) OR a same-tick
##                          still-pending scheduled instant (seq-ordered:
##                          declared after the counter, collapsing at its own
##                          slot; an action that already RESOLVED can never
##                          be countered — the honest boundary: same-tick
##                          instants resolve in declaration order, so the
##                          widened gate covers exactly the SCHEDULED
##                          remainder). S1-b (L2+, [FROM row 8]): a
##                          countered-but-NOT-collapsed action arms the
##                          per-source immunity window (counter_immunities —
##                          the source cannot affect the counter-actor for
##                          immunity_moments Moments; others still affected)
##   terrain_stride       — Round 3a (quick_step): a 0-Moment, SLOT-FREE
##                          IMMEDIATE self declare (the arming-declare
##                          pattern; it rides the movement it modifies —
##                          the design call is documented at the declare)
##                          that opens a timed window
##                          (quick_step_until_tick) in which difficult/rough
##                          terrain prices as normal ground for the strider —
##                          the R33 consumer-overlay seam's first active
##                          consumer. Requires movement remaining (the data's
##                          own gate); duration = stride_moments ticks
##                          (L1 "this Moment" + the +1/+2/+3 Duration rows)
##   terrain_affinity     — Round 3a (swim / acrobatics): PASSIVE — never
##                          declarable (the aura_reading pattern: OWNING the
##                          skill is the mechanic). The R33 cost overlay reads
##                          the grant: swim prices water 1, acrobatics prices
##                          rough 1; swim's grace delays the submersion
##                          suffocation track (CombatSim's water sweep);
##                          acrobatics' L2-4 movement rows extend the declared
##                          roll range (the sim's acrobatic maneuver —
##                          PROVISIONAL reading, documented at the seam)
##   scheduled_pick       — Round 3a (lockpicking): the SCHEDULED pick the R33
##                          downscope deferred here — declare adjacent to a
##                          locked door ("door": key), Moments from the
##                          substrate tier table minus the authored -1 rows
##                          (floor 1), through the standard declare/windup
##                          machinery (feint-able; premise breaks collapse
##                          into Forced Action – Tool — the data's own failure
##                          path); resolve calls CombatSim.pick_lock
##   wall_conjure         — Round 3a (poison_wall / frost_wall / fire_wall):
##                          placed-LINE zone creation on the R32 substrate —
##                          the declare names "from"/"to" hexes (a straight
##                          hex line, length/range per ladder, LOS per the
##                          aoe_blast precedent), the resolve calls
##                          CombatSim.create_zone with the spec's DATA-shaped
##                          zone payload (owner = the caster: attribution).
##                          A rejected create at resolution collapses the
##                          windup (Forced Tool — the invalidated-windup
##                          rule); frost's strike-chill + the zone-attack
##                          path live in ActionResolver (_resolve_zone_attack)
##   strike               — generic single-target strike (the unknown-key fallback)
##
## SCOPE: the six demo-slice skills below carry FINAL authored numbers (not R14
## placeholders); tactical_roll (G1, rules-addendum R25) is implemented with a
## PLACEHOLDER-R14 base range. Content pass batch A ("Chains & Strikes",
## docs/design/skills-r19-ladders-FINAL.md) encodes nine more skills below —
## every batch-A magnitude is PLACEHOLDER (R14) and follows the FINAL ladder's
## authored L1 core + the data rows' L2-4 scaling; L5+ stays threshold DATA.
## Content pass batch B ("Guardians & Grapplers") encodes five more the same
## way: intercept + iron_stance (retarget_guard), pressure_hold +
## death_grip_jaws (skill_grapple), counter_surge (interrupt_counter) — all
## magnitudes PLACEHOLDER (R14), L1 core + data-row L2-4, L5+ threshold DATA.
## Content pass batch C ("Medics & Minds") encodes six more the same way:
## seal_the_wound + field_triage (ally_treatment), read_the_pattern +
## aura_reading (intel_reveal), mind_burst (psychic_strike — the strike
## variant), acrobatic_save (forced_roll_save — the G1 movement-forfeit
## arming) — all magnitudes PLACEHOLDER (R14), L1 core + data-row L2-4, L5+
## threshold DATA (incl. seal L6 resolve, pattern L8 remote read, burst L8
## out-of-sight, save L6 any-fumble).
## Content pass batch D ("Casters & Showfolk") encodes eight more the same
## way: poison_ball + frost_ball + fire_ball (aoe_blast), camouflage
## (stealth_conceal), vibe_control (projection_control), play_to_the_camera
## (hype_surge), telekinesis (sustained_channel), juggling (item_flow) — all
## magnitudes PLACEHOLDER (R14), L1 core + data-row L2-4, L5+ threshold DATA
## (incl. poison L6 choose-the-toxin, frost L6 pin, fire L6 cluster, camo L6
## move-one-hex, vibe L5 range, surge L5 survives-a-hit + L6 loss-cut,
## telekinesis L6 un-Exposed, juggling L6 catch-attacks / L7 wielded
## disarm). L2-4 "+N" rows read as totals over the L1 base (the
## mind_burst/execution/slice precedent). Display names for vibe_control and
## play_to_the_camera are NOT pinned (v2 Group E rename caution) —
## data-sourced only; specs and events carry only the sim keys.
## Content pass Round 3a ("the unblocked KAN-5 skills") encodes seven more the
## same way on the R32/R33 substrates: quick_step (terrain_stride), swim +
## acrobatics (terrain_affinity), lockpicking (scheduled_pick), poison_wall +
## frost_wall + fire_wall (wall_conjure) — all magnitudes PLACEHOLDER (R14),
## L1 core + data-row L2-4, L5+ threshold DATA (incl. quick_step L6 physical-
## terrain effects, swim L6 "+2 Clocks total" grace, lockpicking L5 complex /
## L6 magical, poison L6 choose-the-toxin, frost L6 chill-heal, fire L6
## Shock-passers). elemental_confluence stays DATA-ONLY: the R32 zone
## substrate covers its placement mechanics (create/remove/advance — the
## Toxic Surge shape is the vocabulary's own example); ONLY the consume-unlock
## economics (KAN-7, off-ladder per FINAL default #5) blocks it. These seven
## stay OUT of KNOWN_KEYS for the tier-2 wave's reason (b): KNOWN_KEYS
## membership requires a ruled skill_keywords.json entry (validate_seeds +
## test_keywords) and none of the seven has one yet — the keyword pass owns
## that ruling; mechanics() is the encoding authority either way, so a
## granted key resolves as a REAL implemented skill today.
## The remaining skills in data/skills.json are the fill-in-later content pass;
## until encoded they resolve through the generic `strike` fallback so an
## unknown key still does a real, honest thing.
##
## TIER-2 WAVE 1 (docs/design/tier2-rungs-proposal.md, BLESSED owner
## 2026-08-18): the three low-machinery ladders are ENCODED below —
## perfect_evasion (S5, fused_evasion), vice_grip (S7, skill_grapple grip
## "any") and phantom_grasp (S10, sustained_channel grip "psychic" —
## OQ1 RULED mundane-psionic, escape contest Physique-vs-holder-MIND).
## They are deliberately NOT in KNOWN_KEYS: (a) tier-2 results are
## acquisition-gated — merge/offer results, never learnable directly — and
## the creation surface draws from KNOWN_KEYS (nothing aspirational), so
## listing them would open a wrong door; (b) KNOWN_KEYS membership requires
## a ruled skill_keywords.json entry (validate_seeds + test_keywords), and
## the tier-2 keyword rulings are the keyword pass's scope, not this
## story's. mechanics() is the encoding authority either way — the forge/
## offer grant (or a roster `skills` row) yields a REAL implemented skill.
## The other seven tier-2 ladders (S1-S4, S6, S8-S9) are DATA-ONLY this
## wave: their skills.json rows carry the blessed rung content with [NEEDS]
## flags, and an undeclared key resolves through the `strike` fallback.
## L2-4 magnitudes below are PLACEHOLDER (R14), anchored per the blessed
## ladders' [PH] guidance (L1 >= the consumed parent's L5 value).
##
## TIER-2 WAVE 2 (same proposal doc): two more ladders ENCODED —
## **combat_medic** (S6, M7: Seal Lv5 + Triage Lv3 — ally_treatment
## extended): a IMPLEMENTED (delay ANY condition on self or any ally within
## treat_range; Triage's charge economy kept — ALLY treatment consumes a
## bandage_charge, self-treatment never does) · b IMPLEMENTED (delay/range
## rows) · c DATA ([NEEDS] freeze/arrest — a hold-open distinct from
## multi-Clock delay: blocking re-application advancement needs a
## ConditionEngine mode this wave does not build) · d IMPLEMENTED ([FROM
## row 6, Crush dropped]: the resolve mode — see the archetype note; once
## per Clock, never HP, never a lethal state) · e DATA (threshold row 98 —
## the once-per-combat economy + the stabilize rider stay data; the resolve
## PATH it needs now exists).
## **counterscript** (S1, M2: Counter-Surge Lv5 + Read The Pattern Lv3 —
## fused_counter): a IMPLEMENTED (the standing read + the widened counter
## gate — see the archetype note) · b IMPLEMENTED (deepened cut + the
## per-source 3-Moment immunity window, serialized) · c IMPLEMENTED (the
## second concurrent read + deeper queue reveal) · d DATA ([NEEDS] R15
## combined-action hooks — cross-footprint) · e DATA (threshold row 93;
## [NEEDS] boss win-condition telegraph exposure). Both stay OUT of
## KNOWN_KEYS for wave 1's two reasons (acquisition-gated; keyword rulings
## pending). All magnitudes PLACEHOLDER (R14).
##
## PRIMING (rules-addendum R3, decision-log #20 — "cooldowns do not exist"): a
## spec MAY carry a "prime" Dictionary that ActionResolver._prime_unmet enforces
## at declare (one of chain / stance / stack / state / prep). The CHAIN prime
## supports "same_target": true (batch A) — the chained action's first target
## must equal the actor's last_action_target. Chain gates stay FIXED below the
## authored release rungs (FINAL default #4), so each chained batch-A skill is
## ONLY declarable in sequence and its spec cost IS the authored chained cost
## (the -N chain discounts in the data rows collapse into the flat spec cost —
## there is no un-chained declare to price). Notes:
##   - pressure_strike -> CHAIN after your own "feint", same target — ENCODED
##     (F4, this ladder pass; the v1 deviation note that deferred it is retired).
##     The feint_forced resolve-time gate still governs the bonus Shock: a feint
##     CONSUMED by another action before the strike resolves means chain met,
##     bonus not — both remain honest.
##   - ~~tactical_roll (skills.json id 9) -> STANCE~~ SUPERSEDED by G1 (owner
##     2026-07-23, skills-passover RULINGS; rules-addendum R25): no stance, no
##     charges, no cooldown — the cost is the MOVEMENT FORFEIT. Implemented below
##     as the declared_dodge archetype.
##   - acrobatic_save (skills.json id 37) -> the SAME movement-forfeit cost model
##     (G1: "Acrobatic Save gets the same movement-forfeit cost in place of its
##     cooldown"). Cost model RULED; the skill's effect (die manipulation) stays
##     UNIMPLEMENTED content — do not encode a stance prime when it lands (R25).
##   - intercept + iron_stance: IMPLEMENTED (batch B — the retarget_guard
##     archetype landed; the R27 "DATA-ONLY grant" interim is RETIRED). The
##     Gemstone recipe (data/skill_mutations.json: Intercept Lv5 + Brace Lv3 →
##     Iron Stance Lv1, both parents consumed) now yields a REAL implemented
##     result. The merge machinery (simulation/skill_forge.gd +
##     skill_keywords.gd) still validates on keys+levels only — a SkillBook
##     entry remains deliberately un-required for granting.
##   - intercept's guard declare ARMS the PREP substrate (armed_primes
##     ["intercept"] + the guard record on the combatant); the interception
##     itself is not a declared action, so nothing consumes the prime — the
##     guard persists across hits (one interception per tick: the reaction
##     slot) until replaced or a party goes down (the CombatSim sweep).

const KNOWN_KEYS: Array[String] = [
	"strong_strike", "overhead_slam", "brace", "feint", "pressure_strike", "dance",
	"tactical_roll",
	# Content pass batch A — chains & strikes (skills-r19-ladders-FINAL.md).
	"pounce", "slip_through", "decapitate", "shockwave", "execution",
	"thousand_cuts", "controlled_sweep", "slice_n_dice", "heroic_punch",
	# Content pass batch B — guardians & grapplers (ladders #5/#7 + the G6
	# passover NEW_SKILLS; skills.json ids 5, 7, 46, 47, 49).
	"intercept", "iron_stance", "pressure_hold", "death_grip_jaws",
	"counter_surge",
	# Content pass batch C — medics & minds (ladders #3/#6/#19/#29/#37 + the
	# G6 passover field_triage; skills.json ids 3, 6, 19, 29, 37, 48).
	"seal_the_wound", "field_triage", "read_the_pattern", "aura_reading",
	"mind_burst", "acrobatic_save",
	# Content pass batch D — casters & showfolk (ladders #10/#12/#14/#17/#31/
	# #32/#44 + the G6 passover play_to_the_camera; skills.json ids 10, 12,
	# 14, 17, 31, 32, 44, 50).
	"poison_ball", "frost_ball", "fire_ball", "camouflage", "vibe_control",
	"play_to_the_camera", "telekinesis", "juggling",
]

## Generic fallback for any un-encoded skill: a plain single-target strike so the
## 37 pending skills still resolve (honestly, if modestly) before their content pass.
const FALLBACK: Dictionary = {
	"archetype": "strike",
	"cost": 1,
	"damage_type": "crushed",
	"amount": 1,
	"attack_range": 1,
}


static func is_known(key: String) -> bool:
	return KNOWN_KEYS.has(key)


## Self-targeted skills (no enemy target) — the HUD asks the model rather than
## re-authoring the target/self split itself. The retarget_guard STANCE form
## (iron_stance) is self-targeted too; the reaction form (intercept) declares
## on an ALLY, so it stays out.
static func is_self_skill(key: String) -> bool:
	var spec: Dictionary = mechanics(key, 1)
	var arch := String(spec.get("archetype", ""))
	if arch == "retarget_guard":
		return String(spec.get("form", "")) == "stance"
	# Batch C: the save arming names no target (the movement forfeit is the
	# whole declare); the passive aura is never declared at all but reads
	# self-shaped for any HUD affordance that asks. Tier-2 wave 1: the fused
	# evasion arming is the same shape — a self-declare naming a hex, never
	# a combatant.
	if arch == "forced_roll_save" or arch == "fused_evasion":
		return true
	if arch == "intel_reveal":
		return String(spec.get("form", "")) == "passive_aura"
	# Batch D: the camouflage windup and the surge name no target (the blast
	# names a HEX, not a combatant — it stays out so the HUD asks for an aim).
	if arch == "stealth_conceal" or arch == "hype_surge":
		return true
	# Round 3a: the stride window is a pure self-declare; the passives read
	# self-shaped for any HUD affordance that asks (the aura pattern). The
	# pick names a DOOR and the walls name HEXES — both stay out so the HUD
	# asks for an aim, exactly like the blast.
	if arch == "terrain_stride" or arch == "terrain_affinity":
		return true
	return arch == "self_guard" or arch == "self_stance"


## The authored mechanics for (key, level). Level is clamped to [1, 4] for the
## number tables but echoed raw so callers can display it. Returns a fresh dict.
static func mechanics(key: String, level: int) -> Dictionary:
	var lv: int = clampi(level, 1, 4)
	var spec: Dictionary = {}
	match key:
		"strong_strike":
			# Physique, cost 2, melee single. A committed weapon blow; amount is
			# weapon base+1 — crushed/6 is the demo default when no weapon is wired.
			spec = {
				"archetype": "committed_strike",
				"cost": 2,
				"damage_type": "crushed",
				"amount": 6,
				"attack_range": 1,
				"knockdown": false,
			}
		"overhead_slam":
			# Physique, cost 2, adjacent single (torso/arm). 3 Crush at Lv1,
			# +1 per level (amount = 2 + level). A landed hit knocks a standing
			# target Prone. Actor Exposed during the windup.
			spec = {
				"archetype": "committed_strike",
				"cost": 2,
				"damage_type": "crushed",
				"amount": 2 + lv,
				"attack_range": 1,
				"knockdown": true,
			}
		"brace":
			# Physique, cost 0 (free), self. Buffers the NEXT incoming Crush OR Burn
			# hit by (level), floor 0, then the guard is consumed.
			spec = {
				"archetype": "self_guard",
				"cost": 0,
				"guard_amount": lv,
				"conditions": ["crushed", "burn"],
			}
		"feint":
			# Reflexes/Charm, cost 1 (instant), adjacent single. No damage; the
			# target's next resolved action collapses into a Forced Action – Tool.
			# The actor repositions up to 1 space free. R24: the feint carries a
			# read threshold that asks the DEFENDER's Mind (4 + level, PLACEHOLDER
			# R14) through the R22 threshold machinery — an authored value here
			# overrides the formula. Only feint-shaped taunts carry one: a
			# setup_debuff without read_threshold is never readable.
			spec = {
				"archetype": "setup_debuff",
				"cost": 1,
				"attack_range": 1,
				"reposition": 1,
				"read_threshold": 4 + lv,
			}
		"pressure_strike":
			# Reflexes/Physique, cost 2, adjacent single limb. 2 Bleed at Lv1,
			# +1 per level (amount = 1 + level). +Shock T1 when the target is still
			# under Feint's pending consequence. Actor moves up to 2 spaces free.
			# F4 (ladder pass): the declare-time CHAIN prime is ENCODED — below the
			# authored L8 release (FINAL default #4) pressure_strike must follow
			# your own Feint on the same target, or the declare rejects prime_unmet.
			spec = {
				"archetype": "conditional_followup",
				"cost": 2,
				"damage_type": "bleeding",
				"amount": 1 + lv,
				"attack_range": 1,
				"reposition": 2,
				"bonus_shock_tier": 1,
				"prime": {"type": "chain", "after": "feint", "same_target": true},
			}
		"dance":
			# Reflexes, cost 0 (free), self. A stance granting +level Charm effect
			# in charm-gated / spectacle contexts; ends when the dancer is hit,
			# knocked Prone, or commits to an attack / damaging skill.
			spec = {
				"archetype": "self_stance",
				"cost": 0,
				"charm_bonus": lv,
			}
		"pounce":
			# Batch A (ladder #20; Sasha's opener). Physique, cost 2 (windup).
			# Leap up to leap_range spaces + a torso Bleed strike in ONE declare —
			# movement absorbed into the action (the leap consumes neither the
			# free move nor the free-action slot; arena walls/occupancy validated
			# through the existing movement checks). Bleed 2 at L1, +1/level;
			# leap 3 at L1, +1 at L3, +2 at L4 (data rows). All numbers
			# PLACEHOLDER (R14). attack reach for declare/windup re-checks is
			# leap_range + 1 (a strike delivered at the end of the leap); the
			# landing itself re-validates adjacency at resolution. Chain opener:
			# resolving records last_action_key/-target for slip_through.
			spec = {
				"archetype": "leap_strike",
				"cost": 2,
				"damage_type": "bleeding",
				"amount": 1 + lv,
				"leap_range": [3, 3, 4, 5][lv - 1],
			}
		"slip_through":
			# Batch A (ladder #21). Reflexes, CHAIN link after pounce on the SAME
			# target (fixed below L9, FINAL default #4) — so the only declarable
			# cost is the authored chained cost 1. Gate: target at least one size
			# larger (size_rank, the G8 rewording of "Elite or Boss scale").
			# 1 Bleed to EACH leg at L1 (+1/level, data rows; amount is per leg,
			# PLACEHOLDER R14) + reposition BEHIND the target (the R30 rear
			# arc against the target's live facing; far-side fallback when no
			# rear hex is free) + target Exposed until the end of their next
			# Moment. F5 RETIRED (decision #33 / addendum R30): the facing
			# primitive is real — "reposition behind" is the actual rear arc
			# now, no longer the far-side approximation Batch A shipped interim.
			spec = {
				"archetype": "slip_reposition_strike",
				"cost": 1,
				"damage_type": "bleeding",
				"amount": lv,
				"attack_range": 1,
				"exposed_ticks": 2,
				"prime": {"type": "chain", "after": "pounce", "same_target": true},
			}
		"decapitate":
			# Batch A (ladder #22). CHAIN finisher after slip_through on the SAME
			# target (fixed below L9), PLUS the target must be Exposed AND the
			# actor must stand BEHIND it (declare validation — the canonical
			# prime carries one predicate, so the STATE half of "CHAIN + STATE"
			# is enforced by the skill validator; the ladder's "positioned
			# behind" is the REAL R30 rear-arc gate as of decision #33 —
			# Stealth.is_behind — retiring Batch A's Exposed-only interim).
			# Head slash via bypass_head_gate (slip_through created the opening —
			# the audit's one-line _validate_attack flag, shared shape with the
			# mind_burst need). 3 Head Bleed at L1, +1/level (PLACEHOLDER R14).
			# Head -> 0 = the normal lethal path + a cinematic_kill event that
			# scores through the HypeEngine spectacle_points hook (authored
			# payout, PLACEHOLDER R14). Chained cost 1 (base 3 - 2).
			spec = {
				"archetype": "head_finisher",
				"cost": 1,
				"damage_type": "bleeding",
				"amount": 2 + lv,
				"attack_range": 1,
				"bypass_head_gate": true,
				"cinematic_spectacle": 45,
				"prime": {"type": "chain", "after": "slip_through", "same_target": true},
			}
		"shockwave":
			# Batch A (ladder #24). CHAIN link after overhead_slam (sequence only
			# — the wave is an AoE, no same-target gate; fixed per default #4).
			# 3-space cone (HexGeometry.cone) Crush to every enemy in the arc:
			# 1 Crush at L1 (+1 at L2, +2 at L4), cone size 3 (+2 at L3) — data
			# rows, PLACEHOLDER R14. Each connected target is knocked back 1 hex
			# AWAY from the actor (wall/occupation-honest; NO prone — the ladder
			# does not say prone below the L10 capstone). Mobs caught roll
			# Forced Action - Body (the existing ForcedAction rng stream).
			# The Overhead Slam victim (the actor's last_action_target) is
			# EXCLUDED per the authored L1 core — load-bearing: shoving the
			# downed victim out of adjacency would break the Execution finisher.
			# Chained cost 1 (data row).
			spec = {
				"archetype": "aoe_cone_strike",
				"cost": 1,
				"damage_type": "crushed",
				"amount": [1, 2, 2, 3][lv - 1],
				"cone_size": [3, 3, 5, 5][lv - 1],
				"prime": {"type": "chain", "after": "overhead_slam"},
			}
		"execution":
			# Batch A (ladder #25). CHAIN finisher after shockwave (sequence
			# fixed, default #4); the target must be Prone or Helpless (declare
			# validation, re-checked at resolution — standing up mid-windup
			# escapes the finisher) and the part must be Head or Torso. 4 Crush
			# at L1, +2/+4/+6 (data rows, PLACEHOLDER R14). A landed Torso hit
			# adds Shock T3 (Faint); a Head kill rides the normal lethal path
			# (Prone/Helpless already satisfy the head gate via Exposed — no
			# bypass flag needed). Chained cost 2 (data row) — a windup.
			spec = {
				"archetype": "downed_finisher",
				"cost": 2,
				"damage_type": "crushed",
				"amount": [4, 6, 8, 10][lv - 1],
				"attack_range": 1,
				"torso_shock_tier": 3,
				"prime": {"type": "chain", "after": "shockwave"},
			}
		"thousand_cuts":
			# Batch A (ladder #28). CHAIN finisher after pressure_strike on the
			# SAME target (fixed below L9). 3 chosen distinct parts, 1 Bleed each
			# at L1; the L2-4 rows were EMPTY in data/skills.json (data-hygiene
			# #3) and are authored here + in the data as +1 Bleed per cut per
			# level — PROVISIONAL, all numbers PLACEHOLDER (R14). When all 3
			# hits land on parts that ALREADY had active Bleed, each advances
			# +1 tier ON TOP of the engine-standard reapply advance (the rider
			# is the authored all-3 payoff; without it the clause would add
			# nothing over R4's normal reapply). Reposition up to 2 after the
			# final strike. Chained cost 2 (data row) — a windup.
			spec = {
				"archetype": "multi_part_flurry",
				"cost": 2,
				"damage_type": "bleeding",
				"amount": lv,
				"attack_range": 1,
				"parts_required": 3,
				"reposition": 2,
				"prime": {"type": "chain", "after": "pressure_strike", "same_target": true},
			}
		"controlled_sweep":
			# Batch A (ladder #1). Physique, cost 1. Up to mob_limit extra
			# adjacent Mob-category targets struck as SEPARATE single-target
			# strikes in one declare (3 at L1, +1/level — data rows). Damage is
			# the weapon's / the action's own (no spec damage_type: the sweep
			# inherits, per the audit's "single target attack on each"). GATE:
			# at least 2 Mobs adjacent — implemented as DECLARE VALIDATION, not
			# a STATE-prime extension (deliberate: the canonical STATE predicate
			# reads one subject's status; a counted-adjacency predicate would
			# widen the prime vocabulary mid-batch — revisit only if a second
			# skill needs it). Mob-only below the L6 Elite rung (threshold data).
			# Sweeps never merge (R15): separate strikes, no combo_id.
			spec = {
				"archetype": "adjacent_mob_sweep",
				"cost": 1,
				"attack_range": 1,
				"mob_limit": 2 + lv,
			}
		"slice_n_dice":
			# Batch A (ladder #43; Sasha's). Cost 2 (windup). The G8 unambiguous
			# math rewrite (rulebook skills-passover, applied to the live app):
			#   single target: limb_bleed to EACH of two limbs, OR torso_bleed
			#   to the Torso; two adjacent targets: limb_bleed to one limb on
			#   each, OR pair_torso_bleed to each Torso.
			# L1: limbs 2 / torso 3 / pair-torso 1; L2-4 rows scale torso
			# +1/+1/+2 and limbs +0/+1/+1 (data rows; the pair-torso variant
			# rides the torso increments — PROVISIONAL). All PLACEHOLDER (R14).
			# Display name NOT pinned (F7 rename caution) — data-sourced only;
			# this spec and its events carry only the sim key.
			spec = {
				"archetype": "crossing_arc_strike",
				"cost": 2,
				"damage_type": "bleeding",
				"amount": [2, 2, 3, 3][lv - 1],  # limb value = the representative amount
				"limb_bleed": [2, 2, 3, 3][lv - 1],
				"torso_bleed": [3, 4, 4, 5][lv - 1],
				"pair_torso_bleed": [1, 2, 2, 3][lv - 1],
				"attack_range": 1,
			}
		"heroic_punch":
			# Batch A (ladder #39; character-locked availability rides the
			# exclusive_to data pass, not this spec). Cost 1, committed unarmed
			# Crush: 2 at L1, +1/level (data rows, PLACEHOLDER R14). A landed
			# Head hit on an EXPOSED target adds Shock T1 (the head gate itself
			# is NOT bypassed — Exposure/Helpless/Overwhelmed open the head as
			# usual; the rider asks Exposed specifically). A landed Head hit is
			# the crowd beat (the data's POW graphic + Viewer spike): the
			# heroic_punch_pow event carries the authored spectacle payout
			# (PLACEHOLDER R14) through the HypeEngine hook. Display name NOT
			# pinned (F7) — data-sourced only.
			spec = {
				"archetype": "pow_strike",
				"cost": 1,
				"damage_type": "crushed",
				"amount": 1 + lv,
				"attack_range": 1,
				"head_shock_tier": 1,
				"pow_spectacle": 20,
			}
		"intercept":
			# Batch B (G6 passover row, skills.json id 46). Cost 0 (the free
			# slot) — the guard DECLARE: names ONE adjacent ally, resolution
			# ARMS the guard (armed_primes["intercept"] + the guard record).
			# While armed, a hit AIMED at that ally within guard_range
			# retargets to the guardian at the top of _strike_round (before
			# any dodge), costing the guardian's reaction slot per hit. The
			# L2-5 zig-zag (data rows): range +1 at L2, -1 physical damage
			# when intercepting at L3, range +2 (total) at L4; L5+ threshold
			# DATA. All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "retarget_guard",
				"form": "reaction",
				"cost": 0,
				"guard_range": [1, 2, 2, 3][lv - 1],
				"intercept_reduction": [0, 0, 1, 1][lv - 1],
			}
		"iron_stance":
			# Batch B (the Gemstone mutation result — Intercept Lv5 + Brace
			# Lv3, data/skill_mutations.json; skills.json id 49, acquisition-
			# gated). Cost 0 (the free slot) — a STANCE: while held, hits
			# AIMED at ANY adjacent ally (radius, L3 widens) retarget to the
			# stancer with NO reaction cost (the stance's value vs intercept's
			# one-per-tick reaction), plus a PERSISTENT (non-consumed) flat
			# reduction on covered-type damage the stancer takes — Crush/Burn
			# at L1 (-1), -2 at L2, Bleed/Chill join at L4. Breaks on the
			# stancer's movement or Prone (the dance-exit pattern; the
			# CombatSim _guard_checks sweep owns the break). PLACEHOLDER (R14).
			spec = {
				"archetype": "retarget_guard",
				"form": "stance",
				"cost": 0,
				"guard_radius": [1, 1, 2, 2][lv - 1],
				"stance_reduction": [1, 2, 2, 2][lv - 1],
				"stance_types": [["crushed", "burn"], ["crushed", "burn"],
					["crushed", "burn"], ["crushed", "burn", "bleeding", "chilled"]][lv - 1],
			}
		"pressure_hold":
			# Batch B (ladder #7). Cost 2 (windup — the committed clinch). The
			# R9 grapple as a skill: hold lands at resolution (grappling/
			# grappled_by — neither repositions, both Exposed via the existing
			# R9/ExposureEngine substrate; Physique < target's = Forced Body,
			# hold still lands). grip "hands" = the R9 free-hand gate. L2-4
			# scale the drag-while-holding distance (data rows: 1/2/3 spaces
			# per Moment — a cost-1 re-declare with "drag_to" while holding
			# walks the pair 1 hex at a time, the grab_pull idiom). L5+
			# threshold DATA. All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "skill_grapple",
				"cost": 2,
				"attack_range": 1,
				"grip": "hands",
				"drag": [0, 1, 2, 3][lv - 1],
			}
		"death_grip_jaws":
			# Batch B (G6 passover row, skills.json id 47 — approved WITHOUT a
			# prime). Cost 1 (instant). The jaws variant: grip "bite"
			# parameterizes the R9 hands gate — a bite-capable part
			# (data-driven `bite_capable` on the part plan; spec-declared,
			# additive) substitutes for hands; this is what unlocks grappling
			# for handless animal layouts. L2/L4 add the initial-bite Bleed
			# rider on close (1/2 Bleed through the honest R14 strike gate);
			# L3 adds the 1-space drag. L5+ threshold DATA. PLACEHOLDER (R14).
			spec = {
				"archetype": "skill_grapple",
				"cost": 1,
				"attack_range": 1,
				"grip": "bite",
				"drag": [0, 0, 1, 1][lv - 1],
				"bite_bleed": [0, 1, 1, 2][lv - 1],
			}
		"counter_surge":
			# Batch B (ladder #5). Cost 1 (instant). STATE prime: the target
			# must be mid-windup (the "winding_up" STATE predicate reads
			# Clock.has_windup_for — the data row's "currently executing a 2+
			# Moment cost action"). The strike inherits the action/item damage
			# (declare defaults the basic unarmed Crush 1 when none supplied);
			# a CONNECTED hit (damage_applied — a robustness-blocked 0 still
			# connected) CUTS the remaining windup cost by cost_cut (Clock
			# reschedule); a cut >= the remaining cost COLLAPSES the action —
			# the victim rolls Forced Action – BODY (the parameterized
			# collapse table, F3 — the feint path keeps Tool). L2-4 scale the
			# cut (data rows -2/-3/-4); L5+ threshold DATA. PLACEHOLDER (R14).
			spec = {
				"archetype": "interrupt_counter",
				"cost": 1,
				"attack_range": 1,
				"cost_cut": lv,
				"collapse_table": "body",
				"prime": {"type": "state", "who": "target", "status": "winding_up"},
			}
		"seal_the_wound":
			# Batch C (ladder #3; Filipe's / Nikita-kit condition manager).
			# Mind, cost 1 (instant). Delay Bleeding OR Infection on SELF or an
			# ADJACENT ally for delay_clocks Clocks (1 at L1, +1/+2/+3 — data
			# rows; PLACEHOLDER R14) via ConditionEngine.delay. HONESTY PIN
			# (FINAL default #8, applied verbatim): mode is DELAY ONLY at
			# L1-4 — never a cure, never HP; the ally_treatment resolver has
			# NO resolve branch and NO heal_part call, structurally. The L6
			# "resolve" rung stays threshold DATA. Delaying the condition that
			# drives a bleed-out stabilizes the downed ally (R5 — the delay()
			# machinery's existing _stabilize hook, not a special case).
			spec = {
				"archetype": "ally_treatment",
				"cost": 1,
				"treat_range": 1,
				"self_allowed": true,
				"treatable": ["bleeding", "infected"],
				"delay_clocks": lv,
			}
		"field_triage":
			# Batch C (G6 passover NEW_SKILL #11, skills.json id 48). Mind,
			# cost 1 (instant). Treat an ADJACENT ally's condition — delay one
			# advancement (delay_clocks: 1 at L1; L2 +1 Clock; L4 +2 Clocks
			# total over base — data rows) — CONSUMING a bandage_charge: the
			# generic charges STACK prime gates the declare (the audit's
			# "item-as-prime, R3's items-skip-primes inverted"), and the
			# resolver decrements the charge when the treatment actually
			# lands. Charges are GRANTED via the combatant spec's `charges`
			# field (CombatantState.from_spec) — the same generic counter
			# _stack_count already reads. L3 extends the treat range to 2
			# hexes (the data row's "treat at 1 space of range" read as one
			# space of SEPARATION — PROVISIONAL interpretation, flagged).
			# Ally-only (no self), any active condition. All numbers
			# PLACEHOLDER (R14); L6 "fully resolve once per combat" stays
			# threshold DATA (default #8 honesty pin applies here too).
			spec = {
				"archetype": "ally_treatment",
				"cost": 1,
				"treat_range": [1, 1, 2, 2][lv - 1],
				"self_allowed": false,
				"treatable": [],
				"delay_clocks": [1, 2, 2, 3][lv - 1],
				"consumes": "bandage_charge",
				"prime": {"type": "stack", "resource": "bandage_charge", "count": 1},
			}
		"read_the_pattern":
			# Batch C (ladder #6; Nikita's). Mind, cost 1 (instant). Reveal
			# one VISIBLE enemy's next scheduled action(s) until the Clock
			# reset: visibility is Stealth.sees — the OBSERVER's R30 facing
			# cone applies (the skill user must SEE the target; an enemy over
			# your shoulder cannot be read) — and the read reaches read_range
			# hexes (the authored 3; the L8 remote-read rung stays threshold
			# DATA). actions_revealed scales 1 -> 4 (the +1/+2/+3 Action data
			# rows; the Clock's one-scheduled-action cap makes >1 mostly
			# future-proofing, honestly). ZERO rng: the resolver deep-copies
			# Clock.scheduled_entries() rows into a deterministic
			# pattern_read event and records the reveal on the actor
			# (pattern_reads — swept clear at the Clock reset by CombatSim);
			# GameController exposes the live knowledge additively on the
			# OWNER's view_combatants row. All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "intel_reveal",
				"form": "declared_read",
				"cost": 1,
				"read_range": 3,
				"actions_revealed": lv,
			}
		"aura_reading":
			# Batch C (ladder #29; Filipe's). Mind, PASSIVE, cost 0 — no
			# declare exists (declaring rejects passive_skill): OWNING the
			# skill is the mechanic. The wave-3a substrate pays off: a
			# combatant with aura_reading granted gets the ai_stance of every
			# enemy they can currently SEE (Stealth.sees — the R30 facing
			# cone gates it) within aura_range hexes (3 at L1, +1/+2/+3 —
			# data rows) exposed additively on THEIR view_combatants row
			# (GameController._aura_reads). FEELING, never intent: the stance
			# string only — actions are Read the Pattern's lane, thoughts are
			# Telepathy's (the FINAL lane-authoring note). Broadcast
			# omniscience is unchanged — every row's ai_stance field stays;
			# this gates the CONTESTANT-facing knowledge surface only.
			# All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "intel_reveal",
				"form": "passive_aura",
				"cost": 0,
				"aura_range": 2 + lv,
			}
		"mind_burst":
			# Batch C (ladder #19). [MAGIC] Mind, cost 2 (windup). The strike
			# VARIANT: a psychic hit that applies Shock T2 through
			# ConditionEngine.apply_shock — the stated-tier + escalation
			# model (R13) handles already-Shocked targets (old tier ->
			# max(old + 1, 2); the head part is passed so re-abusing the same
			# organ elevates per R13's per-organ rule). No HP damage, no
			# physical dodge (the R22 dodge is Reflexes-vs-physical —
			# documented). May target the HEAD regardless of Exposure:
			# bypass_head_gate (the audit's shared shape with decapitate).
			# Requires line of sight below the L8 remote-stun threshold rung
			# (Stealth.has_los — LOS only, not the sight cone: the burst is
			# aimed, the spec range is its own gate). Range 5 at L1,
			# +5/+10/+15 (data rows). The data's "Req Telepathy Lv 3" is an
			# UNLOCK requirement (KAN-7 progression / acquisition), NOT a
			# runtime prime — deliberately not encoded here, exactly like
			# every other unlock_requirements row. PLACEHOLDER (R14).
			spec = {
				"archetype": "psychic_strike",
				"cost": 2,
				"attack_range": 5 * lv,
				"shock_tier": 2,
				"bypass_head_gate": true,
			}
		"acrobatic_save":
			# Batch C (ladder #37). Reflexes, cost 0 — the REAL cost is the
			# G1 MOVEMENT FORFEIT (owner 2026-07-23, rules-addendum R25:
			# "Acrobatic Save gets the same movement-forfeit cost in place of
			# its cooldown" — NO prime, NO stance; the ladders doc's old
			# "re-express as a prime" note is SUPERSEDED by its 2026-08-18
			# tail annotation). Declaring consumes the Moment's movement
			# (moved_this_tick — the tactical_roll plumbing) and ARMS the
			# save; the owner's next Forced Action – BODY roll draws
			# extra_dice extra dice (1 at L1, +1/+2/+3 — data rows) from the
			# SAME action rng stream, every die emitted, and keeps the
			# LOWEST-severity consequence (ForcedAction.save_severity — the
			# documented deterministic rule; a tie keeps the ORIGINAL roll).
			# The arming is consumed per roll. PROVISIONAL: the arming
			# persists until that next Body roll consumes it (G1 prices the
			# arming, not a window — revisit with R14). The L6 "any fumble"
			# (Tool) rung stays threshold DATA. PLACEHOLDER (R14).
			spec = {
				"archetype": "forced_roll_save",
				"cost": 0,
				"extra_dice": lv,
			}
		"poison_ball":
			# Batch D (ladder #10). [MAGIC] Mind, cost 2 (windup). Ranged
			# declare at a target hex ("at", within attack_range + LOS — the
			# L8/L9 remote-origin rungs stay threshold data); detonation =
			# HexGeometry.blast(at, blast_radius); each caught combatant takes
			# one _strike_round row: the impact splatter (amount — a PLACEHOLDER
			# R14 number; the book authors no HP line, but the R14 wound gate is
			# what lets the toxin seed at all) delivering Tier-1 Poison. The
			# poison ENTRY-CONDITION gate applies PER TARGET inside the
			# condition system itself (_poison_gate_and_soup: an unwounded,
			# un-helpless, non-head hit is condition_ignored / no_entry_condition
			# — the L9 self-supplied-entry rung stays data). poison_type is the
			# AUTHORED hemo below the L6 choose-the-toxin rung (threshold data)
			# — stamped onto the action at declare so the soup machinery reads
			# it. Radius rows +1/+1/+2, range rows +5 at L3/L4 (data;
			# PLACEHOLDER R14).
			spec = {
				"archetype": "aoe_blast",
				"cost": 2,
				"damage_type": "poison",
				"amount": 1,
				"attack_range": [20, 20, 25, 25][lv - 1],
				"blast_radius": [3, 4, 4, 5][lv - 1],
				"poison_type": "hemo",
			}
		"frost_ball":
			# Batch D (ladder #12). [MAGIC] Mind, cost 2 (windup). G8 BINDS the
			# damage typing: "2 Chill Damage" -> flat damage + Chilled T1 —
			# "Chilled deals no HP damage; the DAMAGE is the impact, type
			# CRUSH". So the per-target row is a real crush round (force vs
			# robustness, brace/iron-stance interactions, and R4's coupling: a
			# LANDED crush impact seeds Crushed T1 exactly like every crush hit
			# — the engine's own rule, documented) and the authored Chilled T1
			# rides as a separate rider on every caught, un-escaped target
			# (not dodged, not surface-blocked; Chilled is not wound-gated, so
			# a robustness-blocked impact still chills — the normal-path rule).
			# Damage rows +1/+1/+2, area rows +1 at L3/L4 (data; PLACEHOLDER
			# R14).
			spec = {
				"archetype": "aoe_blast",
				"cost": 2,
				"damage_type": "crushed",
				"amount": [2, 3, 3, 4][lv - 1],
				"attack_range": 20,
				"blast_radius": [2, 2, 3, 3][lv - 1],
				"rider_condition": "chilled",
			}
		"fire_ball":
			# Batch D (ladder #14). [MAGIC] Mind, cost 2 (windup). Burn damage
			# + Burn T1 through the normal R4 coupling (burn IS the condition),
			# 3-space radius (no area rows — the L6 cluster stays threshold
			# data). IGNITES FLAMMABLES: every trash can in the blast takes the
			# per-round burn amount as a TOUCH through the existing can-ignition
			# family (_ignite_cans_in_blast — the cone machinery's blast-shaped
			# sibling; accumulate-or-pop, cascades via _explode_cans, zero
			# arena behavior change). Damage rows +1/+2/+3 (data; PLACEHOLDER
			# R14).
			spec = {
				"archetype": "aoe_blast",
				"cost": 2,
				"damage_type": "burn",
				"amount": lv,
				"attack_range": 20,
				"blast_radius": 3,
				"ignites_flammables": true,
			}
		"camouflage":
			# Batch D (ladder #44). Reflexes/Mind, cost 3 (the authored
			# 3-Moment concealment windup). Resolves into STEALTH on the R20
			# substrate with the concealment MODIFIER: combatant.conceal
			# {"radius", "anchor"} — Stealth.sees caps every observer's
			# effective sight range at reveal_radius ("revealed only within N
			# spaces"; L2-4 shrink it — data rows -1/-2/-3 off the authored ~6,
			# PLACEHOLDER R14), so entry is legal in plain sight of a DISTANT
			# watcher (the unlock's own fiction) and the reveal sweep honors
			# the shrunk radius. BREAKS ON MOVEMENT: any displacement off the
			# anchor hex (voluntary or involuntary — the iron_stance rule)
			# breaks camouflage and the stealth it rides (CombatSim sweep,
			# reason "moved"; the L6 move-one-hex rung stays threshold data),
			# alongside every normal stealth break (seen/shout/downed/reveal).
			spec = {
				"archetype": "stealth_conceal",
				"cost": 3,
				"reveal_radius": [6, 5, 4, 3][lv - 1],
			}
		"vibe_control":
			# Batch D (ladder #31; G4 rework — fiction only, mechanics kept).
			# Charm, cost 1 (instant). Two modes vs a PERCEIVING hostile — the
			# target must currently SEE the actor (Stealth.sees: the TARGET's
			# R30 facing cone, 2×Mind range, LOS — a Mind-0 or cone-blocked
			# enemy cannot be vibed; that IS the perception gate).
			#   FEAR ("too striking to approach"): 1-hex push directly away
			#   (the batch-A knockback helper, wall-honest) + a grudge
			#   REDUCTION toward the actor (EnemyAI.reduce_antagonism —
			#   de-prioritize, floor 0; fear_calm PLACEHOLDER R14).
			#   CHARM ("can't look away"): fixation — a grudge INCREASE toward
			#   the actor (charm_fixate PLACEHOLDER R14) + the target FACES the
			#   actor (the second ruled involuntary facing, the grapple's
			#   mirror) + the actor may reposition 1 hex while they're fixed +
			#   the target is Exposed for exposed_ticks — the ladder's
			#   "Exposed-from-behind" whose "behind" half is the REAL R30
			#   is_behind gate (decision #33): with the facing locked onto the
			#   actor, the rear arc is exactly where the fixation can't watch.
			# L2/L4 "+1 resist penetration" rows are CARRIED as data
			# (resist_penetration — G4 defines it vs mental resistance; no
			# mental-resistance gate exists below the L9 rung, so nothing
			# consumes it yet — documented, not faked). L3 +2 range (data).
			# Display name NOT pinned (v2 Group E) — data-sourced only.
			spec = {
				"archetype": "projection_control",
				"cost": 1,
				"attack_range": [3, 3, 5, 5][lv - 1],
				"resist_penetration": [0, 1, 1, 2][lv - 1],
				"fear_push": 1,
				"fear_calm": 2.0,
				"charm_fixate": 2.0,
				"charm_reposition": 1,
				"exposed_ticks": 2,
			}
		"play_to_the_camera":
			# Batch D (G6 passover NEW_SKILL, skills.json id 50). Charm, cost 1
			# (instant). The STACK prime spends ONE Camera-Call stack — the
			# "camera_call" resource now honestly reads REMAINING stacks
			# (derived total minus HypeEngine.camera_calls_used, the same
			# ledger the spotlight command spends). Resolving opens the timed
			# party-wide surge window in HypeEngine (serialized only-when-set):
			# points credited to party members ×surge_multiplier until the
			# actor's next Moment (SUBJECT attribution — the spotlight's own
			# doubling model, glorious and embarrassing beats alike); L2-4
			# lengthen the window (+1/+2/+3 Moments — data rows, imported in
			# batch B; PLACEHOLDER R14). The L5 survives-a-hit and L6
			# editors-cut (losses stop doubling) rows stay threshold DATA.
			# Display name NOT pinned (v2 Group E) — data-sourced only.
			spec = {
				"archetype": "hype_surge",
				"cost": 1,
				"surge_multiplier": 2,
				"surge_bonus_moments": lv - 1,
				"prime": {"type": "stack", "resource": "camera_call", "count": 1},
			}
		"telekinesis":
			# Batch D (ladder #17). [MAGIC] Mind, cost 1. Grip ONE visible
			# target at range (front arc + 2×Mind sight + LOS — team-agnostic
			# visibility; the G8-reconciled L6 "no longer Exposed" and L7
			# "move while sustaining" stay threshold data). While the channel
			# lives: the actor is Exposed (ExposureEngine — the R9-grapple
			# mirror) and rooted (move/tactical-roll reject "channeling"); the
			# target cannot take movement actions (held_by — move/roll/leap
			# reject "held"; arms stay free per the authored line). UPKEEP:
			# the sustain occupies the actor's scheduled action each Moment —
			# a cost-1 {"sustain": true} re-declare per tick; declaring any
			# other scheduled action abandons the grip, an unpaid Moment
			# lapses it at tick end (CombatSim), and a free {"release": true}
			# declare drops it voluntarily (abandoning a state — the stealth-
			# reveal precedent). A sustain may carry "drag_to": one hex of
			# forced movement for the target (wall/bounds/can/body-honest; the
			# dragged body's facing never changes — R30 involuntary). ENDS on
			# actor damage (any damage this tick — the sweep), grapple contact,
			# helpless/downed either side, or the target leaving range/LOS at
			# a sustain. The data's throw line stays UNIMPLEMENTED content
			# (not in this story's L1 core — documented). Range rows +3/+6/+9
			# (data; PLACEHOLDER R14).
			spec = {
				"archetype": "sustained_channel",
				"cost": 1,
				"grip_range": [10, 13, 16, 19][lv - 1],
				"drag": 1,
			}
		"juggling":
			# Batch D (ladder #32; the [spectacle L10] tail stays data).
			# Reflexes, cost 0 — the FREE-SLOT economy ("absorbed into an
			# existing action": R3's one free action per tick IS the price).
			# The first combatant-to-combatant item transfer primitive: moves
			# ONE item dict between two combatants within pass_range, the
			# juggler always one end ("from"/"to"; both-other flows are the L6
			# mass-flow rung — data). Enemy-source flow only for DROPPED items
			# (G8: disarm gated to unwielded/dropped; wielded disarm is the L7
			# payoff, threshold data); ally-source and own-item passes move
			# freely; the transferred dict keeps its whole state (magazine
			# rounds included) and lands un-dropped in the catcher's hands.
			# Range rows +3/+6/+9 over the G8-reconciled base 5 (data;
			# PLACEHOLDER R14).
			spec = {
				"archetype": "item_flow",
				"cost": 0,
				"pass_range": [5, 8, 11, 14][lv - 1],
			}
		"perfect_evasion":
			# Tier-2 wave 1 (S5, M6: Tactical Roll Lv5 + Acrobatic Save Lv3 —
			# BLESSED 2026-08-18). Reflexes, 0 Moments — the R25 MOVEMENT
			# FORFEIT is the whole price (no stance, no charges, no cooldown;
			# both parents already priced by it). ONE declare arms BOTH
			# defenses: the declared-hex roll (roll_range hexes, moves at
			# declare, the AoE-center rule applies) AND the armed save
			# (extra_dice on the next Forced Body, keep the lowest severity).
			# L1 anchors >= the parents' L5 values (roll L5 = 8 spaces, save
			# L5 = 5 dice — PLACEHOLDER R14, threshold rows 15/67 read as
			# totals); L2-4 scale both halves together (S5-b). second_roll
			# gates S5-c (OQ2 RULED: a second distinct attack in the same
			# window may be answered by a second declared-hex roll — the
			# forfeit is never waived, and never re-charged). negate gates
			# S5-d ([FROM row 68]: once per Clock the armed save negates a
			# Forced Action – Body outright). L5 stays threshold DATA.
			spec = {
				"archetype": "fused_evasion",
				"cost": 0,
				"roll_range": [8, 9, 10, 11][lv - 1],
				"extra_dice": [5, 6, 7, 8][lv - 1],
				"second_roll": lv >= 3,
				"negate": lv >= 4,
			}
		"vice_grip":
			# Tier-2 wave 1 (S7, M8: Pressure Hold Lv5 + Death Grip Jaws Lv3
			# — AND the mirrored twin vice_grip_animal: Jaws Lv5 + Hold Lv3,
			# SAME result key; BLESSED 2026-08-18). Cost 1 (the R9 initiate —
			# the ladder header). GRIP-NEUTRAL: grip "any" satisfies the R9
			# grip gate with hands OR a bite-capable part — one skill for
			# every body plan (_grip_unmet's third value). While held: the
			# standard R9 hold (no reposition, both Exposed) + drag up to
			# `drag` spaces per Moment (L1 >= the Hold's L5 drag 4; L4 = row
			# 12's 5 — PLACEHOLDER R14; the R11.7 drag override). grip_bleed
			# (S7-b, [FROM row 86], L2+): the grip closes with a real 1-Bleed
			# wound on the held part through the honest R14 strike gate — the
			# standing per-Clock condition advancement carries the wound
			# forward; the literal while-held per-reset re-application NEEDS
			# the Clock-reset rider (combat_sim's sweep — outside this
			# story's footprint, rung content carried as data). S7-c
			# (multi-hold/limb-pin) stays DATA ([NEEDS]); S7-d's
			# grapple-Suffocation rides the EXISTING grapple_suffocate kind —
			# at L4+ a full jaw grip substitutes for the both-hands gate
			# (_validate_grapple_suffocate; R9 boss/size caps uncut). L5
			# stays threshold DATA.
			spec = {
				"archetype": "skill_grapple",
				"cost": 1,
				"attack_range": 1,
				"grip": "any",
				"drag": [4, 4, 4, 5][lv - 1],
				"grip_bleed": [0, 1, 1, 1][lv - 1],
			}
		"phantom_grasp":
			# Tier-2 wave 1 (S10, OFFER: Telekinesis Lv5 + Pressure Hold Lv3
			# — broad-only `control`, BLESSED 2026-08-18; OQ1 RULED:
			# mundane-PSIONIC, not magic — is_magic 0 on the data row, no
			# magic privileges ever on this band). Mind, cost 1 + sustain.
			# The sustained_channel substrate with HOLD semantics: grip one
			# visible target at range (target movement-locked via held_by —
			# R9's lock at range), actor Exposed + rooted while sustaining,
			# upkeep/lapse/break-on-damage all shipped. The grip "psychic"
			# value marks the channel as a trained HOLD on the R9 gate set:
			# the target may escape per R9's escape ACTIONS, and the escape
			# contest swaps the holder's stat — target's Physique vs the
			# holder's MIND (OQ1 ruled; ActionResolver.escape_holder_stat).
			# Drag per sustain walks up to `drag` hexes (the trained hold
			# replaces raw lifting; telekinesis keeps its 1). L1 range >= the
			# parent's L5 range 22 (PLACEHOLDER R14, threshold row 31 read
			# as a total). S10-c (collision damage), S10-d (multi-hold) and
			# S10-e (suffocation for a channel hold) stay DATA ([NEEDS] —
			# cross-footprint or unbuilt). L5 stays threshold DATA.
			spec = {
				"archetype": "sustained_channel",
				"cost": 1,
				"grip_range": [22, 24, 26, 28][lv - 1],
				"drag": [2, 3, 3, 4][lv - 1],
				"grip": "psychic",
			}
		"combat_medic":
			# Tier-2 wave 2 (S6, M7: Seal The Wound Lv5 + Field Triage Lv3 —
			# BLESSED 2026-08-18). Mind, cost 1 (instant). The fused medic:
			# treat SELF or ANY ally within treat_range (L1 = 2, Triage's L5
			# reach — threshold row 87 read as a total), delay ANY condition
			# (both parents' lanes fused: no treatable list) delay_clocks
			# Clocks (L1 = 4, >= Seal's L5 total — row 5's "+3 Clock" over
			# base 1). Triage's economy kept via ally_consumes: an ALLY
			# treatment requires + consumes a bandage_charge (the declare
			# gate lives in _validate_ally_treatment — conditional on the
			# target, so no unconditional STACK prime fits); SELF treatment
			# never touches the counter (Seal's lane had no charge). S6-c
			# (arrest/freeze) stays DATA ([NEEDS] — a hold-open distinct
			# from multi-Clock delay). S6-d (L4, [FROM row 6 — audit fix:
			# Crush dropped]): resolve_conditions unlocks the RESOLVE mode —
			# fully remove one active Infection or Bleeding, once per Clock,
			# through ConditionEngine.treat's own gates; never HP, never a
			# lethal state (default #8 — the boundary is enforced, not
			# assumed). S6-e stays threshold DATA (row 98). All numbers
			# PLACEHOLDER (R14).
			spec = {
				"archetype": "ally_treatment",
				"cost": 1,
				"treat_range": [2, 3, 3, 3][lv - 1],
				"self_allowed": true,
				"treatable": [],
				"delay_clocks": [4, 5, 5, 6][lv - 1],
				"ally_consumes": "bandage_charge",
			}
			if lv >= 4:
				spec["resolve_conditions"] = ["infected", "bleeding"]
		"counterscript":
			# Tier-2 wave 2 (S1, M2: Counter-Surge Lv5 + Read The Pattern
			# Lv3 — BLESSED 2026-08-18). Physique/Mind, cost 1 (both modes).
			# The fusion: mode "read" holds the standing read (read_range =
			# the parent's authored 3; actions_revealed L1 >= the parent's
			# L5 total 5 — row 9's "+4 Action"; L3 adds row 10's +4);
			# read_targets caps CONCURRENT reads (S1-c: the second enemy at
			# L3+ — reading past the cap replaces the oldest). Default mode
			# "counter": strike an ADJACENT read target — the widened gate
			# (no winding_up prime: any declared action of the read target
			# with remaining cost); the strike inherits action/item damage
			# (the counter_surge basic-unarmed default); a connected hit
			# cuts cost_cut (L1 = 5, >= the parent's L5 cut — row 7; the
			# S1-b deepen continues the band), collapse -> Forced BODY (the
			# parameterized table). immunity_moments (S1-b, L2+ — [FROM row
			# 8]): a cut that does NOT collapse arms the per-source
			# 3-Moment immunity window. S1-d/e stay DATA ([NEEDS] R15
			# hooks / boss telegraph exposure — cross-footprint; threshold
			# row 93). All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "fused_counter",
				"cost": 1,
				"attack_range": 1,
				"read_range": 3,
				"actions_revealed": [5, 5, 9, 9][lv - 1],
				"read_targets": [1, 1, 2, 2][lv - 1],
				"cost_cut": [5, 6, 6, 7][lv - 1],
				"collapse_table": "body",
				"immunity_moments": [0, 3, 3, 3][lv - 1],
			}
		"quick_step":
			# Round 3a (ladder #2). Reflexes, cost 0 — and SLOT-FREE (design
			# call, documented at _declare_terrain_stride: the stride rides
			# the movement it modifies; charging the R3 slot would price the
			# L1 window out of its own payload — the free move needs that
			# slot the same Moment). An IMMEDIATE self-declare (the arming
			# pattern — the window must exist before this tick's move, so
			# nothing schedules): opens a timed window in
			# which the R33 cost overlay prices difficult AND rough hexes as
			# normal ground for the strider (the story's ruling: both
			# slow-ground types read 1; WATER stays priced — that lane is
			# swim's). Duration in Moments: 1 at L1 ("for this moment") +1/+2/
			# +3 (data rows) — PLACEHOLDER (R14). Gate: "Must have movement
			# remaining" (the data requirement) — declaring after this tick's
			# movement rejects movement_spent. The L5 "+4 Duration" and L6
			# "Ignore Physical terrain effects" rows stay threshold DATA.
			spec = {
				"archetype": "terrain_stride",
				"cost": 0,
				"stride_moments": lv,
				"stride_types": ["difficult", "rough"],
			}
		"swim":
			# Round 3a (ladder #30). Physique, PASSIVE, cost 0 — no declare
			# exists (declaring rejects passive_skill): OWNING the skill is
			# the mechanic. Two lanes off the R33/R9 substrates:
			#  * the cost overlay: water prices 1 for a swim owner. Honesty
			#    note (the destination-cost contract): a priced move enters
			#    exactly ONE terrain hex — its destination — so the L1 "+1
			#    space of movement when swimming" exactly cancels the single
			#    water surcharge; the L2-4 "+1 Movement" rows have no further
			#    bite under this model and stay data-annotated until a
			#    per-step pricing model exists (documented coarseness).
			#  * the drowning track: CombatSim's Clock-reset water sweep reads
			#    the grant — a swim owner's submersion suffocation timer
			#    starts with suffocation_grace_clocks of delay ("extends the
			#    Suffocation timer by 1 Clock before it begins" — the L1
			#    core; constant through L1-4: the L2-4 rows author movement,
			#    and the L6 "+2 Clocks total" rung stays threshold DATA).
			#    Surfacing within the grace never advances the track — the
			#    L1 swimmer is exempt in every short dip. PLACEHOLDER (R14).
			spec = {
				"archetype": "terrain_affinity",
				"cost": 0,
				"water_affinity": true,
				"suffocation_grace_clocks": 1,
			}
		"acrobatics":
			# Round 3a (ladder #42). Reflexes, PASSIVE, cost 0 — never
			# declarable (the aura pattern). Rough-terrain immunity via the
			# R33 cost overlay: rough prices 1 for an acrobatics owner
			# (difficult stays priced — that lane is quick_step's; water is
			# swim's). The L2-4 "+1 Movement when performing an acrobatic
			# maneuver" rows extend the DECLARED ROLL range (+1/+2/+3 on
			# tactical_roll / the fused evasion's roll half) — the sim's
			# acrobatic maneuver ("Do a barrel roll!"); PROVISIONAL reading,
			# documented at the seam. Falls do not exist in the sim: every
			# safe-fall clause ("Safe falling distance +1", L9's fall
			# immunity) stays data-annotated; balance/jump/climb prose has no
			# substrate either — data. L6 3D traversal stays threshold DATA.
			# All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "terrain_affinity",
				"cost": 0,
				"rough_affinity": true,
				"acrobatic_move_bonus": lv - 1,
			}
		"lockpicking":
			# Round 3a (ladder #41). Reflexes, the SCHEDULED pick the R33
			# downscope deferred to this story. Declare adjacent to a LOCKED
			# door ("door": key); the validator prices the attempt off the
			# substrate tier table (Arena.LOCK_PICK_MOMENTS: simple 1 /
			# moderate 2) minus the authored "-1 Moment" rows (discount_tiers;
			# floor 1 — a scheduled act costs at least 1 Moment, PLACEHOLDER
			# R14) and stamps action.cost, so the Moments flow through the
			# normal schedule (a cost-2 moderate pick is a real windup:
			# feint-able, and a premise break at resolution collapses into
			# Forced Action – Tool — the data's own failure path). Tier
			# access: simple at L1+, moderate at L3+ (data rows); complex is
			# the L5 threshold and magical the L6 (+ the special capability,
			# the L9 rung) — BOTH stay threshold DATA, so an L1-4 declare
			# against them rejects (magical rejects magical_lock_needs_special
			# — the substrate's own vocabulary — without the flag). Resolve
			# calls CombatSim.pick_lock (the R33 API), reporting the Moments
			# actually charged. The data's "thin tool" requirement and
			# "Reflexes 3" stay un-modeled like every other skill's
			# requirements prose (unlock/acquisition scope — documented).
			spec = {
				"archetype": "scheduled_pick",
				"cost": 2,
				"pick_tiers": [["simple"], ["simple"],
					["simple", "moderate"], ["simple", "moderate"]][lv - 1],
				"discount_tiers": [[], ["simple"],
					["simple"], ["simple", "moderate"]][lv - 1],
			}
		"poison_wall":
			# Round 3a (ladder #11). [MAGIC] Mind, cost 2 (windup). A placed
			# LINE of toxic vapor on the R32 zone substrate: length 5 at L1
			# (+1/+2/+3 Space — data rows), range 5 (the data's range; every
			# wall hex within reach + LOS), persists 1 Clock. The authored
			# effect — "passes through or starts their Moment inside takes
			# Tier 1 Poison (Pneumotoxin)" — maps onto the substrate's three
			# triggers verbatim: on_enter (stepping in) / on_pass (a dash
			# crossing) / on_occupy_clock (starting inside at the reset — the
			# substrate's occupancy granularity, documented). The Poison rows
			# ride source "attack", so the ENTRY-CONDITION gate applies per
			# victim inside the condition system itself (an unwounded walker
			# is condition_ignored / no_entry_condition — the honest gate;
			# the L9-family "applies without entry conditions" stays data).
			# affects "all" — the caster's own wall poisons the caster too
			# (the R32 fire-wall precedent; ally-safe is the L9 rung, data).
			# poison_type pneumo (the authored toxin; L6 choose-the-toxin
			# stays threshold DATA). All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "wall_conjure",
				"cost": 2,
				"attack_range": 5,
				"wall_length": [5, 6, 7, 8][lv - 1],
				"zone": {
					"key": "poison_wall",
					"duration_clocks": 1,
					"hp": -1,
					"blocks_movement": false,
					"blocks_los": false,
					"effects": {
						"on_enter": {"affects": "all", "conditions": [
							{"condition": "poison", "tier": 1, "part": "torso",
								"poison_type": "pneumo", "source": "attack"}]},
						"on_pass": {"affects": "all", "conditions": [
							{"condition": "poison", "tier": 1, "part": "torso",
								"poison_type": "pneumo", "source": "attack"}]},
						"on_occupy_clock": {"affects": "all", "conditions": [
							{"condition": "poison", "tier": 1, "part": "torso",
								"poison_type": "pneumo", "source": "attack"}]},
					},
				},
			}
		"frost_wall":
			# Round 3a (ladder #13). [MAGIC] Mind, cost 2 (windup). A placed
			# LINE of solid ice: length 5 (data-hygiene #8 CLEANED at
			# implementation — the target line's 5 wins over the garbled
			# text's 6), range 5, persists 2 Clocks or until destroyed. The
			# zone BLOCKS movement (Arena.is_wall parity — moves, dash lanes
			# and bounces, staging, pathing) AND projectiles/sight
			# (blocks_los — the lane channel; a solid ice wall is honestly
			# lane-solid, so the R32 shared-choke-point caveat is a feature
			# here, not a debt). Wall HP 3 at L1 (+2/+4/+6 — data rows),
			# worn down ONLY through the zone-attack path
			# (ActionResolver._resolve_zone_attack -> CombatSim.damage_zone:
			# the R14 gate vs Zones.WALL_ROBUSTNESS, burn-typed damage x2 —
			# the authored "Burn damage deals twice as much"); destroyed at 0
			# unblocks the hexes (zone_expired "destroyed"). The chill
			# semantics — "strikes or collides ... Chilled Tier 1 to the
			# striking limb" — land on ADJACENT strikers at the zone-attack
			# seam (strike_chill_tier; a ranged striker's limb never touches
			# the ice; dash-collision chill has no collision seam this story
			# — documented honest gap). No enter/occupy effects: a blocking
			# wall cannot be stood in. L6 chill-heal stays threshold DATA;
			# raise-under-a-target is the L8 rung (zone_blocked_by_body holds
			# — the R32 door-close precedent). All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "wall_conjure",
				"cost": 2,
				"attack_range": 5,
				"wall_length": 5,
				"strike_chill_tier": 1,
				"zone": {
					"key": "frost_wall",
					"duration_clocks": 2,
					"hp": [3, 5, 7, 9][lv - 1],
					"blocks_movement": true,
					"blocks_los": true,
					"effects": {},
				},
			}
		"fire_wall":
			# Round 3a (ladder #15). [MAGIC] Mind, cost 3 (the authored
			# windup). A placed LINE of fire: length 5 at L1 (+1/+2/+3 Space
			# — data rows), range 5, persists 1 Clock, indestructible (hp -1
			# — "cannot be destroyed, only outlasted": the zone-attack
			# validator rejects it as a target). The authored effect maps
			# onto the triggers: passing through (on_enter / on_pass) = Burn
			# T1; starting inside (on_occupy_clock — the substrate's
			# Clock-reset occupancy bite, its own granularity for "starts
			# their Moment inside", documented) = Burn T2. Burn rows ride
			# source "attack" (the once-per-tick advance cap; Burn carries no
			# entry gate) on the torso — the "all exposed body parts" breadth
			# is a magnitude-family detail deferred with R14 (multi-part rows
			# would remap onto non-human plans dishonestly — documented
			# coarseness). affects "all": the caster burns in their own wall
			# (R32's words). The L6 "passers take tier 2 Shock" rung stays
			# threshold DATA (the vocabulary already carries it — R32's own
			# example). All numbers PLACEHOLDER (R14).
			spec = {
				"archetype": "wall_conjure",
				"cost": 3,
				"attack_range": 5,
				"wall_length": [5, 6, 7, 8][lv - 1],
				"zone": {
					"key": "fire_wall",
					"duration_clocks": 1,
					"hp": -1,
					"blocks_movement": false,
					"blocks_los": false,
					"effects": {
						"on_enter": {"affects": "all", "conditions": [
							{"condition": "burn", "tier": 1, "part": "torso",
								"source": "attack"}]},
						"on_pass": {"affects": "all", "conditions": [
							{"condition": "burn", "tier": 1, "part": "torso",
								"source": "attack"}]},
						"on_occupy_clock": {"affects": "all", "conditions": [
							{"condition": "burn", "tier": 2, "part": "torso",
								"source": "attack"}]},
					},
				},
			}
		"tactical_roll":
			# Reflexes, 0 Moments — the cost is the actor's MOVEMENT for the
			# Moment (G1, owner 2026-07-23; rules-addendum R25): a declared-hex
			# dodge that moves IMMEDIATELY at declare and forfeits this tick's
			# move. Roll range: base 2 hexes at L1 (PLACEHOLDER R14 — the book
			# says 1; the digital base is under tuning) + the seed-data ladder's
			# space increments (skills.json id 9: L2 "+1 Space", L3 "+1 Space",
			# L4 "+2 Space" — each row's "-2 Moment cooldown" rider is DEAD text
			# per G1/R3: no cooldowns). The L5/L6 threshold rows (char-sheet
			# template ids 15–16, cooldown-based) are superseded and un-ruled —
			# DATA-ONLY, not implemented.
			spec = {
				"archetype": "declared_dodge",
				"cost": 0,
				"roll_range": [2, 3, 4, 6][lv - 1],
			}
		_:
			spec = FALLBACK.duplicate(true)
	spec["key"] = key
	spec["level"] = level
	return spec
