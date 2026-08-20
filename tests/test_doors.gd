extends SimTestBase
## KAN-5 wave 4b — DOORS (rules-addendum R29).
##
## Under test:
##  * config/placement validation (Arena.from_config shape gates + the
##    set_arena arena_door_misplaced placement gates) and staging honesty
##    (staging_on_door_hex — a doorway is never a spawn hex, open OR closed).
##  * the ONE-QUERY blocking model: a CLOSED door blocks exactly like a wall
##    THROUGH Arena.is_wall, so movement / tactical rolls / AI steps / dash
##    lanes (end AND phase-3 bounce) inherit doors with zero consumer edits;
##    an OPEN door blocks nothing.
##  * the door command: adjacency (distance exactly 1 — no closing a door
##    under yourself), alive/ready gates, the R3/R34 free-action BUDGET (the
##    inventory-interaction family — CombatantState.FREE_ACTIONS_PER_CLOCK
##    free actions per tick since the owner's 2026-08-19 ruling, no
##    Moment-cost fallback in v1), open->move-through, close-behind-you, the
##    door_blocked_by_body doorway guard, door_changed events.
##  * serialization: doors ride the arena's to_dict (hash-covered, state
##    included mid-flip); the doors key is ABSENT on a door-less arena (the
##    wave-3d byte-compat pin); save/restore lockstep.
## Enemies never issue the door command in v1 (the AI never DECIDES doors —
## no enemy_ai path exists; pinned here only via the walled-off wait, which
## is the wall parity the one-query model guarantees).

const BOUNDS: Dictionary = {"width": 41, "height": 60}


func arena_cfg(walls: Array = [], objects: Array = [], doors: Array = [],
		bounds: Dictionary = BOUNDS) -> Dictionary:
	return {"bounds": bounds, "walls": walls, "objects": objects, "doors": doors}


func door_row(key: String, pos: Array, state: String = "closed") -> Dictionary:
	return {"key": key, "position": pos, "state": state}


func set_arena(sim: CombatSim, cfg: Dictionary) -> Array[Dictionary]:
	return sim.apply_command({"type": "set_arena", "arena": cfg})


func door(sim: CombatSim, actor: String, key: String, to_state: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "door", "actor": actor, "key": key, "set": to_state})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The test_arena.gd idiom: the seeded Incinedile trait block minus the dodge
## threshold, so staged hits stay pin-exact without rng.
func traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}


## A dash-only synthetic boss (test_arena.gd's isolation pattern).
func add_dash_boss(sim: CombatSim, upgrades: Array, pos: Array = [0, 0]) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "boss", "enemy": "incinedile",
		"team": "enemies", "position": pos,
		"boss_traits": traits_without_dodge(),
		"phases": [{
			"phase_number": 1, "name": "Synthetic",
			"behavior": {"abilities": ["dash"], "upgrades": upgrades},
		}],
	}})


func hand_dash(lane: Array) -> Dictionary:
	return {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 2}, "attack_range": 6,
		"targets": [{"id": "vic", "part": "torso"}],
		"area_shape": {"kind": "line", "lane": lane},
	}


# ------------------------------------------------- config + placement + staging

func test_door_config_and_placement_validation() -> void:
	var sim: CombatSim = make_sim()
	# Shape gates (Arena.from_config): missing key / bad state / duplicate key
	# / bad position each reject the whole config as invalid.
	assert_rejected(set_arena(sim, arena_cfg([], [], [door_row("", [3, 0])])),
		"invalid_arena", "a door needs a non-empty key")
	assert_rejected(set_arena(sim, arena_cfg([], [], [door_row("d", [3, 0], "ajar")])),
		"invalid_arena", "a door state must be open|closed")
	assert_rejected(set_arena(sim, arena_cfg([], [], [door_row("d", [3, 0]), door_row("d", [4, 0])])),
		"invalid_arena", "door keys must be unique")
	assert_rejected(set_arena(sim, arena_cfg([], [], [{"key": "d", "position": [3], "state": "open"}])),
		"invalid_arena", "a door position must be a hex pair")
	# Placement gates (set_arena): out of bounds / on a wall / on an object /
	# two doors one hex.
	assert_rejected(set_arena(sim, arena_cfg([], [], [door_row("d", [99, 99])])),
		"arena_door_misplaced", "a door outside the room")
	assert_rejected(set_arena(sim, arena_cfg([[3, 0]], [], [door_row("d", [3, 0])])),
		"arena_door_misplaced", "a door on a wall")
	# Door/object collisions reject from whichever side sees them first: an
	# OPEN door under a can is caught by the door loop; a CLOSED door reads
	# as a wall to the object loop (is_wall), so the CAN is what rejects.
	assert_rejected(set_arena(sim, arena_cfg([], [{"key": "trash_can", "position": [3, 0]}],
		[door_row("d", [3, 0], "open")])), "arena_door_misplaced", "an open door on a trash can")
	assert_rejected(set_arena(sim, arena_cfg([], [{"key": "trash_can", "position": [3, 0]}],
		[door_row("d", [3, 0], "closed")])), "arena_object_misplaced",
		"a can on a CLOSED door is a can on a wall-like hex — rejected either way")
	assert_rejected(set_arena(sim, arena_cfg([], [], [door_row("a", [3, 0]), door_row("b", [3, 0], "open")])),
		"arena_door_misplaced", "two doors on one hex")
	assert_true(sim.arena == null, "every rejection left the sim arena-less")
	# A combatant already standing on a door hex (even an OPEN one) blocks the set.
	add_human(sim, "squatter", {"team": "party", "position": [3, 0]})
	assert_rejected(set_arena(sim, arena_cfg([], [], [door_row("d", [3, 0], "open")])),
		"combatant_outside_arena", "a late set_arena cannot trap a body in a doorway")
	# A valid set carries the doors on the arena_set event.
	var sim2: CombatSim = make_sim()
	var events: Array[Dictionary] = set_arena(sim2, arena_cfg([], [],
		[door_row("hatch", [3, 0]), door_row("gate", [-4, 2], "open")]))
	var arena_event: Dictionary = assert_event(events, "arena_set", "the opt-in event")
	assert_eq((arena_event.get("doors", []) as Array).size(), 2, "both doors ride the event")
	assert_eq(String(((arena_event.get("doors", []) as Array)[0] as Dictionary).get("state", "")),
		"closed", "authored state echoed")
	# Staging honesty: a doorway is never a spawn hex — open OR closed.
	assert_rejected(add_human(sim2, "on_closed", {"position": [3, 0]}),
		"staging_on_door_hex", "no spawn on a CLOSED door hex")
	assert_rejected(add_human(sim2, "on_open", {"position": [-4, 2]}),
		"staging_on_door_hex", "no spawn on an OPEN door hex either")
	assert_event(add_human(sim2, "ok", {"position": [1, 0]}), "combatant_added",
		"legal ground stages fine")


# ------------------------------------------------- the one-query blocking model

func test_closed_door_blocks_like_a_wall_open_blocks_nothing() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([], [], [door_row("hatch", [1, 0]), door_row("gate", [0, 1], "open")]))
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	# Free move: a closed door rejects exactly like a wall; an open one is floor.
	assert_rejected(move(sim, "h", [1, 0]), "hex_blocked", "a move onto a closed door rejects")
	assert_event(move(sim, "h", [0, 1]), "moved", "standing in an OPEN doorway is legal")
	# Tactical roll: same query, same verdicts.
	sim.apply_command({"type": "advance_tick"})
	assert_rejected(sim.apply_command({"type": "declare_action", "actor": "h",
		"action": {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [1, 0]}}),
		"hex_blocked", "a roll onto a closed door rejects")
	# AI step: a mob walled off by a CLOSED door waits — the wall parity that
	# proves enemies (who never open doors in v1) are honestly stuck.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, arena_cfg([], [], [door_row("hatch", [1, 0])]))
	add_human(sim2, "vic", {"team": "party", "position": [0, 0]})
	sim2.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [2, 0],
	}})
	var stuck: Dictionary = first_event(ai_decide(sim2, "mob"), "ai_decision")
	assert_eq(String(stuck.get("choice", "")), "wait",
		"a closed door walls the mob off — it waits (the AI never opens doors, v1)")
	assert_eq((sim2.combatants["mob"] as CombatantState).position, Vector2i(2, 0), "and never moved")


func test_dash_lane_ends_at_closed_door_passes_open_and_bounces() -> void:
	# Geometry authority first (Arena.bounced_lane — the query every dash
	# path walks): a CLOSED door truncates the lane exactly like a wall at
	# bounce budget 0, BOUNCES it like a wall with the budget, and an OPEN
	# door does neither.
	var arena: Arena = Arena.from_config(arena_cfg([], [], [door_row("hatch", [2, 0])]))
	var flat: Dictionary = arena.bounced_lane(Vector2i(0, 0), Vector2i(5, 0), 4, 0)
	assert_eq(flat["lane"], [Vector2i(0, 0), Vector2i(1, 0)],
		"budget 0: the lane ENDS before the closed door (wall parity)")
	var banked: Dictionary = arena.bounced_lane(Vector2i(0, 0), Vector2i(5, 0), 4, 2)
	assert_eq(banked["bounces"], [Vector2i(1, 0)],
		"with the budget a dash BOUNCES off a closed door exactly like a wall")
	arena.doors[0]["state"] = "open"
	var through: Dictionary = arena.bounced_lane(Vector2i(0, 0), Vector2i(5, 0), 4, 0)
	assert_eq((through["lane"] as Array).size(), 5, "an OPEN door: the lane runs straight through")
	# The REAL resolver path: a hand-built dash whose lane crosses the closed
	# door rejects lane_blocked; opening the door (the door command, by an
	# adjacent party member) makes the SAME declare legal and the charge
	# crosses the doorway.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([], [], [door_row("hatch", [2, 0])]))
	add_human(sim, "vic", {"team": "party", "position": [4, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_human(sim, "op", {"team": "party", "position": [1, 1]})
	add_dash_boss(sim, [])
	var lane: Array = [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]]
	assert_rejected(sim.apply_command({"type": "declare_action", "actor": "boss",
		"action": hand_dash(lane)}), "lane_blocked",
		"a committed lane never contains a closed-door hex (the wall rule verbatim)")
	assert_event(door(sim, "op", "hatch", "open"), "door_changed", "an adjacent contestant opens it")
	assert_event(sim.apply_command({"type": "declare_action", "actor": "boss",
		"action": hand_dash(lane)}), "action_declared", "the same lane declares once the door is open")
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "dash_charged", "the charge runs through the open doorway")
	assert_eq((sim.combatants["boss"] as CombatantState).position, Vector2i(3, 0),
		"adjacent-before the target, straight through the doorway")
	assert_event(resolved, "damage_applied", "and the strike lands (Reflexes 2 cannot dodge)")


# ------------------------------------------------- the door command

func test_door_command_gates_and_free_slot_economy() -> void:
	var sim: CombatSim = make_sim()
	assert_rejected(door(sim, "ghost", "hatch", "open"), "unknown_actor", "unknown actor")
	set_arena(sim, arena_cfg([], [], [door_row("hatch", [1, 0]), door_row("far", [9, 0], "open")]))
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	add_human(sim, "bystander", {"team": "party", "position": [0, -1]})
	# A no-arena sim has no doors at all.
	var bare: CombatSim = make_sim()
	add_human(bare, "h", {"team": "party", "position": [0, 0]})
	assert_rejected(door(bare, "h", "hatch", "open"), "no_arena", "no arena = no doors")
	# Ask gates: unknown key / bad state / adjacency.
	assert_rejected(door(sim, "h", "nope", "open"), "unknown_door", "unknown door key")
	assert_rejected(sim.apply_command({"type": "door", "actor": "h", "key": "hatch", "set": "ajar"}),
		"unknown_door_state", "only open|closed are ruled states")
	assert_rejected(door(sim, "h", "far", "closed"), "door_not_adjacent",
		"distance 9: the actor must be ADJACENT to the door hex")
	# Same-state flips reject without touching the slot.
	assert_rejected(door(sim, "h", "hatch", "closed"), "door_already_closed", "no-op close rejects")
	assert_eq((sim.combatants["h"] as CombatantState).free_actions_used, 0,
		"every rejection above left the free-action budget UNSPENT")
	# The flip: door_changed + the R3 free slot consumed.
	var opened: Array[Dictionary] = door(sim, "h", "hatch", "open")
	var changed: Dictionary = assert_event(opened, "door_changed", "the flip event")
	assert_eq(String(changed.get("key", "")), "hatch", "which door")
	assert_eq(changed.get("position", []), [1, 0], "where it is")
	assert_eq(String(changed.get("state", "")), "open", "the new state")
	assert_eq((sim.combatants["h"] as CombatantState).free_actions_used, 1,
		"the flip consumed ONE free-action entry (R3 inventory-interaction family)")
	assert_true((sim.combatants["h"] as CombatantState).has_free_action(),
		"R34 (owner 2026-08-19): the second entry is still open — a door is no longer the whole tick")
	# Budget economy: the door and the free move draw on ONE shared pool, so the
	# second entry pays for the move and the THIRD rejects; v1 still grants NO
	# Moment-cost fallback for a second door interaction.
	assert_event(move(sim, "h", [0, 1]), "moved", "the free move rides the budget's second entry")
	assert_rejected(door(sim, "h", "hatch", "closed"), "free_action_used",
		"the third free action of the tick rejects (no Moment-cost fallback, v1)")
	# And the mirror, on a throwaway board so this one keeps its open door:
	# free move first, door second, third rejects — one pool, not one per family.
	var mirror: CombatSim = make_sim()
	set_arena(mirror, arena_cfg([], [], [door_row("hatch", [1, 0])]))
	add_human(mirror, "m", {"team": "party", "position": [0, 0]})
	assert_event(move(mirror, "m", [0, 1]), "moved", "entry 1: the free move")
	assert_event(door(mirror, "m", "hatch", "open"), "door_changed",
		"entry 2: the door still flips after a move (the R3 forfeit is gone — that IS the ruling)")
	assert_rejected(door(mirror, "m", "hatch", "closed"), "free_action_used",
		"entry 3 rejects — move + door spent the whole shared budget")
	# The bystander walks into door reach for the body-guard checks below.
	assert_event(move(sim, "bystander", [1, -1]), "moved", "the bystander spends a free move")
	# Next tick the slot refreshes; closing onto a LIVE body in the doorway
	# rejects; standing ON the open door cannot close it under yourself.
	advance(sim, 1)
	assert_event(move(sim, "h", [1, 0]), "moved", "h steps INTO the open doorway")
	assert_rejected(door(sim, "h", "hatch", "closed"), "door_not_adjacent",
		"distance 0 is not adjacent — no closing a door under yourself")
	assert_rejected(door(sim, "bystander", "hatch", "closed"), "door_blocked_by_body",
		"a live body in the doorway blocks the close")
	# Dead actors and dead bodies: a corpse neither works doors nor blocks them.
	advance(sim, 1)
	assert_event(move(sim, "h", [2, 0]), "moved", "h clears the doorway")
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "torso", "condition": "suffocation"})
	for _i: int in range(160):
		if not (sim.combatants["h"] as CombatantState).alive:
			break
		advance(sim, 1)
	assert_false((sim.combatants["h"] as CombatantState).alive, "precondition: h suffocated")
	assert_rejected(door(sim, "h", "hatch", "closed"), "actor_dead", "the dead work no doors")
	var closed: Array[Dictionary] = door(sim, "bystander", "hatch", "closed")
	assert_event(closed, "door_changed", "the survivor closes it — h's corpse is off the hex")


func test_open_move_through_close_behind_you() -> void:
	# The full flow the feature exists for: a closed door splits the room; a
	# contestant opens it (free action), walks through over two ticks, and
	# CLOSES IT BEHIND HER — the pursuing mob (which never opens doors, v1)
	# is walled off again.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([], [], [door_row("hatch", [1, 0])]))
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [-2, 0],
	}})
	# The doorway HEX is what blocks (destination check — the exact wall
	# contract, wave 3d: movement never path-traces, and neither do doors).
	assert_rejected(move(sim, "h", [1, 0]), "hex_blocked",
		"precondition: the closed doorway hex rejects a move onto it")
	assert_event(door(sim, "h", "hatch", "open"), "door_changed", "tick 0: open (free action)")
	advance(sim, 1)
	assert_event(move(sim, "h", [1, 0]), "moved", "tick 1: step INTO the open doorway")
	advance(sim, 1)
	assert_event(move(sim, "h", [2, 0]), "moved", "tick 2: step out the far side")
	advance(sim, 1)
	var closed: Array[Dictionary] = door(sim, "h", "hatch", "closed")
	assert_event(closed, "door_changed", "tick 3: close it behind you (adjacent from the far side)")
	assert_true(sim.arena.is_closed_door(Vector2i(1, 0)), "the door is closed again")
	assert_event(move(sim, "h", [3, 0]), "moved",
		"R34: the close spent ONE entry — the budget's second still pays for the step away")
	assert_false((sim.combatants["h"] as CombatantState).has_free_action(),
		"close + step = the whole free-action budget for this tick")
	advance(sim, 1)
	assert_rejected(move(sim, "h", [1, 0]), "hex_blocked", "and the doorway blocks again next tick")
	# The pursuer is honestly stuck on the far side.
	var stuck: Dictionary = first_event(ai_decide(sim, "mob"), "ai_decision")
	assert_ne(String(stuck.get("choice", "")), "attack", "the mob cannot reach through the closed door")


# ------------------------------------------------- serialization + determinism

func test_doors_serialize_hash_covered_and_lockstep() -> void:
	var sim: CombatSim = make_sim(99)
	set_arena(sim, arena_cfg([[5, 0]], [{"key": "trash_can", "position": [6, 0]}],
		[door_row("hatch", [1, 0]), door_row("gate", [-3, 1], "open")]))
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	door(sim, "h", "hatch", "open")  # a MID-FLIP state must serialize
	var snapshot: Dictionary = sim.to_dict()
	var mid_hash: String = sim.state_hash()
	assert_true((snapshot["arena"] as Dictionary).has("doors"), "doors ride the arena block")
	assert_eq(String((((snapshot["arena"] as Dictionary)["doors"] as Array)[0] as Dictionary).get("state", "")),
		"open", "the flipped state is what serializes")
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), mid_hash, "roundtrip hash identical (doors covered)")
	assert_eq(restored.arena.door_index_for("gate"), 1, "both doors restored, authored order")
	# Hash teeth: a tampered door state must change the run hash.
	var tampered: Dictionary = sim.to_dict()
	(((tampered["arena"] as Dictionary)["doors"] as Array)[0] as Dictionary)["state"] = "closed"
	assert_ne(CombatSim.from_dict(tampered).state_hash(), mid_hash,
		"door state is hash-covered — a silent flip cannot hide")
	# Lockstep: identical command tails from the restored snapshot.
	advance(sim, 1)
	advance(restored, 1)
	for s: CombatSim in ([sim, restored] as Array):
		s.apply_command({"type": "door", "actor": "h", "key": "hatch", "set": "closed"})
		s.apply_command({"type": "advance_tick"})
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")
	# The wave-3d byte-compat pin: a DOOR-LESS arena serializes with NO doors
	# key at all — pre-door arena saves and views keep their exact shape.
	var plain: CombatSim = make_sim()
	set_arena(plain, arena_cfg([[3, 0]]))
	assert_false((plain.to_dict()["arena"] as Dictionary).has("doors"),
		"no doors authored = no 'doors' key (byte-identical wave-3d arenas)")
	assert_false(plain.arena.view().has("doors"), "view_arena mirrors the pin")
