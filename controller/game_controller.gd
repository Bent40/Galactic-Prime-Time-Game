extends Node
## GameController — the single gateway between presentation and the sim (KAN3-S1).
##
## MVC contract (architecture doc + docs/architecture/architecture.md):
## - Owns the CombatSim instance; scenes NEVER touch simulation/ classes.
## - Every command funnels through apply_command(); every event the sim returns
##   is re-emitted as a signal: a typed signal for the catalog's combat events
##   plus the generic sim_event for everything (scenes may subscribe to either).
## - Constructor-friendly: no _ready dependency, so headless tests can drive it.
##
## TODO-S2: static data currently loads straight from data/*.json here; KAN3-S2
## replaces this with the DAL as the single data owner.

signal sim_event(event: Dictionary)
signal combatant_added(event: Dictionary)
signal combatant_died(event: Dictionary)
signal damage_applied(event: Dictionary)
signal condition_applied(event: Dictionary)
signal condition_advanced(event: Dictionary)
signal action_resolved(event: Dictionary)
signal forced_action_triggered(event: Dictionary)
signal breach_opened(event: Dictionary)
signal clock_moment_changed(event: Dictionary)
signal clock_reset(event: Dictionary)
signal hype_band_changed(event: Dictionary)
signal hype_spike(event: Dictionary)
signal command_rejected(event: Dictionary)

## event type -> typed signal name (generic sim_event fires for every event).
const TYPED: Dictionary = {
	"combatant_added": "combatant_added",
	"combatant_died": "combatant_died",
	"damage_applied": "damage_applied",
	"condition_applied": "condition_applied",
	"condition_advanced": "condition_advanced",
	"action_resolved": "action_resolved",
	"forced_action_triggered": "forced_action_triggered",
	"breach_opened": "breach_opened",
	"clock_moment_changed": "clock_moment_changed",
	"clock_reset": "clock_reset",
	"hype_band_changed": "hype_band_changed",
	"hype_spike": "hype_spike",
	"command_rejected": "command_rejected",
}

var sim: CombatSim


## Creates a fresh sim. Passing static_data overrides the JSON load (tests).
func start_combat(sim_seed: int, static_data: Dictionary = {}) -> void:
	if static_data.is_empty():
		static_data = _load_static_data()
	sim = CombatSim.new(sim_seed, static_data)


## The one command funnel. Returns the sim's events after re-emitting them.
func apply_command(cmd: Dictionary) -> Array[Dictionary]:
	if sim == null:
		push_error("GameController.apply_command before start_combat")
		return []
	var events: Array[Dictionary] = sim.apply_command(cmd)
	for event: Dictionary in events:
		sim_event.emit(event)
		var event_type := String(event.get("type", ""))
		if TYPED.has(event_type):
			emit_signal(StringName(TYPED[event_type]), event)
	return events


func state_hash() -> String:
	return "" if sim == null else sim.state_hash()


static func _load_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func _load_static_data() -> Dictionary:
	return {
		"conditions": _load_json("res://data/conditions.json"),
		"races": _load_json("res://data/races.json"),
		"enemies": _load_json("res://data/enemies.json"),
		"items": _load_json("res://data/items.json"),
	}
