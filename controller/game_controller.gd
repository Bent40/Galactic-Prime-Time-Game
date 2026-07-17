extends Node
## GameController — the single gateway between presentation and the sim (KAN3-S1).
##
## MVC contract (architecture doc + docs/architecture/architecture.md):
## - Owns the CombatSim instance; scenes NEVER touch simulation/ classes.
## - Every command funnels through apply_command(); every event the sim returns
##   is re-emitted as a signal: a typed signal for the catalog's combat events
##   plus the generic sim_event for everything (scenes may subscribe to either).
## - Constructor-friendly: no _ready dependency, so headless tests can drive it.
## - Owns the COMMAND LOG (the sim is the reducer; the caller owns the log) and
##   the save/load flow via SaveManager (KAN3-S2). Static data comes exclusively
##   from the DAL.

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
var dal: Dal = Dal.new()
var saves: SaveManager = SaveManager.new()
var command_log: Array[Dictionary] = []


## Creates a fresh sim. Passing static_data overrides the DAL load (tests).
func start_combat(sim_seed: int, static_data: Dictionary = {}) -> void:
	if static_data.is_empty():
		static_data = dal.static_data_for_sim()
	sim = CombatSim.new(sim_seed, static_data)
	command_log = []


## The one command funnel: logs the command, applies it, re-emits every event.
func apply_command(cmd: Dictionary) -> Array[Dictionary]:
	if sim == null:
		push_error("GameController.apply_command before start_combat")
		return []
	command_log.append(cmd.duplicate(true))
	var events: Array[Dictionary] = sim.apply_command(cmd)
	for event: Dictionary in events:
		sim_event.emit(event)
		var event_type := String(event.get("type", ""))
		if TYPED.has(event_type):
			emit_signal(StringName(TYPED[event_type]), event)
	return events


func state_hash() -> String:
	return "" if sim == null else sim.state_hash()


## Read-only VIEW API (KAN3-S3): plain-Dictionary projections of sim state so
## scenes can render without importing simulation classes. Sorted, primitive,
## and safe to call every frame.
func view_combatants() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if sim == null:
		return out
	var ids: Array = sim.combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = sim.combatants[id]
		var parts: Array[Dictionary] = []
		var part_keys: Array = c.parts.keys()
		part_keys.sort()
		for part_key: Variant in part_keys:
			var part: Dictionary = c.parts[part_key]
			var conds: Dictionary = {}
			var on_part: Dictionary = c.conditions.get(part_key, {})
			for cond_id: Variant in on_part:
				conds[String(cond_id)] = int((on_part[cond_id] as Dictionary).get("tier", 1))
			parts.append({
				"key": String(part_key),
				"hp": int(part.get("hp", 0)),
				"max_hp": c.max_hp(String(part_key)),
				"lethal": bool(part.get("lethal", false)),
				"disabled": bool(part.get("disabled", false)),
				"conditions": conds,
			})
		out.append({
			"id": String(id),
			"name": c.display_name,
			"position": [c.position.x, c.position.y],
			"alive": c.alive,
			"shock": c.shock,
			"exposed": c.exposed_cache,
			"parts": parts,
		})
	return out


func view_clock() -> Dictionary:
	if sim == null:
		return {}
	return {"tick": sim.clock.tick, "moment": sim.clock.moment()}


func save_game(save_name: String) -> bool:
	if sim == null:
		return false
	return saves.save_game(save_name, sim, command_log)


## Restores sim + log from a save. Returns false (soft) on missing/corrupt file.
func load_game(save_name: String) -> bool:
	var envelope: Dictionary = saves.load_game(save_name)
	if envelope.is_empty():
		return false
	sim = CombatSim.from_dict(envelope["snapshot"])
	command_log.assign(envelope.get("command_log", []))
	return true
