class_name CombatSim
extends RefCounted
## Headless combat simulation facade (KAN-2) — a pure command-stream reducer.
##
## Contract (docs/DIRECTION.md technical deltas + docs/rules-addendum.md):
## - The sim advances ONLY via apply_command(cmd) -> [events]. The caller owns
##   the command log; the sim is the reducer. State is a pure function of
##   (seed, ordered command log): no wall-clock reads, one seeded RNG consumed
##   only inside apply_command, every roll emitted in an event.
## - Clock drivers live OUTSIDE the sim: it never self-advances; the driver
##   feeds "advance_tick" commands (R0).
##
## Commands (Dictionary, "type" +):
##   {"type": "add_combatant", "combatant": {spec}}         (see CombatantState.from_spec)
##   {"type": "advance_tick"}                                completes the current tick (R1)
##   {"type": "declare_action", "actor", "action": {...}}    (see ActionResolver.declare)
##   {"type": "move", "actor", "to": [q, r]}                 hex movement (R3)
##   {"type": "inventory", "actor", "item"?, "interaction"?} inventory interaction (R3)
##   {"type": "reaction", "actor", "cost", "target"?, "part"?, "damage"?} (R2)
##   {"type": "treat", "target", "part", "condition", "mode": "delay"|"resolve"} (R4/R10)
##   {"type": "heal", "target", "part", "amount"}            explicit field healing only
##   {"type": "apply_condition", "target", "part", "condition", "tier"?, "poison_type"?,
##            "activation_delay"?}                           environment/GM source
##   {"type": "grant_level", "actor"} / {"type": "spend_level_point", "actor", "trait"} (R6)
##   {"type": "set_status", "target", "status": "overwhelmed"|"prone"|"slowed", "value"}
##
## Rejected commands emit a single command_rejected event and mutate nothing.

var rng: RandomNumberGenerator
var rng_seed: int = 0
var static_data: Dictionary = {}
var clock: Clock
var combatants: Dictionary = {}  # id -> CombatantState (shared with helpers)
var cond: ConditionEngine
var resolver: ActionResolver
var hype: HypeEngine
## State snapshot taken at the START of the current tick — all resolutions at
## a tick compute against it (R2 simultaneity; simultaneous kills trade).
var tick_snapshot: Dictionary = {}


func _init(sim_seed: int = 0, data: Dictionary = {}) -> void:
	rng_seed = sim_seed
	rng = RandomNumberGenerator.new()
	rng.seed = sim_seed
	static_data = data.duplicate(true)
	clock = Clock.new()
	cond = ConditionEngine.new()
	cond.setup(static_data.get("conditions", []), combatants)
	resolver = ActionResolver.new()
	resolver.setup(clock, combatants, cond, rng)
	hype = HypeEngine.new()
	_rebuild_snapshot()


func apply_command(cmd: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	match String(cmd.get("type", "")):
		"add_combatant":
			events = _add_combatant(cmd.get("combatant", {}))
		"advance_tick":
			events = _advance_tick()
		"declare_action":
			events = resolver.declare(String(cmd.get("actor", "")), cmd.get("action", {}))
		"move":
			var to: Array = cmd.get("to", [0, 0])
			events = resolver.move(String(cmd.get("actor", "")), Vector2i(int(to[0]), int(to[1])))
		"inventory":
			events = resolver.inventory(String(cmd.get("actor", "")), cmd)
		"reaction":
			events = resolver.reaction(String(cmd.get("actor", "")), cmd)
		"treat":
			events = _treat(cmd)
		"heal":
			events = _heal(cmd)
		"apply_condition":
			events = _apply_condition(cmd)
		"grant_level":
			events = _grant_level(cmd)
		"spend_level_point":
			events = _spend_level_point(cmd)
		"set_status":
			events = _set_status(cmd)
		_:
			events = [{"type": "command_rejected", "reason": "unknown_command", "command": String(cmd.get("type", ""))}]
	_post(events)
	return events


## Housekeeping after every command: deaths cancel scheduled actions, breach
## checks run, exposure caches refresh, events get the tick stamp.
func _post(events: Array[Dictionary]) -> void:
	for event: Dictionary in events.duplicate():
		if String(event.get("type", "")) == "combatant_died":
			var dead_id := String(event.get("combatant", ""))
			clock.cancel_for(dead_id)
			var dead: CombatantState = combatants.get(dead_id)
			if dead != null:
				dead.windup_pending = false
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if Resistance.check_breach(c):
			c.breached = true
			var part_keys: Array = c.parts.keys()
			part_keys.sort()
			for part_key: Variant in part_keys:
				var part: Dictionary = c.parts[part_key]
				if bool(part.get("hidden", false)):
					part["hidden"] = false
			events.append({"type": "breach_opened", "combatant": c.id})
		events.append_array(ExposureEngine.refresh(c, clock.tick))
	events.append_array(hype.ingest(events))
	for event: Dictionary in events:
		if not event.has("tick"):
			event["tick"] = clock.tick


# ------------------------------------------------------------------ commands

func _add_combatant(spec: Dictionary) -> Array[Dictionary]:
	var id := String(spec.get("id", ""))
	if id == "":
		return [{"type": "command_rejected", "reason": "missing_id"}]
	if combatants.has(id):
		return [{"type": "command_rejected", "reason": "duplicate_id", "combatant": id}]
	var c := CombatantState.from_spec(spec, static_data)
	c.next_action_tick = clock.tick
	combatants[id] = c
	tick_snapshot[id] = _snapshot_entry(c)
	var events: Array[Dictionary] = [{"type": "combatant_added", "combatant": id}]
	return events


## R1 order of operations for the CURRENT tick:
## 1. resolve all actions due this tick (against the tick-start snapshot),
## 2. apply Forced-Action consequences queued by step 1,
## 3. if this tick completes a Clock: universal condition advancement (R4),
## 4. advance to the next tick and re-snapshot.
func _advance_tick() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var result: Dictionary = resolver.resolve_due(tick_snapshot)
	events.append_array(result["events"])
	for queued: Variant in result["forced"] as Array:
		var forced: Dictionary = queued
		var actor: CombatantState = combatants.get(String(forced.get("actor", "")))
		if actor == null:
			continue
		events.append_array(ForcedAction.apply_consequence(
			forced["rolled"], actor, forced.get("ctx", {}), cond, combatants, clock.tick))
	if clock.completes_clock():
		events.append({"type": "clock_reset", "tick": clock.tick})
		var ids: Array = combatants.keys()
		ids.sort()
		for id: Variant in ids:
			events.append_array(cond.on_clock_reset(combatants[id], clock.tick))
	# Everything above happened ON the completing tick — stamp before advancing.
	for event: Dictionary in events:
		if not event.has("tick"):
			event["tick"] = clock.tick
			event["moment"] = clock.moment()
	clock.advance()
	var all_ids: Array = combatants.keys()
	all_ids.sort()
	for id: Variant in all_ids:
		var c: CombatantState = combatants[id]
		c.reset_tick_flags()
		c.windup_pending = clock.has_windup_for(c.id)
	events.append({"type": "clock_moment_changed", "tick": clock.tick, "moment": clock.moment()})
	_rebuild_snapshot()
	return events


func _treat(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	var mode := String(cmd.get("mode", "delay"))
	if mode != "delay" and mode != "resolve":
		return [{"type": "command_rejected", "reason": "unknown_treat_mode", "mode": mode}]
	return cond.treat(target, String(cmd.get("part", "")), String(cmd.get("condition", "")), mode)


func _heal(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	return cond.heal_part(target, String(cmd.get("part", "")), int(cmd.get("amount", 0)))


func _apply_condition(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	var ctx: Dictionary = {"source": "direct"}
	if cmd.has("tier"):
		ctx["tier"] = int(cmd["tier"])
	if cmd.has("poison_type"):
		ctx["poison_type"] = String(cmd["poison_type"])
	if cmd.has("activation_delay"):
		ctx["activation_delay"] = int(cmd["activation_delay"])
	return cond.apply(target, String(cmd.get("part", "")), String(cmd.get("condition", "")), clock.tick, ctx)


func _grant_level(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor"}]
	actor.level_points += 1
	var events: Array[Dictionary] = [{"type": "level_granted", "combatant": actor.id, "pool": actor.level_points}]
	return events


## R6: a level point buys +1 levelBonus on any one trait; a Physique threshold
## crossing also raises every part's max (and current) HP.
func _spend_level_point(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor"}]
	var trait_key := String(cmd.get("trait", ""))
	if not CombatantState.TRAIT_KEYS.has(trait_key):
		return [{"type": "command_rejected", "reason": "unknown_trait", "trait": trait_key}]
	if actor.level_points <= 0:
		return [{"type": "command_rejected", "reason": "no_level_points"}]
	var hp_bonus_before: int = actor.hp_bonus_per_part()
	actor.level_points -= 1
	var stat: Dictionary = actor.stats[trait_key]
	stat["level_bonus"] = int(stat.get("level_bonus", 0)) + 1
	var events: Array[Dictionary] = [{
		"type": "level_point_spent", "combatant": actor.id, "trait": trait_key,
		"total": actor.trait_total(trait_key), "pool": actor.level_points,
	}]
	var hp_gain: int = actor.hp_bonus_per_part() - hp_bonus_before
	if hp_gain > 0:
		var part_keys: Array = actor.parts.keys()
		part_keys.sort()
		for part_key: Variant in part_keys:
			var part: Dictionary = actor.parts[part_key]
			part["hp"] = int(part["hp"]) + hp_gain
		events.append({"type": "max_hp_increased", "combatant": actor.id, "per_part": hp_gain})
	return events


func _set_status(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	var status := String(cmd.get("status", ""))
	if not ["overwhelmed", "prone", "slowed"].has(status):
		return [{"type": "command_rejected", "reason": "unknown_status", "status": status}]
	var value: bool = bool(cmd.get("value", true))
	if value:
		target.statuses[status] = true
	else:
		target.statuses.erase(status)
	var events: Array[Dictionary] = [{"type": "status_changed", "combatant": target.id, "status": status, "value": value}]
	return events


# ------------------------------------------------------------------ snapshot

func _snapshot_entry(c: CombatantState) -> Dictionary:
	return {
		"position": [c.position.x, c.position.y],
		"alive": c.alive and not c.removed_from_play,
		"exposed": c.exposed_cache,
		"helpless": c.is_helpless(clock.tick),
		"overwhelmed": bool(c.statuses.get("overwhelmed", false)),
	}


func _rebuild_snapshot() -> void:
	tick_snapshot = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		tick_snapshot[String(id)] = _snapshot_entry(combatants[id])


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	var combatant_dicts: Dictionary = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		combatant_dicts[String(id)] = (combatants[id] as CombatantState).to_dict()
	return {
		"rng_seed": rng_seed,
		"rng_state": rng.state,
		"clock": clock.to_dict(),
		"combatants": combatant_dicts,
		"tick_snapshot": tick_snapshot.duplicate(true),
		"static_data": static_data.duplicate(true),
		"hype": hype.to_dict(),
	}


static func from_dict(data: Dictionary) -> CombatSim:
	var sim := CombatSim.new(int(data.get("rng_seed", 0)), data.get("static_data", {}))
	sim.rng.state = int(data.get("rng_state", sim.rng.state))
	sim.clock = Clock.from_dict(data.get("clock", {}))
	var combatant_dicts: Dictionary = data.get("combatants", {})
	for id: Variant in combatant_dicts:
		sim.combatants[String(id)] = CombatantState.from_dict(combatant_dicts[id])
	sim.tick_snapshot = (data.get("tick_snapshot", {}) as Dictionary).duplicate(true)
	sim.hype = HypeEngine.from_dict(data.get("hype", {}))
	# Re-wire helper references (clock instance was replaced above).
	sim.resolver.setup(sim.clock, sim.combatants, sim.cond, sim.rng)
	sim.cond.setup(sim.static_data.get("conditions", []), sim.combatants)
	return sim


## Hash over the canonically-serialized state. Identical (seed, command log)
## must always produce an identical hash (DIRECTION contract; criterion 19).
func state_hash() -> String:
	return canonical_serialize(to_dict()).sha256_text()


## Canonical, key-sorted, type-stable text form of a Variant tree.
static func canonical_serialize(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			# JSON-parsed numbers arrive as floats; whole floats print as ints.
			var f: float = value
			if f == floorf(f) and absf(f) < 9007199254740992.0:
				return str(int(f))
			return str(f)
		TYPE_STRING, TYPE_STRING_NAME:
			return "\"" + String(value).c_escape() + "\""
		TYPE_ARRAY:
			var items: Array[String] = []
			for item: Variant in value as Array:
				items.append(canonical_serialize(item))
			return "[" + ",".join(items) + "]"
		TYPE_DICTIONARY:
			var dict: Dictionary = value
			var keys: Array = dict.keys()
			keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
			var pairs: Array[String] = []
			for key: Variant in keys:
				pairs.append("\"" + str(key).c_escape() + "\":" + canonical_serialize(dict[key]))
			return "{" + ",".join(pairs) + "}"
	return "\"" + str(value).c_escape() + "\""
