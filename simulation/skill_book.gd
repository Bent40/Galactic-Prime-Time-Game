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
##                          — mode is DELAY ONLY (FINAL default #8: never a cure,
##                          never HP; no resolve/heal path exists in the
##                          resolver). Two carriers via spec fields:
##                          seal_the_wound (self_allowed, bleeding/infected
##                          only) and field_triage (ally-only, any condition,
##                          consumes a bandage_charge via the generic STACK
##                          prime)
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
## The remaining skills in data/skills.json are the fill-in-later content pass;
## until encoded they resolve through the generic `strike` fallback so an
## unknown key still does a real, honest thing.
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
	# self-shaped for any HUD affordance that asks.
	if arch == "forced_roll_save":
		return true
	if arch == "intel_reveal":
		return String(spec.get("form", "")) == "passive_aura"
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
