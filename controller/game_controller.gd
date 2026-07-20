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
signal ai_decision(event: Dictionary)
signal boss_phase_changed(event: Dictionary)
signal attack_dodged(event: Dictionary)
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
	"ai_decision": "ai_decision",
	"boss_phase_changed": "boss_phase_changed",
	"attack_dodged": "attack_dodged",
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


## The enemy side of a tick (R11 #15): feeds one ai_decide per ready
## AI-controlled combatant (sorted) into the command log. The driver calls
## this before advancing the tick; each decision recomputes deterministically
## on replay, so the log stays the single source of truth.
func run_enemy_turn() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if sim == null:
		return events
	for id: String in sim.ai_ready_ids():
		events.append_array(apply_command({"type": "ai_decide", "actor": id}))
	return events


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
				"destroyed": bool(part.get("destroyed", false)),
				# A part hidden_until_breach reads hidden=true until this combatant
				# is breached — the HUD keeps the boss's mycelium network off-screen
				# until the party discovers it (breached flips it visible).
				"hidden": bool(part.get("hidden", false)) and not c.breached,
				"conditions": conds,
			})
		out.append({
			"id": String(id),
			"name": c.display_name,
			"position": [c.position.x, c.position.y],
			"alive": c.alive,
			"shock": c.shock,
			"exposed": c.exposed_cache,
			"breached": c.breached,
			"parts": parts,
		})
	return out


func view_clock() -> Dictionary:
	if sim == null:
		return {}
	return {"tick": sim.clock.tick, "moment": sim.clock.moment()}


## Owner-blessed band display names (2026-07-19): the sim enum -> broadcast copy.
const BAND_DISPLAY: Dictionary = {
	"cold": "COLD OPEN", "warm": "WARMING UP", "hot": "ELECTRIC", "on_fire": "ON FIRE",
}


## Broadcast/audience projection for the combat HUD. view_combatants covers the
## fighters; this covers the audience economy the mockup shows — hype meter+band,
## the active crowd goal, the camera spotlight, and per-contestant tags — none of
## which lived in a view before (slice playtest finding F3). Read-only over the
## sim's HypeEngine + TagEngine; presentation only, never mutates.
func view_broadcast() -> Dictionary:
	if sim == null:
		return {}
	var hype: HypeEngine = sim.hype
	var band := String(hype.band)
	var goal: Dictionary = {}
	if not hype.active_goal.is_empty():
		var g: Dictionary = hype.active_goal
		goal = {
			"id": String(g.get("id", "")),
			"name": String(g.get("name", "")),
			"kind": String(g.get("kind", "")),
			"payout": int(g.get("payout", 0)),
			"clocks_left": int(g.get("clocks_left", 0)),
			"progress": int(g.get("progress", 0)),
			"params": (g.get("params", {}) as Dictionary).duplicate(true),
		}
	var spotlight: Dictionary = {}
	if not hype.spotlight.is_empty():
		spotlight = {
			"caller": String(hype.spotlight.get("caller", "")),
			"target": String(hype.spotlight.get("target", "")),
			"clocks_left": int(hype.spotlight.get("clocks_left", 0)),
		}
	# Per-contestant tags (held + in-progress) for the tag feed / unit tokens.
	var tags: Dictionary = {}
	var tag_ids: Array = sim.tags.held.keys()
	for pid: Variant in sim.tags.progress.keys():
		if not tag_ids.has(pid):
			tag_ids.append(pid)
	tag_ids.sort()
	for pid: Variant in tag_ids:
		var held_keys: Array = (sim.tags.held.get(pid, {}) as Dictionary).keys()
		held_keys.sort()
		tags[String(pid)] = {
			"held": held_keys,
			"progress": (sim.tags.progress.get(pid, {}) as Dictionary).duplicate(true),
		}
	return {
		"hype": {
			"meter": int(hype.meter),
			"band": band,
			"band_display": String(BAND_DISPLAY.get(band, band.to_upper())),
		},
		"goal": goal,
		"spotlight": spotlight,
		"tags": tags,
	}


## Turn-order projection (KAN-6): live combatants ordered by when they next act
## (next_action_tick, soonest first; deterministic id tie-break). Drives the HUD
## tick-order rail and the on-the-clock highlight. `ready` = can act at the current
## tick and not still winding up; `windup_pending` marks a committed multi-Moment
## action mid-resolution.
func view_turn_order() -> Array[Dictionary]:
	var order: Array[Dictionary] = []
	if sim == null:
		return order
	var ids: Array = sim.combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = sim.combatants[id]
		if not c.alive or c.removed_from_play:
			continue
		order.append({
			"id": String(id),
			"name": c.display_name,
			"category": c.category,
			"is_contestant": not EnemyAI.AI_CATEGORIES.has(c.category),
			"next_action_tick": c.next_action_tick,
			"ready": c.can_act(sim.clock.tick) and not c.windup_pending and c.next_action_tick <= sim.clock.tick,
			"windup_pending": c.windup_pending,
		})
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["next_action_tick"]) != int(b["next_action_tick"]):
			return int(a["next_action_tick"]) < int(b["next_action_tick"])
		return String(a["id"]) < String(b["id"]))
	return order


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
