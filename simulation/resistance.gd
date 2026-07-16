class_name Resistance
extends RefCounted
## Resistance & boss-trait rules (rules-addendum R4/R6 + enemies.json trait hooks).
##
## - Physical resistance is FLAT damage reduction (floor 0), fed by the base
##   "Physical" resistance plus any player-allocated Reflexes-derived points for
##   that specific damage type (R6).
## - Affliction/Psychic resistance is TIER IMMUNITY: tier N blocks effects of
##   tier <= N (R6). The Dissolution timer is not tiered — psychic resistance
##   instead slows it by +1 Clock per tier (R6).
## - Boss trait hooks: fire_heals, surface_immunity breach checks (enemies.json).

## Physical conditions whose damage the flat reduction applies to.
const PHYSICAL_TYPES: Array[String] = ["bleeding", "crushed", "burn"]


static func flat_physical_reduction(c: CombatantState, condition_id: String) -> int:
	var reduction: int = int(c.resistances.get("Physical", 0))
	reduction += int(c.allocated_physical.get(condition_id, 0))
	return reduction


static func reduce_damage(amount: int, c: CombatantState, condition_def: Dictionary, condition_id: String) -> int:
	if String(condition_def.get("resistance_type", "")) == "Physical":
		return maxi(0, amount - flat_physical_reduction(c, condition_id))
	return maxi(0, amount)


## Tier immunity for Affliction/Psychic conditions (R6): an application or
## advance that would leave the condition at tier <= resistance is negated.
static func blocks_condition_tier(c: CombatantState, condition_def: Dictionary, tier: int) -> bool:
	var res_type := String(condition_def.get("resistance_type", ""))
	if res_type == "Affliction":
		return tier <= int(c.resistances.get("Affliction", 0))
	if res_type == "Psychic":
		return tier <= psychic_resistance(c)
	return false


static func psychic_resistance(c: CombatantState) -> int:
	return int(c.resistances.get("Psychic", 0)) + CombatantState.over_cap(c.trait_total("mind"), 15)


## Extra Clocks added to a Dissolution timer (+1 per psychic resistance tier, R6).
static func dissolution_extra_clocks(c: CombatantState) -> int:
	return psychic_resistance(c)


static func fire_heals(c: CombatantState) -> bool:
	return bool(c.boss_traits.get("fire_heals", false))


## True while the part is hidden behind surface immunity and not yet breached.
static func part_blocked_by_surface_immunity(c: CombatantState, part_key: String) -> bool:
	if c.breached:
		return false
	var part: Dictionary = c.parts.get(part_key, {})
	return bool(part.get("hidden", false))


## Evaluates the surface_immunity breach conditions (enemies.json shape):
## - {"type": "condition_tier", "condition": id, "tier": N, "on": "any_part"}
## - {"type": "burst_damage", "amount": N, "window": "tick"}
## Returns true when the breach opens NOW (call after damage/condition changes).
static func check_breach(c: CombatantState) -> bool:
	if c.breached:
		return false
	var immunity: Dictionary = c.boss_traits.get("surface_immunity", {})
	if immunity.is_empty():
		return false
	for breach_cond: Variant in immunity.get("breach_conditions", []) as Array:
		var cond: Dictionary = breach_cond
		var kind := String(cond.get("type", ""))
		if kind == "condition_tier":
			if c.highest_tier_anywhere(String(cond.get("condition", ""))) >= int(cond.get("tier", 1)):
				return true
		elif kind == "burst_damage":
			if c.damage_taken_this_tick >= int(cond.get("amount", 0)):
				return true
	return false


func to_dict() -> Dictionary:
	return {}


static func from_dict(_data: Dictionary) -> Resistance:
	return Resistance.new()
