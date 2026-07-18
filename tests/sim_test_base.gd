class_name SimTestBase
extends RefCounted
## Base class for sim test scripts. Assert helpers ACCUMULATE failures instead
## of aborting, so one broken expectation never hides the rest of the picture.
## Tests may use FileAccess (they live outside simulation/) to load data/*.json
## and hand the parsed Dictionaries to the sim.

var failures: Array[String] = []
var checks: int = 0
var current_test: String = ""


func begin_test(test_name: String) -> void:
	failures = []
	checks = 0
	current_test = test_name


func fail_test(message: String) -> void:
	checks += 1
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	checks += 1
	if not condition:
		failures.append("assert_true failed: " + message)


func assert_false(condition: bool, message: String = "") -> void:
	checks += 1
	if condition:
		failures.append("assert_false failed: " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	checks += 1
	if not _loose_eq(actual, expected):
		failures.append("assert_eq failed: %s — expected %s, got %s" % [message, str(expected), str(actual)])


func assert_ne(actual: Variant, other: Variant, message: String = "") -> void:
	checks += 1
	if _loose_eq(actual, other):
		failures.append("assert_ne failed: %s — both are %s" % [message, str(actual)])


## JSON numbers parse as floats; compare numerics numerically.
static func _loose_eq(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	return a == b


# ---------------------------------------------------------------- data + sim

static func load_json(path: String) -> Variant:
	var text: String = FileAccess.get_file_as_string(path)
	return JSON.parse_string(text)


static func load_static_data() -> Dictionary:
	return {
		"conditions": load_json("res://data/conditions.json"),
		"races": load_json("res://data/races.json"),
		"enemies": load_json("res://data/enemies.json"),
		"items": load_json("res://data/items.json"),
		"crowd_goals": load_json("res://data/crowd_goals.json"),
	}


func make_sim(sim_seed: int = 1234) -> CombatSim:
	return CombatSim.new(sim_seed, load_static_data())


## Adds a human-race contestant; overrides merge over the default spec.
func add_human(sim: CombatSim, id: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id,
		"name": id,
		"race": "human",
		"position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func advance(sim: CombatSim, ticks: int = 1) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for i: int in range(ticks):
		events.append_array(sim.apply_command({"type": "advance_tick"}))
	return events


func declare(sim: CombatSim, actor: String, action: Dictionary) -> Array[Dictionary]:
	return sim.apply_command({"type": "declare_action", "actor": actor, "action": action})


## Basic single-target melee-style attack action.
func attack_action(damage_type: String, amount: int, target_id: String, part: String, extra: Dictionary = {}) -> Dictionary:
	var action: Dictionary = {
		"kind": "attack",
		"cost": 1,
		"damage": {"type": damage_type, "amount": amount},
		"attack_range": 1,
		"targets": [{"id": target_id, "part": part}],
	}
	action.merge(extra, true)
	return action


# ---------------------------------------------------------------- event query

func events_of(events: Array[Dictionary], event_type: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event: Dictionary in events:
		if String(event.get("type", "")) == event_type:
			found.append(event)
	return found


func first_event(events: Array[Dictionary], event_type: String) -> Dictionary:
	for event: Dictionary in events:
		if String(event.get("type", "")) == event_type:
			return event
	return {}


func has_event(events: Array[Dictionary], event_type: String) -> bool:
	return not first_event(events, event_type).is_empty()


func assert_event(events: Array[Dictionary], event_type: String, message: String = "") -> Dictionary:
	checks += 1
	var event: Dictionary = first_event(events, event_type)
	if event.is_empty():
		var seen: Array[String] = []
		for e: Dictionary in events:
			seen.append(String(e.get("type", "?")))
		failures.append("expected event '%s' (%s) — saw: [%s]" % [event_type, message, ", ".join(seen)])
	return event


func assert_no_event(events: Array[Dictionary], event_type: String, message: String = "") -> void:
	checks += 1
	if has_event(events, event_type):
		failures.append("expected NO event '%s' (%s) but found one: %s" % [event_type, message, str(first_event(events, event_type))])


func assert_rejected(events: Array[Dictionary], reason: String, message: String = "") -> void:
	checks += 1
	var event: Dictionary = first_event(events, "command_rejected")
	if event.is_empty():
		failures.append("expected command_rejected(%s) (%s) — command was accepted: %s" % [reason, message, str(events)])
	elif String(event.get("reason", "")) != reason:
		failures.append("expected rejection reason '%s' (%s), got '%s'" % [reason, message, String(event.get("reason", ""))])
