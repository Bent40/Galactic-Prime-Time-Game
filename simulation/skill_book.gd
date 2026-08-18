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
##   strike               — generic single-target strike (the unknown-key fallback)
##
## SCOPE: the six demo-slice skills below carry FINAL authored numbers (not R14
## placeholders); tactical_roll (G1, rules-addendum R25) is implemented with a
## PLACEHOLDER-R14 base range. Content pass batch A ("Chains & Strikes",
## docs/design/skills-r19-ladders-FINAL.md) encodes nine more skills below —
## every batch-A magnitude is PLACEHOLDER (R14) and follows the FINAL ladder's
## authored L1 core + the data rows' L2-4 scaling; L5+ stays threshold DATA. The
## remaining skills in data/skills.json are the fill-in-later content pass; until
## encoded they resolve through the generic `strike` fallback so an unknown key
## still does a real, honest thing.
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
##   - intercept (G6-approved 2026-07-23) + iron_stance (its Gemstone MUTATION
##     result with brace, data/skill_mutations.json — R27): NOT implemented,
##     content pass. Iron Stance's ruled effect (stance: attacks on adjacent
##     allies retarget to you + persistent Crush/Burn reduction) needs a
##     retarget-guard archetype in ActionResolver before an honest encode —
##     until then both are DATA-ONLY grants (from_spec accepts any {key, level}
##     row). The merge machinery (simulation/skill_forge.gd + skill_keywords.gd)
##     validates on keys+levels and never requires a SkillBook entry.

const KNOWN_KEYS: Array[String] = [
	"strong_strike", "overhead_slam", "brace", "feint", "pressure_strike", "dance",
	"tactical_roll",
	# Content pass batch A — chains & strikes (skills-r19-ladders-FINAL.md).
	"pounce", "slip_through", "decapitate", "shockwave", "execution",
	"thousand_cuts", "controlled_sweep", "slice_n_dice", "heroic_punch",
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
## re-authoring the target/self split itself.
static func is_self_skill(key: String) -> bool:
	var arch := String(mechanics(key, 1).get("archetype", ""))
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
