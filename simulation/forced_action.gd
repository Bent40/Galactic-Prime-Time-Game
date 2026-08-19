class_name ForcedAction
extends RefCounted
## The two Forced Action d6 tables (rulebook, kept verbatim; addendum R10).
##
## Consequences are applied AFTER action resolution (book rule; R1 step 2).
## Rolls consume the sim's seeded RNG and are always emitted in the
## forced_action_triggered event — no unlogged randomness. "Always allowed":
## a Forced Action never rejects the command; only Whiff (Tool 1) negates the
## action's own effect (review-1 D6).

const TABLE_BODY: String = "body"
const TABLE_TOOL: String = "tool"

const BODY_TABLE: Array[String] = [
	"tear_something",  # 1 dmg to the relevant part; escalate a condition if at 0
	"lock_up",         # part unusable 3 Moments
	"condition_surge", # advance an active condition 1 tier, else Shock T1
	"drop",            # drop held item
	"shock_spike",     # +1 Shock tier
	"stumble",         # Exposed until next Moment
]
const TOOL_TABLE: Array[String] = [
	"whiff",           # no effect (negates the action)
	"overcommit",      # Exposed
	"collateral",      # ally/object/environment hit
	"slip",            # unarmed until next Moment
	"strained_grip",   # +1 Moment cost next tool action
	"overextension",   # next scheduled action delayed +1 Moment
]

## Batch C (acrobatic_save — the forced_roll_save choose rule): the AUTHORED
## severity ranking over the BODY table, higher = worse. The save keeps the
## LOWEST-severity roll; a tie keeps the original (earliest) die. Ordering
## rationale (PLACEHOLDER-family judgment, R14 — pinned so the choose rule is
## deterministic and documented, revisit with the numbers pass):
## tear_something (permanent HP loss / condition escalation) > condition_surge
## (a real tier advance) > shock_spike (climbs the R13 ladder) > lock_up (a
## part gone 3 Moments) > drop (an item, recoverable) > stumble (Exposed one
## beat). Tool consequences are deliberately unranked — the save is BODY-only
## below the L6 "any fumble" threshold rung.
const BODY_SEVERITY: Dictionary = {
	"tear_something": 6,
	"condition_surge": 5,
	"shock_spike": 4,
	"lock_up": 3,
	"drop": 2,
	"stumble": 1,
}


## Severity of a rolled BODY consequence for the save's choose rule; unknown
## consequences rank hardest (never silently preferred).
static func save_severity(rolled: Dictionary) -> int:
	return int(BODY_SEVERITY.get(String(rolled.get("consequence", "")), 100))


## Tier-2 wave 4 (the_long_con S9-b — die manipulation): the AUTHORED severity
## ranking over the TOOL table, higher = worse FOR THE VICTIM, curated from
## the con-holder's vantage (the holder "chooses the result" — feint L3/L4's
## own texture — so the sim keeps the deterministic worst). Ranking rationale
## (PLACEHOLDER-family judgment, R14 — pinned so the choose rule is
## deterministic and documented, revisit with the numbers pass): whiff (the
## answered action simply never happened — the con's whole fantasy) > slip
## (unarmed) > strained_grip (+1 Moment next tool act) > overextension (a
## delayed schedule) > overcommit (Exposed — real but brief) > collateral
## (the wild swing may even serve the victim's side). The acrobatic_save
## stays BODY-only (its L6 "any fumble" rung is threshold data) — this
## ranking is consumed ONLY by the con's curated roll.
const TOOL_SEVERITY: Dictionary = {
	"whiff": 6,
	"slip": 5,
	"strained_grip": 4,
	"overextension": 3,
	"overcommit": 2,
	"collateral": 1,
}


## Severity of a rolled TOOL consequence for the con's curate rule; unknown
## consequences rank hardest (the save_severity convention).
static func tool_severity(rolled: Dictionary) -> int:
	return int(TOOL_SEVERITY.get(String(rolled.get("consequence", "")), 100))


## Rolls the d6 on the named table. The caller emits the event (with reason)
## and defers apply_consequence() until after all resolutions this tick (R1).
static func roll(table: String, rng: RandomNumberGenerator) -> Dictionary:
	var roll_value: int = rng.randi_range(1, 6)
	var table_entries: Array[String] = BODY_TABLE if table == TABLE_BODY else TOOL_TABLE
	return {"table": table, "roll": roll_value, "consequence": table_entries[roll_value - 1]}


static func make_event(actor_id: String, rolled: Dictionary, reason: String) -> Dictionary:
	return {
		"type": "forced_action_triggered",
		"actor": actor_id,
		"table": String(rolled["table"]),
		"roll": int(rolled["roll"]),
		"consequence": String(rolled["consequence"]),
		"reason": reason,
	}


## ctx keys: "part" (acting part), "damage" (per-round magnitude, for
## collateral), "damage_type" (condition id), "target" (original target id).
static func apply_consequence(rolled: Dictionary, actor: CombatantState, ctx: Dictionary, cond: ConditionEngine, combatants: Dictionary, tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not actor.alive:
		return events
	var part_key := String(ctx.get("part", actor.acting_part(tick)))
	match String(rolled["consequence"]):
		"tear_something":
			var part: Dictionary = actor.parts.get(part_key, {})
			if not part.is_empty() and int(part.get("hp", 0)) <= 0:
				var pick: Dictionary = cond.first_active_condition(actor)
				if not pick.is_empty():
					events.append_array(cond.advance(actor, String(pick["part"]), String(pick["condition"]), 1, tick, "tear_something"))
			else:
				# R11 #14 v2: the actor authored their own tear — a self-kill
				# attributes to the victim themselves (the literal killing blow).
				events.append_array(cond.damage_part(actor, part_key, 1, "forced", "", tick, actor.id))
		"lock_up":
			actor.part_locked_until[part_key] = tick + 3
			events.append({"type": "part_locked", "combatant": actor.id, "part": part_key, "until_tick": tick + 3})
		"condition_surge":
			var pick: Dictionary = cond.first_active_condition(actor)
			if pick.is_empty():
				events.append_array(cond.apply_shock(actor, 1, tick))
			else:
				events.append_array(cond.advance(actor, String(pick["part"]), String(pick["condition"]), 1, tick, "condition_surge"))
		"collateral":
			var victim_id: String = collateral_target(actor, String(ctx.get("target", "")), combatants)
			if victim_id == "":
				events.append({"type": "collateral_missed", "combatant": actor.id})
			else:
				var victim: CombatantState = combatants[victim_id]
				var dmg: int = maxi(1, int(ctx.get("damage", 1)))
				events.append({"type": "collateral_hit", "combatant": actor.id, "victim": victim_id})
				# R11 #14 v2: the wild swing is still the actor's blow — a collateral
				# kill attributes to them (friendly fire counts, Q69 — "it's cinema").
				events.append_array(cond.damage_part(victim, default_part(victim), dmg, "forced", "", tick, actor.id))
		"drop":
			var item_keys: Array = actor.items.keys()
			item_keys.sort()
			for item_key: Variant in item_keys:
				var item: Dictionary = actor.items[item_key]
				if not bool(item.get("dropped", false)):
					item["dropped"] = true
					events.append({"type": "item_dropped", "combatant": actor.id, "item": String(item_key)})
					break
		"shock_spike":
			events.append_array(cond.apply_shock(actor, 1, tick))
		"stumble", "overcommit":
			actor.exposed_until_tick = maxi(actor.exposed_until_tick, tick + 1)
		"slip":
			actor.unarmed_until_tick = maxi(actor.unarmed_until_tick, tick + 1)
		"strained_grip":
			actor.strained_grip = true
		"overextension":
			actor.next_action_tick += 1
		"whiff":
			pass  # the action's own effects were negated at resolution
	return events


## Deterministic collateral pick: nearest combatant that is neither the actor
## nor the intended target (distance, then id). Returns "" when nobody is hit.
static func collateral_target(actor: CombatantState, original_target: String, combatants: Dictionary) -> String:
	var best_id: String = ""
	var best_distance: int = -1
	var ids: Array = combatants.keys()
	ids.sort()
	for other_id: Variant in ids:
		var oid := String(other_id)
		if oid == actor.id or oid == original_target:
			continue
		var other: CombatantState = combatants[oid]
		if not other.alive:
			continue
		var d: int = CombatantState.hex_distance(actor.position, other.position)
		if best_distance < 0 or d < best_distance:
			best_distance = d
			best_id = oid
	return best_id


## Collateral hit location: torso if present, else the first non-head lethal
## part, else the first part in sorted order (an accident is never a called
## head shot).
static func default_part(c: CombatantState) -> String:
	var keys: Array = c.parts.keys()
	keys.sort()
	# Never route an accidental hit onto a part hidden behind an un-breached surface
	# immunity (the boss's undiscovered network) — collateral hits visible flesh (F2).
	for part_key: Variant in keys:
		if String(part_key).contains("torso") and not bool((c.parts[part_key] as Dictionary).get("hidden", false)):
			return String(part_key)
	for part_key: Variant in keys:
		var part: Dictionary = c.parts[part_key]
		if bool(part.get("lethal", false)) and not String(part_key).contains("head") and not bool(part.get("hidden", false)):
			return String(part_key)
	for part_key: Variant in keys:
		if not bool((c.parts[part_key] as Dictionary).get("hidden", false)):
			return String(part_key)
	return "" if keys.is_empty() else String(keys[0])


func to_dict() -> Dictionary:
	return {}


static func from_dict(_data: Dictionary) -> ForcedAction:
	return ForcedAction.new()
