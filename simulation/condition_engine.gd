class_name ConditionEngine
extends RefCounted
## Condition application, universal Clock-reset advancement, tier effects and
## timers (rules-addendum R4/R5), driven by the data/conditions.json shapes
## passed in as plain Dictionaries — no file IO here.

## Conditions whose route to 0 HP on a vital part triggers bleed-out instead of
## immediate death (R5). Crushed and direct weapon damage kill outright.
const DELAYABLE: Array[String] = ["bleeding", "poison", "infected", "burn"]

## Damage-type vocabulary normalization (rulebook + seed enums are canonical).
const DAMAGE_TYPE_TO_CONDITION: Dictionary = {
	"bleed": "bleeding", "bleeding": "bleeding",
	"crush": "crushed", "crushed": "crushed",
	"burn": "burn",
	"chill": "chilled", "chilled": "chilled",
	"poison": "poison",
	"infection": "infected", "infected": "infected",
	"suffocation": "suffocation",
	"dissolution": "dissolution",
	"shock": "shock",
}

var defs: Dictionary = {}  # condition_id -> def (conditions.json entry)
var combatants: Dictionary = {}  # id -> CombatantState (shared ref, wired by CombatSim)
## True only while on_clock_reset() runs — timers created mid-reset are marked
## "fresh" so the same reset cannot immediately decrement them.
var in_clock_reset: bool = false


func setup(condition_defs: Variant, combatants_ref: Dictionary) -> void:
	defs = {}
	if condition_defs is Array:
		for entry: Variant in condition_defs as Array:
			var d: Dictionary = entry
			defs[String(d.get("id", ""))] = d
	elif condition_defs is Dictionary:
		defs = condition_defs
	combatants = combatants_ref


static func normalize_condition_id(damage_type: String) -> String:
	return String(DAMAGE_TYPE_TO_CONDITION.get(damage_type.to_lower(), damage_type.to_lower()))


func def_for(condition_id: String) -> Dictionary:
	return defs.get(condition_id, {})


func tier_entry(condition_id: String, tier: int) -> Dictionary:
	for entry: Variant in def_for(condition_id).get("tiers", []) as Array:
		var t: Dictionary = entry
		if int(t.get("tier", 0)) == tier:
			return t
	return {}


func max_tier(condition_id: String) -> int:
	var spread: Dictionary = def_for(condition_id).get("spread_rules", {})
	return int(spread.get("max_tier", 4))


func is_timer_condition(condition_id: String) -> bool:
	var spread: Dictionary = def_for(condition_id).get("spread_rules", {})
	return spread.has("clock_timer")


## All effect strings from currently-active condition tiers (passives queried
## on demand — prevents_healing, accelerates_conditions:N, moment penalties...).
func active_effects(c: CombatantState) -> Array[String]:
	var out: Array[String] = []
	var part_keys: Array = c.conditions.keys()
	part_keys.sort()
	for part_key: Variant in part_keys:
		var on_part: Dictionary = c.conditions[part_key]
		var cond_ids: Array = on_part.keys()
		cond_ids.sort()
		for cond_id: Variant in cond_ids:
			var instance: Dictionary = on_part[cond_id]
			if int(instance.get("activation_delay", 0)) > 0:
				continue
			var entry: Dictionary = tier_entry(String(cond_id), int(instance.get("tier", 0)))
			for eff: Variant in entry.get("effects", []) as Array:
				out.append(String(eff))
	return out


## Max N across "name:N" effects; bare "name" counts as 1; absent -> 0.
func effect_value(c: CombatantState, effect_name: String) -> int:
	var best: int = 0
	for eff: String in active_effects(c):
		if eff == effect_name:
			best = maxi(best, 1)
		elif eff.begins_with(effect_name + ":"):
			best = maxi(best, int(eff.get_slice(":", 1)))
	return best


## True when the actor's next action must roll Forced Action – Body: a Body
## forced_action_type on the acting part's conditions, or on a torso-hosted
## (whole-body) condition (exhausted T3, bleeding T2+ torso...).
func forced_body_required(c: CombatantState, acting_part_key: String) -> bool:
	var part_keys: Array = c.conditions.keys()
	part_keys.sort()
	for part_key: Variant in part_keys:
		var key := String(part_key)
		if key != acting_part_key and key != "torso":
			continue
		var on_part: Dictionary = c.conditions[part_key]
		var cond_ids: Array = on_part.keys()
		cond_ids.sort()
		for cond_id: Variant in cond_ids:
			var instance: Dictionary = on_part[cond_id]
			if int(instance.get("activation_delay", 0)) > 0:
				continue
			var entry: Dictionary = tier_entry(String(cond_id), int(instance.get("tier", 0)))
			if String(entry.get("forced_action_type", "")) == "Body":
				return true
	return false


## Applies (or re-applies) a condition. ctx keys: "source" ("attack"|"direct"|
## "forced"), "tier" (direct set, default 1), "poison_type", "injection".
func apply(c: CombatantState, part_key: String, condition_id: String, tick: int, ctx: Dictionary = {}) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.alive:
		return events
	if condition_id == "shock":
		return apply_shock(c, maxi(1, int(ctx.get("tier", 1))), tick)
	var def: Dictionary = def_for(condition_id)
	if def.is_empty():
		events.append({"type": "condition_ignored", "combatant": c.id, "condition": condition_id, "reason": "unknown_condition"})
		return events

	# S2.6: remap to a part the TARGET actually has. Empty target_body_parts = any
	# existing part is legal; a restricted list (suffocation/exhausted/infected →
	# torso, dissolution → head) routes to the combatant's closest equivalent —
	# never to a template key the combatant lacks (non-human part plans).
	var legal_parts: Array = def.get("target_body_parts", [])
	var valid_target: bool = c.parts.has(part_key) \
		and (legal_parts.is_empty() or legal_parts.has(part_key))
	if not valid_target:
		part_key = _equivalent_part(c, legal_parts)
		if part_key == "":
			events.append({"type": "condition_ignored", "combatant": c.id, "condition": condition_id, "reason": "no_valid_part"})
			return events

	# Bleed immunity (F2 rework): a bleed_immune part — the mycelium network — has
	# no blood to lose, so bleeding never establishes on it (and the systemic
	# bleed-out drain never touches it either). Finish such a part with
	# crushing/HP damage after the breach, not by bleeding it.
	if condition_id == "bleeding" and bool(c.parts.get(part_key, {}).get("bleed_immune", false)):
		events.append({"type": "condition_resisted", "combatant": c.id, "part": part_key, "condition": condition_id, "reason": "bleed_immune"})
		return events

	if is_timer_condition(condition_id):
		return _apply_timer_condition(c, part_key, condition_id, def, events)

	var source := String(ctx.get("source", "direct"))
	if condition_id == "poison":
		var gate_events := _poison_gate_and_soup(c, part_key, tick, ctx)
		if not gate_events.is_empty():
			return gate_events

	var on_part: Dictionary = c.conditions.get(part_key, {})
	if on_part.has(condition_id):
		var instance: Dictionary = on_part[condition_id]
		if condition_id == "chilled":
			instance["reapplied_this_clock"] = true
		# At most one attack-driven advance per part per tick (R4).
		if source == "attack" and int(instance.get("last_attack_advance_tick", -1)) == tick:
			return events
		if source == "attack":
			instance["last_attack_advance_tick"] = tick
		events.append_array(advance(c, part_key, condition_id, 1, tick, "reapplied"))
		return events

	var start_tier: int = maxi(1, int(ctx.get("tier", 1)))
	if Resistance.blocks_condition_tier(c, def, start_tier):
		events.append({"type": "condition_resisted", "combatant": c.id, "part": part_key, "condition": condition_id, "tier": start_tier})
		return events
	var instance: Dictionary = {
		"tier": start_tier,
		"delayed": false,
		"reapplied_this_clock": condition_id == "chilled",
		"poison_type": String(ctx.get("poison_type", "")),
		"activation_delay": int(ctx.get("activation_delay", 0)),
		"last_attack_advance_tick": tick if source == "attack" else -1,
	}
	if not c.conditions.has(part_key):
		c.conditions[part_key] = {}
	c.conditions[part_key][condition_id] = instance
	events.append({"type": "condition_applied", "combatant": c.id, "part": part_key, "condition": condition_id, "tier": start_tier})
	for t: int in range(1, start_tier + 1):
		events.append_array(_apply_tier_entry_effects(c, part_key, condition_id, t, tick))
	return events


func _apply_timer_condition(c: CombatantState, part_key: String, condition_id: String, def: Dictionary, events: Array[Dictionary]) -> Array[Dictionary]:
	var spread: Dictionary = def.get("spread_rules", {})
	for timer: Dictionary in c.timers:
		if String(timer.get("condition", "")) == condition_id:
			if not bool(spread.get("timer_resets_on_reapply", false)):
				return events  # already running; re-application is a no-op
	var clocks: int = int(spread.get("clock_timer", 2))
	if condition_id == "dissolution":
		clocks += Resistance.dissolution_extra_clocks(c)  # R6: psychic slows it
	c.timers.append({
		"kind": condition_id,
		"condition": condition_id,
		"part": part_key,
		"clocks_remaining": clocks,
		"delay": 0,
		"paused": false,
		"fresh": in_clock_reset,
	})
	events.append({"type": "timer_started", "combatant": c.id, "kind": condition_id, "clocks": clocks})
	return events


## Poison typing (R10): different types are incompatible -> Poison Soup (both
## resolve; burst = sum of tiers, capped at part max HP - 1 on vitals). Attack-
## sourced poison also needs an entry condition. Non-empty return = handled.
func _poison_gate_and_soup(c: CombatantState, part_key: String, tick: int, ctx: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var source := String(ctx.get("source", "direct"))
	if source == "attack":
		var has_entry: bool = c.condition_tier(part_key, "bleeding") > 0 \
			or part_key.contains("head") \
			or bool(ctx.get("injection", false)) \
			or c.is_helpless(tick)
		if not has_entry:
			events.append({"type": "condition_ignored", "combatant": c.id, "part": part_key, "condition": "poison", "reason": "no_entry_condition"})
			return events
	var existing: Dictionary = c.condition_instance(part_key, "poison")
	if not existing.is_empty():
		var new_type := String(ctx.get("poison_type", ""))
		var old_type := String(existing.get("poison_type", ""))
		if new_type != old_type:
			var burst: int = int(existing.get("tier", 1)) + maxi(1, int(ctx.get("tier", 1)))
			var part: Dictionary = c.parts.get(part_key, {})
			if bool(part.get("lethal", false)):
				burst = mini(burst, c.max_hp(part_key) - 1)
			events.append({"type": "poison_soup", "combatant": c.id, "part": part_key, "types": [old_type, new_type], "burst": burst})
			events.append_array(resolve(c, part_key, "poison", "poison_soup"))
			events.append_array(damage_part(c, part_key, burst, "condition", "poison", tick))
			return events
	return []


func advance(c: CombatantState, part_key: String, condition_id: String, steps: int, tick: int, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var instance: Dictionary = c.condition_instance(part_key, condition_id)
	if instance.is_empty() or steps <= 0 or not c.alive:
		return events
	var old_tier: int = int(instance.get("tier", 1))
	var new_tier: int = mini(old_tier + steps, max_tier(condition_id))
	if new_tier == old_tier:
		return events
	instance["tier"] = new_tier
	events.append({
		"type": "condition_advanced",
		"combatant": c.id, "part": part_key, "condition": condition_id,
		"from_tier": old_tier, "to_tier": new_tier, "reason": reason,
	})
	for t: int in range(old_tier + 1, new_tier + 1):
		events.append_array(_apply_tier_entry_effects(c, part_key, condition_id, t, tick))
	return events


func resolve(c: CombatantState, part_key: String, condition_id: String, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var on_part: Dictionary = c.conditions.get(part_key, {})
	if not on_part.has(condition_id):
		return events
	on_part.erase(condition_id)
	if on_part.is_empty():
		c.conditions.erase(part_key)
	events.append({"type": "condition_resolved", "combatant": c.id, "part": part_key, "condition": condition_id, "reason": reason})
	# Cancel timers this condition was driving (incl. suffocation/dissolution).
	var kept: Array[Dictionary] = []
	for timer: Dictionary in c.timers:
		if String(timer.get("condition", "")) == condition_id and String(timer.get("kind", "")) != "bleed_out":
			events.append({"type": "timer_cancelled", "combatant": c.id, "kind": String(timer.get("kind", ""))})
		else:
			kept.append(timer)
	c.timers = kept
	if String(c.bleed_out.get("condition", "")) == condition_id:
		events.append_array(_stabilize(c))
	_recompute_part_disabled(c, part_key)
	_recompute_incapacitated(c)
	return events


func delay(c: CombatantState, part_key: String, condition_id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var instance: Dictionary = c.condition_instance(part_key, condition_id)
	var found: bool = false
	if not instance.is_empty():
		instance["delayed"] = true
		found = true
		events.append({"type": "condition_delayed", "combatant": c.id, "part": part_key, "condition": condition_id})
	for timer: Dictionary in c.timers:
		if String(timer.get("condition", "")) == condition_id and String(timer.get("kind", "")) != "bleed_out":
			timer["delay"] = int(timer.get("delay", 0)) + 1
			found = true
			events.append({"type": "timer_delayed", "combatant": c.id, "kind": String(timer.get("kind", ""))})
	if not found:
		events.append({"type": "condition_ignored", "combatant": c.id, "part": part_key, "condition": condition_id, "reason": "not_active"})
		return events
	if String(c.bleed_out.get("condition", "")) == condition_id:
		events.append_array(_stabilize(c))
	return events


## Field treatment primitive (R10 healing rules): mode "delay" or "resolve".
## Infected T1+ prevents resolution of OTHER conditions (delay stays legal).
func treat(c: CombatantState, part_key: String, condition_id: String, mode: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if mode == "resolve":
		if condition_id != "infected" and effect_value(c, "prevents_healing") > 0:
			events.append({"type": "heal_blocked", "combatant": c.id, "condition": condition_id, "reason": "infected_prevents_resolution"})
			return events
		var timer_found: bool = false
		for timer: Dictionary in c.timers:
			if String(timer.get("condition", "")) == condition_id:
				timer_found = true
		if c.condition_instance(part_key, condition_id).is_empty() and not timer_found:
			events.append({"type": "condition_ignored", "combatant": c.id, "part": part_key, "condition": condition_id, "reason": "not_active"})
			return events
		if timer_found and c.condition_instance(part_key, condition_id).is_empty():
			# Timer-only condition (suffocation/dissolution): resolving removes it.
			var kept: Array[Dictionary] = []
			for timer: Dictionary in c.timers:
				if String(timer.get("condition", "")) == condition_id:
					events.append({"type": "timer_cancelled", "combatant": c.id, "kind": String(timer.get("kind", ""))})
				else:
					kept.append(timer)
			c.timers = kept
			return events
		return resolve(c, part_key, condition_id, "treated")
	return delay(c, part_key, condition_id)


## Shock stacking (R7/E5): fresh Shock lands at the source tier; a new source
## S2.6 fallback chain: first listed legal part the combatant HAS, else its torso,
## else its first lethal part (sorted), else its first part (sorted), else "".
func _equivalent_part(c: CombatantState, legal_parts: Array) -> String:
	for legal: Variant in legal_parts:
		if c.parts.has(String(legal)):
			return String(legal)
	if c.parts.has("torso"):
		return "torso"
	var keys: Array = c.parts.keys()
	keys.sort()
	for key: Variant in keys:
		if bool((c.parts[key] as Dictionary).get("lethal", false)):
			return String(key)
	if not keys.is_empty():
		return String(keys[0])
	return ""


## while already Shocked escalates one above current (never below the source
## tier). T3 (Faint) = Helpless for 1 Clock + drop held items.
func apply_shock(c: CombatantState, source_tier: int, tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if source_tier <= 0 or not c.alive:
		return events
	var old: int = c.shock
	var new_shock: int = source_tier if old == 0 else maxi(old + 1, source_tier)
	new_shock = mini(new_shock, 4)
	if new_shock == old:
		return events
	c.shock = new_shock
	events.append({"type": "shock_changed", "combatant": c.id, "from_tier": old, "to_tier": new_shock})
	if new_shock >= 3 and old < 3:
		c.helpless_until_tick = maxi(c.helpless_until_tick, tick + Clock.TICKS_PER_CLOCK)
		var item_keys: Array = c.items.keys()
		item_keys.sort()
		for item_key: Variant in item_keys:
			var item: Dictionary = c.items[item_key]
			if not bool(item.get("dropped", false)):
				item["dropped"] = true
				events.append({"type": "item_dropped", "combatant": c.id, "item": String(item_key)})
	return events


## Central HP damage sink. source_kind: "weapon"|"condition"|"forced"|"environment".
## Emits damage_applied (even at 0 for transparency) and owns the death /
## bleed-out decision (R5). `amount` is already post-resistance.
func damage_part(c: CombatantState, part_key: String, amount: int, source_kind: String, source_condition: String, tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.alive or not c.parts.has(part_key):
		return events
	var part: Dictionary = c.parts[part_key]
	events.append({
		"type": "damage_applied",
		"combatant": c.id, "part": part_key, "amount": amount, "source": source_kind,
	})
	if amount <= 0:
		return events
	if not c.bleed_out.is_empty():
		events.append_array(_kill(c, "damage_during_bleed_out"))  # any damage kills (R5)
		return events
	c.damage_taken_this_tick += amount
	part["hp"] = maxi(0, int(part["hp"]) - amount)
	if int(part["hp"]) > 0:
		return events
	if bool(part.get("lethal", false)):
		if source_kind == "condition" and DELAYABLE.has(source_condition):
			events.append_array(_start_bleed_out(c, part_key, source_condition))
		else:
			events.append_array(_kill(c, "vital_part_destroyed"))
	else:
		if not bool(part.get("disabled", false)):
			part["disabled"] = true
			events.append({"type": "part_disabled", "combatant": c.id, "part": part_key})
	# Exhausted T2: body hits expose (conditions.json "exposed_on_body_hit").
	if c.alive and effect_value(c, "exposed_on_body_hit") > 0:
		c.exposed_until_tick = maxi(c.exposed_until_tick, tick + 1)
	return events


func heal_part(c: CombatantState, part_key: String, amount: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.alive or not c.parts.has(part_key) or amount <= 0:
		return events
	if effect_value(c, "prevents_healing") > 0:
		events.append({"type": "heal_blocked", "combatant": c.id, "part": part_key, "reason": "infected_prevents_healing"})
		return events
	var part: Dictionary = c.parts[part_key]
	if bool(part.get("destroyed", false)):
		events.append({"type": "heal_blocked", "combatant": c.id, "part": part_key, "reason": "part_destroyed"})
		return events
	part["hp"] = mini(c.max_hp(part_key), int(part["hp"]) + amount)
	events.append({"type": "healed", "combatant": c.id, "part": part_key, "amount": amount})
	if int(part["hp"]) > 0 and bool(part.get("disabled", false)):
		_recompute_part_disabled(c, part_key)
	return events


## Universal Clock-reset advancement (R4) + timers + exhausted rest recovery.
func on_clock_reset(c: CombatantState, tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.alive:
		return events
	in_clock_reset = true
	# Infected T2 acceleration snapshot: other conditions advance extra (R4).
	var extra: int = effect_value(c, "accelerates_conditions")

	var part_keys: Array = c.conditions.keys()
	part_keys.sort()
	for part_key: Variant in part_keys:
		if not c.alive:
			break
		var on_part: Dictionary = c.conditions.get(part_key, {})
		var cond_ids: Array = on_part.keys()
		cond_ids.sort()
		for cond_id: Variant in cond_ids:
			if not c.alive:
				break
			var condition_id := String(cond_id)
			var instance: Dictionary = c.condition_instance(String(part_key), condition_id)
			if instance.is_empty():
				continue  # resolved by an earlier advancement's side effects
			var spread: Dictionary = def_for(condition_id).get("spread_rules", {})
			if int(instance.get("activation_delay", 0)) > 0:
				instance["activation_delay"] = int(instance["activation_delay"]) - 1
				continue
			if bool(instance.get("delayed", false)):
				# A Delayed condition skips exactly one advancement (R4).
				instance["delayed"] = false
				events.append({"type": "condition_delay_consumed", "combatant": c.id, "part": String(part_key), "condition": condition_id})
				continue
			if bool(spread.get("resolves_if_not_reapplied", false)):
				if bool(instance.get("reapplied_this_clock", false)):
					instance["reapplied_this_clock"] = false
				else:
					events.append_array(resolve(c, String(part_key), condition_id, "not_reapplied"))
				continue
			if bool(spread.get("recovers_when_resting", false)):
				if not c.took_scheduled_action_this_clock:
					var tier: int = int(instance.get("tier", 1))
					if tier <= 1:
						events.append_array(resolve(c, String(part_key), condition_id, "rested"))
					else:
						instance["tier"] = tier - 1
						events.append({"type": "condition_advanced", "combatant": c.id, "part": String(part_key), "condition": condition_id, "from_tier": tier, "to_tier": tier - 1, "reason": "rested"})
				continue
			if bool(spread.get("advances_on_clock_reset", false)):
				var steps: int = 1 + (extra if condition_id != "infected" else 0)
				events.append_array(advance(c, String(part_key), condition_id, steps, tick, "clock_reset"))

	events.append_array(_bleed_out_drain(c, tick))
	events.append_array(_advance_timers(c))
	c.took_scheduled_action_this_clock = false
	in_clock_reset = false
	return events


## Systemic bleed-out (F2 rework, owner ruling 2026-07-19). A part bleeding out to
## a lethal degree drains the whole body each Clock: blood loss ticks HP off every
## OTHER part that can bleed — never a bleed_immune part (the mycelium network is a
## separate organism with no blood), never one still hidden behind surface immunity,
## never one already destroyed. Death is NOT a special effect here: the drain routes
## through damage_part, so the show ends only when a LETHAL part empties (the normal
## vital-part-destroyed rule). Skipped while a formal bleed-out grace is already
## running — that timer finishes the job. Drain scales with the worst bleed tier.
func _bleed_out_drain(c: CombatantState, tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.alive or not c.bleed_out.is_empty():
		return events
	var cfg: Dictionary = def_for("bleeding").get("bleed_out_drain", {})
	var per_tier: int = int(cfg.get("hp_per_tier", 0))
	var from_tier: int = int(cfg.get("from_tier", 3))
	if per_tier <= 0:
		return events
	var worst: int = 0
	for pk: Variant in c.conditions.keys():
		var t: int = int(((c.conditions[pk] as Dictionary).get("bleeding", {}) as Dictionary).get("tier", 0))
		if t >= from_tier and t > worst:
			worst = t
	if worst <= 0:
		return events
	var drain: int = per_tier * worst
	events.append({"type": "bleed_out_draining", "combatant": c.id, "amount": drain, "tier": worst})
	var drain_keys: Array = c.parts.keys()
	drain_keys.sort()
	for pk: Variant in drain_keys:
		if not c.alive:
			break
		var part: Dictionary = c.parts[pk]
		if bool(part.get("bleed_immune", false)) or bool(part.get("hidden", false)) \
				or bool(part.get("destroyed", false)) or int(part.get("hp", 0)) <= 0:
			continue
		events.append_array(damage_part(c, String(pk), drain, "bleed_out", "bleeding", tick))
	return events


func _advance_timers(c: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var kept: Array[Dictionary] = []
	var expired: Array[Dictionary] = []
	for timer: Dictionary in c.timers:
		if not c.alive:
			kept.append(timer)
			continue
		if bool(timer.get("fresh", false)):
			timer["fresh"] = false  # created during this reset — starts next reset
			kept.append(timer)
			continue
		if bool(timer.get("paused", false)):
			kept.append(timer)
			continue
		if int(timer.get("delay", 0)) > 0:
			timer["delay"] = int(timer["delay"]) - 1
			events.append({"type": "timer_delay_consumed", "combatant": c.id, "kind": String(timer.get("kind", ""))})
			kept.append(timer)
			continue
		timer["clocks_remaining"] = int(timer.get("clocks_remaining", 1)) - 1
		if int(timer["clocks_remaining"]) <= 0:
			expired.append(timer)
		else:
			events.append({"type": "timer_advanced", "combatant": c.id, "kind": String(timer.get("kind", "")), "clocks_remaining": int(timer["clocks_remaining"])})
			kept.append(timer)
	c.timers = kept
	for timer: Dictionary in expired:
		var kind := String(timer.get("kind", ""))
		events.append({"type": "timer_expired", "combatant": c.id, "kind": kind})
		if kind == "dissolution":
			events.append_array(_mind_collapse(c))
		else:  # death / suffocation / bleed_out
			events.append_array(_kill(c, kind))
	return events


func _apply_tier_entry_effects(c: CombatantState, part_key: String, condition_id: String, tier: int, tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.alive:
		return events
	var entry: Dictionary = tier_entry(condition_id, tier)
	if entry.is_empty():
		return events
	var part: Dictionary = c.parts.get(part_key, {})
	var lethal: bool = bool(part.get("lethal", false))
	events.append_array(apply_shock(c, int(entry.get("shock_tier", 0)), tick))
	for eff_raw: Variant in entry.get("effects", []) as Array:
		if not c.alive:
			break
		var eff := String(eff_raw)
		if eff.begins_with("cures:"):
			events.append_array(resolve(c, part_key, eff.get_slice(":", 1), "cured_by_" + condition_id))
		elif eff == "part_disabled" or (eff == "part_disabled_if_limb" and not lethal):
			if not part.is_empty() and not bool(part.get("disabled", false)):
				part["disabled"] = true
				events.append({"type": "part_disabled", "combatant": c.id, "part": part_key})
		elif eff == "part_destroyed":
			if not part.is_empty():
				part["hp"] = 0
				if not (lethal and DELAYABLE.has(condition_id)):
					part["destroyed"] = true
					part["disabled"] = true
					events.append({"type": "part_destroyed", "combatant": c.id, "part": part_key})
		elif eff == "lethal_if_vital":
			if lethal:
				events.append_array(_vital_zero_by_condition(c, part_key, condition_id))
		elif eff == "lethal_if_head":
			# Respect the part's lethal flag (F2): a humanoid head is lethal:true so
			# this still fires, but an entity whose "head" is lethal:false (the
			# mycelium puppet head) is cosmetic — only its network can kill it.
			if part_key.contains("head") and lethal:
				events.append_array(_vital_zero_by_condition(c, part_key, condition_id))
		elif eff == "incapacitated_if_head":
			if part_key.contains("head"):
				c.statuses["incapacitated"] = true
				events.append({"type": "status_changed", "combatant": c.id, "status": "incapacitated", "value": true})
		elif eff == "death":
			events.append_array(_kill(c, condition_id + "_t" + str(tier)))
		elif eff.begins_with("death_timer_clocks:"):
			events.append_array(_add_death_timer(c, condition_id, part_key, int(eff.get_slice(":", 1))))
		elif eff.begins_with("death_timer_clocks_if_vital:"):
			if lethal:
				events.append_array(_add_death_timer(c, condition_id, part_key, int(eff.get_slice(":", 1))))
		# Passive effect strings (prevents_healing, accelerates_conditions:N,
		# moment_cost_penalty_*, exposed_on_body_hit, *_entry_open) are queried
		# on demand via effect_value(); no state to write here.
	return events


func _add_death_timer(c: CombatantState, condition_id: String, part_key: String, clocks: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for timer: Dictionary in c.timers:
		if String(timer.get("kind", "")) == "death" and String(timer.get("condition", "")) == condition_id:
			return events  # already running
	c.timers.append({
		"kind": "death", "condition": condition_id, "part": part_key,
		"clocks_remaining": clocks, "delay": 0, "paused": false,
		"fresh": in_clock_reset,
	})
	events.append({"type": "timer_started", "combatant": c.id, "kind": "death", "condition": condition_id, "clocks": clocks})
	return events


## A vital part reached 0 through a condition: delayable -> bleed-out (R5),
## anything else (Crushed) -> immediate death.
func _vital_zero_by_condition(c: CombatantState, part_key: String, condition_id: String) -> Array[Dictionary]:
	if DELAYABLE.has(condition_id) and c.bleed_out.is_empty():
		var part: Dictionary = c.parts.get(part_key, {})
		if not part.is_empty():
			part["hp"] = 0
		return _start_bleed_out(c, part_key, condition_id)
	return _kill(c, condition_id + "_vital")


func _start_bleed_out(c: CombatantState, part_key: String, condition_id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.bleed_out.is_empty() or not c.alive:
		return events
	c.bleed_out = {"condition": condition_id, "part": part_key}
	# Always fresh: the 1-Clock grace (R5) survives at least one full reset,
	# even when the bleed-out starts during reset processing itself.
	c.timers.append({
		"kind": "bleed_out", "condition": condition_id, "part": part_key,
		"clocks_remaining": 1, "delay": 0, "paused": false,
		"fresh": true,
	})
	events.append({"type": "bleed_out_started", "combatant": c.id, "part": part_key, "condition": condition_id})
	return events


func _stabilize(c: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if c.bleed_out.is_empty():
		return events
	c.bleed_out = {}
	var kept: Array[Dictionary] = []
	for timer: Dictionary in c.timers:
		if String(timer.get("kind", "")) != "bleed_out":
			kept.append(timer)
	c.timers = kept
	events.append({"type": "bleed_out_stabilized", "combatant": c.id})
	return events


func _kill(c: CombatantState, cause: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not c.alive:
		return events
	c.alive = false
	c.bleed_out = {}
	events.append({"type": "combatant_died", "combatant": c.id, "cause": cause})
	events.append_array(_release_grapples(c))
	return events


## Dissolution completion: mind collapsed, removed from play — NEVER engine
## death (R5); the body stays alive.
func _mind_collapse(c: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if c.removed_from_play:
		return events
	c.removed_from_play = true
	events.append({"type": "mind_collapsed", "combatant": c.id})
	events.append_array(_release_grapples(c))
	return events


func _release_grapples(c: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if c.grappling != "":
		var target: CombatantState = combatants.get(c.grappling)
		if target != null:
			target.grappled_by = ""
		events.append({"type": "grapple_ended", "grappler": c.id, "target": c.grappling, "reason": "grappler_out"})
		c.grappling = ""
	if c.grappled_by != "":
		var grappler: CombatantState = combatants.get(c.grappled_by)
		if grappler != null:
			grappler.grappling = ""
		events.append({"type": "grapple_ended", "grappler": c.grappled_by, "target": c.id, "reason": "target_out"})
		c.grappled_by = ""
	return events


## First active condition in deterministic order — Forced Action Body
## "Condition Surge" picks this and advances it. Returns {} if none active.
func first_active_condition(c: CombatantState) -> Dictionary:
	var part_keys: Array = c.conditions.keys()
	part_keys.sort()
	for part_key: Variant in part_keys:
		var on_part: Dictionary = c.conditions[part_key]
		var cond_ids: Array = on_part.keys()
		cond_ids.sort()
		for cond_id: Variant in cond_ids:
			return {"part": String(part_key), "condition": String(cond_id)}
	return {}


func _recompute_part_disabled(c: CombatantState, part_key: String) -> void:
	var part: Dictionary = c.parts.get(part_key, {})
	if part.is_empty() or bool(part.get("destroyed", false)) or int(part.get("hp", 0)) <= 0:
		return
	var still_disabled: bool = false
	var on_part: Dictionary = c.conditions.get(part_key, {})
	for cond_id: Variant in on_part:
		var instance: Dictionary = on_part[cond_id]
		for t: int in range(1, int(instance.get("tier", 1)) + 1):
			var entry: Dictionary = tier_entry(String(cond_id), t)
			var effects: Array = entry.get("effects", [])
			if effects.has("part_disabled"):
				still_disabled = true
			if effects.has("part_disabled_if_limb") and not bool(part.get("lethal", false)):
				still_disabled = true
	part["disabled"] = still_disabled


func _recompute_incapacitated(c: CombatantState) -> void:
	if not bool(c.statuses.get("incapacitated", false)):
		return
	var part_keys: Array = c.conditions.keys()
	for part_key: Variant in part_keys:
		if not String(part_key).contains("head"):
			continue
		var on_part: Dictionary = c.conditions[part_key]
		for cond_id: Variant in on_part:
			var instance: Dictionary = on_part[cond_id]
			for t: int in range(1, int(instance.get("tier", 1)) + 1):
				var entry: Dictionary = tier_entry(String(cond_id), t)
				if (entry.get("effects", []) as Array).has("incapacitated_if_head"):
					return  # still justified
	c.statuses.erase("incapacitated")


func to_dict() -> Dictionary:
	return {"defs": defs.duplicate(true)}


static func from_dict(data: Dictionary) -> ConditionEngine:
	var engine := ConditionEngine.new()
	engine.defs = (data.get("defs", {}) as Dictionary).duplicate(true)
	return engine
