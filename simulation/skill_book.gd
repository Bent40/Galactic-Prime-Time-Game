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
##   strike               — generic single-target strike (the unknown-key fallback)
##
## SCOPE: the six demo-slice skills below carry FINAL authored numbers (not R14
## placeholders). The remaining 37 skills in data/skills.json are the
## fill-in-later content pass; until encoded they resolve through the generic
## `strike` fallback so an unknown key still does a real, honest thing.
##
## PRIMING (rules-addendum R3, decision-log #20 — "cooldowns do not exist"): a
## spec MAY carry a "prime" Dictionary that ActionResolver._prime_unmet enforces
## at declare (one of chain / stance / stack / state / prep). Only skills whose
## prime is safe to enforce for their EXISTING tests carry an encoded prime here;
## the rest ride a later ladder pass. Documented intents for skills built later:
##   - pressure_strike -> CHAIN after "feint". NOT encoded as an enforced prime:
##     the working feint->pressure_strike mechanic (feint_forced) already gates the
##     bonus at resolve, and test_pressure_strike_no_shock_without_feint declares
##     pressure_strike with NO preceding feint, which an enforced declare-time CHAIN
##     would reject. The CHAIN predicate is exercised on a test-only skill instead
##     (tests/test_priming.gd); this note records the sequence the ladder pass wires.
##   - tactical_roll (skills.json id 9)   -> STANCE (usable only in a defensive stance)
##   - acrobatic_save (skills.json id 37) -> STANCE (usable only in a defensive stance)
##   - slip_through   (skills.json id 21) -> CHAIN  (must follow Pounce immediately)
## These three are NOT in the demo-6 and are not mechanically built as reactions
## here; the note above is for when their full reaction mechanics are implemented.

const KNOWN_KEYS: Array[String] = [
	"strong_strike", "overhead_slam", "brace", "feint", "pressure_strike", "dance",
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
			# The actor repositions up to 1 space free.
			spec = {
				"archetype": "setup_debuff",
				"cost": 1,
				"attack_range": 1,
				"reposition": 1,
			}
		"pressure_strike":
			# Reflexes/Physique, cost 2, adjacent single limb. 2 Bleed at Lv1,
			# +1 per level (amount = 1 + level). +Shock T1 when the target is still
			# under Feint's pending consequence. Actor moves up to 2 spaces free.
			spec = {
				"archetype": "conditional_followup",
				"cost": 2,
				"damage_type": "bleeding",
				"amount": 1 + lv,
				"attack_range": 1,
				"reposition": 2,
				"bonus_shock_tier": 1,
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
		_:
			spec = FALLBACK.duplicate(true)
	spec["key"] = key
	spec["level"] = level
	return spec
